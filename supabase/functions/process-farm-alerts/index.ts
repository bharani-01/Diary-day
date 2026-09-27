import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Custom OAuth2 Signer using Native WebCrypto for Deno
async function getFcmAccessToken(serviceAccountJson: any): Promise<string> {
  const email = serviceAccountJson.client_email;
  const privateKeyPem = serviceAccountJson.private_key;
  
  // Format PEM key contents
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = privateKeyPem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");
  
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0));
  
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );
  
  const header = {
    alg: "RS256",
    typ: "JWT",
  };
  
  const now = Math.floor(Date.now() / 1000);
  const claimSet = {
    iss: email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };
  
  const base64url = (json: any) => {
    const str = JSON.stringify(json);
    const bytes = new TextEncoder().encode(str);
    let bin = "";
    for (let i = 0; i < bytes.byteLength; i++) {
      bin += String.fromCharCode(bytes[i]);
    }
    return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
  };
  
  const tokenInput = `${base64url(header)}.${base64url(claimSet)}`;
  const tokenInputBytes = new TextEncoder().encode(tokenInput);
  
  const signatureBytes = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    privateKey,
    tokenInputBytes
  );
  
  let signatureBin = "";
  const sigBytesArr = new Uint8Array(signatureBytes);
  for (let i = 0; i < sigBytesArr.byteLength; i++) {
    signatureBin += String.fromCharCode(sigBytesArr[i]);
  }
  const signature = btoa(signatureBin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
  
  const assertion = `${tokenInput}.${signature}`;
  
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${assertion}`,
  });
  
  const data = await res.json();
  if (data.error) {
    throw new Error(`Google OAuth2 key exchange failed: ${data.error_description || data.error}`);
  }
  
  return data.access_token;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Initialize Supabase Client using backend environment keys
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ""
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ""
    
    if (!supabaseUrl || !supabaseKey) {
      throw new Error("Missing environment variables: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY")
    }

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Calculate dates and times in Indian Standard Time (IST - Asia/Kolkata)
    const formatterDate = new Intl.DateTimeFormat('en-CA', { 
      timeZone: 'Asia/Kolkata', 
      year: 'numeric', 
      month: '2-digit', 
      day: '2-digit' 
    })
    const todayStr = formatterDate.format(new Date()) // YYYY-MM-DD

    const formatterTime = new Intl.DateTimeFormat('en-US', { 
      timeZone: 'Asia/Kolkata', 
      hour12: false, 
      hour: '2-digit', 
      minute: '2-digit', 
      second: '2-digit' 
    })
    const currentTimeStr = formatterTime.format(new Date()) // HH:MM:SS

    const newNotifications = []

    // ==========================================
    // TASK A: Process Custom Alerts Due Today
    // ==========================================
    const { data: customAlerts, error: alertErr } = await supabase
      .from('custom_alerts')
      .select('id, title, cow_tag, notes, cow_id, alert_time')
      .eq('alert_date', todayStr)
      .eq('is_dismissed', false)

    if (alertErr) throw alertErr

    // Filter alerts to only trigger if their scheduled time has arrived or passed (or if alert_time is null/all-day)
    const activeAlerts = (customAlerts || []).filter(alert => {
      if (!alert.alert_time) return true; // All-day / general alert
      return alert.alert_time <= currentTimeStr;
    })

    for (const alert of activeAlerts) {
      newNotifications.push({
        title: `🔔 Reminder: ${alert.title}`,
        body: alert.cow_tag ? `Cow: ${alert.cow_tag}. ${alert.notes || ''}` : `${alert.notes || ''}`,
        type: 'custom',
        payload: { alert_id: alert.id, cow_id: alert.cow_id }
      })
      
      // Auto-dismiss in database to avoid triggering on the next run
      await supabase
        .from('custom_alerts')
        .update({ is_dismissed: true })
        .eq('id', alert.id)
    }

    // ==========================================
    // TASK B: Process Calving Reminders (7 Days Out)
    // ==========================================
    // Calving is expected ~283 days after breeding.
    // Calving reminder fires 7 days before calving, which is 276 days after breeding date.
    const breedingThreshold = new Date()
    breedingThreshold.setDate(breedingThreshold.getDate() - 276)
    const thresholdStr = breedingThreshold.toISOString().split('T')[0]

    // Fetch breeding records from exactly 276 days ago
    const { data: breedingRecords, error: breedErr } = await supabase
      .from('breeding_records')
      .select('id, breeding_date, cow_id, cows:cow_id ( tag_number )')
      .eq('breeding_date', thresholdStr)

    if (breedErr) throw breedErr

    for (const record of breedingRecords || []) {
      const cowTag = (record.cows as any)?.tag_number || 'Unknown'
      
      // De-duplicate checking: Ensure we have not already inserted a calving alert for this breeding record
      const { data: existingNotifs, error: existErr } = await supabase
        .from('notifications')
        .select('id')
        .eq('type', 'breeding')
        .contains('payload', { breeding_id: record.id })

      if (existErr) throw existErr

      if (!existingNotifs || existingNotifs.length === 0) {
        newNotifications.push({
          title: `🐄 Calving Alert: Cow ${cowTag}`,
          body: `Expected calving in ~7 days! Cow bred on ${record.breeding_date}.`,
          type: 'breeding',
          payload: { breeding_id: record.id, cow_id: record.cow_id }
        })
      }
    }

    // ==========================================
    // TASK C: Insert Notifications into DB
    // ==========================================
    if (newNotifications.length > 0) {
      const { error: insertErr } = await supabase
        .from('notifications')
        .insert(newNotifications)
        
      if (insertErr) throw insertErr

      // ==========================================
      // TASK D: Dispatch FCM Push Notifications
      // ==========================================
      const serviceAccountEnv = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
      if (serviceAccountEnv) {
        try {
          const serviceAccount = JSON.parse(serviceAccountEnv);
          const projectId = serviceAccount.project_id;
          const accessToken = await getFcmAccessToken(serviceAccount);
          
          // Fetch all registered push tokens
          const { data: tokenRows, error: tokenErr } = await supabase
            .from('user_push_tokens')
            .select('push_token');
            
          if (!tokenErr && tokenRows && tokenRows.length > 0) {
            const uniqueTokens = Array.from(new Set(tokenRows.map(r => r.push_token)));
            
            for (const notification of newNotifications) {
              for (const deviceToken of uniqueTokens) {
                try {
                  await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
                    method: 'POST',
                    headers: {
                      'Authorization': `Bearer ${accessToken}`,
                      'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                      message: {
                        token: deviceToken,
                        notification: {
                          title: notification.title,
                          body: notification.body,
                        },
                        data: {
                          click_action: "FLUTTER_NOTIFICATION_CLICK",
                          type: notification.type,
                          payload: JSON.stringify(notification.payload || {}),
                        },
                        android: {
                          priority: "high",
                          notification: {
                            channel_id: "main_channel",
                            sound: "default",
                            notification_priority: "PRIORITY_HIGH",
                            default_sound_config: true
                          }
                        },
                        apns: {
                          headers: {
                            "apns-priority": "10"
                          },
                          payload: {
                            aps: {
                              sound: "default",
                              contentAvailable: true
                            }
                          }
                        }
                      }
                    })
                  });
                } catch (e) {
                  console.error(`FCM: Error sending push to device token: ${e}`);
                }
              }
            }
          }
        } catch (fcmError) {
          console.error(`FCM system dispatch failed: ${fcmError}`);
        }
      } else {
        console.log("FCM: FIREBASE_SERVICE_ACCOUNT environment variable is not set. Skipping push alerts.");
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        processed_alerts: customAlerts?.length || 0,
        inserted_notifications: newNotifications.length 
      }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }), 
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})
