# Database (Supabase)

> **Source of truth warning:** this repository has **no `schema.sql` and no migrations**. The live
> schema, constraints, RLS policies, storage policies, and the scheduler for the edge function exist
> only in the hosted Supabase project `plfkyjmlhrqtqblprtbz` ("DailyDay-KRB").
> Everything below is **inferred from client and edge-function code** (model `fromJson`/`toJson`,
> queries, upsert conflict targets). Verify it against the project before relying on exact types, defaults, or
> policies. The first database task for any agent should be to dump the real schema into an
> idempotent `supabase/schema.sql`, for example with `supabase db dump --schema public`.

## Conventions observed

- Primary key `id`: a string on the client, almost certainly `uuid default gen_random_uuid()`.
- `created_at`: a server default (the client never sends it).
- Date-only columns are sent as `yyyy-MM-dd` strings. `todo_list.start_time`/`end_time` are full timestamps.
- Money and litres are parsed as `num` then converted to double (`numeric`/`float` columns).
- **No `user_id` / `farm_id` on any domain table.** All data is shared across all authenticated users.
- Every table read through `.stream()` must be in the `supabase_realtime` publication.

## Tables

### `cows`
`id`, `tag_number` (text; formats seen: `KRB-101` and bare numbers), `name`, `breed`, `age` (int years at
registration), `dob` (date), `health_status` (default 'Healthy'), `image_url`, `image_urls` (text[]),
`created_at`, `cow_type` ('Cow' | 'Bull' | 'Buffalo' | …; default 'Cow'), `is_born_in_farm` (bool),
`mother_cow_id` (FK → `cows.id`, self-reference for calves), `status` ('Active' | 'Sold' | 'Deceased'),
`is_dry` (bool), `buyer_name`, `sale_price`, `sale_date`, `source`, `purchase_price`, `health_at_purchase`.
Streamed. Ordered by `tag_number`.

### `shift_milk_entries`
`id`, `entry_date` (date), `shift` ('Morning' | 'Evening'), `quantity` (litres), `fat_percentage`, `snf`.
**Requires a unique constraint on `(entry_date, shift)`** because the client upserts on it. Streamed.

### `cow_milk_estimates`
`id`, `shift_entry_date` (date), `shift`, `cow_id` (FK → cows), `estimated_liters`.
Saved with a delete-then-insert-each-row pattern per date+shift (not atomic).

### `breeding_records`
`id`, `cow_id` (FK → cows), `breeding_date` (date), `details`, `created_at`. Streamed.
The edge function embeds `cows:cow_id ( tag_number )`, so the FK must exist.

### `health_records`
`id`, `cow_id` (FK → cows), `date` (date), `type`, `treatment`, `administered_by`, `notes`. Streamed (raw maps).

### `payments` (income)
`id`, `title`, `description`, `category`, `amount`, `payment_date` (date), `notes`, `period_start`,
`period_end`. `sellCow()` also writes **`buyer_name`**, which the `Payment` model never reads. Streamed.

### `expenses`
`id`, `title`, `category`, `amount`, `expense_date` (date), `notes`, `is_recurring` (bool),
`frequency` ('daily' | 'weekly' | 'monthly'), `last_auto_date` (date), `cow_id` (FK → cows, nullable),
`cow_tag` (denormalised). Recurring rows act as templates, and generated copies are prefixed `(Auto)`. Streamed.

### `monthly_budgets`
`id`, `category`, `month` (int), `year` (int), `budget_amount`. **Unique `(category, month, year)`** (upsert target).

### `milk_goals`
`id`, `month`, `year`, `target_liters`. **Unique `(month, year)`** (upsert target).

### `todo_list`
`id`, `task`, `description`, `is_done`, `created_at`, `start_time`, `end_time` (timestamptz),
`priority` ('low' | 'medium' | 'high'), `cow_id`, `cow_tag`, `category`. Streamed.

### `vet_contacts`
`id`, `name`, `phone`, `specialty`, `notes`, `created_at`. Streamed.

### `custom_alerts`
`id`, `title`, `notes`, `cow_id`, `cow_tag`, `alert_date` (date), `alert_time` (time, nullable = all
day), `is_recurring`, `frequency`, `is_dismissed` (bool), `created_at`. Streamed.
`is_recurring`/`frequency` are stored, but the edge function ignores them: it dismisses the alert after
firing once.

### `notifications`
`id`, `title`, `body`, `type` ('custom' | 'breeding'), `payload` (jsonb; `alert_id`, `breeding_id`,
`cow_id`), `is_read` (bool), `created_at`. Written by the edge function (service role), streamed by
clients, and `is_read` is updated by clients.

### `user_push_tokens`
`user_id` (FK → `auth.users`), `push_token`, `device_platform` ('android' | 'ios').
The client upserts **without `onConflict`**, so de-duplication depends on the table's primary key or unique
constraint (ideally unique on `push_token`). If none exists, rows accumulate on every launch. The edge
function de-duplicates in memory.

### Legacy
`lib/models/milk_entry.dart` (`MilkEntry`: per-cow `cow_id`, `entry_date`, `shift`, `quantity`, embedded
`cows`) is **not imported anywhere**. A legacy `milk_entries` table may still exist in the project.

## Storage

- Bucket **`cow-images`**, used as a **public** bucket (`getPublicUrl`). The object name is
  `cow_<sanitisedTag>_<epochMs>.jpg`, flat with no folders. Uploaded with `upsert: false` and
  `cacheControl: '0'`. Images are never deleted when a cow is deleted.

## Edge function: `process-farm-alerts`

- Path: `supabase/functions/process-farm-alerts/index.ts` (Deno, `std@0.168.0`, `supabase-js@2.38.4`).
- Secrets: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (provided by the platform), and
  `FIREBASE_SERVICE_ACCOUNT` (full service-account JSON). If the Firebase secret is missing, the function
  still writes notifications but skips push.
- It has no caller authentication of its own: it responds to any request that passes the gateway's JWT
  check, and sends `Access-Control-Allow-Origin: *`. Deploy with JWT verification **on**, and call it only
  from a scheduler.
- The trigger/schedule is **not in the repo**. Expected cadence is every few minutes (custom alerts
  compare `alert_time <= now` in IST).
- It returns `{ success, processed_alerts, inserted_notifications }`, or HTTP 400 with `{ error }`.

## RLS expectations (to verify, not confirmed)

The app is used only by internal staff with pre-provisioned accounts, and sharing all farm data among them
is intended. The goal of RLS here is to keep **non-staff** out, not to isolate staff from each other.
Internal APK distribution lowers the chance of the anon key leaking, but doesn't remove it: a forwarded
APK or a lost phone still exposes the key. The minimum acceptable policy set is: RLS **enabled** on every table
above, with `authenticated` allowed to select, insert, update, and delete domain tables and `anon` denied everything.
`notifications` insert should be restricted to the service role. `user_push_tokens` should be restricted to
`user_id = auth.uid()`. If RLS is disabled anywhere, the public anon key in the app gives full
read/write access to that table to anyone who extracts it from the APK.
