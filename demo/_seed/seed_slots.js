// Dodaje demo-sloty kalendarza firmom (7 dni do przodu). Idempotentny.
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

const DEMO_DIR = path.resolve(__dirname, '..');
const keyFile = fs
  .readdirSync(DEMO_DIR)
  .find((f) => f.includes('firebase-adminsdk') && f.endsWith('.json'));
initializeApp({ credential: cert(path.join(DEMO_DIR, keyFile)) });
const db = getFirestore();
const auth = getAuth();

const companies = require('./companies.json');
const HOURS = [9, 11, 13, 15, 17];

(async () => {
  for (const c of companies) {
    const email = `demo.${c.prefix}@qubdud-demo.pl`;
    let uid;
    try {
      uid = (await auth.getUserByEmail(email)).uid;
    } catch (_) {
      continue;
    }
    const slotsCol = db.collection('users').doc(uid).collection('slots');
    const existing = await slotsCol
      .where('start', '>', Timestamp.now())
      .limit(1)
      .get();
    if (!existing.empty) {
      console.log(`~ ${c.prefix}: sloty już są`);
      continue;
    }
    const batch = db.batch();
    let count = 0;
    const today = new Date();
    for (let d = 1; d <= 7; d++) {
      // 2-3 sloty dziennie, różne godziny per firma/dzień
      const picks = HOURS.filter((h, i) => (d + i + c.prefix.length) % 2 === 0);
      for (const h of picks.slice(0, 3)) {
        const dt = new Date(
          today.getFullYear(), today.getMonth(), today.getDate() + d, h, 0);
        batch.set(slotsCol.doc(), { start: Timestamp.fromDate(dt), bookedBy: '' });
        count++;
      }
    }
    await batch.commit();
    console.log(`+ ${c.prefix}: ${count} slotów`);
  }
  console.log('Gotowe.');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
