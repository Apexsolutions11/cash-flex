#!/bin/bash

# Cash Flex Backend - Environment Variables Setup Script
# Run this script to set up all required environment variables in Vercel

echo "Setting up environment variables for Cash Flex Backend..."
echo ""

# Firebase Client Configuration (from google-services.json)
vercel env add NEXT_PUBLIC_FIREBASE_API_KEY production <<< "AIzaSyA3AUz9aaEpRPq9FKEKmeP-vn-HZLPIcLY"
vercel env add NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN production <<< "cash-flex-3b6d3.firebaseapp.com"
vercel env add NEXT_PUBLIC_FIREBASE_PROJECT_ID production <<< "cash-flex-3b6d3"
vercel env add NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET production <<< "cash-flex-3b6d3.firebasestorage.app"
vercel env add NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID production <<< "1032761328062"
vercel env add NEXT_PUBLIC_FIREBASE_APP_ID production <<< "1:1032761328062:android:fad58c31ee8cfb9dda39ef"

echo ""
echo "✅ Firebase client environment variables added!"
echo ""
echo "⚠️  IMPORTANT: You still need to manually add:"
echo "   1. FIREBASE_SERVICE_ACCOUNT - Firebase Admin SDK service account JSON"
echo "   2. SECURE_KEY - Your secure API key"
echo "   3. IP_KEY - IP API key"
echo "   4. PAYOUT_KEY - Payout service key"
echo "   5. ADJOE_KEY - Adjoe API key"
echo "   6. MYSTERY_KEY - Mystery app key"
echo "   7. ADMIN_EMAIL - Admin email address"
echo "   8. CRON_SECRET - For external cron services (generate with: openssl rand -base64 32)"
echo ""
echo "After adding all variables, redeploy with: vercel --prod"
