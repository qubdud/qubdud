// Migracja starych relacji klient↔firma (users/{x}/clients, users/{x}/myCompanies).
// Najstarsze dokumenty trzymają źródło w pojedynczym polu `requestId`
// (id zgłoszenia albo 'slot_<id>'). Apka i Cloud Functions czytają je jeszcze
// obok tablic (fallback oznaczony `// EXPIRES: … migrate_relation_request_id.js`).
// Przenosimy je do requestIds / slotIds i kasujemy `requestId`.
// Zapis do podkolekcji users nie uruchamia żadnej Cloud Function.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_relation_request_id.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  let changed = 0;
  for (const group of ['clients', 'myCompanies']) {
    const snap = await db.collectionGroup(group).get();
    for (const d of snap.docs) {
      const legacy = d.data().requestId;
      if (legacy === undefined) continue;
      const update = { requestId: FieldValue.delete() };
      if (typeof legacy === 'string' && legacy.startsWith('slot_')) {
        update.slotIds = FieldValue.arrayUnion(legacy.slice(5));
      } else if (typeof legacy === 'string' && legacy) {
        update.requestIds = FieldValue.arrayUnion(legacy);
      }
      console.log(`${apply ? '+' : '?'} ${d.ref.path}: requestId '${legacy}' → ${
        update.slotIds ? 'slotIds' : update.requestIds ? 'requestIds' : 'usunięte (puste)'}`);
      if (apply) await d.ref.update(update);
      changed++;
    }
  }
  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
