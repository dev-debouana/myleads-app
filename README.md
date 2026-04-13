# My Leads

**Scannez. Connectez. Convertissez.**

Application mobile iOS & Android de gestion intelligente de contacts professionnels.

Transformez chaque rencontre professionnelle en opportunite. Scannez une carte, un QR code ou un profil professionnel et contactez instantanement vos leads, sans papier, sans friction.

## Screenshots

| Splash | Login | Dashboard | Scan | Contacts | Detail |
|--------|-------|-----------|------|----------|--------|
| Splash Screen | Auth Screen | Home Dashboard | Camera Scan | Contact List | Contact Detail |

## Features

- **Scan OCR** - Capture automatique des cartes de visite via camera
- **QR Code** - Lecture instantanee de QR codes professionnels
- **NFC** - Lecture de tags NFC
- **Gestion Contacts** - CRUD complet avec tags, status et notes
- **Lead Scoring** - Classification Hot / Warm / Cold
- **Rappels** - Systeme de follow-up intelligent
- **Actions Rapides** - Appel, SMS, WhatsApp, Email en 1 tap
- **Recherche** - Recherche instantanee multi-criteres
- **Offline Mode** - Stockage local avec Hive
- **Sync Cloud** - Synchronisation automatique

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.24+ |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Storage | Hive |
| OCR | Google ML Kit |
| Scanner | mobile_scanner |
| NFC | nfc_manager |
| Animations | flutter_animate |

## Getting Started

### Prerequisites

- Flutter SDK >= 3.24.0
- Dart SDK >= 3.5.0
- Android Studio / Xcode
- Physical device (for camera/NFC features)

### Installation

```bash
# Clone the repository
git clone https://github.com/rbouana/myleads-app.git
cd myleads-app

# Install dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Project Structure

```
lib/
  core/
    theme/          # Colors, Typography, Theme
    constants/      # Strings, Config
    router/         # GoRouter configuration
  models/           # Data models (Contact, Reminder, Interaction)
  providers/        # Riverpod state management
  services/         # Storage, API services
  screens/
    splash/         # Splash screen
    auth/           # Login, Signup
    home/           # Dashboard, Main shell
    scan/           # Camera scan, QR, NFC
    review/         # OCR review & validation
    contacts/       # Contacts list, Detail
    reminders/      # Follow-up management
    profile/        # User profile
    pricing/        # Subscription plans
  widgets/          # Shared reusable widgets
```

## Pricing

| Plan | Price | Features |
|------|-------|----------|
| Free | Gratuit | 10 contacts, scan basique |
| Premium | 2.99 EUR/mois | Illimite, OCR+QR+NFC, IA, Export |
| Business | 5.99 EUR/utilisateur/mois | Multi-users, CRM, Analytics, API |

### Payment Methods

- **Africa**: Mobile Money, PayPal, CB
- **Europe**: PayPal, CB, Virement, Apple Pay, Google Pay
- **North America**: PayPal, CB, Virement, Apple Pay, Google Pay
- **Asia**: Tarification locale adaptee

## Design System

| Element | Value |
|---------|-------|
| Primary | `#0B3C5D` (Bleu profond) |
| Accent | `#D4AF37` (Dore) |
| Hot | `#E74C3C` (Rouge) |
| Warm | `#F39C12` (Orange) |
| Cold | `#95A5A6` (Gris) |
| Font | Plus Jakarta Sans |

## KPI Produit

- Scan success rate > 95%
- Save time < 30 sec
- D30 retention > 35%
- Premium conversion > 7%

## Roadmap

- **MVP** : 3 mois
- **V1** : 6 mois
- **Enterprise** : 9 mois

## License

Copyright 2026 De Bouana. All rights reserved.

---

Built with love by **De Bouana** - *Scannez. Connectez. Convertissez.*
