// Seed demo-userów i fake zgłoszeń. Idempotentny (po fileName).
// Użycie: node seed_requests.js

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { getAuth } = require('firebase-admin/auth');

const DEMO_DIR = path.resolve(__dirname, '..');
const IMG_DIR = path.join(DEMO_DIR, '_reqimg');
const BUCKET = 'qubdud-8f2b8.firebasestorage.app';

const keyFile = fs
  .readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
initializeApp({
  credential: cert(path.join(DEMO_DIR, keyFile)),
  storageBucket: BUCKET,
});
const db = getFirestore();
const bucket = getStorage().bucket();
const auth = getAuth();

const USERS = {
  1: { email: 'demo.user1@qubdud-demo.pl', firstName: 'Jan', lastName: 'Testowy', lat: 52.2297, lng: 21.0122 },
  2: { email: 'demo.user2@qubdud-demo.pl', firstName: 'Anna', lastName: 'Przykładowa', lat: 52.2405, lng: 21.0305 },
  3: { email: 'demo.user3@qubdud-demo.pl', firstName: 'Piotr', lastName: 'Demo', lat: 52.2155, lng: 20.9855 },
};

async function uploadPublic(localPath, destination) {
  const token = crypto.randomUUID();
  await bucket.upload(localPath, {
    destination,
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(
    destination
  )}?alt=media&token=${token}`;
}

(async () => {
  // 1. userzy demo
  const uids = {};
  for (const [key, u] of Object.entries(USERS)) {
    let uid;
    try {
      uid = (await auth.getUserByEmail(u.email)).uid;
    } catch (_) {
      uid = (
        await auth.createUser({
          email: u.email,
          password: 'Demo123!',
          displayName: `${u.firstName} ${u.lastName}`,
        })
      ).uid;
    }
    uids[key] = uid;
    await db.collection('users').doc(uid).set(
      {
        email: u.email,
        firstName: u.firstName,
        lastName: u.lastName,
        phone: '600200300',
        bio: 'Konto demonstracyjne.',
        isCompany: false,
        firma: false,
        consents: { terms: true, rodo: true, acceptedAt: FieldValue.serverTimestamp() },
        createdAt: FieldValue.serverTimestamp(),
        demo: true,
      },
      { merge: true }
    );
    console.log(`user ${u.email} → ${uid}`);
  }

  // 2. zgłoszenia
  const reqs = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'requests.json'), 'utf8')
  );
  for (const r of reqs) {
    const fileName = `${r.file}.jpg`;
    const existing = await db
      .collection('requests')
      .where('fileName', '==', fileName)
      .limit(1)
      .get();
    if (!existing.empty) {
      console.log(`~ ${fileName} już jest, pomijam`);
      continue;
    }

    const img = path.join(IMG_DIR, fileName);
    const fileUrl = await uploadPublic(img, `files/${fileName}`);
    const thumbUrl = await uploadPublic(img, `thumbs/${fileName}`);

    await db.collection('requests').add({
      userId: uids[r.user],
      category: r.category,
      sector: r.sector,
      location: { lat: r.lat, lng: r.lng },
      city: r.city,
      fileUrl,
      thumbUrl,
      fileName,
      timestamp: FieldValue.serverTimestamp(),
      is24: r.is24,
      description: r.desc,
      status: 'open',
      takenBy: '',
      takenByName: '',
      confirmedByCompany: false,
      confirmedByUser: false,
      demo: true,
    });
    console.log(`+ ${fileName} (${r.sector}${r.is24 ? ', PILNE' : ''})`);
  }
  console.log('Gotowe.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
