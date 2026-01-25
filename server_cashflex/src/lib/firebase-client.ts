import { initializeApp, getApps, FirebaseApp } from 'firebase/app';
import { getAuth, Auth } from 'firebase/auth';
import { getFirestore, Firestore } from 'firebase/firestore';

let app: FirebaseApp | null = null;
let auth: Auth | null = null;
let firestore: Firestore | null = null;

export function getFirebaseApp(): FirebaseApp {
  if (app) {
    return app;
  }

  if (typeof window === 'undefined') {
    throw new Error('Firebase client can only be initialized in browser');
  }

  const firebaseConfig = {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
  };

  if (getApps().length === 0) {
    app = initializeApp(firebaseConfig);
  } else {
    app = getApps()[0];
  }

  return app;
}

export function getFirebaseAuth(): Auth {
  if (auth) {
    return auth;
  }

  const firebaseApp = getFirebaseApp();
  auth = getAuth(firebaseApp);
  return auth;
}

export function getFirestoreClient(): Firestore {
  if (firestore) {
    return firestore;
  }

  const firebaseApp = getFirebaseApp();
  firestore = getFirestore(firebaseApp);
  return firestore;
}

