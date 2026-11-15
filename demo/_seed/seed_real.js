// Seed PRAWDZIWYCH firm z companies_real.tsv (1 film = 1 firma).
// Konto: <plik>@a.pl / asdfghjkl. Reużywa plików już wgranych do Storage.
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
const PASSWORD = 'asdfghjkl';

const keyFile = fs.readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
initializeApp({ credential: cert(path.join(DEMO_DIR, keyFile)), storageBucket: BUCKET });
const db = getFirestore();
const bucket = getStorage().bucket();
const auth = getAuth();

// walidacja kategorii/branż względem constants.dart aplikacji
function loadAppCategories() {
  const src = fs.readFileSync(
    path.resolve(__dirname, '../../lib/shared/constants.dart'), 'utf8');
  const start = src.indexOf('Map<String, List<String>> categories = {');
  const end = src.indexOf('};', start);
  const body = src.slice(start, end);
  const map = {};
  let current = null;
  for (const line of body.split('\n')) {
    const cat = line.match(/^\s*'(.+)':\s*\[/);
    const item = line.match(/^\s*'(.+)',\s*$/);
    if (cat) { current = cat[1]; map[current] = []; }
    else if (item && current) map[current].push(item[1]);
  }
  return map;
}
const APP_CATEGORIES = loadAppCategories();

function titleCase(s) {
  return s.toLowerCase().replace(/(^|[\s-])\S/g, (c) => c.toUpperCase());
}

async function publicUrlFor(localPath, destination) {
  const f = bucket.file(destination);
  const token = crypto.randomUUID();
  const [exists] = await f.exists();
  if (exists) {
    await f.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  } else {
    if (!localPath || !fs.existsSync(localPath)) return null;
    await bucket.upload(localPath, {
      destination,
      metadata: { metadata: { firebaseStorageDownloadTokens: token } },
    });
  }
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(destination)}?alt=media&token=${token}`;
}

(async () => {
  const rows = fs
    .readFileSync(path.join(__dirname, 'companies_real.tsv'), 'utf8')
    .split('\n')
    .map((l) => l.replace(/\r$/, ''))
    .filter((l) => l.trim().length > 0)
    .map((l) => l.split('\t'));

  const HOURS = [9, 11, 13, 15, 17];
  let ok = 0, noVideo = 0, bad = 0;

  for (const r of rows) {
    const [sector, category, plik, , companyName, lastName, firstName,
      nip, , phone, contactEmail, www, postCode, , , city, street,
      buildingNr, flatNr, lokalizacja] = r;

    if (!APP_CATEGORIES[category] || !APP_CATEGORIES[category].includes(sector)) {
      console.error(`!! ${plik}: zła kategoria/branża "${category}"/"${sector}" — pomijam`);
      bad++;
      continue;
    }
    const [latS, lngS] = (lokalizacja || '').split(',').map((s) => s.trim());
    const lat = parseFloat(latS), lng = parseFloat(lngS);
    if (!isFinite(lat) || !isFinite(lng)) {
      console.error(`!! ${plik}: zła lokalizacja — pomijam`);
      bad++;
      continue;
    }

    const email = `${plik}@a.pl`;
    let uid;
    try { uid = (await auth.getUserByEmail(email)).uid; }
    catch (_) {
      uid = (await auth.createUser({
        email, password: PASSWORD, displayName: companyName,
      })).uid;
    }

    const loc = { lat, lng };
    await db.collection('users').doc(uid).set({
      email,
      firstName: titleCase(firstName || ''),
      lastName: titleCase(lastName || ''),
      phone: (phone || '').replace(/[^0-9+]/g, ''),
      bio: `${sector} — ${city}.`,
      isCompany: true,
      firma: true,
      nip: nip || '',
      companyName,
      companyCategory: category,
      companySector: sector,
      companyCity: city,
      companyLocation: loc,
      companyAddress: {
        street: street || '',
        buildingNr: buildingNr || '',
        flatNr: flatNr || '',
        city: city || '',
        postCode: postCode || '',
      },
      contactEmail: contactEmail || '',
      www: www || '',
      consents: { terms: true, rodo: true, acceptedAt: FieldValue.serverTimestamp() },
      createdAt: FieldValue.serverTimestamp(),
      demo: true,
    }, { merge: true });

    // promo (film) — idempotentnie po fileName
    const fileName = `${plik}.mp4`;
    const existing = await db.collection('promos')
      .where('fileName', '==', fileName).limit(1).get();
    if (existing.empty) {
      const fileUrl = await publicUrlFor(
        path.join(DEMO_DIR, fileName), `files/${fileName}`);
      if (fileUrl == null) {
        console.log(`~ ${plik}: BRAK PLIKU WIDEO — firma bez prezentacji`);
        noVideo++;
      } else {
        const thumbUrl = (await publicUrlFor(
          path.join(THUMB_DIR, `${plik}.jpg`), `thumbs/${plik}.jpg`)) || '';
        await db.collection('promos').add({
          userId: uid,
          category, sector, location: loc,
          fileUrl, thumbUrl, fileName,
          timestamp: FieldValue.serverTimestamp(),
          description: `${sector} • ${city}`,
          companyName,
          demo: true,
        });
      }
    }

    // sloty na 7 dni (30 min dla Barber/Dentyści, inaczej 60)
    const slotsCol = db.collection('users').doc(uid).collection('slots');
    const hasSlots = await slotsCol.limit(1).get();
    if (hasSlots.empty) {
      const dur = (sector === 'Barber' || sector === 'Dentyści') ? 30 : 60;
      const batch = db.batch();
      const today = new Date();
      for (let d = 1; d <= 7; d++) {
        const picks = HOURS.filter((h, i) => (d + i + plik.length) % 2 === 0)
          .slice(0, 3);
        for (const h of picks) {
          const dt = new Date(today.getFullYear(), today.getMonth(),
            today.getDate() + d, h, 0);
          batch.set(slotsCol.doc(), {
            start: Timestamp.fromDate(dt), durationMin: dur, bookedBy: '',
          });
        }
      }
      await batch.commit();
    }

    ok++;
    if (ok % 20 === 0) console.log(`... ${ok} firm`);
  }
  console.log(`Gotowe: ${ok} firm (bez wideo: ${noVideo}, pominięte: ${bad}).`);
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
