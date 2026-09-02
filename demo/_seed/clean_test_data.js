// Porządkowanie testowych treści (śmieciowe/wulgarne wpisy → sensowne).
const path = require('path'), fs = require('fs');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(path.join('..', fs.readdirSync('..').find(f => f.includes('adminsdk')))) });
const db = getFirestore();

const REQUESTS = {
  dkibb5gvb7cZtumLVwy5: 'Iskrzy gniazdko w kuchni i czuć spaleniznę. Proszę o szybki kontakt.',
  tPT4Lw2QBWV0mmFbSNGB: 'Wymiana starej rozdzielni na nową z zabezpieczeniami różnicowoprądowymi.',
};
const REQUEST_REGEX = [[/zepsu/i, 'Po burzy nie działa światło w połowie mieszkania, bezpieczniki wybijają.']];
const REVIEWS = {
  '5LYeI5eol8KPC5WN9Yia': 'Długo czekałem na termin, ale sama usługa w porządku.',
  '8KcrJjHQJKP89Qf2HZ0m': 'Solidnie, choć trochę drożej niż zakładałem.',
  HZmAGlSNEzsH73U7vTBN: 'Szybko i sprawnie, polecam.',
  QdCWs8HZPBTCPepV6yF3: 'Punktualnie, czysto, wszystko działa. Polecam!',
  b5OoCHqaEeEqHdh2C0He: 'Dobra robota, kontakt bez problemu.',
  h5R6k7f7RSNMQczdQST0: 'Usługa wykonana, ale bez szału.',
  ibYv1TwKNWnByxQO3YIc: 'Termin przesunięty dwa razy, nie polecam.',
  y9ZNbWv8wTGwhOtxXzDw: 'Wycena trochę niejasna, ale naprawa działa.',
  yuWkLevihINIaxHtzR1h: 'Fachowo i na czas.',
};
const COMMENTS = {
  a1KDPDzGMBXzwGXuG1on: 'Dziękuję za opinię, zapraszam ponownie.',
  z1NxQytdSXdP1ST0emcC: 'Dziękujemy za wizytę, do zobaczenia!',
  w1KisrJm40KQq4jdEiA0: 'Dziękuję, cieszę się, że wszystko działa.',
};
const NOTES = {
  'dZesVJR4eONA9zsvML97gPYFqEd2/SMkoRjpzsKMwrThbqd5oY13NA6l2': 'Klient wymagający, dzwonić przed przyjazdem.',
  'dZesVJR4eONA9zsvML97gPYFqEd2/dZesVJR4eONA9zsvML97gPYFqEd2': null, // notatka o samym sobie
  'dZesVJR4eONA9zsvML97gPYFqEd2/zLz7WNbpheWcnFB7QrjqZxEi2Ls2': 'Stały klient, rabat 10%.',
};
const USERS = {
  SMkoRjpzsKMwrThbqd5oY13NA6l2: ['Natalia', 'Borkowska'],
  ZPChVhqR9DgTcD2jtFl5AX6jffz2: ['Ksawery', 'Nowicki'],
  nXZC3kRnvIgPLR3N2g3IIYmKPeW2: ['Krzysztof', 'Kowal'],
};
const MESSAGES = {
  '6d3z9DqjmaUxnQ4HCQt6Gl0e5X42_SMkoRjpzsKMwrThbqd5oY13NA6l2/vc650Ws1e8xa1NzqtB54': 'Dzień dobry, czy mogę prosić o wycenę montażu gniazdek?',
  'QmDWzmptSdfxRx6CRCYisT9LVwt1_zLz7WNbpheWcnFB7QrjqZxEi2Ls2/f6vvav2OKKzfgpl5yGB1': 'Dzień dobry, kiedy mogliby Państwo przyjechać?',
  'SMkoRjpzsKMwrThbqd5oY13NA6l2_dZesVJR4eONA9zsvML97gPYFqEd2/aBn7JSb4cyjcyNNBNSLA': 'Dziękuję za szybką naprawę!',
  'dZesVJR4eONA9zsvML97gPYFqEd2_zLz7WNbpheWcnFB7QrjqZxEi2Ls2/85HhKUL1nokTZxDwWRLq': 'Czy termin w piątek jest nadal aktualny?',
};
const DELETE_CHATS = ['6d3z9DqjmaUxnQ4HCQt6Gl0e5X42_6d3z9DqjmaUxnQ4HCQt6Gl0e5X42']; // rozmowa z samym sobą

(async () => {
  let n = 0;
  for (const [id, t] of Object.entries(REQUESTS)) { await db.collection('requests').doc(id).update({ description: t }); n++; }
  for (const d of (await db.collection('requests').get()).docs) {
    const t = d.data().description || '';
    for (const [re, nt] of REQUEST_REGEX) if (re.test(t)) { await d.ref.update({ description: nt }); n++; console.log('request regex:', d.id); }
  }
  for (const [id, t] of Object.entries(REVIEWS)) { await db.collection('reviews').doc(id).update({ description: t }); n++; }
  for (const r of (await db.collection('reviews').get()).docs) {
    for (const c of (await r.ref.collection('comments').get()).docs) {
      if (COMMENTS[c.id]) { await c.ref.update({ text: COMMENTS[c.id] }); n++; }
    }
  }
  for (const [p, t] of Object.entries(NOTES)) {
    const [uid, cid] = p.split('/');
    const ref = db.collection('users').doc(uid).collection('clientNotes').doc(cid);
    if (t === null) await ref.delete(); else await ref.update({ note: t });
    n++;
  }
  for (const [uid, [first, last]] of Object.entries(USERS)) {
    await db.collection('users').doc(uid).update({ firstName: first, lastName: last });
    const full = `${first} ${last}`;
    for (const c of (await db.collection('chats').where('participants', 'array-contains', uid).get()).docs) {
      await c.ref.update({ [`names.${uid}`]: full });
    }
    for (const u of (await db.collection('users').get()).docs) {
      const cl = u.ref.collection('clients').doc(uid);
      if ((await cl.get()).exists) await cl.update({ name: full });
    }
    for (const r of (await db.collection('reviews').where('userId', '==', uid).get()).docs) {
      if (r.data().authorName) await r.ref.update({ authorName: full });
    }
    n++;
  }
  for (const [p, t] of Object.entries(MESSAGES)) {
    const [chat, mid] = p.split('/');
    await db.collection('chats').doc(chat).collection('messages').doc(mid).update({ content: t });
    await db.collection('chats').doc(chat).update({ lastMessage: t });
    n++;
  }
  for (const id of DELETE_CHATS) {
    const ref = db.collection('chats').doc(id);
    for (const m of (await ref.collection('messages').get()).docs) await m.ref.delete();
    await ref.delete(); n++;
  }
  console.log('poprawionych wpisów:', n);
  process.exit(0);
})();
