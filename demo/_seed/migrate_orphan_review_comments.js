// Komentarze usuniętych opinii (reviews/{id}/comments bez dokumentu opinii).
// Od teraz sprząta je cleanupDeletedReview; stare zostały i pokazałyby się pod nową
// opinią tej samej osoby o tej samej firmie (to samo id {autor}_{firma}).
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_orphan_review_comments.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  const exists = new Map();
  let changed = 0;
  for (const c of (await db.collectionGroup('comments').get()).docs) {
    const review = c.ref.parent.parent;
    if (!review || review.parent.id !== 'reviews') continue;
    if (!exists.has(review.id)) exists.set(review.id, (await review.get()).exists);
    if (exists.get(review.id)) continue;
    console.log(`${apply ? '-' : '?'} ${c.ref.path}`);
    if (apply) await c.ref.delete();
    changed++;
  }
  console.log(`${apply ? 'Usunięto' : 'Do usunięcia (dry-run)'}: ${changed}`);
  if (!apply) console.log('Uruchom z --apply, żeby usunąć.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
