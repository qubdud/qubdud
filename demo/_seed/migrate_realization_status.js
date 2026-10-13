// Spójność realizacji ze zgłoszeniem (QB-27, QB-32, kontrakt K7).
// Apka od teraz przy dodaniu zdjęć przez firmę ustawia requests/{id}.realizationStatus
// = 'pending', a decyzja klienta 'approved' dopisuje closedReason 'realized'.
// Stare dane:
//  - zgłoszenia 'taken' z czekającymi zdjęciami firmy nie mają realizationStatus
//    → ustawiamy 'pending' (Aktywność pokaże „zdjęcia do potwierdzenia"),
//  - zamknięte z realizationStatus 'approved' bez closedReason → 'realized'.
// Zapis do requests nie uruchamia żadnej Cloud Function.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_realization_status.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  const pending = await db.collection('realizations').where('status', '==', 'pending').get();
  const withPending = new Set(
    pending.docs.filter((d) => d.data().addedByRole !== 'user').map((d) => d.data().requestId));

  let changed = 0;
  for (const requestId of withPending) {
    if (!requestId) continue;
    const ref = db.collection('requests').doc(requestId);
    const r = await ref.get();
    if (!r.exists) continue;
    const d = r.data();
    if (d.status !== 'taken' || d.realizationStatus) continue;
    console.log(`${apply ? '+' : '?'} ${requestId}: realizationStatus ← pending`);
    if (apply) await ref.update({ realizationStatus: 'pending' });
    changed++;
  }

  const approved = await db.collection('requests').where('realizationStatus', '==', 'approved').get();
  for (const r of approved.docs) {
    const d = r.data();
    if (d.status !== 'closed' || d.closedReason) continue;
    console.log(`${apply ? '+' : '?'} ${r.id}: closedReason ← realized`);
    if (apply) await r.ref.update({ closedReason: 'realized' });
    changed++;
  }

  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
