// Migracja slotów ze statusem 'rejected' (QB-42). Odrzucenie rezerwacji zwalnia
// dziś termin (status 'free', releasedBy: 'rejected'), a 'rejected' zostaje tylko
// w users/{klient}/myBookings. Stare odrzucone sloty blokują termin innym klientom
// i apka już ich nie rozpoznaje — zwalniamy je tak samo.
// Trigger slotów nie wysyła przy tym powiadomień (przejście z 'rejected',
// a powiadomienia idą tylko przy zwolnieniu z pending/accepted).
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_rejected_slots.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  const users = await db.collection('users').listDocuments();
  let found = 0;
  for (const u of users) {
    const snap = await u.collection('slots').where('status', '==', 'rejected').get();
    for (const d of snap.docs) {
      const s = d.data();
      const when = s.start && s.start.toDate ? s.start.toDate().toISOString() : '?';
      console.log(`${apply ? '+' : '?'} users/${u.id}/slots/${d.id} ${when} klient=${s.bookedBy || '—'}`);
      if (apply) {
        await d.ref.update({
          status: 'free',
          bookedBy: '',
          bookedByName: '',
          releasedBy: 'rejected',
        });
      }
      found++;
    }
  }
  console.log(`${apply ? 'Zwolniono' : 'Do zwolnienia (dry-run)'}: ${found} slotów, firm sprawdzonych: ${users.length}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
