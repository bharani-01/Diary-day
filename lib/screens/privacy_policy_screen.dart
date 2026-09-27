import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/language_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.isTamil ? 'தனியுரிமைக் கொள்கை' : 'Privacy Policy'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              lp.isTamil ? 'KRB டெய்ரி பார்ம்ஸ் தனியுரிமைக் கொள்கை' : 'KRB Dairy Farms Privacy Policy',
              lp.isTamil ? 'கடைசியாக புதுப்பிக்கப்பட்டது: மே 26, 2026' : 'Last Updated: May 26, 2026',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              lp.isTamil ? '1. அறிமுகம் மற்றும் கொள்கையின் நோக்கம்' : '1. Introduction and Scope of Policy',
              lp.isTamil 
                  ? 'இந்த தனியுரிமைக் கொள்கை ("கொள்கை") KRB டெய்ரி பார்ம்ஸ் மொபைல் செயலியை நீங்கள் பயன்படுத்தும் போது சேகரிக்கப்படும் தகவல்களின் தனியுரிமை நடைமுறைகளை உங்களுக்கு விளக்க உருவாக்கப்பட்டது. இந்த செயலி உங்கள் பண்ணை மற்றும் கால்நடைகளின் தினசரி உற்பத்தி, மருத்துவப் பதிவுகள், மற்றும் நிதிப் பரிவர்த்தனைகளை ஒழுங்குபடுத்த வடிவமைக்கப்பட்டுள்ளது. செயலியைப் பயன்படுத்துவதன் மூலம், இந்த கொள்கையின் கீழ் உங்கள் தனிப்பட்ட மற்றும் பண்ணைத் தரவைச் சேகரிப்பதற்கும், மாற்றுவதற்கும், சேமிப்பதற்கும் நீங்கள் முழுமையாகச் சம்மதிக்கிறீர்கள்.'
                  : 'This Privacy Policy ("Policy") explains the privacy practices and data handling protocols applied by KRB Dairy Farms when you use our mobile application. This application is designed to help organize and streamline dairy herd management, milk production logging, medical registry, and expense tracking. By installing and accessing this application, you express your voluntary consent to the collection, transmission, and processing of your personal and farm-specific data under the terms of this Policy.',
            ),
            _buildSection(
              lp.isTamil ? '2. நாங்கள் சேகரிக்கும் தகவல்கள்' : '2. Information We Collect',
              lp.isTamil
                  ? 'செயலியின் செயல்பாட்டிற்காக பின்வரும் தகவல்கள் உங்களிடமிருந்து சேகரிக்கப்படுகின்றன:\n\n'
                    'அ) பயனர் கணக்குத் தரவு:\n'
                    'கைமுறையாக உருவாக்கப்படும் கணக்குக்கான மின்னஞ்சல் முகவரி, பயனர் பெயர், மற்றும் கடவுச்சொற்கள்.\n\n'
                    'ஆ) பண்ணை மற்றும் கால்நடைத் தரவு:\n'
                    '• மாடுகளின் அடையாளக் குறியீடு (Tag Number), வயது, இனம், மற்றும் அவற்றின் தற்போதைய நிலை (Milking/Dry/Sold).\n'
                    '• தினசரி பால் கறவை அளவுகள் (காலை மற்றும் மாலை ஷிப்ட் வாரியாக).\n'
                    '• மாடுகளின் பேறுகாலப் பதிவுகள் (Breeding records) மற்றும் அடுத்த கன்று ஈனும் தேதிகள்.\n'
                    '• மாடுகளின் மருத்துவ சிகிச்சைப் பதிவுகள், பயன்படுத்தப்பட்ட மருந்து விவரங்கள், மற்றும் கால்நடை மருத்துவர் தொடர்பு எண்கள்.\n\n'
                    'இ) நிதி பரிவர்த்தனைத் தரவு:\n'
                    '• பால் விற்பனை மூலம் பெறப்படும் வருமானம் மற்றும் வாடிக்கையாளர் விவரங்கள்.\n'
                    '• தீவனம், மருத்துவம், மற்றும் பிற பண்ணைப் பராமரிப்புச் செலவுகளுக்கான கட்டணங்கள்.'
                  : 'The application collects and processes the following parameters to ensure proper herd tracking and analysis:\n\n'
                    'A) User Account Information:\n'
                    'Admin-provisioned login email credentials, usernames, encrypted authentication tokens, and passwords.\n\n'
                    'B) Herd & Cattle Specific Data:\n'
                    '• Cow unique Tag Numbers, age, breed type, health condition, pedigree, and status (Milking, Dry, or Sold).\n'
                    '• Daily milk production logs categorized by morning and evening shifts.\n'
                    '• Artificial insemination, breeding records, pregnancy scans, and estimated calving dates.\n'
                    '• Vet medical treatment records, medication logs, and veterinarian directory numbers.\n\n'
                    'C) Transactional and Financial Logs:\n'
                    '• Income records from milk purchasers and buyers.\n'
                    '• Categorized farm expenses such as cattle feed, veterinary services, labor, and capital investment.',
            ),
            _buildSection(
              lp.isTamil ? '3. சாதன அனுமதிகள் மற்றும் அவற்றின் பயன்பாடு' : '3. Device Permissions & Hardware Access',
              lp.isTamil
                  ? 'செயலியின் முழுமையான செயல்பாட்டிற்கு உங்கள் சாதனத்திலிருந்து பின்வரும் அனுமதிகள் கோரப்படும்:\n\n'
                    '• கேமரா மற்றும் புகைப்படத் தொகுப்பு (Camera & Photo Gallery): மாடுகளைச் சேர்க்கும் போது அல்லது அவற்றின் அடையாளத்திற்காக புகைப்படங்களைப் படம் பிடித்து கிளவுட் சேமிப்பகத்தில் பதிவேற்ற இந்த அனுமதி தேவைப்படும்.\n'
                    '• பயோமெட்ரிக் அங்கீகாரம் (Fingerprint / FaceID): உங்கள் பண்ணைத் தரவை பிறர் பார்க்காதவாறு சாதனத்திலேயே பாதுகாப்பாகத் திறக்க இந்த அனுமதி பயன்படுகிறது. உங்கள் பயோமெட்ரிக் அடையாளத் தரவு எதுவும் எங்கள் சர்வருக்கு அனுப்பப்படாது, அது உங்கள் மொபைல் சாதனத்திலேயே குறியாக்கம் செய்யப்பட்டு பாதுகாக்கப்படுகிறது.\n'
                    '• புஷ் அறிவிப்புகள் (Push Notifications): மாடுகளின் பேறுகால நினைவூட்டல்கள், அவசர மருத்துவ கால அட்டவணைகள், மற்றும் தினசரி பால் பதிவு செய்வதற்கான நினைவூட்டல் அறிவிப்புகளை உங்களுக்கு அனுப்பப் பயன்படுகிறது.'
                  : 'To enable interactive hardware-level integrations, the application requests the following operating system permissions:\n\n'
                    '• Camera & Storage Library Access: Required to capture and attach profile photographs to individual cattle records, which are stored in the cloud storage bucket.\n'
                    '• Biometric Hardware Authentication (Fingerprint/FaceID): Used to lock the app locally. The biometric hashing is processed strictly on-device by the operating system’s secure enclave. KRB Dairy Farms never accesses, reads, or transmits your raw biometric templates.\n'
                    '• Local & Push Notification Triggers: Used to sound immediate alarms and push background reminders for daily shifts, vet appointments, and calving alerts.',
            ),
            _buildSection(
              lp.isTamil ? '4. தரவு சேமிப்பு மற்றும் கிளவுட் பாதுகாப்பு' : '4. Data Storage & Cloud Security',
              lp.isTamil
                  ? 'உங்கள் பண்ணைத் தரவு அனைத்தும் எங்களின் பாதுகாப்பான சப்போபேஸ் (Supabase) கிளவுட் தரவுத்தளத்தில் சேமிக்கப்படுகிறது. தரவு பரிமாற்றம் அனைத்தும் TLS குறியாக்க தொழில்நுட்பம் மூலம் மிகவும் பாதுகாப்பாக நிகழ்கிறது. உங்கள் அனுமதியின்றி இந்தத் தரவு எக்காரணம் கொண்டும் பிற நிறுவனங்களுக்கோ அல்லது விளம்பரதாரர்களுக்கோ பகிரப்படாது.'
                  : 'All farm logs are securely offloaded to our Supabase cloud database instance. Information transit is secured via TLS (Transport Layer Security) encryption. Database tables employ row-level security policies to ensure that your records are protected from unauthorized access. Your metrics are never sold, rented, or shared with third-party advertising networks.',
            ),
            _buildSection(
              lp.isTamil ? '5. தரவு தக்கவைப்பு மற்றும் நீக்கம்' : '5. Data Retention & Deletion Rights',
              lp.isTamil
                  ? 'உங்கள் பயனர் கணக்கு செயலில் இருக்கும் வரை உங்கள் பண்ணைத் தரவு கிளவுடில் சேமிக்கப்படும். உங்கள் கணக்கையும் அதனுடன் இணைக்கப்பட்ட அனைத்து தரவுகளையும் முழுமையாக நீக்க விரும்பினால், எங்களின் நிர்வாகியைத் தொடர்பு கொண்டு உங்கள் கணக்கை நீக்கக் கோரலாம். கோரிக்கை விடுக்கப்பட்ட 30 நாட்களுக்குள் உங்கள் அனைத்துத் தரவுகளும் சர்வரிலிருந்து நிரந்தரமாக அழிக்கப்படும்.'
                  : 'We retain your farm metadata as long as your admin-managed user account remains active. Should you choose to terminate your usage of this service and request database purging, you can contact our administrator. Upon verification, all records associated with your account will be permanently deleted from our servers within 30 days.',
            ),
            _buildSection(
              lp.isTamil ? '6. மாற்றங்கள் மற்றும் தொடர்புக்கு' : '6. Changes to this Policy & Contact Information',
              lp.isTamil
                  ? 'இந்த தனியுரிமைக் கொள்கை எப்போது வேண்டுமானாலும் மாற்றியமைக்கப்படலாம். மாற்றங்கள் செயலியின் தற்போதைய அப்டேட்டில் பிரதிபலிக்கும். கொள்கை குறித்து ஏதேனும் கேள்விகள் அல்லது புகார்கள் இருந்தால், krbdairyfarms@gmail.com என்ற மின்னஞ்சலில் எங்களை அணுகலாம்.'
                  : 'KRB Dairy Farms reserves the right to revise this Privacy Policy to comply with evolving data protection regulations. Users will be notified of material changes within the app. For feedback or inquiries regarding your data privacy, write to us at krbdairyfarms@gmail.com.',
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'KRB Dairy Farms © 2026',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String lastUpdated, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lastUpdated,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        const Divider(thickness: 1.5),
      ],
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
