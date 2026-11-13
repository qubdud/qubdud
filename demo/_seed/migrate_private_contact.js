// Telefon i e-mail → users/{uid}/private/contact (RODO). users/{uid} czyta każde zalogowane
// konto; private/contact tylko właściciel i firma z relacją users/{firma}/clients/{klient}.
//  1) kopiuje e-mail (każde konto) i telefon (klient; telefon firmy jest jawny) do private/contact,
//     nie nadpisując wartości zapisanej już przez nową apkę,
//  2) dopisuje brakujące relacje klient↔firma z przyjętych ofert,
//  3) audytuje istniejące relacje (mogły być sfałszowane przed 2026-10-13); --prune usuwa
//     te bez przyjętej oferty ani rezerwacji klienta,
//  --strip: w users/{uid} email → '' (każde konto), phone → '' (klient). Klucze zostają —
//     APK ≤1.3.x robi `email!` na stronie zgłoszenia.
// Zapisy do users/{uid} uruchamiają syncPrivateContact i onUserUpdated — przy pustych polach bez skutków.
//
// Domyślnie tylko podgląd (dry-run). Zapis: node migrate_private_contact.js --apply --strip --prune
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp({
  credential: cert(path.join(__dirname, '..', 'qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json')),
});
const db = getFirestore();
const apply = process.argv.includes('--apply');
const strip = process.argv.includes('--strip');
const sign = apply ? '+' : '?';
const isCompany = (u) => u.firma === true || u.isCompany === true;

(async () => {
  const users = new Map((await db.collection('users').get()).docs.map((d) => [d.id, d.data()]));

  // ── 1) i 3) private/contact, czyszczenie jawnych pól ──
  let copied = 0;
  let stripped = 0;
  for (const [uid, u] of users) {
    const ref = db.collection('users').doc(uid);
    const contactRef = ref.collection('private').doc('contact');
    const saved = (await contactRef.get()).data() || {};
    const fields = isCompany(u) ? ['email'] : ['email', 'phone'];
    const copy = Object.fromEntries(fields
      .filter((k) => typeof u[k] === 'string' && u[k] && !saved[k]).map((k) => [k, u[k]]));
    if (Object.keys(copy).length) {
      console.log(`${sign} ${contactRef.path} ← ${Object.keys(copy).join(', ')}`);
      if (apply) await contactRef.set(copy, { merge: true });
      copied++;
    }
    const clear = Object.fromEntries(fields.filter((k) => u[k]).map((k) => [k, '']));
    if (strip && Object.keys(clear).length) {
      console.log(`${sign} users/${uid}: ${Object.keys(clear).join(', ')} → ''`);
      if (apply) await ref.update(clear);
      stripped++;
    }
  }

  // ── 2) brakujące relacje z przyjętych ofert (tylko źródła, których firma nie podrobi:
  //       takenBy ustawia klient razem z offers/{firma}.status == 'accepted') ──
  let linked = 0;
  for (const d of (await db.collection('requests').get()).docs) {
    const r = d.data();
    const companyId = r.takenBy;
    if (!companyId || companyId === r.userId || !users.has(companyId) || !users.has(r.userId)) continue;
    const offer = (await d.ref.collection('offers').doc(companyId).get()).data();
    if (!offer || offer.status !== 'accepted') continue;
    const client = users.get(r.userId);
    const sides = [
      [db.doc(`users/${companyId}/clients/${r.userId}`),
        { userId: r.userId, name: `${client.firstName || ''} ${client.lastName || ''}`.trim() }],
      [db.doc(`users/${r.userId}/myCompanies/${companyId}`),
        { companyId, name: users.get(companyId).companyName || 'Firma' }],
    ];
    for (const [ref, base] of sides) {
      const snap = await ref.get();
      const rel = snap.data() || {};
      // EXPIRES (pole requestId): po migrate_relation_request_id.js --apply
      if ((rel.requestIds || []).includes(d.id) || rel.requestId === d.id) continue;
      console.log(`${sign} ${ref.path}${snap.exists ? '' : ' (nowa)'}: zgłoszenie ${d.id}`);
      if (apply) {
        const at = r.takenAt || r.timestamp || FieldValue.serverTimestamp();
        await ref.set({
          ...(!snap.exists && { ...base, addedAt: at, lastAt: at }),
          requestIds: FieldValue.arrayUnion(d.id),
        }, { merge: true });
      }
      linked++;
    }
  }

  // ── 3) audyt istniejących relacji: do 2026-10-13 reguły pozwalały zapisać je każdemu
  //       zalogowanemu, a od relacji zależy dostęp firmy do private/contact.
  //       Źródło musi być prawdziwe: przyjęta oferta albo rezerwacja z kopią klienta
  //       (myBookings z bookedAt — to pole zapisuje wyłącznie klient). --prune usuwa resztę. ──
  const prune = process.argv.includes('--prune');
  let suspicious = 0;
  const reqCache = new Map();
  const requestOk = async (companyId, clientId, id) => {
    const key = `${companyId}|${id}`;
    if (!reqCache.has(key)) {
      const ref = db.collection('requests').doc(id);
      const [r, o] = await Promise.all([ref.get(), ref.collection('offers').doc(companyId).get()]);
      const rd = r.data();
      reqCache.set(key, !!rd && rd.userId === clientId && rd.takenBy === companyId
        && (o.data() || {}).status === 'accepted');
    }
    return reqCache.get(key);
  };
  const slotOk = async (companyId, clientId, slotId) => {
    const b = (await db.doc(`users/${clientId}/myBookings/${companyId}_${slotId}`).get()).data();
    return !!b && !!b.bookedAt && ['pending', 'accepted'].includes(b.status);
  };
  for (const c of (await db.collectionGroup('clients').get()).docs) {
    const companyId = c.ref.parent.parent.id;
    const clientId = c.id;
    const d = c.data();
    const legacy = d.requestId || '';
    const reqIds = [...(d.requestIds || []), ...(legacy && !legacy.startsWith('slot_') ? [legacy] : [])];
    const slotIds = [...(d.slotIds || []), ...(legacy.startsWith('slot_') ? [legacy.slice(5)] : [])];
    const goodReq = [];
    for (const id of reqIds) if (await requestOk(companyId, clientId, id)) goodReq.push(id);
    const goodSlot = [];
    for (const id of slotIds) if (await slotOk(companyId, clientId, id)) goodSlot.push(id);
    const bad = reqIds.length + slotIds.length - goodReq.length - goodSlot.length;
    if (!bad) continue;
    suspicious++;
    const mirror = db.doc(`users/${clientId}/myCompanies/${companyId}`);
    const none = !goodReq.length && !goodSlot.length;
    console.log(`! ${c.ref.path}: ${bad} źródeł bez potwierdzenia`
      + (none ? (d.contactRequestId ? ' (zostaje prośba o kontakt)' : ' → do usunięcia') : ''));
    if (!(apply && prune)) continue;
    if (none && !d.contactRequestId) {
      await Promise.all([c.ref.delete(), mirror.delete()]);
    } else {
      const fix = { requestIds: goodReq, slotIds: goodSlot, requestId: FieldValue.delete() };
      await Promise.all([c.ref.set(fix, { merge: true }), mirror.set(fix, { merge: true })]);
    }
  }

  console.log(`${apply ? 'Zapisano' : 'Do zapisania (dry-run)'}: private/contact ${copied}, `
    + `relacje ${linked}${strip ? `, wyczyszczone profile ${stripped}` : ''}`
    + `, podejrzane relacje ${suspicious}${apply && prune ? ' (poprawione)' : ''}`);
  if (!apply) console.log('Uruchom z --apply --strip --prune, żeby zapisać, wyczyścić jawne pola i usunąć podejrzane relacje.');
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
