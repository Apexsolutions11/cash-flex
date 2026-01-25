import * as admin from 'firebase-admin';

let projectId = '';
let _db: admin.firestore.Firestore | null = null;
let _auth: admin.auth.Auth | null = null;

/**
 * Initialize Firebase Admin (singleton)
 */
function initializeFirebaseAdmin(): admin.app.App {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  try {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable is not set.');
    }

    const serviceAccount = JSON.parse(serviceAccountJson);
    projectId = serviceAccount.project_id || '';
    return admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.error('Firebase Admin initialization error:', error);
    throw error;
  }
}

/**
 * Lazy Firestore getter
 */
function getDb(): admin.firestore.Firestore {
  if (_db) return _db;

  const app = initializeFirebaseAdmin();
  _db = admin.firestore(app);
  return _db;
}

/**
 * Lazy Auth getter
 */
function getAuth(): admin.auth.Auth {
  if (_auth) return _auth;

  const app = initializeFirebaseAdmin();
  _auth = admin.auth(app);
  return _auth;
}

/**
 * Proxied exports (safe lazy access)
 */
export const db = new Proxy({} as admin.firestore.Firestore, {
  get(_target, prop) {
    const instance = getDb();
    const value = (instance as any)[prop];
    return typeof value === 'function' ? value.bind(instance) : value;
  },
});

export const auth = new Proxy({} as admin.auth.Auth, {
  get(_target, prop) {
    const instance = getAuth();
    const value = (instance as any)[prop];
    return typeof value === 'function' ? value.bind(instance) : value;
  },
});

export { admin, projectId };
