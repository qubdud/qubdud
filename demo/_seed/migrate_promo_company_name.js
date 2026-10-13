// Uzupełnienie nazwy firmy w prezentacjach: promos/{id}.companyName (QB-50).
// Apka zapisuje companyName przy dodawaniu prezentacji; dla starych PromoTile
// dociąga nazwę z users (fallback oznaczony
// `// EXPIRES: … migrate_promo_company_name.js` w lib/shared/widgets/promo_tile.dart).
// Po migracji: usunąć ten fallback.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_promo_company_name.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

(async () => {
  const snap = await db.collection('promos').get();
  const names = new Map();
  let changed = 0;
  let skipped = 0;
  for (const d of snap.docs) {
    const p = d.data();
    if ((p.companyName || '').trim()) continue;
    if (!p.userId) {
      skipped++;
      console.log(`- ${d.id}: brak userId`);
      continue;
    }
    if (!names.has(p.userId)) {
      const u = await db.collection('users').doc(p.userId).get();
      names.set(p.userId, u.exists ? (u.data().companyName || '').trim() : '');
    }
    const companyName = names.get(p.userId);
    if (!companyName) {
      skipped++;
      console.log(`- ${d.id}: firma ${p.userId} bez companyName`);
      continue;
    }
    console.log(`${apply ? '+' : '?'} ${d.id}: companyName ← "${companyName}"`);
    if (apply) await d.ref.update({ companyName });
    changed++;
  }

  console.log(
    `${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed}, pominięto: ${skipped}, ` +
      `prezentacji: ${snap.size}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
