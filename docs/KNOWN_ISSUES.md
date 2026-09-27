# Known Issues and Risks

This register comes from a full static review (September 2026) plus `dart analyze lib` on Flutter 3.44 / Dart 3.12.
Severity: **P0** means it blocks builds or is an active security exposure, **P1** means incorrect behaviour or data risk, and **P2** means quality or maintainability.
When you fix an item, remove it here and note the fix in your summary.

## Build and toolchain

| Sev | Issue | Where |
| --- | --- | --- |
| P0 | The app can't be built on this machine. It targets about Flutter 3.7 / Dart 2.19 (per `pubspec.lock`), but the only SDK installed is Flutter 3.44. On 3.44, `main.dart` fails (`CardTheme`/`DialogTheme` must become `CardThemeData`/`DialogThemeData`), and so do locked packages: `fl_chart 0.62` (`MediaQuery.boldTextOverride`), `win32 4.1.4` and `archive 3.4.10` (`UnmodifiableUint8ListView`), and `cached_network_image 3.2.x` (`DecoderCallback`). Fix it either by installing Flutter 3.7.x (fvm) or by doing a full dependency migration (supabase_flutter 1→2, fl_chart, firebase, etc.). | `lib/main.dart`, `pubspec.lock` |
| P1 | Every dependency is `any` except `home_widget: <0.3.0`, so builds aren't reproducible without `pubspec.lock`. The lock pins old majors (`supabase_flutter 1.10.25`, `fl_chart 0.62`, `firebase_messaging 14`), and a clean `pub get` on a new SDK may pick breaking versions. | `pubspec.yaml` |
| P1 | `intl`, `rxdart`, `http`, and `timezone` are imported but only available transitively. Declare them directly. | `database_service.dart`, `report_service.dart`, `weather_service.dart`, `notification_service.dart` |
| P2 | `test/widget_test.dart` is the Flutter counter template and fails. There are no real tests. | `test/` |
| P2 | Analyzer shows 12 warnings (unused imports and fields) and 142 infos (mostly deprecated `withOpacity`, and `print` in production code). | `lib/**` |
| P2 | The folder isn't a git repository yet, so the CI workflow (`.github/workflows/android-build.yml`) hasn't run and is unverified. Release build has `minifyEnabled false` and lint `abortOnError false`. Java/Kotlin target is 1.8. | root, `android/app/build.gradle` |
| P2 | Root `fix_const.dart`, `fix_dark_mode.dart`, and `fix_theme.dart` are one-off codemods left in the project root. | root |

## Security

Context: the app is internal-only. Staff accounts are pre-provisioned, the APK is shared internally,
and all staff intentionally share the same farm data. The risks below concern **outsiders** getting in
and **losing control of the release pipeline**, not staff seeing each other's data.

| Sev | Issue | Where |
| --- | --- | --- |
| P1 | RLS status is unknown and not versioned. The Supabase URL and anon key are inside the APK, so a forwarded APK or lost phone lets anyone call the API directly. Any table without RLS limited to `authenticated` is open to them. Verify once and capture the policies in `schema.sql`. | Supabase project (see `DATABASE.md`) |
| P1 | The release keystore and its plaintext passwords sit together in the project tree. The main internal risk is **losing** it: without this keystore, installed phones can't take updates without an uninstall, which wipes local data such as calendar notes and settings. Back it up outside this folder, and keep it out of any git repo. | `android/key.properties`, `android/app/upload-keystore.jks` |
| P2 | OpenWeatherMap API key is hardcoded in the client. Low impact for an internal app (worst case is quota abuse). Restrict it at the provider or proxy it if that becomes a problem. | `lib/services/weather_service.dart` ~276 |
| P2 | `process-farm-alerts` allows `*` CORS and has no check beyond the gateway JWT. Keep JWT verification on and call it only from the scheduler. Sending every alert to every staff device is intended. | `supabase/functions/process-farm-alerts/index.ts` |
| P2 | Optional: there's no role separation, so any staff member can delete cows or financial records. Add an owner/worker role only if the farm asks for it. | all tables |
| P2 | `cow-images` is a public bucket with guessable names (`cow_<tag>_<epoch>.jpg`). Acceptable for cow photos. Switch to private + signed URLs only if images become sensitive. | `DatabaseService.uploadCowImage` |
| P2 | The FCM device token and notification contents are printed to logs. The success animation loads Lottie JSON from a third-party URL at runtime, so it fails offline. | `main_navigation_screen.dart`, `milk_entry_success_screen.dart` |

## Behaviour and data bugs

| Sev | Issue | Where |
| --- | --- | --- |
| P1 | Every time the dashboard opens it reschedules **both** shift reminders to 20:00, overwriting the times and the on/off switch the user set in Alerts Manager. | `dashboard_screen.dart` `_scheduleDailyDigest` vs `alerts_manager_screen.dart` |
| P1 | Recurring expenses are generated client-side on dashboard open. Two devices can create duplicates, because it's a read-then-insert race. Only one period is caught up per open. Entries are dated today rather than the due date. Monthly rollover from the 29th–31st overflows into the next month. | `DatabaseService.autoCreateRecurringExpenses` |
| P1 | Multi-step writes aren't atomic: sell cow (update, then insert payment), purchase cow (insert cow, then insert expense), and per-cow estimates (delete, then N inserts). A failure midway leaves partial data. Move them into Postgres RPC functions. | `database_service.dart` |
| P1 | In-app notification `is_read` is global. The first device to receive a notification marks it read, so other devices never show it. The listener looks only at the newest row, so a batch of several new notifications shows only one. | `main_navigation_screen.dart` `_listenToLiveNotifications` |
| P1 | Calving push matches `breeding_date == today − 276 days` exactly, computed in **UTC** while other logic uses IST. If the function doesn't run on that exact day, the reminder is lost for good. Recurring `custom_alerts` fire once and are then dismissed permanently. | edge function Task B / Task A |
| P1 | Farm calendar notes are stored only in SharedPreferences. They're lost on reinstall and never shared across devices. | `farm_calendar_screen.dart` (`farm_notes`) |
| P2 | Two inconsistent tag generators: `getNextTagNumber()` produces numeric tags, and `getNextCowTag()` produces the `KRB-` prefix. | `database_service.dart` |
| P2 | Dashboard health mix and calving alerts include sold and deceased cows. "Healthy" is total cows minus those treated in the last 14 days. | `_calculateHealthStats`, `getDashboardDataStream` |
| P2 | Several screens still create realtime streams inside `build()`, so every rebuild tears down and re-opens a channel (fixed on the cow list; use the same `initState` pattern elsewhere). The dashboard also streams six full tables and aggregates on-device, and the cost grows with farm history. | `payments_expenses_screen.dart`, `dashboard_screen.dart` and others; `getDashboardDataStream` |
| P2 | Cow photos uploaded before the caching fix were stored with `Cache-Control: max-age=0`. The app keeps them on disk but revalidates them with a small conditional request (ETag, 304) each time they're loaded from disk. New uploads are cached for a year. Re-uploading or rewriting the metadata of old objects would remove the revalidation. | Storage `cow-images` |
| P2 | The herd list shows sold and deceased cows mixed in with active ones, and the card has no status badge. | `cow_list_screen.dart` |
| P2 | `deleteCow` doesn't remove storage images and may fail on FK references (health, breeding, estimates, calves) unless the database cascades. | `DatabaseService.deleteCow` |
| P2 | `user_push_tokens` upsert has no `onConflict`, so it may accumulate duplicate rows (see `DATABASE.md`). | `DatabaseService.registerPushToken` |
| P2 | Language choice isn't persisted. Many strings bypass `LanguageProvider.translate` (hardcoded English, or inline `isTamil ? … : …`). | `language_provider.dart`, screens |
| P2 | `NotificationService.autoScheduleFromPrefs()` is an empty placeholder. On Windows, "scheduled" notifications fire immediately. | `notification_service.dart` |
| P2 | Timezone is hardcoded to `Asia/Kolkata` in both the client and the edge function. | `notification_service.dart`, edge function |
| P2 | `lib/models/milk_entry.dart` is unused dead code. | `lib/models/` |
| P2 | iOS has no `GoogleService-Info.plist`. Firebase init fails silently there. Web is unsupported (`dart:io` `Platform` checks). | `ios/`, `main.dart` |

## Suggested order of work

1. Fix the four theme type errors so the app builds on the current SDK. Declare transitive imports and pin dependency ranges.
2. Back up the keystore outside the project, then initialise git with a `.gitignore` that excludes it.
3. Dump the live schema and RLS into an idempotent `supabase/schema.sql`. Verify every table allows `authenticated` only.
4. Move multi-step writes, recurring expenses, and calving detection server-side (RPC or edge function with IST-correct, range-based matching).
5. Fix the reminder override and per-device notification delivery.
6. Replace the template test with real model and service tests.
