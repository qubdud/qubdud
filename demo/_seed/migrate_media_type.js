// Migracja typu pliku zgłoszeń: requests/{id}.mediaType = 'image' | 'video' (QB-44).
// Apka zapisuje mediaType przy uploadzie; stare zgłoszenia rozpoznaje jeszcze
// po rozszerzeniu fileName (fallback oznaczony `// EXPIRES: … migrate_media_type.js`
// w lib/domain_layer/domain_models/promoVideo.dart). Po migracji: usunąć ten fallback.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_media_type.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');

// ta sama reguła co w apce (_mediaTypeFromName)
const mediaTypeFromName = (name) =>
  /\.(mp4|mov|m4v|3gp|webm|mkv)$/i.test(name || '') ? 'video' : 'image';

(async () => {
  const snap = await db.collection('requests').get();
  let batch = db.batch();
  let inBatch = 0;
  let changed = 0;
  for (const d of snap.docs) {
    const r = d.data();
    if (['image', 'video', 'none'].includes(r.mediaType)) continue;
    const mediaType = mediaTypeFromName(r.fileName);
    console.log(`${apply ? '+' : '?'} ${d.id}: ${r.fileName || '(brak fileName)'} → ${mediaType}`);
    changed++;
    if (!apply) continue;
    batch.update(d.ref, { mediaType });
    if (++inBatch === 400) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }
  if (apply && inBatch > 0) await batch.commit();

  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: ${changed} z ${snap.size} zgłoszeń`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
