import { initializeApp } from 'firebase/app';
import { initializeAppCheck, ReCaptchaEnterpriseProvider } from 'firebase/app-check';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, getFirestore } from 'firebase/firestore';
import { connectStorageEmulator, getStorage } from 'firebase/storage';
import type { Ctx } from './data/ctx.ts';

const env = import.meta.env;

const config = {
  apiKey: env.VITE_FIREBASE_API_KEY as string | undefined,
  authDomain: env.VITE_FIREBASE_AUTH_DOMAIN as string | undefined,
  projectId: env.VITE_FIREBASE_PROJECT_ID as string | undefined,
  storageBucket: env.VITE_FIREBASE_STORAGE_BUCKET as string | undefined,
  messagingSenderId: env.VITE_FIREBASE_MESSAGING_SENDER_ID as string | undefined,
  appId: env.VITE_FIREBASE_APP_ID as string | undefined,
};

const useEmulators = env.VITE_USE_EMULATORS === 'true';

/** Brakujące klucze konfiguracji — strona pokazuje wtedy komunikat zamiast się wysypać. */
export const missingConfig = (
  useEmulators ? (['projectId'] as const) : (['apiKey', 'authDomain', 'projectId', 'storageBucket', 'appId'] as const)
).filter((k) => !config[k]);

function create(): Ctx | null {
  if (missingConfig.length) return null;
  const app = initializeApp({
    ...config,
    apiKey: config.apiKey || 'emulator',
    appId: config.appId || '1:0:web:0',
    authDomain: config.authDomain || `${config.projectId}.firebaseapp.com`,
    storageBucket: config.storageBucket || `${config.projectId}.appspot.com`,
  });
  const appCheckKey = env.VITE_APPCHECK_RECAPTCHA_ENTERPRISE_KEY as string | undefined;
  if (appCheckKey && !useEmulators) {
    initializeAppCheck(app, { provider: new ReCaptchaEnterpriseProvider(appCheckKey), isTokenAutoRefreshEnabled: true });
  }
  const auth = getAuth(app);
  auth.languageCode = 'pl';
  const db = getFirestore(app);
  const storage = getStorage(app);
  if (useEmulators) {
    const host = (env.VITE_EMULATOR_HOST as string | undefined) || '127.0.0.1';
    connectAuthEmulator(auth, `http://${host}:${env.VITE_AUTH_EMULATOR_PORT || 9199}`, { disableWarnings: true });
    connectFirestoreEmulator(db, host, Number(env.VITE_FIRESTORE_EMULATOR_PORT || 8185));
    connectStorageEmulator(storage, host, Number(env.VITE_STORAGE_EMULATOR_PORT || 9299));
  }
  return { db, auth, storage };
}

export const fb = create();

export const ctx = (): Ctx => {
  if (!fb) throw new Error('Brak konfiguracji Firebase');
  return fb;
};
