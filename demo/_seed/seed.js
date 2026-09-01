// Seed demo-firm do Firebase (Auth + Firestore + Storage).
// Wejście: companies.json (generowany z Excela), filmy w ../, miniatury w ../_thumbs/.
// Każdy dokument dostaje flagę demo:true — łatwo potem wyczyścić.
// Użycie: node seed.js [--dry] [--only=prefix]

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');
const { getAuth } = require('firebase-admin/auth');

const DRY = process.argv.includes('--dry');
const onlyArg = process.argv.find((a) => a.startsWith('--only='));
const ONLY = onlyArg ? onlyArg.split('=')[1] : null;

const DEMO_DIR = path.resolve(__dirname, '..');
const THUMB_DIR = path.join(DEMO_DIR, '_thumbs');
const BUCKET = 'qubdud-8f2b8.firebasestorage.app';

// ── init admin ───────────────────────────────────────────────────────────────
const keyFile = fs
  .readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
if (!keyFile) {
  console.error('Brak klucza serwisowego w', DEMO_DIR);
  process.exit(1);
}
initializeApp({
  credential: cert(path.join(DEMO_DIR, keyFile)),
  storageBucket: BUCKET,
});
const db = getFirestore();
const bucket = getStorage().bucket();
const auth = getAuth();

// ── walidacja kategorii względem constants.dart ──────────────────────────────
function loadAppCategories() {
  const src = fs.readFileSync(
    path.resolve(__dirname, '../../lib/shared/constants.dart'),
    'utf8'
  );
  const start = src.indexOf('Map<String, List<String>> categories = {');
  const end = src.indexOf('};', start);
  const body = src.slice(start, end);
  const map = {};
  let current = null;
  for (const line of body.split('\n')) {
    const cat = line.match(/^\s*'(.+)':\s*\[/);
    const item = line.match(/^\s*'(.+)',\s*$/);
    if (cat) {
      current = cat[1];
      map[current] = [];
    } else if (item && current) {
      map[current].push(item[1]);
    }
  }
  return map;
}
const APP_CATEGORIES = loadAppCategories();

// ── helpers ──────────────────────────────────────────────────────────────────
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

async function ensureAuthUser(email, displayName) {
  try {
    return (await auth.getUserByEmail(email)).uid;
  } catch (_) {
    const u = await auth.createUser({
      email,
      password: 'Demo123!',
      displayName,
    });
    return u.uid;
  }
}

const geoCache = {};
async function geocodeCity(city) {
  if (geoCache[city]) return geoCache[city];
  const url =
    'https://nominatim.openstreetmap.org/search?format=json&limit=1&countrycodes=pl&q=' +
    encodeURIComponent(city);
  const res = await fetch(url, {
    headers: { 'User-Agent': 'qubdud-demo-seed/1.0' },
  });
  const json = await res.json();
  if (!json.length) throw new Error(`Nie znaleziono miasta: ${city}`);
  const out = { lat: parseFloat(json[0].lat), lng: parseFloat(json[0].lon) };
  geoCache[city] = out;
  await new Promise((r) => setTimeout(r, 1100)); // limit Nominatim 1 req/s
  return out;
}

// ── main ─────────────────────────────────────────────────────────────────────
(async () => {
  const companies = JSON.parse(
    fs.readFileSync(path.join(__dirname, 'companies.json'), 'utf8')
  );

  for (const c of companies) {
    if (ONLY && c.prefix !== ONLY) continue;

    // walidacja kategorii/branży
    if (!APP_CATEGORIES[c.category]) {
      console.error(`[${c.prefix}] ZŁA KATEGORIA: "${c.category}" — pomijam`);
      continue;
    }
    if (!APP_CATEGORIES[c.category].includes(c.sector)) {
      console.error(
        `[${c.prefix}] ZŁA BRANŻA: "${c.sector}" (kategoria "${c.category}") — pomijam`
      );
      continue;
    }

    const videos = fs
      .readdirSync(DEMO_DIR)
      .filter((f) => f.endsWith('.mp4') && f.match(new RegExp(`^${c.prefix}\\d+w\\.mp4$`)));
    if (!videos.length) {
      console.error(`[${c.prefix}] brak filmów — pomijam`);
      continue;
    }

    const loc =
      c.lat && c.lng ? { lat: c.lat, lng: c.lng } : await geocodeCity(c.city);
    const email = c.email || `demo.${c.prefix}@qubdud-demo.pl`;

    console.log(
      `[${c.prefix}] ${c.companyName} | ${c.category} / ${c.sector} | ${c.city} (${loc.lat.toFixed(4)},${loc.lng.toFixed(4)}) | filmów: ${videos.length}${DRY ? ' [DRY]' : ''}`
    );
    if (DRY) continue;

    const uid = await ensureAuthUser(email, c.companyName);

    await db.collection('users').doc(uid).set(
      {
        email,
        firstName: 'Demo',
        lastName: c.companyName,
        phone: c.phone || '600100200',
        bio: c.bio || `${c.sector} — ${c.city}. Konto demonstracyjne.`,
        isCompany: true,
        firma: true,
        nip: c.nip || '0000000000',
        companyName: c.companyName,
        companyCategory: c.category,
        companySector: c.sector,
        companyCity: c.city,
        companyLocation: loc,
        consents: { terms: true, rodo: true, acceptedAt: FieldValue.serverTimestamp() },
        createdAt: FieldValue.serverTimestamp(),
        demo: true,
      },
      { merge: true }
    );

    for (const video of videos) {
      // idempotencja: pomiń jeśli promo z tym fileName już istnieje
      const existing = await db
        .collection('promos')
        .where('fileName', '==', video)
        .limit(1)
        .get();
      if (!existing.empty) {
        console.log(`  ~ ${video} już jest, pomijam`);
        continue;
      }

      const thumbFile = path.join(THUMB_DIR, video.replace('.mp4', '.jpg'));
      const fileUrl = await uploadPublic(
        path.join(DEMO_DIR, video),
        `files/${video}`
      );
      const thumbUrl = fs.existsSync(thumbFile)
        ? await uploadPublic(thumbFile, `thumbs/${video.replace('.mp4', '.jpg')}`)
        : '';

      await db.collection('promos').add({
        userId: uid,
        category: c.category,
        sector: c.sector,
        location: loc,
        fileUrl,
        thumbUrl,
        fileName: video,
        timestamp: FieldValue.serverTimestamp(),
        description: c.bio || `${c.sector} — ${c.city}`,
        companyName: c.companyName,
        demo: true,
      });
      console.log(`  + ${video}`);
    }
  }
  console.log('Gotowe.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
