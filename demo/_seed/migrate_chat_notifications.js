// Migracja dzwonka: stare wpisy czatu (jeden na wiadomość, losowe id) → jeden wpis na rozmowę
// notifications/chat_{odbiorca}_{nadawca} (format notifyNewMessage od QB-10).
// Domyślnie --dry-run (tylko raport). Zapis: node migrate_chat_notifications.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({ credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')) });
const db = getFirestore();
const APPLY = process.argv.includes('--apply');
const BATCH_MAX = 400;
const ms = (t) => (t && t.toMillis ? t.toMillis() : 0);

(async () => {
  const snap = await db.collection('notifications').where('type', '==', 'chat').get();
  const groups = new Map();
  let skipped = 0;
  for (const d of snap.docs) {
    if (d.id.startsWith('chat_')) continue;
    const n = d.data();
    if (!n.userId || !n.from) { skipped++; continue; }
    const key = `chat_${n.userId}_${n.from}`;
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(d);
  }

  const ops = [];
  let merged = 0;
  for (const [id, docs] of groups) {
    const latest = docs.reduce((a, b) => (ms(b.data().createdAt) > ms(a.data().createdAt) ? b : a)).data();
    const target = await db.collection('notifications').doc(id).get();
    // wpis w nowym formacie (po wdrożeniu funkcji) jest nowszy — zostaje bez zmian
    if (!target.exists || ms(target.data().createdAt) < ms(latest.createdAt)) {
      ops.push((b) => b.set(db.collection('notifications').doc(id), {
        userId: latest.userId,
        type: 'chat',
        from: latest.from,
        title: latest.title || '',
        body: latest.body || '',
        audience: latest.audience || 'both',
        requestId: '',
        companyId: '',
        read: docs.every((d) => d.data().read === true),
        createdAt: latest.createdAt,
      }, { merge: true }));
      merged++;
    }
    for (const d of docs) ops.push((b) => b.delete(d.ref));
  }

  const old = [...groups.values()].reduce((s, g) => s + g.length, 0);
  console.log(`starych wpisów czatu: ${old} w ${groups.size} rozmowach; do zapisu: ${merged}; bez userId/from (pominięte): ${skipped}`);
  if (!APPLY) {
    console.log('DRY-RUN — nic nie zapisano. Uruchom z --apply, aby wykonać.');
    return;
  }
  for (let i = 0; i < ops.length; i += BATCH_MAX) {
    const batch = db.batch();
    ops.slice(i, i + BATCH_MAX).forEach((op) => op(batch));
    await batch.commit();
  }
  console.log(`zapisano ${merged} wpisów, usunięto ${old} starych`);
})().catch((e) => { console.error(e); process.exitCode = 1; });
