// Usuwa STARE błędne demo-firmy (demo.*@qubdud-demo.pl poza demo.user1-3)
// wraz z users doc + subkolekcjami (slots/clients) i WSZYSTKIE promos demo:true.
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const DEMO_DIR = path.resolve(__dirname, '..');
const keyFile = fs.readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
initializeApp({ credential: cert(path.join(DEMO_DIR, keyFile)) });
const db = getFirestore();
const auth = getAuth();

const KEEP = new Set([
  'demo.user1@qubdud-demo.pl',
  'demo.user2@qubdud-demo.pl',
  'demo.user3@qubdud-demo.pl',
]);

async function deleteSubcollection(uid, name) {
  const snap = await db.collection('users').doc(uid).collection(name).get();
  if (snap.empty) return 0;
  const batch = db.batch();
  snap.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  return snap.size;
}

(async () => {
  // 1. firmy demo.* → out
  let pageToken;
  const toDelete = [];
  do {
    const res = await auth.listUsers(1000, pageToken);
    for (const u of res.users) {
      const email = u.email || '';
      if (email.endsWith('@qubdud-demo.pl') && !KEEP.has(email)) {
        toDelete.push({ uid: u.uid, email });
      }
    }
    pageToken = res.pageToken;
  } while (pageToken);

  console.log(`Do usunięcia firm: ${toDelete.length}`);
  for (const { uid, email } of toDelete) {
    for (const sub of ['slots', 'clients', 'myBookings', 'contacts',
        'favoritePromos', 'skippedRequests', 'myCompanies']) {
      await deleteSubcollection(uid, sub);
    }
    await db.collection('users').doc(uid).delete();
    await auth.deleteUser(uid);
    console.log(`- ${email}`);
  }

  // 2. wszystkie promos demo:true
  const promos = await db.collection('promos').where('demo', '==', true).get();
  console.log(`Promos do usunięcia: ${promos.size}`);
  let batch = db.batch();
  let n = 0;
  for (const d of promos.docs) {
    batch.delete(d.ref);
    if (++n % 400 === 0) { await batch.commit(); batch = db.batch(); }
  }
  await batch.commit();

  // 3. myBookings userów demo (wskazują na skasowane firmy)
  for (const email of KEEP) {
    try {
      const uid = (await auth.getUserByEmail(email)).uid;
      const removed = await deleteSubcollection(uid, 'myBookings');
      if (removed) console.log(`~ wyczyszczono myBookings ${email}: ${removed}`);
    } catch (_) {}
  }

  console.log('Cleanup gotowy.');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
