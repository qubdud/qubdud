// Scenariusz strony gościa na emulatorach (auth + firestore [+ storage]) z regułami z repo.
// Uruchamiaj przez: npm test (albo npm run test:bez-storage). Moduły danych są te same co w UI.
import assert from 'node:assert/strict';
import {
  isSignInWithEmailLink,
  sendSignInLinkToEmail,
  signInAnonymously,
  signInWithEmailLink,
} from 'firebase/auth';
import {
  arrayRemove,
  collection,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import { AUTH, PROJECT, RUN, STORAGE, closeAll, makeCtx, ownerSet, registerInApp } from './helpers.mjs';

import { UserError } from '../src/data/ctx.ts';
import { createGuestProfile, loadMyProfile } from '../src/data/profile.ts';
import {
  createRequest,
  listOffers,
  setOfferStatus,
  setRealizationStatus,
  uploadRequestMedia,
  watchMyRequests,
  watchOffers,
} from '../src/data/requests.ts';
import { bookSlot, cancelSlotBooking, slotsFromDocs, slotsQuery, watchMyBookings } from '../src/data/slots.ts';
import { markChatRead, sendMessage, watchChats, watchMessages } from '../src/data/chat.ts';
import {
  getCompany,
  getCompanyPromos,
  getCompanyRealizations,
  getCompanyReviews,
  getCompletedJobsCount,
} from '../src/data/company.ts';

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Uruchom przez npm test (firebase emulators:exec) — brak FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST');
  process.exit(2);
}

let passed = 0;
async function step(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  ok  ${name}`);
  } catch (e) {
    console.error(`  BŁĄD  ${name}`);
    throw e;
  }
}

const denied = (p) => assert.rejects(p, (e) => e?.code === 'permission-denied', 'oczekiwano permission-denied');

/** Pierwszy stan z nasłuchu spełniający warunek. */
function waitFor(subscribe, pred, label, ms = 10000) {
  return new Promise((resolve, reject) => {
    let unsub = () => {};
    const timer = setTimeout(() => {
      unsub();
      reject(new Error(`Timeout: ${label}`));
    }, ms);
    unsub = subscribe(
      (v) => {
        if (pred(v)) {
          clearTimeout(timer);
          setTimeout(() => unsub(), 0);
          resolve(v);
        }
      },
      (e) => {
        clearTimeout(timer);
        reject(e);
      },
    );
  });
}

async function main() {
  console.log(`Projekt ${PROJECT}, storage: ${STORAGE ? 'tak' : 'nie (pomijam wysyłkę zdjęć)'}`);
  const firma = makeCtx('firma');
  const firma2 = makeCtx('firma2');
  const ola = makeCtx('ola');
  const anon = makeCtx('anon');
  const guest = makeCtx('guest');

  let firmaUid, firma2Uid, olaUid, guestUid;
  const slotIds = {};
  const tomorrow = new Date(Date.now() + 24 * 3600e3);
  const at = (h) => new Date(tomorrow.getFullYear(), tomorrow.getMonth(), tomorrow.getDate(), h, 0);

  console.log('Dane startowe (apka)');
  await step('firma zakłada konto i profil firmowy', async () => {
    firmaUid = await registerInApp(firma, {
      email: `firma-${RUN}@test.qb`,
      firstName: 'Jan',
      lastName: 'Kowalski',
      phone: '500 600 700',
      company: { nip: '1234567890', name: 'Hydro-Test' },
    });
    firma2Uid = await registerInApp(firma2, {
      email: `firma2-${RUN}@test.qb`,
      firstName: 'Piotr',
      lastName: 'Zieliński',
      phone: '501 501 501',
      company: { nip: '0987654321', name: 'Rury-Express' },
    });
  });
  await step('firma dodaje prezentację i 3 terminy', async () => {
    await setDoc(doc(collection(firma.db, 'promos')), {
      userId: firmaUid,
      category: 'Budowlane i Remontowe',
      sector: 'Hydraulik',
      location: { lat: 52.2297, lng: 21.0122 },
      fileUrl: 'https://example.invalid/film.mp4',
      thumbUrl: 'https://example.invalid/film.jpg',
      fileName: 'film.mp4',
      timestamp: serverTimestamp(),
      description: '',
      companyName: 'Hydro-Test',
    });
    const b = writeBatch(firma.db);
    for (const [key, h] of [['s1', 10], ['s2', 11], ['s3', 12]]) {
      const ref = doc(collection(firma.db, 'users', firmaUid, 'slots'));
      slotIds[key] = ref.id;
      b.set(ref, { start: Timestamp.fromDate(at(h)), durationMin: 60, bookedBy: '' });
    }
    await b.commit();
  });
  await step('inny klient (apka) rezerwuje s3, wystawia opinię; firma komentuje', async () => {
    olaUid = await registerInApp(ola, {
      email: `ola-${RUN}@test.qb`,
      firstName: 'Ola',
      lastName: 'Wiśniewska',
      phone: '600 100 200',
    });
    await bookSlot(ola, firmaUid, slotIds.s3);
    const reviewId = `${olaUid}_${firmaUid}`;
    await setDoc(doc(ola.db, 'reviews', reviewId), {
      userId: olaUid,
      promoId: 'profile_review',
      authorName: 'Ola',
      reviewedUserId: firmaUid,
      score: 5,
      fileUrl: '',
      thumbUrl: '',
      fileName: '',
      timestamp: serverTimestamp(),
      description: 'Szybko i porządnie.',
    });
    await setDoc(doc(firma.db, 'reviews', reviewId, 'comments', firmaUid), {
      reviewId,
      authorId: firmaUid,
      authorName: 'Hydro-Test',
      isOwner: true,
      text: 'Dziękujemy!',
      timestamp: serverTimestamp(),
    });
    const base = {
      companyId: firmaUid,
      requestId: 'stare',
      userId: olaUid,
      category: 'Budowlane i Remontowe',
      addedByRole: 'company',
      publishedByCompany: false,
      timestamp: new Date(),
    };
    await ownerSet(`realizations/widoczna-${RUN}`, { ...base, imageUrl: 'https://example.invalid/po.jpg', status: 'approved', visible: true });
    await ownerSet(`realizations/ukryta-${RUN}`, { ...base, imageUrl: 'https://example.invalid/x.jpg', status: 'pending', visible: false });
  });

  console.log('Anonim przegląda wizytówkę');
  await signInAnonymously(anon.auth);
  await step('czyta profil firmy, prezentacje, opinie z komentarzem, realizacje i wolne terminy', async () => {
    const c = await getCompany(anon, firmaUid);
    assert.equal(c?.companyName, 'Hydro-Test');
    assert.equal((await getCompanyPromos(anon, firmaUid)).length, 1);
    const reviews = await getCompanyReviews(anon, firmaUid);
    assert.equal(reviews.length, 1);
    assert.equal(reviews[0].comments[0]?.text, 'Dziękujemy!');
    assert.equal((await getCompanyRealizations(anon, firmaUid)).length, 1);
    const slots = slotsFromDocs((await getDocs(slotsQuery(anon, firmaUid))).docs);
    assert.deepEqual(slots.map((s) => s.id).sort(), [slotIds.s1, slotIds.s2].sort());
  });
  await step('NIE czyta danych prywatnych ani zajętych terminów', async () => {
    assert.equal(await getCompany(anon, olaUid), null);
    await denied(getDoc(doc(anon.db, 'users', olaUid)));
    await denied(getDoc(doc(anon.db, 'users', olaUid, 'private', 'contact')));
    await denied(getDoc(doc(anon.db, 'users', firmaUid, 'private', 'contact')));
    await denied(getDoc(doc(anon.db, 'users', firmaUid, 'slots', slotIds.s3)));
    await denied(getDocs(collection(anon.db, 'users', firmaUid, 'slots')));
    await denied(getDocs(query(collection(anon.db, 'realizations'), where('companyId', '==', firmaUid))));
    await denied(getDoc(doc(anon.db, 'realizations', `ukryta-${RUN}`)));
    await denied(getDocs(query(collection(anon.db, 'users', firmaUid, 'clients'))));
    await denied(getCompletedJobsCount(anon, firmaUid));
  });
  await step('NIE zapisuje zgłoszenia ani rezerwacji', async () => {
    await denied(
      setDoc(doc(collection(anon.db, 'requests')), {
        userId: anon.auth.currentUser.uid,
        category: 'Budowlane i Remontowe',
        sector: 'Hydraulik',
        location: { lat: 52.23, lng: 21.01 },
        city: '',
        fileUrl: '',
        thumbUrl: '',
        fileName: '',
        mediaType: 'none',
        timestamp: serverTimestamp(),
        is24: false,
        description: 'Zgłoszenie anonima',
        status: 'open',
        takenBy: '',
        takenByName: '',
        confirmedByCompany: false,
        confirmedByUser: false,
      }),
    );
    await assert.rejects(bookSlot(anon, firmaUid, slotIds.s1), UserError);
  });

  console.log('Gość: logowanie linkiem z e-maila i profil');
  const guestEmail = `gosc-${RUN}@test.qb`;
  await step('przeglądanie anonimowe, potem link z e-maila → zwykłe konto (nowy uid)', async () => {
    const anonUid = (await signInAnonymously(guest.auth)).user.uid;
    await sendSignInLinkToEmail(guest.auth, guestEmail, { url: 'http://localhost:5173/zglos', handleCodeInApp: true });
    const res = await fetch(`http://${AUTH}/emulator/v1/projects/${PROJECT}/oobCodes`);
    const { oobCodes } = await res.json();
    const code = oobCodes.filter((c) => c.email === guestEmail && c.requestType === 'EMAIL_SIGNIN').pop();
    assert.ok(code?.oobLink, 'brak linku w emulatorze');
    assert.ok(isSignInWithEmailLink(guest.auth, code.oobLink));
    const cred = await signInWithEmailLink(guest.auth, guestEmail, code.oobLink);
    guestUid = cred.user.uid;
    assert.notEqual(guestUid, anonUid);
    assert.equal(cred.user.isAnonymous, false);
    const token = await cred.user.getIdTokenResult();
    assert.notEqual(token.signInProvider, 'anonymous');
  });
  await step('pierwsze logowanie: brak profilu → profil jak rejestracja w apce', async () => {
    assert.equal(await loadMyProfile(guest), null);
    await createGuestProfile(guest, { firstName: 'Anna', lastName: 'Nowak', phone: '600 700 800' });
    const p = await loadMyProfile(guest);
    assert.equal(p.email, '');
    assert.equal(p.phone, '');
    assert.equal(p.firma, false);
    assert.equal(p.consents.terms, true);
    const contact = (await getDoc(doc(guest.db, 'users', guestUid, 'private', 'contact'))).data();
    assert.deepEqual(contact, { email: guestEmail, phone: '600 700 800' });
    await denied(getDoc(doc(firma.db, 'users', guestUid, 'private', 'contact')));
  });

  console.log('Zgłoszenie → oferty → przyjęcie');
  let requestId;
  const exact = { lat: 52.229676, lng: 21.012229 };
  await step(`gość dodaje zgłoszenie${STORAGE ? ' ze zdjęciem' : ' bez zdjęcia'} (okolica + private/location)`, async () => {
    let media = null;
    if (STORAGE) {
      const jpg = new Blob([new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0, 16, 0x4a, 0x46, 0x49, 0x46, 0, 1, 0xff, 0xd9])], { type: 'image/jpeg' });
      media = await uploadRequestMedia(guest, jpg, jpg);
      assert.match(media.fileUrl, /files%2F/);
      assert.match(media.thumbUrl, /thumbs%2F/);
    }
    requestId = await createRequest(
      guest,
      {
        category: 'Budowlane i Remontowe',
        sector: 'Hydraulik',
        description: 'Cieknie syfon pod zlewem w kuchni',
        city: 'Warszawa',
        location: exact,
        is24: false,
        timing: 'week',
        budget: 500,
        answers: { 'Rodzaj obiektu': 'Mieszkanie', Zakres: '' },
      },
      media,
    );
    const r = (await getDoc(doc(guest.db, 'requests', requestId))).data();
    assert.deepEqual(r.location, { lat: 52.23, lng: 21.01 });
    assert.equal(r.mediaType, media ? 'image' : 'none');
    assert.deepEqual(r.answers, { 'Rodzaj obiektu': 'Mieszkanie' });
    assert.equal(r.budget, 500);
    const priv = (await getDoc(doc(guest.db, 'requests', requestId, 'private', 'location'))).data();
    assert.deepEqual(priv, exact);
    const mine = await waitFor((n, e) => watchMyRequests(guest, n, e), (l) => l.length === 1, 'moje zgłoszenia');
    assert.equal(mine[0].id, requestId);
  });
  await step('firma widzi zgłoszenie, ale nie dokładne miejsce; anonim nic', async () => {
    assert.equal((await getDoc(doc(firma.db, 'requests', requestId))).data().sector, 'Hydraulik');
    await denied(getDoc(doc(firma.db, 'requests', requestId, 'private', 'location')));
    await denied(getDoc(doc(anon.db, 'requests', requestId)));
    await denied(getDoc(doc(anon.db, 'requests', requestId, 'private', 'location')));
  });
  await step('dwie firmy składają oferty (apka), gość widzi je na żywo', async () => {
    const offer = (uid, name, price) => ({
      companyId: uid,
      companyName: name,
      message: `Oferta ${name}`,
      price,
      priceTo: price + 150,
      when: 'tomorrow',
      status: 'pending',
      timestamp: serverTimestamp(),
    });
    await setDoc(doc(firma.db, 'requests', requestId, 'offers', firmaUid), offer(firmaUid, 'Hydro-Test', 300));
    await setDoc(doc(firma2.db, 'requests', requestId, 'offers', firma2Uid), offer(firma2Uid, 'Rury-Express', 250));
    const live = await waitFor((n, e) => watchOffers(guest, requestId, n, e), (o) => o.length === 2, 'oferty');
    assert.deepEqual(live.map((o) => o.price).sort(), [250, 300]);
    await denied(getDoc(doc(firma2.db, 'requests', requestId, 'offers', firmaUid)));
  });
  await step('gość przyjmuje ofertę (setOfferStatus jak w apce)', async () => {
    await setOfferStatus(guest, { id: requestId, userId: guestUid }, firmaUid, 'Hydro-Test', 'accepted');
    const r = (await getDoc(doc(guest.db, 'requests', requestId))).data();
    assert.equal(r.status, 'taken');
    assert.equal(r.takenBy, firmaUid);
    assert.equal(r.takenByName, 'Hydro-Test');
    const offers = await listOffers(guest, requestId);
    assert.equal(offers.find((o) => o.companyId === firmaUid).status, 'accepted');
    assert.equal(offers.find((o) => o.companyId === firma2Uid).status, 'closed');
    const client = (await getDoc(doc(guest.db, 'users', firmaUid, 'clients', guestUid))).data();
    assert.deepEqual(client.requestIds, [requestId]);
    assert.equal(client.name, 'Anna Nowak');
    const myCompany = (await getDoc(doc(guest.db, 'users', guestUid, 'myCompanies', firmaUid))).data();
    assert.equal(myCompany.name, 'Hydro-Test');
  });
  await step('po przyjęciu firma widzi telefon klienta i dokładne miejsce, druga firma nie', async () => {
    const contact = (await getDoc(doc(firma.db, 'users', guestUid, 'private', 'contact'))).data();
    assert.equal(contact.phone, '600 700 800');
    assert.deepEqual((await getDoc(doc(firma.db, 'requests', requestId, 'private', 'location'))).data(), exact);
    await denied(getDoc(doc(firma2.db, 'users', guestUid, 'private', 'contact')));
    await denied(getDoc(doc(firma2.db, 'requests', requestId, 'private', 'location')));
  });
  await step('firma prosi o potwierdzenie bez zdjęć → gość „Jeszcze nie”', async () => {
    await updateDoc(doc(firma.db, 'requests', requestId), { realizationStatus: 'pending' });
    await setRealizationStatus(guest, requestId, 'rejected');
    const r = (await getDoc(doc(guest.db, 'requests', requestId))).data();
    assert.equal(r.realizationStatus, 'rejected');
    assert.equal(r.status, 'taken');
  });
  await step('firma dodaje zdjęcie realizacji → gość potwierdza wykonanie', async () => {
    await writeBatch(firma.db)
      .set(doc(collection(firma.db, 'realizations')), {
        companyId: firmaUid,
        requestId,
        userId: guestUid,
        category: 'Budowlane i Remontowe',
        imageUrl: 'https://example.invalid/syfon.jpg',
        addedByRole: 'company',
        status: 'pending',
        publishedByCompany: false,
        visible: false,
        timestamp: serverTimestamp(),
      })
      .update(doc(firma.db, 'requests', requestId), { realizationStatus: 'pending' })
      .commit();
    await setRealizationStatus(guest, requestId, 'approved');
    const r = (await getDoc(doc(guest.db, 'requests', requestId))).data();
    assert.equal(r.status, 'closed');
    assert.equal(r.closedReason, 'realized');
    assert.equal(r.realizationStatus, 'approved');
    assert.equal((await getCompanyRealizations(anon, firmaUid)).length, 2);
    assert.equal(await getCompletedJobsCount(guest, firmaUid), 1);
  });

  console.log('Czat');
  await step('gość pisze, firma odpisuje (zapis jak w apce), gość widzi i oznacza przeczytane', async () => {
    await sendMessage(guest, firmaUid, 'Dzień dobry, kiedy możecie przyjechać?');
    const chatId = [guestUid, firmaUid].sort().join('_');
    const chat = (await getDoc(doc(firma.db, 'chats', chatId))).data();
    assert.deepEqual(chat.participants, chatId.split('_'));
    assert.equal(chat.names[guestUid], 'Anna Nowak');
    assert.equal(chat.isCompany[guestUid], false);
    assert.equal(chat.unread[firmaUid], 1);
    const chatRef = doc(firma.db, 'chats', chatId);
    await writeBatch(firma.db)
      .set(
        chatRef,
        {
          participants: chatId.split('_'),
          names: { [firmaUid]: 'Hydro-Test' },
          isCompany: { [firmaUid]: true },
          lastMessage: 'Jutro o 10:00',
          lastTimestamp: serverTimestamp(),
          unread: { [guestUid]: increment(1) },
          hiddenFor: arrayRemove(firmaUid, guestUid),
        },
        { merge: true },
      )
      .set(doc(collection(chatRef, 'messages')), { from: firmaUid, content: 'Jutro o 10:00', timestamp: serverTimestamp(), read: false })
      .commit();
    const msgs = await waitFor((n, e) => watchMessages(guest, firmaUid, 50, n, e), (m) => m.length === 2 && !m.some((x) => x.pending), 'wiadomości');
    assert.deepEqual(msgs.map((m) => m.from), [guestUid, firmaUid]);
    const chats = await waitFor((n, e) => watchChats(guest, n, e), (c) => c.length === 1 && c[0].unread === 1, 'rozmowy');
    assert.equal(chats[0].name, 'Hydro-Test');
    assert.equal(chats[0].isCompany, true);
    await markChatRead(guest, firmaUid);
    const after = (await getDoc(doc(guest.db, 'chats', chatId))).data();
    assert.equal(after.unread[guestUid], 0);
    const unreadLeft = await getDocs(
      query(collection(guest.db, 'chats', chatId, 'messages'), where('from', '==', firmaUid), where('read', '==', false)),
    );
    assert.equal(unreadLeft.size, 0);
    await denied(getDoc(doc(anon.db, 'chats', chatId)));
    await denied(getDocs(collection(firma2.db, 'chats', chatId, 'messages')));
  });

  console.log('Rezerwacja na wizytówce');
  await step('gość rezerwuje s1 (bookSlot jak w apce)', async () => {
    const before = slotsFromDocs((await getDocs(slotsQuery(guest, firmaUid))).docs);
    assert.deepEqual(before.map((s) => s.id).sort(), [slotIds.s1, slotIds.s2].sort());
    await bookSlot(guest, firmaUid, slotIds.s1);
    const s = (await getDoc(doc(guest.db, 'users', firmaUid, 'slots', slotIds.s1))).data();
    assert.equal(s.status, 'pending');
    assert.equal(s.bookedBy, guestUid);
    const b = (await getDoc(doc(guest.db, 'users', guestUid, 'myBookings', `${firmaUid}_${slotIds.s1}`))).data();
    assert.equal(b.status, 'pending');
    assert.equal(b.companyName, 'Hydro-Test');
    const rel = (await getDoc(doc(guest.db, 'users', guestUid, 'myCompanies', firmaUid))).data();
    assert.deepEqual(rel.slotIds, [slotIds.s1]);
    const anonSlots = slotsFromDocs((await getDocs(slotsQuery(anon, firmaUid))).docs);
    assert.deepEqual(anonSlots.map((s) => s.id), [slotIds.s2]);
    await assert.rejects(bookSlot(firma2, firmaUid, slotIds.s1), /niedostępny/);
  });
  await step('firma przyjmuje rezerwację (apka) → gość widzi „potwierdzona”', async () => {
    const slotRef = doc(firma.db, 'users', firmaUid, 'slots', slotIds.s1);
    await runTransaction(firma.db, async (tx) => {
      const slot = (await tx.get(slotRef)).data();
      tx.update(slotRef, { status: 'accepted' });
      tx.set(
        doc(firma.db, 'users', guestUid, 'myBookings', `${firmaUid}_${slotIds.s1}`),
        { companyId: firmaUid, companyName: 'Hydro-Test', slotId: slotIds.s1, start: slot.start, status: 'accepted', decidedAt: serverTimestamp() },
        { merge: true },
      );
    });
    const list = await waitFor((n, e) => watchMyBookings(guest, n, e), (l) => l.length === 1 && l[0].status === 'accepted', 'rezerwacje');
    assert.equal(list[0].companyName, 'Hydro-Test');
  });
  await step('gość odwołuje rezerwację → termin wraca do puli', async () => {
    await cancelSlotBooking(guest, firmaUid, slotIds.s1);
    const s = (await getDoc(doc(firma.db, 'users', firmaUid, 'slots', slotIds.s1))).data();
    assert.equal(s.status, 'free');
    assert.equal(s.bookedBy, '');
    assert.equal(s.releasedBy, 'user');
    assert.equal((await getDoc(doc(guest.db, 'users', guestUid, 'myBookings', `${firmaUid}_${slotIds.s1}`))).exists(), false);
    const rel = (await getDoc(doc(guest.db, 'users', guestUid, 'myCompanies', firmaUid))).data();
    assert.deepEqual(rel.slotIds, []);
    assert.deepEqual(rel.requestIds, [requestId]);
    const anonSlots = slotsFromDocs((await getDocs(slotsQuery(anon, firmaUid))).docs);
    assert.deepEqual(anonSlots.map((s) => s.id).sort(), [slotIds.s1, slotIds.s2].sort());
  });
  await step('gość nie czyta cudzych danych kontaktowych', async () => {
    await denied(getDoc(doc(guest.db, 'users', olaUid, 'private', 'contact')));
    await denied(getDoc(doc(guest.db, 'users', firmaUid, 'private', 'contact')));
    await denied(getDoc(doc(guest.db, 'users', olaUid, 'myBookings', `${firmaUid}_${slotIds.s3}`)));
  });

  console.log(`\nZaliczone kroki: ${passed}`);
}

try {
  await main();
} catch (e) {
  console.error(e);
  process.exitCode = 1;
} finally {
  await closeAll();
  setTimeout(() => process.exit(process.exitCode ?? 0), 500).unref();
}
