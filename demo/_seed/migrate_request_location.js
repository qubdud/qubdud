// Dokładne miejsce zgłoszeń → requests/{id}/private/location (klient i firma z przyjętą ofertą),
// w requests/{id}.location zostaje okolica na siatce 0,01° (jak approxLocation w apce
// i funkcja hideRequestLocation dla nowych zgłoszeń ze starszych APK).
// Nie nadpisuje private/location zapisanego już przez nową apkę.
// Zgłoszeń w realizacji (status 'taken') nie zaokrągla: firma je zna, a APK ≤1.4.0+22
// stawia pinezkę na requests.location i pojechałaby pod zły adres.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_request_location.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');
const sign = apply ? '+' : '?';
const approx = (v) => Math.round(v * 100) / 100;

(async () => {
  let moved = 0;
  let rounded = 0;
  for (const d of (await db.collection('requests').get()).docs) {
    const l = d.get('location');
    if (!l || typeof l.lat !== 'number' || typeof l.lng !== 'number') continue;
    const priv = d.ref.collection('private').doc('location');
    const near = { lat: approx(l.lat), lng: approx(l.lng) };
    const exists = (await priv.get()).exists;
    const changed = d.get('status') !== 'taken' && (near.lat !== l.lat || near.lng !== l.lng);
    if (exists && !changed) continue;
    console.log(`${sign} ${d.ref.path}${exists ? '' : ' → private/location'}${changed ? ', location zaokrąglone' : ''}`);
    if (apply) {
      await db.runTransaction(async (tx) => {
        const [cur, p] = await Promise.all([tx.get(d.ref), tx.get(priv)]);
        const c = cur.get('location');
        if (!c || typeof c.lat !== 'number') return;
        if (!p.exists) tx.set(priv, { lat: c.lat, lng: c.lng });
        if (cur.get('status') !== 'taken') tx.update(d.ref, { location: { lat: approx(c.lat), lng: approx(c.lng) } });
      });
    }
    if (!exists) moved++;
    if (changed) rounded++;
  }
  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: private/location ${moved}, zaokrąglone ${rounded}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
