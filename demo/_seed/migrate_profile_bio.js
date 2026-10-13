// Migracja opisu firmy: profile/{uid}.description → users/{uid}.bio (QB-43).
// Apka zapisuje i pokazuje już tylko users.bio; stary opis z kolekcji `profile`
// czyta jeszcze fallback oznaczony w kodzie `// EXPIRES: … migrate_profile_bio.js`.
// Po migracji: usunąć te fallbacki (getProfileByUser, ProfileInfo w profilach)
// oraz kolekcję `profile` i jej regułę.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_profile_bio.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  const profiles = await db.collection('profile').get();

  // apka brała najnowszy wpis użytkownika (orderBy timestamp desc, limit 1)
  const latest = new Map();
  for (const d of profiles.docs) {
    const p = d.data();
    const uid = p.userId || d.id;
    const description = (p.description || '').trim();
    if (!description) continue;
    const ts = p.timestamp && p.timestamp.toMillis ? p.timestamp.toMillis() : 0;
    const cur = latest.get(uid);
    if (!cur || ts >= cur.ts) latest.set(uid, { description, ts });
  }

  let toCopy = 0;
  let skipped = 0;
  for (const [uid, { description }] of latest) {
    const ref = db.collection('users').doc(uid);
    const user = await ref.get();
    if (!user.exists) {
      skipped++;
      console.log(`- ${uid}: brak users/${uid}`);
      continue;
    }
    if ((user.data().bio || '').trim()) {
      skipped++;
      console.log(`~ ${uid}: bio już jest — zostawiam`);
      continue;
    }
    console.log(`${apply ? '+' : '?'} ${uid}: bio ← "${description.slice(0, 60)}"`);
    if (apply) await ref.update({ bio: description });
    toCopy++;
  }

  console.log(
    `${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${toCopy}, pominięto: ${skipped}, ` +
      `dokumentów profile: ${profiles.size}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
