// Dane do ręcznego klikania strony na emulatorach (npm run emulators w drugim oknie):
//   node test/seed.mjs            — firma „Hydro-Demo” z terminami, opinią i realizacją
//   node test/seed.mjs oferta     — firma składa ofertę do otwartych zgłoszeń z branży Hydraulik
//   node test/seed.mjs wykonane   — firma prosi o potwierdzenie wykonania przyjętych zgłoszeń
import { signInWithEmailAndPassword } from 'firebase/auth';
import { collection, doc, getDoc, getDocs, query, serverTimestamp, setDoc, Timestamp, updateDoc, where, writeBatch } from 'firebase/firestore';
import { PASSWORD, closeAll, makeCtx, ownerSet, registerInApp } from './helpers.mjs';

const FIRM = { email: 'firma@demo.qb', firstName: 'Jan', lastName: 'Kowalski', phone: '500 600 700', company: { nip: '1234567890', name: 'Hydro-Demo' } };
const CLIENT = { email: 'klient@demo.qb', firstName: 'Ola', lastName: 'Wiśniewska', phone: '600 100 200' };

async function login(name, who) {
  const c = makeCtx(name);
  try {
    await signInWithEmailAndPassword(c.auth, who.email, PASSWORD);
  } catch {
    await registerInApp(c, who);
  }
  return c;
}

async function seed() {
  const firm = await login('firma', FIRM);
  const firmUid = firm.auth.currentUser.uid;
  const slots = await getDocs(collection(firm.db, 'users', firmUid, 'slots'));
  if (slots.empty) {
    const b = writeBatch(firm.db);
    const now = new Date();
    for (let d = 1; d <= 6; d++) {
      for (const h of [9, 11, 14, 16]) {
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() + d, h, 0);
        b.set(doc(collection(firm.db, 'users', firmUid, 'slots')), { start: Timestamp.fromDate(start), durationMin: 60, bookedBy: '' });
      }
    }
    await b.commit();
  }
  await updateDoc(doc(firm.db, 'users', firmUid), {
    bio: 'Hydraulika od 2009 roku: awarie, biały montaż, wymiana instalacji. Działamy w Warszawie i okolicach.',
    slotsInfo: 'Bezpłatna wycena u Ciebie (ok. 30 min)',
    companyAddress: { street: 'Marszałkowska', buildingNr: '10', postCode: '00-001', city: 'Warszawa' },
  });

  const client = await login('klient', CLIENT);
  const clientUid = client.auth.currentUser.uid;
  const reviewId = `${clientUid}_${firmUid}`;
  if (!(await getDoc(doc(client.db, 'reviews', reviewId))).exists()) {
    await setDoc(doc(client.db, 'reviews', reviewId), {
      userId: clientUid,
      promoId: 'profile_review',
      authorName: CLIENT.firstName,
      reviewedUserId: firmUid,
      score: 5,
      fileUrl: '',
      thumbUrl: '',
      fileName: '',
      timestamp: serverTimestamp(),
      description: 'Przyjechali tego samego dnia, wszystko szczelne. Polecam.',
    });
    await setDoc(doc(firm.db, 'reviews', reviewId, 'comments', firmUid), {
      reviewId,
      authorId: firmUid,
      authorName: FIRM.company.name,
      isOwner: true,
      text: 'Dziękujemy, zapraszamy ponownie!',
      timestamp: serverTimestamp(),
    });
  }
  await ownerSet(`realizations/demo-${firmUid}`, {
    companyId: firmUid,
    requestId: 'demo',
    userId: clientUid,
    category: 'Budowlane i Remontowe',
    imageUrl: `data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400"><rect width="400" height="400" fill="#edf1fd"/><text x="200" y="210" font-size="28" text-anchor="middle" fill="#2a4cd7">Realizacja (demo)</text></svg>')}`,
    addedByRole: 'company',
    status: 'approved',
    publishedByCompany: false,
    visible: true,
    timestamp: new Date(),
  });
  console.log(`Wizytówka: http://localhost:5173/f/${firmUid}`);
}

async function offer() {
  const firm = await login('firma', FIRM);
  const firmUid = firm.auth.currentUser.uid;
  const open = await getDocs(query(collection(firm.db, 'requests'), where('status', '==', 'open'), where('sector', '==', 'Hydraulik')));
  let n = 0;
  for (const r of open.docs) {
    if (r.data().userId === firmUid) continue;
    const ref = doc(firm.db, 'requests', r.id, 'offers', firmUid);
    if ((await getDoc(ref)).exists()) continue;
    await setDoc(ref, {
      companyId: firmUid,
      companyName: FIRM.company.name,
      message: 'Dzień dobry, możemy przyjechać jutro rano. Wycena na miejscu gratis.',
      price: 250,
      priceTo: 400,
      when: 'tomorrow',
      status: 'pending',
      timestamp: serverTimestamp(),
    });
    n++;
  }
  console.log(`Złożone oferty: ${n}`);
}

async function done() {
  const firm = await login('firma', FIRM);
  const taken = await getDocs(query(collection(firm.db, 'requests'), where('takenBy', '==', firm.auth.currentUser.uid), where('status', '==', 'taken')));
  let n = 0;
  for (const r of taken.docs) {
    if (r.data().realizationStatus === 'pending') continue;
    await updateDoc(r.ref, { realizationStatus: 'pending' });
    n++;
  }
  console.log(`Prośby o potwierdzenie: ${n}`);
}

try {
  await ({ oferta: offer, wykonane: done }[process.argv[2]] ?? seed)();
} catch (e) {
  console.error(e);
  process.exitCode = 1;
} finally {
  await closeAll();
  setTimeout(() => process.exit(process.exitCode ?? 0), 300).unref();
}
