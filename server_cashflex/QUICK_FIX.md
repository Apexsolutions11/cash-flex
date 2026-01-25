# Quick Fix for Client-Side Error

## Problem
The error "Application error: a client-side exception has occurred" is happening because Firebase client environment variables are missing.

## Solution: Set Environment Variables in Vercel Dashboard

### Step 1: Go to Vercel Dashboard
Open: https://vercel.com/spideyy78s-projects/server_cashflex/settings/environment-variables

### Step 2: Add These Firebase Client Variables

Click "Add New" and add each variable:

1. **NEXT_PUBLIC_FIREBASE_API_KEY**
   - Value: `AIzaSyA3AUz9aaEpRPq9FKEKmeP-vn-HZLPIcLY`
   - Environment: Production

2. **NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN**
   - Value: `cash-flex-3b6d3.firebaseapp.com`
   - Environment: Production

3. **NEXT_PUBLIC_FIREBASE_PROJECT_ID**
   - Value: `cash-flex-3b6d3`
   - Environment: Production

4. **NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET**
   - Value: `cash-flex-3b6d3.firebasestorage.app`
   - Environment: Production

5. **NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID**
   - Value: `1032761328062`
   - Environment: Production

6. **NEXT_PUBLIC_FIREBASE_APP_ID**
   - Value: `1:1032761328062:android:fad58c31ee8cfb9dda39ef`
   - Environment: Production

### Step 3: Redeploy

After adding all variables, redeploy:

```bash
cd server_cashflex
vercel --prod
```

Or trigger a redeploy from the Vercel Dashboard.

## After This Fix

The admin panel should load. You'll still need to add:
- `FIREBASE_SERVICE_ACCOUNT` (for API endpoints)
- Other API keys (SECURE_KEY, IP_KEY, etc.)

But the client-side error will be fixed!
