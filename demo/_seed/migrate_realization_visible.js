// Pole visible w realizacjach: reguły pokazują osobom postronnym tylko visible == true,
// a galeria profilu firmy i zgłoszenia pytają where('visible', true).
// visible = zdjęcia firmy potwierdzone przez klienta (stare bez status = potwierdzone)
// albo zdjęcia klienta opublikowane przez firmę. Bez migracji stare zdjęcia znikną z profili.
// Zapis do realizations nie uruchamia powiadomień (notifyRealizationDecision patrzy na status).
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_realization_visible.js --apply
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
  for (const d of (await db.collection('realizations').get()).docs) {
    const r = d.data();
    const visible = r.addedByRole === 'user'
      ? r.publishedByCompany === true
      : (r.status || 'approved') === 'approved';
    if (r.visible === visible) continue;
    console.log(`${apply ? '+' : '?'} ${d.id}: visible ← ${visible}`);
    if (apply) await d.ref.update({ visible });
    changed++;
  }
  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
