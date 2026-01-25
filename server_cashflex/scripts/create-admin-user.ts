/**
 * Script to create an admin user in Firebase Authentication
 * 
 * Usage:
 * 1. Make sure FIREBASE_SERVICE_ACCOUNT is set in your environment
 * 2. Run: npx tsx scripts/create-admin-user.ts
 */

import { auth } from '../src/lib/firebase-admin';

async function createAdminUser() {
  const email = 'admin@gmail.com';
  const password = '121245';

  try {
    console.log(`Creating admin user: ${email}...`);

    // Check if user already exists
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
      console.log(`User ${email} already exists with UID: ${userRecord.uid}`);
      console.log('Updating password...');
      
      // Update password
      await auth.updateUser(userRecord.uid, {
        password: password,
        emailVerified: true,
      });
      
      console.log('✅ Password updated successfully!');
      console.log(`\nLogin credentials:`);
      console.log(`Email: ${email}`);
      console.log(`Password: ${password}`);
      return;
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        // User doesn't exist, create new one
        console.log('User does not exist, creating new user...');
      } else {
        throw error;
      }
    }

    // Create new user
    userRecord = await auth.createUser({
      email: email,
      password: password,
      emailVerified: true,
    });

    console.log('✅ Admin user created successfully!');
    console.log(`UID: ${userRecord.uid}`);
    console.log(`Email: ${userRecord.email}`);
    console.log(`\nLogin credentials:`);
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log(`\nYou can now log in at: https://servercashflex.vercel.app/admin/login`);
  } catch (error: any) {
    console.error('❌ Error creating admin user:', error.message);
    
    if (error.code === 'auth/email-already-exists') {
      console.log('\nUser already exists. Trying to update password...');
      try {
        const existingUser = await auth.getUserByEmail(email);
        await auth.updateUser(existingUser.uid, {
          password: password,
          emailVerified: true,
        });
        console.log('✅ Password updated successfully!');
      } catch (updateError: any) {
        console.error('❌ Error updating password:', updateError.message);
      }
    } else {
      process.exit(1);
    }
  }
}

// Run the script
createAdminUser()
  .then(() => {
    console.log('\n✅ Script completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Script failed:', error);
    process.exit(1);
  });
