# Firebase Authentication Setup - Fix "operation-not-allowed" Error

## 🔴 Error: `auth/operation-not-allowed`

This error means **Email/Password authentication is not enabled** in Firebase Console.

## ✅ Solution: Enable Email/Password Authentication

### Step 1: Go to Firebase Console

1. Visit: https://console.firebase.google.com/
2. Select your project: **cash-flex-3b6d3**

### Step 2: Navigate to Authentication

1. Click **"Authentication"** in the left sidebar
2. If you see "Get Started", click it to enable Authentication

### Step 3: Enable Email/Password Provider

1. Click on the **"Sign-in method"** tab (at the top)
2. You'll see a list of sign-in providers
3. Find **"Email/Password"** in the list
4. Click on it

### Step 4: Enable Email/Password

1. Toggle **"Email/Password"** to **ON** (enabled)
2. Optionally enable **"Email link (passwordless sign-in)"** if you want passwordless login
3. Click **"Save"**

### Step 5: Verify

You should now see:
- ✅ Email/Password status: **Enabled**
- ✅ Provider ID: `password`

## 🔐 After Enabling: Login Again

Once Email/Password is enabled:

1. Go to: https://servercashflex.vercel.app/admin/login
2. Enter:
   - **Email**: `admin@gmail.com`
   - **Password**: `121245`
3. Click "Login"

## 📝 Additional: Verify Admin User Exists

If login still fails after enabling Email/Password:

1. Go to Firebase Console → Authentication → **Users** tab
2. Check if `admin@gmail.com` exists
3. If not, create it:
   - Click **"Add user"**
   - Email: `admin@gmail.com`
   - Password: `121245`
   - Click **"Add user"**

## 🛠️ Quick Fix Script

If you want to verify/create the user programmatically:

```bash
cd server_cashflex
export FIREBASE_SERVICE_ACCOUNT="$(cat /path/to/service-account.json | jq -c)"
node scripts/create-admin-user.js
```

## ✅ Checklist

- [ ] Firebase Authentication is enabled
- [ ] Email/Password provider is enabled
- [ ] Admin user `admin@gmail.com` exists in Firebase
- [ ] Password is set correctly (`121245`)
- [ ] Firebase Client SDK environment variables are set in Vercel

## 🔍 Troubleshooting

**Still getting "operation-not-allowed"?**
- Wait 1-2 minutes after enabling (propagation delay)
- Clear browser cache
- Try incognito/private window
- Check Firebase Console → Authentication → Sign-in method → Email/Password is **Enabled**

**"User not found" error?**
- User doesn't exist in Firebase
- Run the create-admin-user script or create manually in Firebase Console

**"Invalid password" error?**
- Password is incorrect
- Reset password in Firebase Console → Authentication → Users → Edit user

---

**Most Common Issue**: Email/Password provider is not enabled in Firebase Console. Enable it first!
