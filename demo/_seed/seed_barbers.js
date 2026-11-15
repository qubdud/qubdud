// 2 demo-firmy barberskie: konta + filmy (kopie u*.mp4) + losowe sloty 30-min.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { getAuth } = require('firebase-admin/auth');

const DEMO_DIR = path.resolve(__dirname, '..');
const THUMB_DIR = path.join(DEMO_DIR, '_thumbs');
const BUCKET = 'qubdud-8f2b8.firebasestorage.app';

const keyFile = fs.readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
initializeApp({ credential: cert(path.join(DEMO_DIR, keyFile)), storageBucket: BUCKET });
const db = getFirestore();
const bucket = getStorage().bucket();
const auth = getAuth();

const BARBERS = [
  {
    email: 'demo.barber1@qubdud-demo.pl', companyName: 'Barber King',
    city: 'Warszawa', lat: 52.2352, lng: 21.0011,
    videos: { 'u1w.mp4': 'barber1_a.mp4', 'u2w.mp4': 'barber1_b.mp4', 'u3w.mp4': 'barber1_c.mp4' },
  },
  {
    email: 'demo.barber2@qubdud-demo.pl', companyName: 'Cut&Go Barbershop',
    city: 'Kraków', lat: 50.0619, lng: 19.9368,
    videos: { 'u4w.mp4': 'barber2_a.mp4', 'u5w.mp4': 'barber2_b.mp4' },
  },
];

async function uploadPublic(localPath, destination) {
  const token = crypto.randomUUID();
  await bucket.upload(localPath, {
    destination,
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(destination)}?alt=media&token=${token}`;
}

(async () => {
  for (const b of BARBERS) {
    let uid;
    try { uid = (await auth.getUserByEmail(b.email)).uid; }
    catch (_) {
      uid = (await auth.createUser({ email: b.email, password: 'Demo123!', displayName: b.companyName })).uid;
    }
    const loc = { lat: b.lat, lng: b.lng };
    await db.collection('users').doc(uid).set({
      email: b.email, firstName: 'Demo', lastName: b.companyName,
      phone: '600400500', bio: `Barber — ${b.city}. Konto demonstracyjne.`,
      isCompany: true, firma: true, nip: '0000000000',
      companyName: b.companyName, companyCategory: 'Zdrowie i uroda',
      companySector: 'Barber', companyCity: b.city, companyLocation: loc,
      consents: { terms: true, rodo: true, acceptedAt: FieldValue.serverTimestamp() },
      createdAt: FieldValue.serverTimestamp(), demo: true,
    }, { merge: true });
    console.log(`user ${b.email} → ${uid}`);

    // filmy (kopie plików u*)
    for (const [src, dst] of Object.entries(b.videos)) {
      const existing = await db.collection('promos')
        .where('fileName', '==', dst).limit(1).get();
      if (!existing.empty) { console.log(`  ~ ${dst} już jest`); continue; }
      const fileUrl = await uploadPublic(path.join(DEMO_DIR, src), `files/${dst}`);
      const thumbSrc = path.join(THUMB_DIR, src.replace('.mp4', '.jpg'));
      const thumbUrl = fs.existsSync(thumbSrc)
        ? await uploadPublic(thumbSrc, `thumbs/${dst.replace('.mp4', '.jpg')}`)
        : '';
      await db.collection('promos').add({
        userId: uid, category: 'Zdrowie i uroda', sector: 'Barber',
        location: loc, fileUrl, thumbUrl, fileName: dst,
        timestamp: FieldValue.serverTimestamp(),
        description: `Barber — ${b.city}`, companyName: b.companyName, demo: true,
      });
      console.log(`  + ${dst}`);
    }

    // losowe sloty 30-min na 7 dni
    const slotsCol = db.collection('users').doc(uid).collection('slots');
    const existing = await slotsCol.where('start', '>', Timestamp.now()).limit(1).get();
    if (!existing.empty) { console.log('  ~ sloty już są'); continue; }
    const batch = db.batch();
    let count = 0;
    const today = new Date();
    for (let d = 1; d <= 7; d++) {
      const n = 4 + Math.floor(Math.random() * 5); // 4-8 slotów
      const startHour = 9 + Math.floor(Math.random() * 3); // 9-11
      for (let i = 0; i < n; i++) {
        const minutes = startHour * 60 + i * 30 + (Math.random() < 0.3 ? 30 : 0);
        const dt = new Date(today.getFullYear(), today.getMonth(),
          today.getDate() + d, Math.floor(minutes / 60), minutes % 60);
        batch.set(slotsCol.doc(), {
          start: Timestamp.fromDate(dt), durationMin: 30, bookedBy: '',
        });
        count++;
      }
    }
    await batch.commit();
    console.log(`  + ${count} slotów 30-min`);
  }
  console.log('Gotowe.');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
