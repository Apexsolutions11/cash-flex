# Admin Dashboard Login Guide

## How Admin Authentication Works

The admin dashboard uses **Firebase Authentication**. Any user created in Firebase Authentication can log in to the admin panel.

**Important**: There are no hardcoded admin credentials. You need to create an admin user in Firebase Console first.

---

## Step 1: Create Admin User in Firebase Console

1. **Go to Firebase Console**:
   - Visit: https://console.firebase.google.com/
   - Select your project: `cash-flex-3b6d3`

2. **Navigate to Authentication**:
   - Click on "Authentication" in the left sidebar
   - Click on "Get Started" if you haven't enabled it yet

3. **Enable Email/Password Authentication**:
   - Go to the "Sign-in method" tab
   - Click on "Email/Password"
   - Enable "Email/Password" (toggle it ON)
   - Click "Save"

4. **Create Admin User**:
   - Go to the "Users" tab
   - Click "Add user"
   - Enter:
     - **Email**: `admin@cashflex.com` (or any email you prefer)
     - **Password**: Create a strong password (e.g., `Admin123!@#`)
   - Click "Add user"

---

## Step 2: Login to Admin Dashboard

1. **Go to Admin Login Page**:
   - Visit: `https://servercashflex.vercel.app/admin/login`
   - Or locally: `http://localhost:3000/admin/login`

2. **Enter Credentials**:
   - **Email**: The email you created in Firebase (e.g., `admin@cashflex.com`)
   - **Password**: The password you set in Firebase

3. **Click "Login"**

---

## Important Notes

### Security
- **Any Firebase user can access the admin panel** - there's no special admin role check
- Make sure only trusted users have Firebase accounts
- Use strong passwords for admin accounts
- Consider enabling 2FA in Firebase for additional security

### Admin Email Environment Variable
- The `ADMIN_EMAIL` environment variable is used for some backend checks (like payout restrictions)
- It doesn't control who can log in - it's just a reference email
- You can set it to your admin email in Vercel environment variables if needed

### Troubleshooting

**"Login failed" error:**
- Verify the user exists in Firebase Console → Authentication → Users
- Check that Email/Password authentication is enabled
- Ensure Firebase Client SDK environment variables are set correctly:
  - `NEXT_PUBLIC_FIREBASE_API_KEY`
  - `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
  - `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
  - etc.

**"User not found" error:**
- Make sure you created the user in the correct Firebase project (`cash-flex-3b6d3`)
- Verify the email address is correct

**Can't access admin pages after login:**
- Check browser console for errors
- Verify Firebase Client SDK is initialized correctly
- Check that `FIREBASE_SERVICE_ACCOUNT` is set correctly in Vercel

---

## Quick Setup Script (Optional)

If you want to create an admin user programmatically, you can use Firebase Admin SDK:

```typescript
// This would be a one-time script
import { auth } from '@/lib/firebase-admin';

async function createAdminUser() {
  try {
    const userRecord = await auth.createUser({
      email: 'admin@cashflex.com',
      password: 'YourSecurePassword123!',
      emailVerified: true,
    });
    console.log('Admin user created:', userRecord.uid);
  } catch (error) {
    console.error('Error creating admin user:', error);
  }
}
```

But the easiest way is to use Firebase Console as described above.

---

## Summary

1. ✅ Create user in Firebase Console → Authentication → Users
2. ✅ Use that email/password to log in at `/admin/login`
3. ✅ That's it! No special configuration needed.

The admin dashboard will work for any authenticated Firebase user.

---

## ✅ Admin User Already Created

**Current Admin Credentials:**
- **Email**: `admin@gmail.com`
- **Password**: `121245`
- **Login URL**: https://servercashflex.vercel.app/admin/login

You can use these credentials to log in to the admin dashboard right now!

**Note**: If you need to change the password or create additional admin users, you can:
1. Use Firebase Console → Authentication → Users
2. Or run the script: `node scripts/create-admin-user.js` (after setting FIREBASE_SERVICE_ACCOUNT)
