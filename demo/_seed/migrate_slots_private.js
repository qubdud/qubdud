// Prywatność slotów: obcy czyta tylko sloty z bookedBy '' (wolne) albo swoje,
// a apka pyta where('bookedBy', 'in', ['', uid]) — slot bez pola bookedBy zniknąłby
// klientom. Ustawia bookedBy '' tam, gdzie go nie ma, i usuwa bookedByName
// (imię i nazwisko klienta firma bierze teraz z jego profilu).
// Stare 'rejected' (APK ≤1.3.2) zwalnia jak migrate_rejected_slots.js — inaczej
// z bookedBy odrzuconego klienta byłyby niewidoczne dla innych.
// Trigger slotów nie wysyła przy tym powiadomień (status i bookedBy rezerwacji bez zmian,
// przejście z 'rejected' nie jest zwolnieniem rezerwacji).
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_slots_private.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');
const sign = apply ? '+' : '?';

(async () => {
  const snap = await db.collectionGroup('slots').get();
  const writer = db.bulkWriter();
  let changed = 0;
  for (const d of snap.docs) {
    const s = d.data();
    const patch = {};
    if (s.status === 'rejected') {
      Object.assign(patch, { status: 'free', bookedBy: '', releasedBy: 'rejected' });
    } else if (typeof s.bookedBy !== 'string') {
      patch.bookedBy = '';
    }
    if ('bookedByName' in s) patch.bookedByName = FieldValue.delete();
    if (!Object.keys(patch).length) continue;
    console.log(`${sign} ${d.ref.path} ${Object.keys(patch).join(', ')}`);
    if (apply) writer.update(d.ref, patch);
    changed++;
  }
  await writer.close();
  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed} z ${snap.size} slotów`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
