// Dodatkowi userzy testowi z realnymi zgłoszeniami (Warszawa i okolice).
// Idempotentny: zgłoszenie rozpoznawane po polu `seedKey`.
// Użycie: node seed_users_more.js
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const DEMO_DIR = path.resolve(__dirname, '..');
const keyFile = fs.readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
initializeApp({ credential: cert(path.join(DEMO_DIR, keyFile)) });
const db = getFirestore();
const auth = getAuth();

const PASSWORD = 'Demo123!';

// branże dobrane pod firmy demo z Warszawy (elektryk, hydraulik, barber,
// sprzątanie, stolarz, mechanik, dentysta, zwierzęta, RTV AGD)
const PEOPLE = [
  {
    email: 'demo.user4@qubdud-demo.pl',
    firstName: 'Katarzyna', lastName: 'Nowak', phone: '600100104',
    bio: 'Mieszkanie na Mokotowie, remont w toku.',
    lat: 52.1935, lng: 21.0245, city: 'Warszawa',
    requests: [
      { key: 'u4-elektryk', category: 'Budowlane i Remontowe', sector: 'Elektryk',
        is24: true, daysAgo: 0,
        description: 'Po burzy wybija bezpiecznik w całym mieszkaniu. Potrzebny elektryk najlepiej dziś.' },
      { key: 'u4-stolarz', category: 'Budowlane i Remontowe', sector: 'Wykończenia wnętrz',
        is24: false, daysAgo: 2,
        description: 'Szafa wnękowa 240x260 cm w sypialni — proszę o wycenę z montażem.' },
      { key: 'u4-sprzatanie', category: 'Sprzątanie', sector: 'Sprzątanie',
        is24: false, daysAgo: 5,
        description: 'Sprzątanie po remoncie, 48 m², dużo kurzu budowlanego. Termin do uzgodnienia.' },
    ],
  },
  {
    email: 'demo.user5@qubdud-demo.pl',
    firstName: 'Michał', lastName: 'Zieliński', phone: '600100105',
    bio: 'Dom pod Warszawą, dwa auta w rodzinie.',
    lat: 52.2680, lng: 20.9700, city: 'Warszawa',
    requests: [
      { key: 'u5-hydraulik', category: 'Budowlane i Remontowe', sector: 'Hydraulik',
        is24: true, daysAgo: 0,
        description: 'Cieknie zawór pod zlewem w kuchni, woda leci na podłogę. Pilne!' },
      { key: 'u5-mechanik', category: 'Motoryzacja', sector: 'Mechanik samochodowy',
        is24: false, daysAgo: 1,
        description: 'Passat B7 — stuka przednie zawieszenie na nierównościach. Proszę o diagnostykę.' },
      { key: 'u5-agd', category: 'Montaż i naprawa', sector: 'Serwis RTV AGD',
        is24: false, daysAgo: 4,
        description: 'Pralka Bosch nie odwirowuje i głośno pracuje. Naprawa u mnie w domu.' },
    ],
  },
  {
    email: 'demo.user6@qubdud-demo.pl',
    firstName: 'Ewa', lastName: 'Wiśniewska', phone: '600100106',
    bio: 'Wola, pies i sporo spraw na głowie.',
    lat: 52.2320, lng: 20.9640, city: 'Warszawa',
    requests: [
      { key: 'u6-zwierzeta', category: 'Zwierzęta', sector: 'Opieka nad zwierzętami',
        is24: false, daysAgo: 0,
        description: 'Opieka nad labradorem przez 5 dni w przyszłym tygodniu, spacery 2x dziennie.' },
      { key: 'u6-dentysta', category: 'Zdrowie i uroda', sector: 'Dentyści',
        is24: true, daysAgo: 0,
        description: 'Ukruszony ząb przedni, boli przy zimnym. Szukam wizyty na już.' },
      { key: 'u6-barber', category: 'Zdrowie i uroda', sector: 'Barber',
        is24: false, daysAgo: 3,
        description: 'Strzyżenie męskie + broda dla syna przed studniówką, sobota rano.' },
    ],
  },
];

(async () => {
  // walidacja kategorii względem apki
  const src = fs.readFileSync(path.resolve(__dirname, '../../lib/shared/constants.dart'), 'utf8');
  const body = src.slice(src.indexOf('Map<String, List<String>> categories = {'));
  const cats = {};
  let cur = null;
  for (const line of body.split('\n')) {
    const c = line.match(/^\s*'(.+)':\s*\[/);
    const i = line.match(/^\s*'(.+)',\s*$/);
    if (c) { cur = c[1]; cats[cur] = []; } else if (i && cur) cats[cur].push(i[1]);
    if (line.trim() === '};') break;
  }

  let people = 0, added = 0, skipped = 0;
  for (const p of PEOPLE) {
    let uid;
    try {
      uid = (await auth.getUserByEmail(p.email)).uid;
      await auth.updateUser(uid, { password: PASSWORD });
    } catch (_) {
      uid = (await auth.createUser({
        email: p.email, password: PASSWORD,
        displayName: `${p.firstName} ${p.lastName}`,
      })).uid;
    }

    await db.collection('users').doc(uid).set({
      email: p.email,
      firstName: p.firstName,
      lastName: p.lastName,
      phone: p.phone,
      bio: p.bio,
      isCompany: false,
      firma: false,
      consents: { terms: true, rodo: true, acceptedAt: FieldValue.serverTimestamp() },
      createdAt: FieldValue.serverTimestamp(),
      demo: true,
    }, { merge: true });
    people++;

    for (const r of p.requests) {
      if (!cats[r.category] || !cats[r.category].includes(r.sector)) {
        console.error(`!! ${r.key}: zła kategoria/branża ${r.category}/${r.sector}`);
        continue;
      }
      const exists = await db.collection('requests')
        .where('seedKey', '==', r.key).limit(1).get();
      if (!exists.empty) { skipped++; continue; }

      await db.collection('requests').add({
        userId: uid,
        category: r.category,
        sector: r.sector,
        city: p.city,
        location: { lat: p.lat, lng: p.lng },
        description: r.description,
        is24: r.is24,
        fileUrl: '', thumbUrl: '', fileName: '',
        status: 'open',
        timestamp: Timestamp.fromMillis(Date.now() - r.daysAgo * 86400e3),
        seedKey: r.key,
        demo: true,
      });
      added++;
    }
  }
  console.log(`Userzy: ${people} | zgłoszenia dodane: ${added}, pominięte (już były): ${skipped}`);
  console.log('Logowanie: demo.user4/5/6@qubdud-demo.pl — hasło Demo123!');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
