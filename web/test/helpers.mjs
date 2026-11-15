// Wspólne dla testu i danych startowych: klienci Firebase na emulatorach i konta „z apki”.
import { deleteApp, initializeApp } from 'firebase/app';
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, doc, getFirestore, serverTimestamp, writeBatch } from 'firebase/firestore';
import { connectStorageEmulator, getStorage } from 'firebase/storage';

export const PROJECT = process.env.GCLOUD_PROJECT || 'demo-qubdud';
export const FS = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8185';
export const AUTH = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9199';
export const STORAGE = process.env.FIREBASE_STORAGE_EMULATOR_HOST || '';
export const RUN = Date.now().toString(36);
export const PASSWORD = 'Test-haslo-1';

if (!PROJECT.startsWith('demo-')) {
  console.error(`Tylko projekt demo-* na emulatorach (jest ${PROJECT})`);
  process.exit(2);
}

const config = {
  apiKey: 'demo-key',
  authDomain: `${PROJECT}.firebaseapp.com`,
  projectId: PROJECT,
  storageBucket: `${PROJECT}.appspot.com`,
  appId: '1:0:web:0',
};
const hostPort = (h) => {
  const i = h.lastIndexOf(':');
  return [h.slice(0, i), Number(h.slice(i + 1))];
};

const apps = [];

/** Osobna aplikacja Firebase = osobny zalogowany użytkownik (kształt Ctx z src/data/ctx.ts). */
export function makeCtx(name) {
  const app = initializeApp(config, `${name}-${RUN}`);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${AUTH}`, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, ...hostPort(FS));
  const storage = getStorage(app);
  if (STORAGE) connectStorageEmulator(storage, ...hostPort(STORAGE));
  return { app, auth, db, storage };
}

export const closeAll = () => Promise.allSettled(apps.map((a) => deleteApp(a)));

function encode(v) {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(encode) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encode(x)])) } };
}

/** Zapis z pominięciem reguł (nagłówek „Bearer owner” emulatora) — tylko dane startowe. */
export async function ownerSet(path, data) {
  const res = await fetch(`http://${FS}/v1/projects/${PROJECT}/databases/(default)/documents/${path}`, {
    method: 'PATCH',
    headers: { Authorization: 'Bearer owner', 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields: encode(data).mapValue.fields }),
  });
  if (res.status !== 200) throw new Error(`ownerSet ${path}: ${res.status} ${await res.text()}`);
}

/** Konto z hasłem + profil dokładnie jak registerUser w apce (firma: { nip, name }). */
export async function registerInApp(ctx, { email, firstName, lastName, phone, company }) {
  const cred = await createUserWithEmailAndPassword(ctx.auth, email, PASSWORD);
  const uid = cred.user.uid;
  const ref = doc(ctx.db, 'users', uid);
  await writeBatch(ctx.db)
    .set(ref, {
      email: '',
      firstName,
      lastName,
      phone: company ? phone : '',
      isCompany: !!company,
      firma: !!company,
      ...(company
        ? {
            nip: company.nip,
            companyName: company.name,
            companyCategory: 'Budowlane i Remontowe',
            companySector: 'Hydraulik',
            companyCity: 'Warszawa',
            companyLocation: { lat: 52.2297, lng: 21.0122 },
          }
        : {}),
      consents: { terms: true, rodo: true, acceptedAt: serverTimestamp() },
      createdAt: serverTimestamp(),
    })
    .set(doc(ref, 'private', 'contact'), { email, ...(company ? {} : { phone }) })
    .commit();
  return uid;
}
