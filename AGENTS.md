# AGENTS.md — KRB Dairy Farms (DiaryDay)

Operating guide for AI coding agents working in this repository. Read this first, then the
focused references in `docs/` as needed:

| Doc | Read when |
| --- | --- |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Touching app startup, navigation, realtime, notifications, home widgets, reports |
| [`docs/DATABASE.md`](docs/DATABASE.md) | Touching any Supabase table, storage bucket, or the edge function |
| [`docs/KNOWN_ISSUES.md`](docs/KNOWN_ISSUES.md) | Before fixing bugs, hardening security, or upgrading the SDK |

## 1. What this app is

A single-farm dairy management app for **KRB Dairy Farms** (Paramathi Velur, Namakkal, Tamil Nadu).
Farm staff record twice-daily milk production, manage the herd (cows, buffalo, calves, bulls),
track breeding/calving and health treatments, log income and expenses, and receive reminders.

- Package name: `krb_dairy_farms` (Dart), `com.krbdairyfarms.app` (Android)
- Display name: "KRB Dairy Farms"; the Windows notifier and folder use "DiaryDay"
- UI languages: English and Tamil (runtime toggle, not persisted)
- Currency: INR (₹). Timezone: hard-wired to `Asia/Kolkata`
- **Internal-only tool:** used only by KRB's own staff. Accounts are pre-provisioned in Supabase
  Auth (there is no sign-up screen, and OTP login uses `shouldCreateUser: false`), and the APK is
  distributed internally, not through a public store.
- **Shared data by design:** there is no farm or owner scoping in any query. Every signed-in staff
  member sees and edits the same farm data, and that is intended. Don't add multi-tenancy,
  per-user data isolation, or public sign-up unless explicitly asked. The security boundary is
  "authenticated staff vs everyone else", not "user vs user".

## 2. Tech stack

| Layer | Technology |
| --- | --- |
| Client | Flutter (Material 3), Dart, `provider` for app-wide settings state |
| Backend | Supabase: Postgres + PostgREST, Auth (email/password and email OTP), Realtime, Storage |
| Server logic | One Supabase Edge Function (Deno/TypeScript): `supabase/functions/process-farm-alerts` |
| Push | Firebase Cloud Messaging (Android/iOS only), sent from the edge function via FCM HTTP v1 |
| Local notifications | `flutter_local_notifications` (mobile), `local_notifier` (Windows) |
| Charts / reports | `fl_chart`, `pdf` + `printing`, `excel`, `share_plus` |
| Weather | Open-Meteo (no key) plus OpenWeatherMap (key hardcoded in client) |
| Android extras | 7 home-screen widgets via `home_widget` + Kotlin `AppWidgetProvider`s |

Supabase project ref: `plfkyjmlhrqtqblprtbz` (linked via `supabase/.temp/linked-project.json`).

## 3. Commands

Flutter is **not on PATH** on this machine. The SDK lives at `D:\flutter` (see `android/local.properties`).
Use the full path from PowerShell:

```powershell
D:\flutter\bin\flutter.bat pub get
D:\flutter\bin\dart.bat analyze lib          # currently 4 errors, 12 warnings, 142 infos
D:\flutter\bin\flutter.bat test              # only test is a stale template (fails)
D:\flutter\bin\flutter.bat run -d windows    # or an Android device id
D:\flutter\bin\flutter.bat build apk --release
```

**CI build (GitHub Actions):** `.github/workflows/android-build.yml` builds on Flutter 3.7.12 / Java 11
on every push to `main`, on PRs, and on manual runs (Actions → Android build → Run workflow). It uploads
the APK as the `krb-dairy-apk-<run>` artifact. Repository secrets it uses:
`GOOGLE_SERVICES_JSON_BASE64` (required), and `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` (for a release APK; without them it builds a debug APK).
This is the only verified way to build the app while the local SDK is 3.44.

Edge function (requires the Supabase CLI, not currently installed or verified):

```powershell
supabase functions deploy process-farm-alerts
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(Get-Content service-account.json -Raw)"
```

**Toolchain status:** the app targets roughly **Flutter 3.7 / Dart 2.19**. The committed
`pubspec.lock` (sky_engine 0.0.99, collection 1.17.0, meta 1.8.0) and `sdk: '>=2.19.0 <4.0.0'`
both point there. The only SDK installed on this machine is **Flutter 3.44 / Dart 3.12**, and the
project **cannot build on it**: `lib/main.dart` has 4 theme type errors, and locked packages
(`fl_chart 0.62`, `win32 4.1.4`, `archive 3.4.10`, `cached_network_image 3.2.x`) use APIs removed
from the newer SDK. Until the owner decides between installing a matching Flutter 3.7.x (for example
via fvm) and migrating to the current SDK:
- write code that compiles on Flutter 3.7 (use `withOpacity`, not `withValues`; no Dart 3 records,
  patterns, or `sealed`/`final class`);
- don't run `pub get`/`pub add` with the 3.44 SDK and keep the resulting lock. It rewrites
  SDK-pinned packages and, for new dependencies, picks versions that need Dart 3. Back up and
  restore `pubspec.lock`, and pin new dependencies to Dart-2.19-compatible ranges;
- `dart analyze <files>` works on 3.44 for catching errors in files you touched.

## 4. Repository layout

```
lib/
  main.dart                 Boot: Firebase → notifications → Supabase → stale-session recovery → providers → MaterialApp (light/dark themes)
  constants.dart            Supabase URL + anon key, brand colours, spacing, shared InputDecoration
  models/                   Plain Dart classes with fromJson/toJson (snake_case columns ↔ camelCase fields)
  services/
    database_service.dart   The ONLY data-access layer: every Supabase table/stream/storage call
    notification_service.dart  Local + scheduled notifications (static API)
    report_service.dart     PDF/Excel generation and sharing
    weather_service.dart    Open-Meteo + OpenWeatherMap, location stored in SharedPreferences
    biometric_service.dart  local_auth wrapper; enabled flag in SharedPreferences
    *_provider.dart         ChangeNotifiers: language, theme, privacy (hide balances), dashboard shortcuts
  screens/                  One file per screen (~40). Tabs: dashboard, milk history, cows, finance, alerts
  widgets/                  Shared UI: global_drawer, global_error_view, error_dialog, premium_loading, stat_card
  utils/error_handler.dart  Maps exceptions (Socket, Timeout, Postgrest, Storage, Auth) → user-facing AppError
supabase/functions/process-farm-alerts/index.ts   Cron-style alert processor + FCM sender
android/app/src/main/kotlin/.../DairyWidgetProvider.kt  All 7 home widget providers
test/widget_test.dart       Stale Flutter counter template; does not test this app
fix_const.dart, fix_dark_mode.dart, fix_theme.dart  One-off codemod scripts (string replace over lib/). Not part of the app.
build/                      Build output (contains a release APK). Never edit.
```

Not present: `schema.sql`, `supabase/migrations/`, `supabase/config.toml`, `.gitignore`, a git
repository, CI, or real tests. The database schema exists only in the hosted Supabase project and
is inferred in `docs/DATABASE.md`.

## 5. Conventions to follow

**Data access**
- All Supabase access goes through `DatabaseService` (`lib/services/database_service.dart`). Screens
  create their own instance with `final _db = DatabaseService();`. Do not call `Supabase.instance.client`
  from screens, except for auth (login, sign-out, current user).
- Lists that must stay live use `.stream(primaryKey: ['id'])` and render with `StreamBuilder`.
  One-shot reads use `Future` methods. Keep new tables consistent with this pattern.
- Dates go to the database as `yyyy-MM-dd` via `date.toIso8601String().split('T')[0]`. Timestamps
  (`todo_list.start_time`/`end_time`) use full ISO strings.
- Models: `fromJson` reads snake_case columns with null-safe defaults; `toJson` omits `id` and
  `created_at` so the database generates them. Follow this for new models.
- Upserts rely on unique constraints that must exist in the database:
  `shift_milk_entries(entry_date, shift)`, `monthly_budgets(category, month, year)`, `milk_goals(month, year)`.

**UI**
- Screens are `StatefulWidget`s and use `setState` locally. `provider` is only for the 4 global
  settings providers. Read them with `Provider.of<T>(context)`.
- Theme comes from `main.dart` (`_buildLightTheme` / `_buildDarkTheme`), seeded from
  `AppConstants.primaryColor` (teal `#0F766E`). Fonts: Work Sans (body), Epilogue (headings).
  Use `Theme.of(context)` colours instead of hardcoded `Colors.white` / `Colors.black87`, because
  dark mode is supported and the `fix_*.dart` scripts exist to clean up past hardcoding.
- Form fields use `AppConstants.inputDecoration(label, context)`.
- Remote photos use `CowImage` (`lib/widgets/cow_image.dart`), which adds a disk cache and decodes at display
  size. Don't use `Image.network`/`NetworkImage` for storage images; for `DecorationImage` use
  `ResizeImage(CachedNetworkImageProvider(url), width: ...)`. Pick images with `maxWidth`/`maxHeight`
  of 1280 so uploads stay small.
- Start realtime streams once in `initState` and store them in a field. Don't call `_db.get*Stream()` inside `build()`.
- Stream and async error states render `GlobalErrorView(error: ..., onRetry: ...)`, which uses
  `ErrorHandler.handle`. Loading is `CircularProgressIndicator` or `PremiumLoading`.
- Tab screens take `onMenuPressed: Function(int)` and render `GlobalDrawer(currentIndex, onTabSelected)`.
- Localisation: add keys to both `_en` and `_ta` in `language_provider.dart` and use
  `lp.translate('key')`. Many screens still inline `lp.isTamil ? '…' : '…'` or hardcode English.
  Prefer `translate` for new strings.

**Domain rules encoded in code** (keep consistent across client and edge function)
- Gestation: expected calving = breeding date + **283 days**; calving push fires at **276 days**.
- Cow life stage (`Cow.dynamicCowType`): under 6 months is a Calf, under 24 months a Heifer, otherwise
  a Cow. `Bull` and `Buffalo` are static types.
- Cow `status`: `Active` | `Sold` | `Deceased`. `is_dry` excludes a cow from milking lists.
- Shifts: `Morning` / `Evening`. There is one aggregate milk row per date+shift, and optional per-cow
  estimates live in `cow_milk_estimates`.
- Selling a cow also inserts a `payments` row. Purchasing a cow also inserts an `expenses` row
  (category `Cattle Purchase`). These are two separate non-transactional writes.
- Recurring expenses (`is_recurring` + `frequency` daily/weekly/monthly) are materialised
  **client-side** when the dashboard opens (`autoCreateRecurringExpenses`).

## 6. Guardrails

- **Secrets:** never add new secrets to the client or to committed files. The Supabase anon key in
  `constants.dart` is designed to be public, but only if RLS is correct. The OpenWeatherMap key and
  `android/key.properties` (keystore password) are already exposed, so don't copy them anywhere. Service-role
  and Firebase service-account credentials belong only in edge-function secrets.
- **Schema changes:** there is no schema file. If you change the database, create an idempotent
  `supabase/schema.sql` (or migration) capturing the full intended state, and update
  `docs/DATABASE.md`. Don't make changes silently through the dashboard.
- **RLS is unverified.** Don't claim a change is secure without checking policies in the Supabase
  project. See `docs/KNOWN_ISSUES.md`.
- Don't hand-edit `build/`, `.dart_tool/`, `*/flutter/ephemeral/`, `.flutter-plugins*`, or `pubspec.lock`
  (regenerate it with `pub get`).
- The `fix_*.dart` codemods do blind string replacement across `lib/`. Don't re-run them.
- Git: the root `.gitignore` and `android/.gitignore` exclude the keystore, `key.properties`,
  `local.properties`, `google-services.json`, `build/`, and `.dart_tool/`. CI restores the secret files
  from GitHub secrets. Before any first commit, run `git status --ignored` and confirm none of those
  files are staged. Never force-add them.
- Verify before claiming completion: at minimum run `dart analyze` on the files you touched. Once
  the SDK issue is fixed, also build and exercise the affected screen.
