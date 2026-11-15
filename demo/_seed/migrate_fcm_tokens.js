// Tokeny FCM: users/{uid}.fcmTokens → users/{uid}/private/push (czyta tylko właściciel; jawny
// profil czyta każde zalogowane konto, a cudzy token dopisany u siebie zabierał ofierze pushe).
// Kopiuje (arrayUnion) najnowsze tokeny i usuwa stare pole. Token z kilku kont (wylogowanie
// offline) albo zapisany już przez nową apkę w private/push innego konta nie jest kopiowany:
// telefon należy do tamtego konta albo nie wiadomo do którego, a apka przy starcie i tak
// zapisze bieżący token zalogowanemu kontu.
//
// Wdrożyć najpierw funkcje (pushTo czyta oba miejsca), reguły i indeks private.fcmTokens.
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_fcm_tokens.js --apply
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');
const sign = apply ? '+' : '?';
// reguły przyjmują najwyżej 20; arrayUnion dopisuje na końcu, starsze to zwykle martwe po reinstalacji
const KEEP = 10;

const valid = (d) => {
  const t = d.get('fcmTokens');
  return [...new Set(Array.isArray(t) ? t.filter((x) => typeof x === 'string' && x) : [])];
};

(async () => {
  const users = (await db.collection('users').get()).docs.filter((d) => d.get('fcmTokens') !== undefined);
  const legacyHolders = new Map();
  for (const d of users) valid(d).forEach((t) => legacyHolders.set(t, (legacyHolders.get(t) || 0) + 1));

  let moved = 0;
  let skipped = 0;
  for (const d of users) {
    const push = d.ref.collection('private').doc('push');
    const own = [];
    for (const t of valid(d)) {
      if (legacyHolders.get(t) > 1) continue;
      const taken = await db.collectionGroup('private').where('fcmTokens', 'array-contains', t).get();
      if (taken.docs.some((p) => p.ref.path !== push.path)) continue;
      own.push(t);
    }
    const tokens = own.slice(-KEEP);
    const left = valid(d).length - tokens.length;
    skipped += left;
    console.log(`${sign} ${d.ref.path}: ${tokens.length} → private/push${left ? `, pominięte ${left}` : ''}`);
    if (apply) {
      const batch = db.batch();
      if (tokens.length) batch.set(push, { fcmTokens: FieldValue.arrayUnion(...tokens) }, { merge: true });
      batch.update(d.ref, { fcmTokens: FieldValue.delete() });
      await batch.commit();
    }
    moved += tokens.length;
  }
  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: kont ${users.length}, `
    + `tokenów ${moved}, pominiętych ${skipped}`);
  if (!apply) console.log('Uruchom z --apply, żeby zapisać.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
