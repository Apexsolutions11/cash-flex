# Cash Flex - Mobile App & Backend

Complete mobile application with Flutter frontend and Next.js backend for Cash Flex reward platform.

## 📁 Project Structure

```
CashFlex/
├── app_cashflex/          # Flutter mobile application
│   ├── lib/               # Dart source code
│   ├── android/           # Android configuration
│   ├── assets/            # Images and resources
│   └── pubspec.yaml       # Flutter dependencies
│
└── server_cashflex/       # Next.js backend API
    ├── src/               # TypeScript source code
    ├── app/               # Next.js app router
    └── package.json       # Node.js dependencies
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.9.2+)
- **Node.js** (18+)
- **Firebase Project** (with Authentication, Firestore, Cloud Functions enabled)
- **Android Studio** (for Android builds)

### Backend Setup

1. **Navigate to server directory:**
   ```bash
   cd server_cashflex
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   - Copy `.env.example` to `.env.local` (if exists)
   - Or set environment variables in Vercel dashboard
   - See `ENV_STATUS.md` for required variables

4. **Run development server:**
   ```bash
   npm run dev
   ```

5. **Deploy to Vercel:**
   ```bash
   vercel --prod
   ```

### Mobile App Setup

1. **Navigate to app directory:**
   ```bash
   cd app_cashflex
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add `google-services.json` to `android/app/`
   - Update `lib/firebase_options.dart` with your Firebase config

4. **Build Android APK:**
   ```bash
   flutter build apk --release
   ```

5. **Run on device/emulator:**
   ```bash
   flutter run
   ```

## 🔐 Environment Variables

### Backend (Vercel)

See `server_cashflex/ENV_STATUS.md` for complete list. Key variables:

- `FIREBASE_SERVICE_ACCOUNT` - Firebase Admin SDK JSON
- `NEXT_PUBLIC_FIREBASE_*` - Firebase Client SDK config (6 variables)
- `MYSTERY_KEY` - Mystery app authentication key
- `CRON_SECRET` - Cron job authentication
- `IP_KEY` - IP API key
- `SECURE_KEY`, `PAYOUT_KEY`, `ADJOE_KEY` - Service API keys

### Mobile App

- `google-services.json` - Firebase Android config (in `android/app/`)
- `firebase_options.dart` - Firebase Flutter config (auto-generated)

## 📱 App Features

- **User Authentication** - Google Sign-In
- **Reward System** - Earn coins through games and tasks
- **Wallet** - Track balance and transactions
- **Leaderboard** - Compete with other users
- **Referral System** - Invite friends and earn rewards
- **Games & Quizzes** - Math Quiz, General Quiz, Tic Tac Toe, Catch Coins
- **External Apps** - Install apps and earn rewards
- **Payout System** - Redeem coins for cash

## 🔧 Backend API

### User Endpoints
- `POST /api/authenticate-user` - Authenticate user
- `POST /api/claim-coins` - Claim coins from games
- `POST /api/request-payout` - Request payout
- `POST /api/set-referral` - Set referral code

### Admin Endpoints
- `GET /api/admin/stats` - Dashboard statistics
- `GET /api/admin/users` - User management
- `POST /api/admin/users/[uid]/grant-coins` - Grant coins to user
- `GET /api/admin/app-data` - App configuration
- `POST /api/admin/app-data` - Update app configuration

### Cron Endpoints
- `POST /api/cron/reset-leaderboard` - Reset daily leaderboard
- `POST /api/cron/reset-payout-count` - Reset payout limits
- `POST /api/cron/reset-daily-game-count` - Reset game counts

See `server_cashflex/README.md` for complete API documentation.

## 🎨 Admin Dashboard

**Login URL:** `https://servercashflex.vercel.app/admin/login`

**Default Credentials:**
- Email: `admin@gmail.com`
- Password: `121245`

See `server_cashflex/ADMIN_LOGIN_GUIDE.md` for setup instructions.

## 📦 Building & Deployment

### Android APK

```bash
cd app_cashflex
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Backend Deployment

Deployed automatically via Vercel on push to `main` branch.

Manual deployment:
```bash
cd server_cashflex
vercel --prod
```

## 🔒 Security Notes

- **Never commit** sensitive files:
  - `key.properties`
  - `local.properties`
  - `*.jks` / `*.keystore`
  - `google-services.json`
  - `.env` files
  - Service account JSON files

- All sensitive data should be:
  - Stored in Vercel environment variables (backend)
  - Configured locally (mobile app)
  - Never pushed to Git

## 📚 Documentation

- **Backend API:** `server_cashflex/README.md`
- **Environment Setup:** `server_cashflex/ENV_STATUS.md`
- **Admin Login:** `server_cashflex/ADMIN_LOGIN_GUIDE.md`
- **Firebase Setup:** `server_cashflex/FIREBASE_EXPLANATION.md`
- **Deployment:** `server_cashflex/DEPLOYMENT.md`

## 🛠️ Development

### Backend Development

```bash
cd server_cashflex
npm run dev
# Server runs on http://localhost:3000
```

### Mobile App Development

```bash
cd app_cashflex
flutter run
# App runs on connected device/emulator
```

### Running Tests

```bash
# Backend
cd server_cashflex
npm test

# Mobile App
cd app_cashflex
flutter test
```

## 📄 License

Private project - All rights reserved

## 👥 Support

For issues or questions:
- Check documentation in respective directories
- Review `ENV_STATUS.md` for environment setup
- See `ADMIN_LOGIN_GUIDE.md` for admin access

---

**Project:** Cash Flex  
**Version:** 1.0.8+10  
**Last Updated:** 2024
