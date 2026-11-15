// Pole userId w notatkach firm o klientach (users/{firma}/clientNotes/{klient}).
// deleteAccount kasuje po nim notatki wszystkich firm o usuwanym koncie
// (collectionGroup('clientNotes').where('userId', '==', uid)), także bez relacji.
// Apka zapisuje userId od tej wersji; starym notatkom uzupełniamy je z id dokumentu.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_client_notes_user_id.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  let changed = 0;
  for (const d of (await db.collectionGroup('clientNotes').get()).docs) {
    if (d.get('userId') === d.id) continue;
    console.log(`${apply ? '+' : '?'} ${d.ref.path}: userId ← ${d.id}`);
    if (apply) await d.ref.update({ userId: d.id });
    changed++;
  }
  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
