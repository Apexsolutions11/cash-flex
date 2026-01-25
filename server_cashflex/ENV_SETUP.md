# Environment Variables Setup Guide

## Quick Setup

The client-side error is happening because Firebase client environment variables are missing. Follow these steps:

### Step 1: Set Firebase Client Variables (Required for Admin Panel)

Run these commands or set them in Vercel Dashboard:

```bash
cd server_cashflex

# Firebase Client Config (from google-services.json)
vercel env add NEXT_PUBLIC_FIREBASE_API_KEY production
# Value: AIzaSyA3AUz9aaEpRPq9FKEKmeP-vn-HZLPIcLY

vercel env add NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN production
# Value: cash-flex-3b6d3.firebaseapp.com

vercel env add NEXT_PUBLIC_FIREBASE_PROJECT_ID production
# Value: cash-flex-3b6d3

vercel env add NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET production
# Value: cash-flex-3b6d3.firebasestorage.app

vercel env add NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID production
# Value: 1032761328062

vercel env add NEXT_PUBLIC_FIREBASE_APP_ID production
# Value: 1:1032761328062:android:fad58c31ee8cfb9dda39ef
```

### Step 2: Set Firebase Admin SDK Variable (Required for API)

```bash
# Download service account JSON from Firebase Console:
# Project Settings > Service Accounts > Generate new private key

# Convert to single line:
cat path/to/service-account-key.json | jq -c

# Add to Vercel:
vercel env add FIREBASE_SERVICE_ACCOUNT production
# Paste the single-line JSON (wrap in single quotes if needed)
```

### Step 3: Set API Keys (Required for API Endpoints)

```bash
vercel env add SECURE_KEY production
vercel env add IP_KEY production
vercel env add PAYOUT_KEY production
vercel env add ADJOE_KEY production
vercel env add MYSTERY_KEY production
vercel env add ADMIN_EMAIL production
vercel env add CRON_SECRET production
# Generate CRON_SECRET: openssl rand -base64 32
```

### Step 4: Redeploy

After adding all environment variables:

```bash
vercel --prod
```

## Alternative: Set via Vercel Dashboard

1. Go to: https://vercel.com/spideyy78s-projects/server_cashflex/settings/environment-variables
2. Click "Add New"
3. Add each variable with its value
4. Select "Production" environment
5. Click "Save"
6. Redeploy: `vercel --prod`

## Required Variables Summary

### Firebase Client (NEXT_PUBLIC_*)
- `NEXT_PUBLIC_FIREBASE_API_KEY` = `AIzaSyA3AUz9aaEpRPq9FKEKmeP-vn-HZLPIcLY`
- `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` = `cash-flex-3b6d3.firebaseapp.com`
- `NEXT_PUBLIC_FIREBASE_PROJECT_ID` = `cash-flex-3b6d3`
- `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` = `cash-flex-3b6d3.firebasestorage.app`
- `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` = `1032761328062`
- `NEXT_PUBLIC_FIREBASE_APP_ID` = `1:1032761328062:android:fad58c31ee8cfb9dda39ef`

### Firebase Admin
- `FIREBASE_SERVICE_ACCOUNT` = (Service account JSON as single-line string)

### API Keys
- `SECURE_KEY` = (Your secure API key)
- `IP_KEY` = (IP API key)
- `PAYOUT_KEY` = (Payout service key)
- `ADJOE_KEY` = (Adjoe API key)
- `MYSTERY_KEY` = (Mystery app key)
- `ADMIN_EMAIL` = (Admin email address)
- `CRON_SECRET` = (Generate with: `openssl rand -base64 32`)
