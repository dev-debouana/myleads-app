# CLAUDE.md — My Leads (Flutter mobile app)

Reference document for Claude when working on the **My Leads** Flutter
application. Read this first on every task touching this repository so
changes stay consistent with the existing architecture, theme tokens, and
conventions.

**User directives (Apr 2026) — apply to every change without exception:**

1. **Focus exclusively on the mobile app** — do not prioritize the web build.
2. **Dark / light mode on every design change.** Any new or modified UI widget
   must use the context-aware color helpers (`AppColors.bg(context)`,
   `AppColors.surfaceColor(context)`, `AppColors.onSurface(context)`,
   `AppColors.secondary(context)`, `AppColors.hint(context)`,
   `AppColors.borderColor(context)`, `AppColors.inputBackground(context)`)
   instead of the static constants (`AppColors.background`, `AppColors.card`,
   `AppColors.textDark`, etc.). Never introduce a `const TextStyle` that
   references a static color token that has a context-aware equivalent.
3. **Bilingual (FR / EN) on every text change.** Any new user-facing string, or
   any edit to an existing one, must be added / updated in **both** languages
   inside `lib/core/l10n/app_l10n.dart` (the `AppL10n` class). Screens must
   retrieve strings via `final l10n = ref.watch(l10nProvider)` and reference
   `l10n.xxx` — never hardcode a display string in a widget directly. French is
   the default (`_en == false`); English is the `_en == true` branch.

---

## 1. Project overview

- **Name:** My Leads — `myleads` (pub name), bundle id `com.debouana.myleads`.
- **Pitch:** Mobile app for capturing professional contacts through business-card
  scanning (OCR), QR code, NFC, or manual entry, with lead scoring (hot / warm
  / cold), reminders, and quick actions (call / SMS / WhatsApp / email).
- **Slogan:** *Scannez. Connectez. Convertissez.* (FR first, EN fallback in
  `AppStrings.sloganEn`).
- **Stack:** Flutter 3.24.5, Dart SDK `^3.5.0`, Riverpod 2.5 for state, GoRouter
  14 for navigation, SQLite (sqflite + sqflite_common_ffi) for local storage,
  AES-256-CBC encryption of PII via `encrypt` + `flutter_secure_storage`.
- **Pricing tiers:** Free (10 contacts), Premium `2.99 €/mois`, Business
  `5.99 €/utilisateur/mois` — wired to `in_app_purchase` 3.2.
- **Primary UI language:** French. Hardcoded strings live in
  `lib/core/constants/app_strings.dart`.
- **Platforms:** Android (APK delivered via GitHub Actions release), iOS
  (project generated at CI time), Web (secondary, deprioritized).
- **Repository:** `rbouana/myleads-app` on GitHub. Main branch triggers CI.

---

## 2. Directory tree

```
myleads-app/
├── CLAUDE.md                         ← this file
├── README.md
├── pubspec.yaml                      ← dependencies, SDK constraints
├── analysis_options.yaml
├── .github/workflows/build.yml       ← CI: APK + web build + release
├── android/                          ← generated at CI (flutter create)
├── ios/                              ← generated at CI
├── assets/
│   ├── animations/                   ← Lottie (reserved)
│   ├── fonts/                        ← PlusJakartaSans (reserved)
│   ├── icons/
│   └── images/
└── lib/
    ├── main.dart                     ← entry, SystemChrome, StorageService.init()
    ├── config/
    │   └── app_config.dart           ← feature flags & environment toggles
    ├── core/
    │   ├── constants/app_strings.dart
    │   ├── router/app_router.dart    ← GoRouter config, named routes below
    │   ├── theme/
    │   │   ├── app_colors.dart       ← brand tokens (see §3.1)
    │   │   └── app_theme.dart        ← Material ThemeData + fontFamily
    │   └── utils/validators.dart     ← email / password / phone regex
    ├── models/
    │   ├── contact.dart              ← Contact entity (see §6)
    │   ├── interaction.dart          ← call/sms/email history
    │   ├── reminder.dart             ← multi-contact reminder
    │   └── user_account.dart        ← user + session token
    ├── providers/
    │   ├── auth_provider.dart        ← signup/login/logout/changeEmail/changePassword
    │   ├── contacts_provider.dart    ← CRUD + filters + search (Riverpod)
    │   ├── navigation_provider.dart  ← currentTabProvider (IndexedStack)
    │   └── reminders_provider.dart   ← 5 computed lists (today/week/later/late/done)
    ├── screens/
    │   ├── splash/splash_screen.dart
    │   ├── auth/                     ← login / signup / forgot / verify / reset
    │   ├── home/
    │   │   ├── main_shell.dart       ← IndexedStack + bottom nav (see §4)
    │   │   └── home_screen.dart      ← dashboard + stat cards
    │   ├── contacts/                 ← list, detail, edit
    │   ├── scan/scan_screen.dart     ← card / QR / NFC scanner
    │   ├── review/review_screen.dart ← post-OCR verification
    │   ├── reminders/                ← list, create, detail
    │   ├── profile/                  ← profile, my profile, account security
    │   └── pricing/pricing_screen.dart
    ├── services/
    │   ├── calendar_service.dart     ← add_2_calendar wrapper
    │   ├── contact_actions.dart      ← url_launcher for call/sms/whatsapp/email
    │   ├── database_service.dart     ← SQLite, schema v5 with migrations
    │   ├── email_service.dart        ← mailer (SMTP) for verification codes
    │   ├── encryption_service.dart   ← AES-256-CBC master key in Keystore
    │   ├── ocr_parser.dart           ← text → Contact field extraction
    │   ├── ocr_service_mobile.dart   ← ML Kit text recognition
    │   ├── ocr_service_stub.dart     ← web / unsupported platforms
    │   ├── photo_storage_service.dart ← contact / user photo files
    │   ├── storage_service.dart      ← facade, init order for DB + encryption
    │   └── web_db_factory_{stub,web}.dart ← conditional import for sqflite web
    └── widgets/
        ├── bottom_nav_bar.dart       ← standalone variant (legacy)
        ├── lead_card.dart
        ├── quick_action_button.dart
        ├── search_bar_widget.dart
        └── status_badge.dart
```

### Route map (`lib/core/router/app_router.dart`)

| Path                   | Screen                           | Transition |
|------------------------|----------------------------------|------------|
| `/`                    | `SplashScreen`                   | —          |
| `/login`               | `LoginScreen`                    | Fade       |
| `/signup`              | `SignupScreen`                   | Slide L→R  |
| `/forgot-password`     | `ForgotPasswordScreen`           | Slide L→R  |
| `/email-verification`  | `EmailVerificationScreen(email)` | Slide L→R  |
| `/recovery-code`       | `RecoveryCodeScreen(email)`      | Slide L→R  |
| `/reset-password`      | `ResetPasswordScreen(email,code)`| Slide L→R  |
| `/main`                | `MainShell` (tabbed)             | Fade       |
| `/scan`                | `ScanScreen` (standalone)        | Fade       |
| `/review`              | `ReviewScreen(ocrData)`          | Slide L→R  |
| `/contact/new`         | `ContactEditScreen`              | Slide L→R  |
| `/contact/:id`         | `ContactDetailScreen`            | Slide L→R  |
| `/contact/:id/edit`    | `ContactEditScreen(contactId)`   | Slide L→R  |
| `/reminder/new`        | `CreateReminderScreen`           | Slide L→R  |
| `/reminder/:id`        | `ReminderDetailScreen`           | Slide L→R  |
| `/my-profile`          | `MyProfileScreen`                | Slide L→R  |
| `/account-security`    | `AccountSecurityScreen`          | Slide L→R  |
| `/pricing`             | `PricingScreen`                  | Slide bot. |

---

## 3. Design system

### 3.1 Brand colors — `lib/core/theme/app_colors.dart`

Always use the `AppColors` constants, **never hardcode hex**. All widgets must
compose from these tokens so a palette change propagates everywhere.

| Token                 | Hex       | Usage                                        |
|-----------------------|-----------|----------------------------------------------|
| `primary`             | `#0B3C5D` | Brand navy — CTAs, titles, nav highlight     |
| `primaryLight`        | `#134B73` | Gradient top-end of `primaryGradient`        |
| `primaryDark`         | `#072A42` | Pressed state / deep accents                 |
| `accent`              | `#D4AF37` | Brand gold — secondary CTA, scan button      |
| `accentLight`         | `#E8CC6E` | Gradient companion                           |
| `hot`                 | `#E74C3C` | HOT status, error icons, priority `very_important` |
| `hotLight`            | `#FF6B6B` | Gradient companion                           |
| `warm`                | `#F39C12` | WARM status, warning, priority `important`   |
| `warmLight`           | `#FFC048` | Gradient companion                           |
| `cold`                | `#95A5A6` | COLD status                                  |
| `coldLight`           | `#B0BEC5` | Gradient companion                           |
| `success`             | `#27AE60` | Success icons, call button tint              |
| `successLight`        | `#6DD5A0` | —                                            |
| `error`               | `#E74C3C` | (= `hot`) error surfaces                     |
| `warning`             | `#F39C12` | (= `warm`) warning surfaces                  |
| `info`                | `#3498DB` | Informational surfaces                       |
| `white`               | `#FFFFFF` | —                                            |
| `background`          | `#F0F2F5` | Scaffold background                          |
| `card`                | `#FFFFFF` | All card surfaces                            |
| `textDark`            | `#1A1A2E` | Headings, primary body copy                  |
| `textMid`             | `#5A5A7A` | Secondary copy, labels                       |
| `textLight`           | `#9A9ABF` | Hints, placeholders, inactive nav icons      |
| `border`              | `#E8EAF0` | All dividers/borders, input fields           |
| `divider`             | `#F0F0F5` | Thin horizontal rules                        |
| `inputBg`             | `#F0F2F5` | Filled input background (= `background`)     |

### 3.2 Gradients (declared as `const LinearGradient`)

| Name                           | Angle      | Stops                                |
|--------------------------------|------------|--------------------------------------|
| `primaryGradient`              | 135° TL→BR | `primary → primaryLight`             |
| `accentGradient`               | 135° TL→BR | `accent → accentLight`               |
| `hotGradient`                  | 135° TL→BR | `hot → hotLight`                     |
| `warmGradient`                 | 135° TL→BR | `warm → warmLight`                   |
| `avatarGradient(status)`       | 135° TL→BR | status-dependent (hot/warm/cold)     |

### 3.3 Typography

- **Font family:** `PlusJakartaSans` (declared in `AppTheme.fontFamily`; asset
  files live in `assets/fonts/` and are registered via `pubspec.yaml` when
  added). Falls back to system sans if the font file is missing.
- **Weights used:** 400 (body), 600 (medium/nav), 700 (buttons), 800 (titles).
- Headings rely on `TextStyle(fontWeight: FontWeight.w800)` for page titles,
  `w700` for section titles, `w600` for labels.
- **Default input label:** 12px, `w700`, `AppColors.textLight`, letter-spacing
  1 (see `app_theme.dart:63`).
- **Snack bar text:** 14px / `w600` / white on `primary` background.

### 3.4 Spacing, radii, shadows

- **Radii** — compose via `BorderRadius.circular(N)`; canonical values:
  `8` (chips), `10` (small buttons), `12` (inputs, small cards), `14–16` (cards),
  `20` (filter chips), `22` (pill tabs), `24–28` (large / feature cards).
- **Card shadows** — use the three helpers in `AppTheme`:
  - `AppTheme.cardShadow`   → blur 20, y=4, `primary @ 8%`
  - `AppTheme.cardShadowLg` → blur 40, y=8, `primary @ 12%`
  - `AppTheme.accentShadow` → blur 20, y=6, `accent @ 30%`  (scan button, CTAs)
- **Section padding:** horizontal 20–24px in scrollable lists, vertical 16–24px
  between hero sections. Respect `MediaQuery.of(context).padding.top/bottom`
  for safe-area and the 88 px `MainShell` bottom-nav footer.

### 3.5 Status semantics

Contacts carry `status: 'hot' | 'warm' | 'cold'`, reminders carry
`priority: 'very_important' | 'important' | 'normal'`. Mapping:

| Domain value       | Color       | Badge label |
|--------------------|-------------|-------------|
| `status='hot'`     | `hot`       | `HOT`       |
| `status='warm'`    | `warm`      | `WARM`      |
| `status='cold'`    | `cold`      | `COLD`      |
| `priority='very_important'` | `hot`  | —      |
| `priority='important'`      | `warm` | —      |
| `priority='normal'`         | `success` | —   |

Never introduce new status values without adding the colour + badge in
`AppColors`, `status_badge.dart`, and the filter chips in
`contacts_screen.dart` / `reminders_screen.dart`.

### 3.6 Iconography

- Use **rounded Material icons** (`Icons.xxx_rounded` variants) throughout.
  Examples: `home_rounded`, `people_rounded`, `qr_code_scanner_rounded`,
  `access_time_rounded`, `person_rounded`, `add_rounded`,
  `notifications_rounded`, `calendar_month_rounded`.
- Secondary icon pack: `iconsax` 0.0.8 is available but prefer Material
  rounded for consistency.
- No asset-based icon set — stay with vector/system icons.

---

## 4. Navigation & shell

`MainShell` (`lib/screens/home/main_shell.dart`) is the 5-tab host with
`IndexedStack` and a custom bottom nav (88 px tall + safe-area). `extendBody:
true` so `FloatingActionButton`s can overlap. Never add a `Scaffold.bottomNav`
to a tab screen — it's already provided by the shell.

| Index | Icon                          | Label      | Screen             |
|-------|-------------------------------|------------|--------------------|
| 0     | `home_rounded`                | Home       | `HomeScreen`       |
| 1     | `people_rounded`              | Contacts   | `ContactsScreen`   |
| 2     | `qr_code_scanner_rounded` *(elevated gold pill)* | — | `ScanScreen` |
| 3     | `access_time_rounded`         | Rappels    | `RemindersScreen`  |
| 4     | `person_rounded`              | Compte     | `ProfileScreen`    |

Active tab colour: `AppColors.accent`; inactive: `AppColors.textLight`. The
center scan button sits elevated 16 px above the bar with `accentGradient`,
white 4 px border, and `accent @ 40%` shadow.

**FAB positioning rule:** any tab that needs a FAB must wrap it in
`Padding(padding: EdgeInsets.only(bottom: 88 + MediaQuery.of(context).padding.bottom))`
to lift it above the shell bottom nav (see the reminders screen FAB fix).

---

## 5. State management (Riverpod 2)

All providers use `StateNotifierProvider` + an immutable state class with
`copyWith` and a `_sentinel` object to distinguish "not provided" from an
explicit null for nullable fields.

| Provider                  | Exposes                                                                                         |
|---------------------------|-------------------------------------------------------------------------------------------------|
| `authProvider`            | `signUp`, `login`, `logout`, `changePassword`, `changeEmail`, `deleteAccount`                   |
| `contactsProvider`        | CRUD + `filteredContacts`, `activeFilter`, `statusFilter`, `searchQuery`, `totalContacts`, counts |
| `remindersProvider`       | CRUD + 5 computed lists: `todayReminders`, `weekReminders`, `laterReminders`, `lateReminders`, `doneReminders` + `refresh()` |
| `currentTabProvider`      | Simple `StateProvider<int>` for the shell's active tab index                                    |

### Cross-screen navigation patterns

- Pushing a sub-screen from within a tab must forward the Riverpod container
  so nested providers can be read. Example:
  ```dart
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const CreateReminderScreen(),
      ),
    ),
  );
  ```
- For top-level jumps (login → main, edit → detail), use `context.go` or
  `context.push` from GoRouter.

---

## 6. Data model (SQLite schema v5)

### Contact
```
id TEXT PK, first_name, last_name, job_title, company, phone, email,
source, project_1, project_1_budget, project_2, project_2_budget,
interest, notes, tags, status, created_at, last_contact_date,
avatar_color, capture_method, owner_id, photo_path
```
- `email` / `phone` persisted as AES-encrypted blobs.
- Lookup columns `email_lookup` / `phone_lookup` store deterministic SHA-256
  for uniqueness queries without decryption.

### Reminder (v2 schema — multi-contact)
```
id, owner_id, contact_ids (JSON array), start_datetime, end_datetime,
repeat_frequency, note, to_do_action, priority, is_completed, created_at
```
- `to_do_action ∈ {call, sms, whatsapp, email}` drives the reminder card icon.
- `priority ∈ {very_important, important, normal}` → colour + bar.

### UserAccount
```
id, full_name, email, email_hash, password_hash, date_of_birth,
phone, photo_path, session_token, created_at, plan
```
- Password hashed with a salt via `crypto.sha256`.
- `session_token` rotated on logout / password change (pseudo "sign out
  everywhere").

### Interaction
```
id, contact_id, type (call|sms|whatsapp|email|note), at, payload
```

Schema upgrades are additive — see `_onUpgrade` in `database_service.dart`.
**Bump `_dbVersion` and add an `if (oldVersion < N)` block** when changing
the schema; never rewrite existing tables.

---

## 7. Conventions to follow

1. **Theme tokens only.** Import `AppColors` + use `AppTheme.cardShadow/accentShadow`;
   never hardcode hex or raw `BoxShadow(...)`.
2. **All UI colors must be context-aware.** Use `AppColors.bg(context)`,
   `AppColors.surfaceColor(context)`, `AppColors.onSurface(context)`,
   `AppColors.secondary(context)`, `AppColors.hint(context)`,
   `AppColors.borderColor(context)`, `AppColors.inputBackground(context)` so
   every widget responds to light/dark mode automatically. Static constants
   (`AppColors.background`, `AppColors.card`, `AppColors.textDark`, etc.) are
   only valid inside gradient declarations or `const` contexts where no
   context-aware equivalent exists (e.g. the gradient color stops themselves).
3. **All user-facing strings must go through `AppL10n`.** Add or update the
   string in `lib/core/l10n/app_l10n.dart` with both a French branch
   (`_en == false`) and an English branch (`_en == true`). In widgets, obtain
   the accessor with `final l10n = ref.watch(l10nProvider)` and reference
   `l10n.xxx`. Never place a display string literal directly in a widget.
   Use double-quotes `"` in Dart when the literal contains an apostrophe
   (e.g. `"Changer l'email"`).
4. **Form inputs.** Lean on the themed `InputDecorationTheme`. If you must
   override colours (e.g. search bars on a coloured header), set
   `cursorColor: AppColors.primary`,
   `style: TextStyle(color: AppColors.onSurface(context))`,
   `hintStyle: TextStyle(color: AppColors.hint(context))` explicitly.
5. **Buttons.** Primary CTA = `ElevatedButton` (auto-styled accent/primary).
   Secondary = `OutlinedButton`. Tertiary = `TextButton`. Do not ship a custom
   wrapper unless reused ≥ 3 times.
6. **Cards.** Use `Container` with `color: AppColors.surfaceColor(context)`,
   `borderRadius: BorderRadius.circular(14–16)`,
   `border: Border.all(color: AppColors.borderColor(context))`
   **or** `boxShadow: AppTheme.cardShadow`, not both.
7. **Priority bars.** Reminder cards carry a 4 px vertical bar in
   `priorityColor` on the left (see `_ReminderCard`). Keep the bar for any
   new priority-bearing card.
8. **Icons.** Stick to `Icons.xxx_rounded`. For status / action mapping use
   the switch tables in `reminders_screen.dart` / `contacts_screen.dart`.
9. **Storage & encryption.** Any new sensitive column must (a) be encrypted
   on write with `EncryptionService.encryptText`, (b) store a SHA-256 hash in
   a `_lookup` companion column if it needs uniqueness queries.
10. **Never log plaintext PII.** `debugPrint` is OK for non-sensitive metadata;
    never print emails, phones, tokens.
11. **Platform guards.** Use `kIsWeb` + `Platform.isWindows/isLinux` checks in
    services (see `database_service.dart`). Keep conditional imports for web
    via the `web_db_factory_{stub,web}.dart` pattern.
12. **OCR.** `ocr_service_mobile.dart` is the real ML Kit implementation;
    web / desktop fall back to `ocr_service_stub.dart`. Do not import the
    mobile one directly — go through `storage_service.dart` or the provider.
13. **No build-runner output committed.** If you add `@riverpod` annotations,
    run `flutter pub run build_runner build` locally; CI will regenerate.

---

## 8. Build & CI

`.github/workflows/build.yml` runs on every push to `main`. Jobs:

| Job            | Steps                                                            |
|----------------|------------------------------------------------------------------|
| `build-android`| Java 17 → Flutter 3.24.5 → `flutter create` (regenerates android/ios/web) → patch `build.gradle` with ProGuard → **patch `AndroidManifest.xml`** (INTERNET permission + `<queries>` block for tel/sms/mailto/https/http) → `flutter build apk --release --no-tree-shake-icons` → `dart run sqflite_common_ffi_web:setup` → `flutter build web --release --base-href "/myleads-app/"` → upload artifacts |
| `release`      | Downloads APK → deletes existing `v1.0.0` release → creates new release with `app-release.apk` attached |
| `deploy-web`   | Deploys `build/web/` to GitHub Pages                              |

**Release URL pattern:** `https://github.com/rbouana/myleads-app/releases/download/v1.0.0/app-release.apk`.

`flutter create` runs on every CI job, which means edits to the native
manifests or `android/app/build.gradle` **must** be applied via the Python
patch step in the workflow, not via committed files. Files under
`android/` or `ios/` that aren't part of the patch are regenerated.

---

## 9. Quick-start for common tasks

| Task                                   | Start here                                                       |
|----------------------------------------|------------------------------------------------------------------|
| Add a new screen                       | create under `lib/screens/...`, register a `GoRoute` in `app_router.dart` with the existing slide/fade template |
| Add a new tab to the shell             | extend `MainShell._screens` + the `_buildBottomNav` Row; update `currentTabProvider` default |
| Add a new domain model                 | `lib/models/foo.dart` → add table in `_onCreate`, bump `_dbVersion` + `_onUpgrade` in `database_service.dart` |
| Tweak brand colour                     | edit `AppColors` — propagates via `AppTheme` + gradients         |
| Add a new string                       | `AppStrings` (FR). If reused from EN, add an `*En` variant.      |
| Add a platform permission              | patch the Python step in `.github/workflows/build.yml`, not `android/app/src/main/AndroidManifest.xml` (regenerated) |
| Release a new APK                      | push to `main`; CI handles build + GitHub Release + Pages        |
| Watch a CI run                         | `gh run list --limit 3` then `gh run watch <id> --exit-status`   |

---

## 10. Known constraints & gotchas

- **`android/` and `ios/` are not committed source.** They're regenerated on
  every CI run by `flutter create`. Any native-side config (manifest, gradle)
  must live in the workflow's patch steps.
- **`extendBody: true` on `MainShell`.** Tab screens' FABs render behind the
  bottom nav unless wrapped in `Padding(bottom: 88 + safeArea.bottom)`.
- **Scanner (`scan_screen.dart`):** `MobileScanner` is rendered in both card
  and QR modes. Starting the camera in `initState` is intentional — removing
  it reintroduces the black-screen bug. In card mode the `onDetect` callback
  is a no-op so barcode detection doesn't hijack the OCR flow.
- **CAMERA permission:** `mobile_scanner` (5.x) and `image_picker` each merge
  `android.permission.CAMERA` into the final manifest via their library
  manifests. The CI patch therefore only needs to inject `INTERNET` + the
  `<queries>` block. Don't re-add a CAMERA permission block unless a manifest
  merge regression appears in the build logs.
- **Riverpod `ProviderScope`:** sub-screens pushed via `Navigator.push` must
  forward the parent container (`ProviderScope(parent: …, child: …)`),
  otherwise providers reset.
- **`DropdownButtonFormField`:** use `value:`, not `initialValue:` — the
  latter is Flutter > 3.27 only; our pinned SDK is 3.24.5.
- **Apostrophes in Dart strings:** use `"` double-quoted literals (e.g.
  `"Changer l'email"`) or escape `\'`. Single-quote + raw apostrophe breaks
  the parser.
- **Web build is deprioritized** per the user directive (Apr 2026). Don't
  spend effort on web-only fixes unless explicitly asked.
- **Mail:** `mailer` is SMTP-based for verification/reset codes. Credentials
  are resolved at runtime from `app_config.dart` — never commit secrets.
- **SQLite web:** `sqflite_common_ffi_web` needs the WASM blob copied to
  `web/` via `dart run sqflite_common_ffi_web:setup` before
  `flutter build web`. The CI already does this.

---

## 11. Version history anchors

Use these as reference points when coordinating changes:

- **v1.0.0 doc v3** — multi-contact reminders (5 tabs), QR codes, linked
  reminders, calendar sync, email change flow (first pass).
- **v1.0.0 doc v4** — clickable home stat cards (jump to filtered contacts /
  reminders tab), search-bar colour polish, functional email-change flow via
  `authProvider.changeEmail`.
- **v1.0.0 doc v5** — reminders FAB visibility fix (lifted above shell nav,
  upgraded to `FloatingActionButton.extended`), scanner black-screen fix
  (camera preview in card mode + 25% overlay), notifications screen, delete
  account flow, OCR enrichment, contact-detail polish.
- **v1.0.0 doc v7** — WhatsApp removed from the contacts list card (only
  Call + SMS remain; WhatsApp kept on the contact detail screen), official
  WhatsApp brand glyph via `font_awesome_flutter`, date-of-birth removed
  from profile + user model + DB payload, automatic calendar sync on
  reminder save when priority = `important`/`very_important` (verified
  already wired), [ActionTracker](lib/services/action_tracker.dart)
  `WidgetsBindingObserver` that records a persisted `Interaction` when the
  user leaves the app for ≥10 s after tapping a contact action, field-level
  diff logging on `updateContact` (audit entry in `interactions` with
  `type='edit'`), and a unified contact history that merges raw
  interactions with completed reminders for that contact. Calendar sync
  diagnostic: `add_2_calendar` is intent-based (ACTION_INSERT on Android,
  EKEventStore on iOS) — direct Google/Outlook/Apple/Notion/Motion API sync
  would require per-provider OAuth integration beyond this release.

When the user references "doc vN", match the behaviour to the nearest anchor
above and consult the corresponding commit (see `git log --oneline`).

---

*Maintenance: when you add a top-level folder under `lib/`, a new route, a
new theme token, or a new CI step, update the corresponding tables in §2,
§3, §4, §5, §6, and §8.*
