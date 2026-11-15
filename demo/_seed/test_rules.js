// Testy reguł: Firestore i Storage przez Firebase Rules API (:test ocenia przesłane źródło,
// nie dotyka danych, bez emulatora i bez deployu), RTDB lokalnym ewaluatorem kaskady
// (RTDB nie ma Rules API). ALLOW = operacja, którą robi apka; DENY = nadużycie z przeglądu.
// Uruchom: node test_rules.js   (z demo/_seed)
const fs = require('fs');
const { GoogleAuth } = require('google-auth-library');

const NOW = '2026-10-12T10:00:00Z';
const EARLIER = '2026-10-10T10:00:00Z';
const LATER = '2026-10-15T10:00:00Z';
const BOOKED_2H_AGO = '2026-10-12T08:00:00Z';
const BOOKED_30MIN_AGO = '2026-10-12T09:30:00Z';
const MB = 1024 * 1024;

const DOC = '/databases/(default)/documents';
const BUCKET = 'qubdud-8f2b8.firebasestorage.app';
const auth = (uid, provider = 'password') => ({
  uid, token: { firebase: { sign_in_provider: provider } },
});
const ANON = auth('anon1', 'anonymous');
const U1 = auth('u1'), U2 = auth('u2'), C1 = auth('c1'), C2 = auth('c2'), X = auth('x1');

// ── Firestore: before = dokument przed zapisem (null = nie istnieje), patch: DEL usuwa pole ──
const DEL = Symbol('DEL');
const merge = (before, patch) => {
  const out = { ...before };
  for (const [k, v] of Object.entries(patch)) {
    if (v === DEL) delete out[k]; else out[k] = v;
  }
  return out;
};
const fsCase = (name, expectation, method, path, a, { before = null, after, mocks = [] } = {}) => ({
  name, expectation,
  request: { auth: a, path: DOC + path, method, time: NOW, ...(after ? { resource: { data: after } } : {}) },
  resource: before ? { data: before } : null,
  ...(mocks.length ? { functionMocks: mocks } : {}),
});
const get = (n, e, p, a, before = null, mocks) => fsCase(n, e, 'get', p, a, { before, mocks });
const list = (n, e, p, a, before, mocks) => fsCase(n, e, 'list', p, a, { before, mocks });
const create = (n, e, p, a, after, mocks) => fsCase(n, e, 'create', p, a, { after, mocks });
const update = (n, e, p, a, before, patch, mocks) =>
  fsCase(n, e, 'update', p, a, { before, after: merge(before, patch), mocks });
const del = (n, e, p, a, before, mocks) => fsCase(n, e, 'delete', p, a, { before, mocks });
const mock = (fn, path, data) =>
  ({ function: fn, args: [{ exactValue: DOC + path }], result: { value: { data } } });

const loc = { lat: 52.23, lng: 21.01 };
const consents = { terms: true, rodo: true, acceptedAt: NOW };
const newClient = {
  email: 'jan@a.pl', firstName: 'Jan', lastName: 'Kowalski', phone: '500100200', bio: 'Hej',
  isCompany: false, firma: false, consents, createdAt: NOW,
};
const newCompany = {
  email: 'firma@a.pl', firstName: 'Anna', lastName: 'Nowak', phone: '600100200',
  isCompany: true, firma: true, nip: '1234567890', companyName: 'Firma 1',
  companyCategory: 'Hydraulik', companySector: 'Dom', companyCity: 'Warszawa', companyLocation: loc,
  companyAddress: { street: 'Prosta', buildingNr: '1', flatNr: '', city: 'Warszawa', postCode: '00-001' },
  consents, createdAt: NOW,
};
const savedUser = { ...newClient, consents: { ...consents, acceptedAt: EARLIER }, createdAt: EARLIER, fcmTokens: ['t1'] };
const savedCompany = { ...newCompany, consents: { ...consents, acceptedAt: EARLIER }, createdAt: EARLIER };

const promo = {
  userId: 'c1', category: 'Hydraulik', sector: 'Dom', location: loc, fileUrl: 'https://f/1.mp4',
  thumbUrl: 'https://f/1.jpg', fileName: '1.mp4', timestamp: NOW, description: '', companyName: 'Firma 1',
};
const savedPromo = { ...promo, timestamp: EARLIER, views: 3 };

const slotNew = { start: LATER, bookedBy: '' };
const slotFreed = { start: LATER, durationMin: 60, status: 'free', bookedBy: '', releasedBy: 'rejected' };
const slotPending = { start: LATER, durationMin: 60, status: 'pending', bookedBy: 'u1', bookedAt: BOOKED_30MIN_AGO };
const slotExpired = { ...slotPending, bookedAt: BOOKED_2H_AGO };
const slotAccepted = { ...slotPending, status: 'accepted' };
const slotRejectedOld = { ...slotPending, status: 'rejected', bookedByName: 'Jan', bookedAt: BOOKED_2H_AGO };
const book = (uid) => ({ status: 'pending', bookedBy: uid, bookedAt: NOW });
const freed = (by) => ({ status: 'free', bookedBy: '', releasedBy: by });
const blockedBy = (companyId, uid, value) =>
  ({ function: 'exists', args: [{ exactValue: `${DOC}/users/${companyId}/blocked/${uid}` }], result: { value } });

const booking = { companyId: 'c1', companyName: 'Firma 1', slotId: 's1', start: LATER, status: 'pending', bookedAt: NOW };
const decision = (status) => ({ companyId: 'c1', companyName: 'Firma 1', slotId: 's1', start: LATER, status, decidedAt: NOW });
const slotBookedBy = (uid) => mock('get', '/users/c1/slots/s1', { ...slotPending, bookedBy: uid });

const clientLink = { userId: 'u1', name: 'Jan Kowalski', addedAt: NOW, requestIds: ['r1'], lastAt: NOW };
const companyLink = { companyId: 'c1', name: 'Firma 1', addedAt: NOW, requestIds: ['r1'], lastAt: NOW };
const savedClientLink = { ...clientLink, addedAt: EARLIER, lastAt: EARLIER, slotIds: ['s1', 's2'], requestId: 'r0' };
const savedCompanyLink = { ...companyLink, addedAt: EARLIER, lastAt: EARLIER, slotIds: ['s1', 's2'] };

const cr = {
  userId: 'u1', companyId: 'c1', userName: 'Jan Kowalski', companyName: 'Firma 1', phone: '500100200',
  note: 'po 16', status: 'pending', createdAt: NOW, doneAt: null,
};
const savedCr = { ...cr, createdAt: EARLIER };

const request = {
  userId: 'u1', category: 'Hydraulik', sector: 'Dom', location: loc, city: 'Warszawa',
  fileUrl: 'https://f/r.jpg', thumbUrl: 'https://f/rt.jpg', fileName: '1.jpg', mediaType: 'image',
  timestamp: NOW, is24: false, description: 'Cieknie kran', status: 'open', takenBy: '', takenByName: '',
  confirmedByCompany: false, confirmedByUser: false,
};
const reqOpen = { ...request, timestamp: EARLIER };
const reqTaken = { ...reqOpen, status: 'taken', takenBy: 'c1', takenByName: 'Firma 1', confirmedByCompany: true, confirmedByUser: true, takenAt: EARLIER };
const reqPhotos = { ...reqTaken, realizationStatus: 'pending' };
const reqPhotosRejected = { ...reqTaken, realizationStatus: 'rejected' };
const accept = { takenBy: 'c1', takenByName: 'Firma 1', confirmedByCompany: true, confirmedByUser: true, status: 'taken', takenAt: NOW };
const unlock = { takenBy: '', takenByName: '', confirmedByCompany: false, confirmedByUser: false, status: 'open', realizationStatus: DEL };

const offer = { companyId: 'c1', companyName: 'Firma 1', message: 'Jutro, 200 zł', status: 'pending', timestamp: NOW };
const savedOffer = { ...offer, timestamp: EARLIER };
const offerAfter = (status) => mock('getAfter', '/requests/r1/offers/c1', { ...savedOffer, status });
const parentReq = (data) => mock('get', '/requests/r1', data);

const review = {
  userId: 'u1', promoId: 'p1', authorName: 'Jan Kowalski', reviewedUserId: 'c1', score: 5,
  fileUrl: 'https://f/v.jpg', thumbUrl: 'https://f/vt.jpg', fileName: 'v.jpg', timestamp: NOW, description: 'Polecam',
};
const savedReview = { ...review, timestamp: EARLIER };
const comment = { reviewId: 'v1', authorId: 'u2', authorName: 'Ola', isOwner: false, text: 'Potwierdzam', timestamp: NOW };
const parentReview = mock('get', '/reviews/v1', savedReview);

const chatFirst = {
  participants: ['u1', 'u2'], names: { u1: 'Jan Kowalski' }, isCompany: { u1: false },
  lastMessage: 'Hej', lastTimestamp: NOW, unread: { u2: 1 }, hiddenFor: [],
};
const savedChat = {
  participants: ['u1', 'u2'], names: { u1: 'Jan Kowalski', u2: 'Ola' }, isCompany: { u1: false, u2: false },
  lastMessage: 'Hej', lastTimestamp: EARLIER, unread: { u1: 2, u2: 1 }, hiddenFor: ['u2'],
};
const legacyChat = {
  participants: ['u2', 'u1'], names: { u1: 'Jan', u2: 'Ola' }, isCompany: { u1: false, u2: false },
  lastMessage: 'Stara', lastTimestamp: EARLIER, unread: { u1: 0, u2: 0 },
};
// sendMessage: set(merge) rozmowy w batchu z wiadomością
const sent = (before, from, to) => ({
  participants: ['u1', 'u2'],
  names: { ...before.names, [from]: 'Nowa nazwa' },
  isCompany: { ...before.isCompany, [from]: false },
  lastMessage: 'Kolejna', lastTimestamp: NOW,
  unread: { ...before.unread, [to]: ((before.unread || {})[to] || 0) + 1 },
  hiddenFor: (before.hiddenFor || []).filter((x) => x !== from && x !== to),
});
const msg = { from: 'u1', content: 'Hej', timestamp: NOW, read: false };
const savedMsg = { ...msg, timestamp: EARLIER };

const realization = {
  companyId: 'c1', requestId: 'r1', userId: 'u1', category: 'Hydraulik', imageUrl: 'https://f/po.jpg',
  beforeUrl: 'https://f/przed.jpg', addedByRole: 'company', status: 'pending', publishedByCompany: false, timestamp: NOW,
};
const ownPhoto = { companyId: 'c1', requestId: 'r1', userId: 'u1', category: 'Hydraulik', imageUrl: 'https://f/moje.jpg', addedByRole: 'user', status: 'approved', publishedByCompany: false, timestamp: NOW };
const savedRealization = { ...realization, timestamp: EARLIER };
const savedOwnPhoto = { ...ownPhoto, timestamp: EARLIER };

const notif = {
  userId: 'u1', title: 'Nowa wiadomość', body: 'Hej', type: 'chat', audience: 'both', requestId: '',
  companyId: '', from: 'u2', read: false, createdAt: EARLIER,
};

const firestoreCases = [
  // ── promos ──
  get('anon czyta prezentację', 'ALLOW', '/promos/p1', ANON, savedPromo),
  list('anon listuje prezentacje (feed)', 'ALLOW', '/promos/p1', ANON, savedPromo),
  create('firma dodaje prezentację', 'ALLOW', '/promos/p1', C1, promo),
  update('właściciel przepina lokalizację prezentacji', 'ALLOW', '/promos/p1', C1, savedPromo, { location: { lat: 50.06, lng: 19.94 } }),
  update('user dolicza wyświetlenie', 'ALLOW', '/promos/p1', U1, savedPromo, { views: 4 }),
  update('user dolicza pierwsze wyświetlenie (brak pola)', 'ALLOW', '/promos/p1', U1, { ...promo, timestamp: EARLIER }, { views: 1 }),
  del('właściciel usuwa prezentację', 'ALLOW', '/promos/p1', C1, savedPromo),
  update('QB-76 anon dolicza wyświetlenie', 'DENY', '/promos/p1', ANON, savedPromo, { views: 4 }),
  update('QB-76 views = 1e9', 'DENY', '/promos/p1', U1, savedPromo, { views: 1000000000 }),
  update('QB-76 views = "abc"', 'DENY', '/promos/p1', U1, savedPromo, { views: 'abc' }),
  create('QB-76 prezentacja z timestamp jako string', 'DENY', '/promos/p2', X, { ...promo, userId: 'x1', timestamp: 'zawsze-na-gorze' }),
  create('QB-76 prezentacja z description = 0', 'DENY', '/promos/p2', X, { ...promo, userId: 'x1', description: 0 }),
  create('prezentacja z nadanym views', 'DENY', '/promos/p2', C1, { ...promo, views: 999999 }),
  create('prezentacja na cudze konto', 'DENY', '/promos/p2', X, promo),
  update('obcy zmienia opis prezentacji', 'DENY', '/promos/p1', U1, savedPromo, { description: 'spam' }),
  update('właściciel przepisuje prezentację na inne konto', 'DENY', '/promos/p1', C1, savedPromo, { userId: 'x1' }),

  // ── users ──
  get('user czyta profil firmy', 'ALLOW', '/users/c1', U1, savedCompany),
  get('anon czyta profil firmy', 'DENY', '/users/c1', ANON, savedCompany),
  list('QB-68 listowanie kolekcji users', 'DENY', '/users/u1', X, savedUser),
  create('rejestracja klienta', 'ALLOW', '/users/u1', U1, newClient),
  create('rejestracja firmy', 'ALLOW', '/users/c1', C1, newCompany),
  create('rejestracja klienta bez opisu', 'ALLOW', '/users/u1', U1, merge(newClient, { bio: DEL })),
  create('QB-77 rejestracja firmy bez NIP', 'DENY', '/users/c1', C1, merge(newCompany, { nip: DEL })),
  create('QB-77 rejestracja: firma != isCompany', 'DENY', '/users/u1', U1, { ...newClient, firma: true }),
  create('QB-77 rejestracja z polem demo', 'DENY', '/users/u1', U1, { ...newClient, demo: true }),
  create('QB-77 klient z polami firmy', 'DENY', '/users/u1', U1, { ...newClient, companyName: 'Udawana' }),
  create('rejestracja bez zgód', 'DENY', '/users/u1', U1, { ...newClient, consents: { terms: false, rodo: true, acceptedAt: NOW } }),
  create('rejestracja na cudzy uid', 'DENY', '/users/u2', U1, newClient),
  update('Moje dane: imię, nazwisko, telefon, opis', 'ALLOW', '/users/u1', U1, savedUser, { firstName: 'Janek', lastName: 'K', phone: '501', bio: 'nowy' }),
  update('Dane firmy', 'ALLOW', '/users/c1', C1, savedCompany, {
    companyName: 'Firma 1 sp. z o.o.', bio: 'Opis', phone: '601', companyCity: 'Kraków',
    companyAddress: { street: 'Długa', buildingNr: '2', flatNr: '', city: 'Kraków', postCode: '30-001' },
    www: 'https://f.pl', contactEmail: 'k@f.pl', showPhone: false, showAddress: true, companyLocation: { lat: 50.06, lng: 19.94 },
  }),
  update('kalendarz: opis terminów', 'ALLOW', '/users/c1', C1, savedCompany, { slotsInfo: 'Pn-Pt' }),
  update('token FCM (arrayUnion)', 'ALLOW', '/users/u1', U1, savedUser, { fcmTokens: ['t1', 't2'] }),
  update('QB-77 klient ustawia sobie firma=true', 'DENY', '/users/u1', U1, savedUser, { firma: true, isCompany: true }),
  update('QB-77 zmiana NIP', 'DENY', '/users/c1', C1, savedCompany, { nip: '0000000000' }),
  update('QB-77 nadpisanie zgód', 'DENY', '/users/u1', U1, savedUser, { consents: { terms: false } }),
  update('QB-77 zmiana createdAt', 'DENY', '/users/u1', U1, savedUser, { createdAt: NOW }),
  update('QB-77 zmiana e-maila', 'DENY', '/users/u1', U1, savedUser, { email: 'x@x.pl' }),
  update('QB-77 dopisanie demo', 'DENY', '/users/u1', U1, savedUser, { demo: true }),
  update('edycja cudzego profilu', 'DENY', '/users/c1', U1, savedCompany, { phone: '999' }),
  del('usunięcie profilu z apki', 'DENY', '/users/u1', U1, savedUser),

  // ── slots ──
  list('user czyta wolne terminy firmy', 'ALLOW', '/users/c1/slots/s1', U1, slotNew),
  list('user czyta stary wolny termin bez bookedBy', 'ALLOW', '/users/c1/slots/s1', U1, { start: LATER }),
  list('klient czyta swoją rezerwację', 'ALLOW', '/users/c1/slots/s1', U1, slotPending),
  get('klient czyta swój termin w transakcji', 'ALLOW', '/users/c1/slots/s1', U1, slotAccepted),
  list('firma czyta zajęte terminy', 'ALLOW', '/users/c1/slots/s1', C1, slotPending),
  list('QB-55 anon czyta terminy (bez zmian)', 'DENY', '/users/c1/slots/s1', ANON, slotNew),
  list('#2 obcy listuje cudzą rezerwację', 'DENY', '/users/c1/slots/s1', U2, slotPending),
  get('#2 obcy czyta cudzą przyjętą rezerwację', 'DENY', '/users/c1/slots/s1', X, slotAccepted),
  create('firma dodaje termin', 'ALLOW', '/users/c1/slots/s1', C1, slotNew),
  create('firma generuje terminy (batch)', 'ALLOW', '/users/c1/slots/s1', C1, { start: LATER, durationMin: 30, bookedBy: '' }),
  create('#2 termin bez bookedBy (niewidoczny w zapytaniu klienta)', 'DENY', '/users/c1/slots/s1', C1, { start: LATER }),
  create('#3 firma tworzy termin od razu z klientem', 'DENY', '/users/c1/slots/s1', C1, { ...slotNew, bookedBy: 'u1' }),
  update('klient rezerwuje świeży termin (bez pola status)', 'ALLOW', '/users/c1/slots/s1', U1, slotNew, book('u1'), [blockedBy('c1', 'u1', false)]),
  update('klient rezerwuje zwolniony termin', 'ALLOW', '/users/c1/slots/s1', U2, slotFreed, book('u2'), [blockedBy('c1', 'u2', false)]),
  update('#36 klient rezerwuje stary odrzucony (APK ≤1.3.2)', 'ALLOW', '/users/c1/slots/s1', U2, slotRejectedOld, book('u2'), [blockedBy('c1', 'u2', false)]),
  update('QB-37 klient przejmuje wygasłą żółtą (>60 min)', 'ALLOW', '/users/c1/slots/s1', U2, slotExpired, book('u2'), [blockedBy('c1', 'u2', false)]),
  update('klient ponawia swoją wygasłą żółtą', 'ALLOW', '/users/c1/slots/s1', U1, slotExpired, book('u1'), [blockedBy('c1', 'u1', false)]),
  update('#17 klient zablokowany przez firmę rezerwuje', 'DENY', '/users/c1/slots/s1', U1, slotNew, book('u1'), [blockedBy('c1', 'u1', true)]),
  update('#2 rezerwacja z imieniem w slocie', 'DENY', '/users/c1/slots/s1', U1, slotNew, { ...book('u1'), bookedByName: 'Jan' }, [blockedBy('c1', 'u1', false)]),
  update('klient odwołuje swoją żółtą', 'ALLOW', '/users/c1/slots/s1', U1, slotPending, freed('user')),
  update('klient odwołuje swoją przyjętą', 'ALLOW', '/users/c1/slots/s1', U1, slotAccepted, freed('user')),
  update('#36 klient zwalnia stary odrzucony', 'DENY', '/users/c1/slots/s1', U1, slotRejectedOld, freed('user')),
  update('firma przyjmuje rezerwację', 'ALLOW', '/users/c1/slots/s1', C1, slotPending, { status: 'accepted' }),
  update('firma odrzuca (zwalnia termin)', 'ALLOW', '/users/c1/slots/s1', C1, slotPending, freed('rejected')),
  update('firma zwalnia wygasłą', 'ALLOW', '/users/c1/slots/s1', C1, slotExpired, freed('expired')),
  del('firma usuwa termin', 'ALLOW', '/users/c1/slots/s1', C1, slotAccepted),
  update('#3 firma wpisuje klienta i akceptuje', 'DENY', '/users/c1/slots/s1', C1, slotNew, { status: 'accepted', bookedBy: 'u2' }),
  update('#3 firma wpisuje klienta jako żółtą', 'DENY', '/users/c1/slots/s1', C1, slotNew, book('u2')),
  update('#3 firma podmienia rezerwującego', 'DENY', '/users/c1/slots/s1', C1, slotAccepted, { bookedBy: 'u2' }),
  update('#3 firma akceptuje wolny termin', 'DENY', '/users/c1/slots/s1', C1, slotFreed, { status: 'accepted' }),
  update('#3 firma cofa przyjętą do żółtej (ponowny push)', 'DENY', '/users/c1/slots/s1', C1, slotAccepted, { status: 'pending' }),
  update('#3 firma przedłuża żółtą (bookedAt)', 'DENY', '/users/c1/slots/s1', C1, slotPending, { bookedAt: NOW }),
  update('#3 firma zwalnia bez czyszczenia bookedBy', 'DENY', '/users/c1/slots/s1', C1, slotPending, { status: 'free' }),
  update('QB-71 obcy przejmuje przyjętą rezerwację', 'DENY', '/users/c1/slots/s1', X, slotAccepted, book('x1')),
  update('QB-71 obcy przejmuje świeżą żółtą', 'DENY', '/users/c1/slots/s1', X, slotPending, book('x1')),
  update('QB-71 klient sam akceptuje', 'DENY', '/users/c1/slots/s1', U1, slotPending, { status: 'accepted' }),
  update('QB-71 klient przesuwa godzinę', 'DENY', '/users/c1/slots/s1', U1, slotPending, { start: '2026-10-20T08:00:00Z' }),
  update('QB-71 rezerwacja na kogoś innego', 'DENY', '/users/c1/slots/s1', X, slotNew, book('u1')),
  update('QB-71 rezerwacja z bookedAt w przyszłości (wieczna blokada)', 'DENY', '/users/c1/slots/s1', U1, slotNew, { ...book('u1'), bookedAt: LATER }),
  update('rezerwacja minionego terminu', 'DENY', '/users/c1/slots/s1', U1, { start: EARLIER }, book('u1')),
  update('QB-71 obcy zwalnia cudzą rezerwację', 'DENY', '/users/c1/slots/s1', X, slotAccepted, freed('user')),
  update('klient zwalnia z releasedBy=expired (podszycie)', 'DENY', '/users/c1/slots/s1', U1, slotPending, freed('expired')),
  create('klient dodaje termin cudzej firmie', 'DENY', '/users/c1/slots/s9', U1, slotNew),
  del('klient usuwa termin', 'DENY', '/users/c1/slots/s1', U1, slotPending),

  // ── myBookings ──
  list('klient czyta swoje rezerwacje', 'ALLOW', '/users/u1/myBookings/c1_s1', U1, booking),
  create('klient zapisuje kopię rezerwacji', 'ALLOW', '/users/u1/myBookings/c1_s1', U1, booking),
  fsCase('klient rezerwuje ponownie termin po odrzuceniu (set nadpisuje)', 'ALLOW', 'update', '/users/u1/myBookings/c1_s1', U1, { before: decision('rejected'), after: booking }),
  del('klient kasuje rezerwację (odwołanie, sprzątanie)', 'ALLOW', '/users/u1/myBookings/c1_s1', U1, decision('accepted')),
  update('firma przyjmuje (set merge na kopii)', 'ALLOW', '/users/u1/myBookings/c1_s1', C1, booking, { status: 'accepted', decidedAt: NOW }, [slotBookedBy('u1')]),
  create('firma odrzuca (kopii nie było)', 'ALLOW', '/users/u1/myBookings/c1_s1', C1, decision('rejected'), [slotBookedBy('u1')]),
  update('firma usuwa zajęty termin → cancelled', 'ALLOW', '/users/u1/myBookings/c1_s1', C1, decision('accepted'), { status: 'cancelled' }, [slotBookedBy('u1')]),
  create('K11/QB-72 klient sam wpisuje accepted', 'DENY', '/users/u1/myBookings/c1_s1', U1, decision('accepted')),
  update('K11/QB-72 klient zmienia pending na accepted', 'DENY', '/users/u1/myBookings/c1_s1', U1, booking, { status: 'accepted' }),
  create('klient zapisuje kopię pod złym id', 'DENY', '/users/u1/myBookings/c2_s1', U1, booking),
  create('QB-72 obcy wstrzykuje accepted', 'DENY', '/users/u1/myBookings/x1_s9', X, { ...decision('accepted'), companyId: 'x1', slotId: 's9' }, [mock('get', '/users/x1/slots/s9', slotNew)]),
  del('QB-72 obcy kasuje cudzą rezerwację', 'DENY', '/users/u1/myBookings/c1_s1', X, decision('accepted')),
  update('QB-72 inna firma pisze kopię c1', 'DENY', '/users/u1/myBookings/c1_s1', C2, booking, { status: 'accepted', decidedAt: NOW }, [mock('get', '/users/c2/slots/s1', slotPending)]),
  create('QB-72 firma wpisuje accepted klientowi spoza slotu', 'DENY', '/users/u2/myBookings/c1_s1', C1, decision('accepted'), [slotBookedBy('u1')]),
  get('firma czyta kopię klienta', 'DENY', '/users/u1/myBookings/c1_s1', C1, booking),
  list('obcy listuje rezerwacje', 'DENY', '/users/u1/myBookings/c1_s1', X, booking),

  // ── clients / myCompanies ──
  create('klient zakłada relację u firmy (_linkClient)', 'ALLOW', '/users/c1/clients/u1', U1, clientLink),
  update('klient dopisuje źródło relacji (set merge)', 'ALLOW', '/users/c1/clients/u1', U1, savedClientLink, { requestIds: ['r1', 'r2'], lastAt: NOW }),
  create('klient zakłada firmę u siebie', 'ALLOW', '/users/u1/myCompanies/c1', U1, companyLink),
  list('firma listuje klientów', 'ALLOW', '/users/c1/clients/u1', C1, savedClientLink),
  get('klient czyta swój wpis u firmy (transakcja)', 'ALLOW', '/users/c1/clients/u1', U1, savedClientLink),
  get('firma czyta wpis u klienta (transakcja)', 'ALLOW', '/users/u1/myCompanies/c1', C1, savedCompanyLink),
  update('firma zdejmuje termin z relacji u siebie', 'ALLOW', '/users/c1/clients/u1', C1, savedClientLink, { slotIds: ['s2'] }),
  update('firma zdejmuje termin z relacji u klienta', 'ALLOW', '/users/u1/myCompanies/c1', C1, savedCompanyLink, { slotIds: ['s2'] }),
  update('firma dopisuje swój termin do relacji klienta', 'DENY', '/users/u1/myCompanies/c1', C1, savedCompanyLink, { slotIds: ['s1', 's2', 's9'] }),
  del('firma kasuje pustą relację u klienta', 'ALLOW', '/users/u1/myCompanies/c1', C1, savedCompanyLink),
  update('klient zdejmuje zgłoszenie (requestIds, stare requestId)', 'ALLOW', '/users/c1/clients/u1', U1, savedClientLink, { requestIds: [], requestId: DEL }),
  del('klient kasuje relację u firmy', 'ALLOW', '/users/c1/clients/u1', U1, savedClientLink),
  del('QB-72 obcy kasuje klienta firmy', 'DENY', '/users/c1/clients/u1', X, savedClientLink),
  create('QB-72 obcy wstrzykuje firmę do Moich firm', 'DENY', '/users/u1/myCompanies/x1', X, { ...companyLink, companyId: 'x1' }),
  get('obcy czyta wpis klienta u firmy', 'DENY', '/users/c1/clients/u1', X, savedClientLink),
  create('firma sama dopisuje się klientowi', 'DENY', '/users/u1/myCompanies/c1', C1, companyLink),
  update('firma zmienia nazwę w relacji klienta', 'DENY', '/users/u1/myCompanies/c1', C1, savedCompanyLink, { name: 'Najlepsza firma' }),
  create('klient zakłada wpis z cudzym userId', 'DENY', '/users/c1/clients/u1', U1, { ...clientLink, userId: 'u2' }),
  get('właściciel czyta swoje notatki', 'ALLOW', '/users/c1/clientNotes/u1', C1, { note: 'x' }),
  get('obcy czyta notatki firmy', 'DENY', '/users/c1/clientNotes/u1', U1, { note: 'x' }),
  create('pomijanie zgłoszenia', 'ALLOW', '/users/c1/skippedRequests/r1', C1, { skippedAt: NOW }),
  create('cudze ulubione', 'DENY', '/users/u1/favoritePromos/p1', X, { promoId: 'p1', createdAt: NOW }),

  // ── contactRequests ──
  get('QB-60 odczyt nieistniejącej prośby', 'ALLOW', '/contactRequests/c1_u1', U1),
  get('klient czyta swoją prośbę', 'ALLOW', '/contactRequests/c1_u1', U1, savedCr),
  get('firma czyta prośbę', 'ALLOW', '/contactRequests/c1_u1', C1, savedCr),
  create('klient prosi o telefon', 'ALLOW', '/contactRequests/c1_u1', U1, cr),
  fsCase('klient ponawia prośbę (set na istniejącej)', 'ALLOW', 'update', '/contactRequests/c1_u1', U1, { before: { ...savedCr, status: 'done', doneAt: EARLIER }, after: cr }),
  update('firma oznacza załatwione', 'ALLOW', '/contactRequests/c1_u1', C1, savedCr, { status: 'done', doneAt: NOW }),
  get('obcy czyta prośbę', 'DENY', '/contactRequests/c1_u1', X, savedCr),
  create('QB-60 obcy zaklepuje id c1_u1', 'DENY', '/contactRequests/c1_u1', X, { ...cr, userId: 'x1' }),
  create('prośba pod niezgodnym id', 'DENY', '/contactRequests/c2_u1', U1, cr),
  create('prośba do samego siebie', 'DENY', '/contactRequests/c1_c1', C1, { ...cr, userId: 'c1' }),
  update('firma zmienia telefon w prośbie', 'DENY', '/contactRequests/c1_u1', C1, savedCr, { phone: '000' }),
  del('usunięcie prośby', 'DENY', '/contactRequests/c1_u1', U1, savedCr),
  list('listowanie próśb', 'DENY', '/contactRequests/c1_u1', U1, savedCr),

  // ── profile (stary opis) ──
  get('odczyt starego opisu firmy', 'ALLOW', '/profile/c1', U1, { userId: 'c1', bio: 'x' }),
  create('zapis do profile', 'DENY', '/profile/c1', C1, { userId: 'c1', bio: 'x' }),

  // ── requests ──
  list('firma czyta zgłoszenia', 'ALLOW', '/requests/r1', C1, reqOpen),
  list('anon listuje zgłoszenia', 'DENY', '/requests/r1', ANON, reqOpen),
  create('klient dodaje zgłoszenie', 'ALLOW', '/requests/r1', U1, request),
  create('klient dodaje zgłoszenie z filmem (pilne)', 'ALLOW', '/requests/r1', U1, { ...request, mediaType: 'video', fileName: '1.mp4', is24: true }),
  create('zgłoszenie na cudze konto', 'DENY', '/requests/r1', U1, { ...request, userId: 'u2' }),
  create('QB-76 zgłoszenie z is24 = "tak"', 'DENY', '/requests/r1', X, { ...request, userId: 'x1', is24: 'tak' }),
  create('QB-69 zgłoszenie od razu przejęte', 'DENY', '/requests/r1', U1, { ...request, status: 'taken', takenBy: 'c1' }),
  create('zgłoszenie z nieznanym polem', 'DENY', '/requests/r1', U1, { ...request, realizationStatus: 'approved' }),
  update('właściciel edytuje opis', 'ALLOW', '/requests/r1', U1, reqOpen, { description: 'Nowy opis' }),
  update('właściciel akceptuje ofertę (batch z ofertą)', 'ALLOW', '/requests/r1', U1, reqOpen, accept, [offerAfter('accepted')]),
  update('właściciel przejmuje bez zaakceptowanej oferty', 'DENY', '/requests/r1', U1, reqOpen, accept, [offerAfter('pending')]),
  update('właściciel odblokowuje zgłoszenie', 'ALLOW', '/requests/r1', U1, reqPhotosRejected, unlock),
  update('właściciel zamyka zgłoszenie', 'ALLOW', '/requests/r1', U1, reqOpen, { status: 'closed', closedAt: NOW, closedReason: 'byUser' }),
  update('K7 klient potwierdza zdjęcia', 'ALLOW', '/requests/r1', U1, reqPhotos, { realizationStatus: 'approved', status: 'closed', closedReason: 'realized', closedAt: NOW }),
  update('K7 klient odrzuca zdjęcia (zgłoszenie zostaje)', 'ALLOW', '/requests/r1', U1, reqPhotos, { realizationStatus: 'rejected' }),
  update('K11 właściciel sam wpisuje approved bez zdjęć', 'DENY', '/requests/r1', U1, reqTaken, { realizationStatus: 'approved', status: 'closed', closedReason: 'realized', closedAt: NOW }),
  update('K11 przejęcie zamkniętego z zatwierdzonymi zdjęciami innej firmy', 'DENY', '/requests/r1', U1, { ...reqOpen, status: 'closed', realizationStatus: 'approved' }, { ...accept, takenBy: 'c2' }, [mock('getAfter', '/requests/r1/offers/c2', { ...savedOffer, companyId: 'c2', status: 'accepted' })]),
  update('QB-69 właściciel przepisuje userId', 'DENY', '/requests/r1', U1, reqOpen, { userId: 'u2' }),
  update('K7 firma dodaje zdjęcia → pending', 'ALLOW', '/requests/r1', C1, reqTaken, { realizationStatus: 'pending' }),
  update('K7 firma dodaje właściwe po odrzuceniu', 'ALLOW', '/requests/r1', C1, reqPhotosRejected, { realizationStatus: 'pending' }),
  update('firma wycofuje zdjęcia', 'ALLOW', '/requests/r1', C1, reqPhotos, { realizationStatus: DEL }),
  del('właściciel usuwa zgłoszenie', 'ALLOW', '/requests/r1', U1, reqTaken),
  update('QB-69 firma bez oferty przejmuje otwarte', 'DENY', '/requests/r1', C2, reqOpen, { takenBy: 'c2', takenByName: 'F2', status: 'taken', confirmedByUser: true }),
  update('QB-69 firma odbiera zgłoszenie innej firmie', 'DENY', '/requests/r1', C2, reqTaken, { takenBy: 'c2', takenByName: 'F2' }),
  update('QB-69 obcy przepisuje userId i takenBy', 'DENY', '/requests/r1', X, reqOpen, { userId: 'x1', takenBy: 'x1' }),
  del('QB-69 obcy kasuje zgłoszenie', 'DENY', '/requests/r1', X, reqOpen),
  update('QB-69 firma realizująca zmienia opis', 'DENY', '/requests/r1', C1, reqTaken, { description: 'hack' }),
  update('K11 firma realizująca sama zatwierdza zdjęcia', 'DENY', '/requests/r1', C1, reqPhotos, { realizationStatus: 'approved', status: 'closed' }),
  update('firma wpisuje pending przy zgłoszeniu nieprzejętym', 'DENY', '/requests/r1', C1, { ...reqTaken, status: 'closed' }, { realizationStatus: 'pending' }),
  update('firma kasuje zatwierdzone zdjęcia ze zgłoszenia', 'DENY', '/requests/r1', C1, { ...reqTaken, realizationStatus: 'approved' }, { realizationStatus: DEL }),

  // ── offers ──
  create('firma składa ofertę', 'ALLOW', '/requests/r1/offers/c1', C1, offer, [parentReq(reqOpen)]),
  get('firma czyta swoją ofertę', 'ALLOW', '/requests/r1/offers/c1', C1, savedOffer),
  get('firma sprawdza brak swojej oferty', 'ALLOW', '/requests/r1/offers/c1', C1),
  list('właściciel czyta oferty', 'ALLOW', '/requests/r1/offers/c1', U1, savedOffer, [parentReq(reqOpen)]),
  update('właściciel akceptuje ofertę', 'ALLOW', '/requests/r1/offers/c1', U1, savedOffer, { status: 'accepted', decidedAt: NOW }, [parentReq(reqOpen)]),
  update('K6 właściciel zamyka pozostałe oferty', 'ALLOW', '/requests/r1/offers/c2', U1, { ...savedOffer, companyId: 'c2', status: 'maybe' }, { status: 'closed', decidedAt: NOW }, [parentReq(reqOpen)]),
  update('właściciel: „zastanawiam się”', 'ALLOW', '/requests/r1/offers/c1', U1, savedOffer, { status: 'maybe', decidedAt: NOW }, [parentReq(reqOpen)]),
  update('właściciel odrzuca ofertę', 'ALLOW', '/requests/r1/offers/c1', U1, savedOffer, { status: 'rejected', decidedAt: NOW }, [parentReq(reqOpen)]),
  update('odblokowanie: oferta wraca do pending', 'ALLOW', '/requests/r1/offers/c1', U1, { ...savedOffer, status: 'accepted', decidedAt: EARLIER }, { status: 'pending' }, [parentReq(reqTaken)]),
  create('QB-20 firma składa ofertę na własne zgłoszenie', 'DENY', '/requests/r1/offers/c1', C1, offer, [parentReq({ ...reqOpen, userId: 'c1' })]),
  create('oferta do przejętego zgłoszenia', 'DENY', '/requests/r1/offers/c2', C2, { ...offer, companyId: 'c2' }, [parentReq(reqTaken)]),
  create('oferta w imieniu innej firmy', 'DENY', '/requests/r1/offers/c1', C2, offer, [parentReq(reqOpen)]),
  create('QB-74 oferta od razu zaakceptowana', 'DENY', '/requests/r1/offers/c1', C1, { ...offer, status: 'accepted' }, [parentReq(reqOpen)]),
  update('QB-74 firma sama akceptuje ofertę', 'DENY', '/requests/r1/offers/c1', C1, savedOffer, { status: 'accepted' }, [parentReq(reqOpen)]),
  update('QB-74 firma cofa odrzucenie', 'DENY', '/requests/r1/offers/c1', C1, { ...savedOffer, status: 'rejected' }, { status: 'pending' }, [parentReq(reqOpen)]),
  fsCase('QB-74 firma ponawia ofertę po odrzuceniu (set)', 'DENY', 'update', '/requests/r1/offers/c1', C1, { before: { ...savedOffer, status: 'rejected', decidedAt: EARLIER }, after: offer, mocks: [parentReq(reqOpen)] }),
  update('inna firma zmienia ofertę c1', 'DENY', '/requests/r1/offers/c1', C2, savedOffer, { status: 'rejected' }, [parentReq(reqOpen)]),
  update('właściciel zmienia treść oferty', 'DENY', '/requests/r1/offers/c1', U1, savedOffer, { message: 'tanio' }, [parentReq(reqOpen)]),
  update('obcy akceptuje ofertę', 'DENY', '/requests/r1/offers/c1', X, savedOffer, { status: 'accepted' }, [parentReq(reqOpen)]),
  get('konkurencja czyta cudzą ofertę', 'DENY', '/requests/r1/offers/c1', C2, savedOffer, [parentReq(reqOpen)]),
  del('firma usuwa ofertę', 'DENY', '/requests/r1/offers/c1', C1, savedOffer),

  // ── reviews / comments ──
  list('user czyta recenzje firmy', 'ALLOW', '/reviews/v1', U1, savedReview),
  list('anon czyta recenzje (bez zmian)', 'DENY', '/reviews/v1', ANON, savedReview),
  create('klient dodaje recenzję', 'ALLOW', '/reviews/u1_c1', U1, review),
  create('recenzja z profilu firmy (bez prezentacji)', 'ALLOW', '/reviews/u1_c1', U1, { ...review, promoId: '', score: 1 }),
  create('QB-75 druga recenzja tej samej firmy (inne id)', 'DENY', '/reviews/v9', U1, review),
  create('QB-75 score = -100', 'DENY', '/reviews/x1_c1', X, { ...review, userId: 'x1', score: -100 }),
  create('QB-75 score = 4.5', 'DENY', '/reviews/x1_c1', X, { ...review, userId: 'x1', score: 4.5 }),
  create('QB-75 score = "5"', 'DENY', '/reviews/x1_c1', X, { ...review, userId: 'x1', score: '5' }),
  create('QB-75 score = 6', 'DENY', '/reviews/x1_c1', X, { ...review, userId: 'x1', score: 6 }),
  create('QB-75 recenzja samemu sobie', 'DENY', '/reviews/c1_c1', C1, { ...review, userId: 'c1', reviewedUserId: 'c1' }),
  create('recenzja w cudzym imieniu', 'DENY', '/reviews/u1_c1', X, review),
  update('QB-75 przeniesienie recenzji na inną firmę', 'DENY', '/reviews/v1', U1, savedReview, { reviewedUserId: 'c2' }),
  update('QB-75 nadpisanie własnej recenzji', 'DENY', '/reviews/u1_c1', U1, savedReview, { score: 1, timestamp: NOW }),
  del('autor usuwa recenzję', 'ALLOW', '/reviews/v1', U1, savedReview),
  del('obcy usuwa recenzję', 'DENY', '/reviews/v1', U2, savedReview),
  create('user komentuje recenzję', 'ALLOW', '/reviews/v1/comments/u2', U2, comment, [parentReview]),
  create('firma odpowiada jako właściciel', 'ALLOW', '/reviews/v1/comments/c1', C1, { ...comment, authorId: 'c1', isOwner: true }, [parentReview]),
  create('QB-75 drugi komentarz tej osoby (inne id)', 'DENY', '/reviews/v1/comments/k9', U2, comment, [parentReview]),
  create('QB-75 fałszywy znaczek właściciela', 'DENY', '/reviews/v1/comments/x1', X, { ...comment, authorId: 'x1', isOwner: true }, [parentReview]),
  create('komentarz w cudzym imieniu', 'DENY', '/reviews/v1/comments/u2', X, comment, [parentReview]),
  create('komentarz przypięty do innej recenzji', 'DENY', '/reviews/v1/comments/u2', U2, { ...comment, reviewId: 'v2' }, [parentReview]),
  del('autor usuwa komentarz', 'ALLOW', '/reviews/v1/comments/k1', U2, { ...comment, timestamp: EARLIER }),
  del('obcy usuwa komentarz', 'DENY', '/reviews/v1/comments/k1', X, { ...comment, timestamp: EARLIER }),
  update('edycja komentarza', 'DENY', '/reviews/v1/comments/k1', U2, { ...comment, timestamp: EARLIER }, { text: 'zmiana' }),

  // ── chats / messages ──
  get('uczestnik czyta rozmowę', 'ALLOW', '/chats/u1_u2', U1, savedChat),
  get('nazwa z nieistniejącej rozmowy (nameInChat)', 'ALLOW', '/chats/u1_u2', U2),
  list('lista rozmów (participants array-contains)', 'ALLOW', '/chats/u1_u2', U2, savedChat),
  get('obcy czyta rozmowę', 'DENY', '/chats/u1_u2', X, savedChat),
  list('obcy listuje rozmowę', 'DENY', '/chats/u1_u2', X, savedChat),
  get('anon czyta rozmowę', 'DENY', '/chats/u1_u2', ANON, savedChat),
  create('QB-01 pierwsza wiadomość zakłada rozmowę', 'ALLOW', '/chats/u1_u2', U1, chatFirst),
  create('pierwsza wiadomość od drugiej strony', 'ALLOW', '/chats/u1_u2', U2, { ...chatFirst, names: { u2: 'Ola' }, isCompany: { u2: true }, unread: { u1: 1 } }),
  fsCase('kolejna wiadomość (set merge, wyjmuje z kosza)', 'ALLOW', 'update', '/chats/u1_u2', U1, { before: savedChat, after: sent(savedChat, 'u1', 'u2') }),
  fsCase('wiadomość w starej rozmowie (participants w innej kolejności)', 'ALLOW', 'update', '/chats/u1_u2', U2, { before: legacyChat, after: sent(legacyChat, 'u2', 'u1') }),
  update('zerowanie mojego licznika', 'ALLOW', '/chats/u1_u2', U1, savedChat, { unread: { u1: 0, u2: 1 } }),
  update('rozmowa do kosza', 'ALLOW', '/chats/u1_u2', U1, savedChat, { hiddenFor: ['u2', 'u1'] }),
  update('przywrócenie z kosza', 'ALLOW', '/chats/u1_u2', U2, savedChat, { hiddenFor: [] }),
  create('QB-13 obcy zakłada rozmowę A_B z participants [obcy]', 'DENY', '/chats/u1_u2', X, { ...chatFirst, participants: ['x1'], names: { x1: 'X' }, isCompany: { x1: false } }),
  create('QB-13 uczestnik zakłada rozmowę z niepełnymi participants', 'DENY', '/chats/u1_u2', U1, { ...chatFirst, participants: ['u1'] }),
  create('QB-13 rozmowa z obcym w participants', 'DENY', '/chats/u1_u2', U1, { ...chatFirst, participants: ['u1', 'x1'] }),
  create('rozmowa pod nieposortowanym id', 'DENY', '/chats/u2_u1', U1, { ...chatFirst, participants: ['u2', 'u1'] }),
  create('QB-20 rozmowa z samym sobą', 'DENY', '/chats/u1_u1', U1, { ...chatFirst, participants: ['u1', 'u1'], unread: {} }),
  update('QB-13 dowolny licznik rozmówcy', 'DENY', '/chats/u1_u2', U1, savedChat, { unread: { u1: 2, u2: 99 } }),
  update('QB-13 ustawienie sobie licznika ≠ 0', 'DENY', '/chats/u1_u2', U1, savedChat, { unread: { u1: 7, u2: 1 } }),
  update('QB-13 zmiana nazwy rozmówcy', 'DENY', '/chats/u1_u2', U1, savedChat, { names: { u1: 'Jan', u2: 'Oszust' } }),
  update('wrzucenie rozmówcy do kosza', 'DENY', '/chats/u1_u2', U1, { ...savedChat, hiddenFor: [] }, { hiddenFor: ['u2'] }),
  update('usunięcie rozmówcy z participants', 'DENY', '/chats/u1_u2', U1, savedChat, { participants: ['u1', 'x1'] }),
  update('nazwa jako liczba (wywraca listę rozmów)', 'DENY', '/chats/u1_u2', U1, savedChat, { names: { u1: 123, u2: 'Ola' } }),
  update('obcy zmienia rozmowę', 'DENY', '/chats/u1_u2', X, savedChat, { lastMessage: 'spam', lastTimestamp: NOW }),
  del('usunięcie rozmowy', 'DENY', '/chats/u1_u2', U1, savedChat),
  list('QB-01 nasłuch wiadomości przed powstaniem rozmowy', 'ALLOW', '/chats/u1_u2/messages/m1', U2, savedMsg),
  list('obcy czyta wiadomości', 'DENY', '/chats/u1_u2/messages/m1', X, savedMsg),
  list('anon czyta wiadomości', 'DENY', '/chats/u1_u2/messages/m1', ANON, savedMsg),
  create('uczestnik wysyła wiadomość', 'ALLOW', '/chats/u1_u2/messages/m1', U1, msg),
  create('QB-13 wiadomość podszyta pod rozmówcę', 'DENY', '/chats/u1_u2/messages/m1', U1, { ...msg, from: 'u2' }),
  create('wiadomość z dodatkowym polem', 'DENY', '/chats/u1_u2/messages/m1', U1, { ...msg, pinned: true }),
  create('wiadomość od razu przeczytana', 'DENY', '/chats/u1_u2/messages/m1', U1, { ...msg, read: true }),
  create('pusta wiadomość', 'DENY', '/chats/u1_u2/messages/m1', U1, { ...msg, content: '' }),
  create('obcy pisze do rozmowy', 'DENY', '/chats/u1_u2/messages/m1', X, { ...msg, from: 'x1' }),
  update('odbiorca oznacza przeczytane', 'ALLOW', '/chats/u1_u2/messages/m1', U2, savedMsg, { read: true }),
  update('QB-13 autor edytuje treść', 'DENY', '/chats/u1_u2/messages/m1', U1, savedMsg, { content: 'zmienione' }),
  update('QB-13 odbiorca edytuje cudzą treść', 'DENY', '/chats/u1_u2/messages/m1', U2, savedMsg, { content: 'zmienione', read: true }),
  update('autor oznacza swoją jako przeczytaną', 'DENY', '/chats/u1_u2/messages/m1', U1, savedMsg, { read: true }),
  del('usunięcie wiadomości', 'DENY', '/chats/u1_u2/messages/m1', U1, savedMsg),

  // ── realizations ──
  list('user czyta realizacje firmy', 'ALLOW', '/realizations/z1', U1, savedRealization),
  create('K7 firma dodaje zdjęcia realizacji', 'ALLOW', '/realizations/z1', C1, realization, [parentReq(reqTaken)]),
  create('klient dodaje własne zdjęcia', 'ALLOW', '/realizations/z1', U1, ownPhoto, [parentReq(reqTaken)]),
  create('QB-73 obcy wstrzykuje zatwierdzone zdjęcie do portfolio', 'DENY', '/realizations/z1', X, { ...ownPhoto, userId: 'x1' }, [parentReq(reqTaken)]),
  create('QB-73 firma dodaje od razu zatwierdzone', 'DENY', '/realizations/z1', C1, { ...realization, status: 'approved' }, [parentReq(reqTaken)]),
  create('QB-73 firma dodaje zdjęcia do nie swojego zlecenia', 'DENY', '/realizations/z1', C2, { ...realization, companyId: 'c2' }, [parentReq(reqTaken)]),
  create('QB-73 zdjęcia do zgłoszenia nieprzejętego', 'DENY', '/realizations/z1', C1, realization, [parentReq(reqOpen)]),
  create('QB-73 zdjęcia z publishedByCompany = true', 'DENY', '/realizations/z1', U1, { ...ownPhoto, publishedByCompany: true }, [parentReq(reqTaken)]),
  update('klient potwierdza zdjęcia firmy', 'ALLOW', '/realizations/z1', U1, savedRealization, { status: 'approved', decidedAt: NOW }),
  update('klient odrzuca zdjęcia firmy', 'ALLOW', '/realizations/z1', U1, savedRealization, { status: 'rejected', decidedAt: NOW }),
  update('klient „potwierdza” zdjęcia już odrzucone', 'DENY', '/realizations/z1', U1, { ...savedRealization, status: 'rejected' }, { status: 'approved', decidedAt: NOW }),
  update('klient podmienia zdjęcie', 'DENY', '/realizations/z1', U1, savedRealization, { imageUrl: 'https://evil' }),
  update('firma publikuje zdjęcia klienta', 'ALLOW', '/realizations/z1', C1, savedOwnPhoto, { publishedByCompany: true }),
  update('firma sama zatwierdza swoje zdjęcia', 'DENY', '/realizations/z1', C1, savedRealization, { status: 'approved' }),
  del('firma usuwa swoje zdjęcia', 'ALLOW', '/realizations/z1', C1, savedRealization),
  del('klient (odblokowanie) usuwa zdjęcia firmy', 'ALLOW', '/realizations/z1', U1, savedRealization),
  del('obcy usuwa realizację', 'DENY', '/realizations/z1', X, savedRealization),

  // ── notifications ──
  list('dzwonek: moje wpisy', 'ALLOW', '/notifications/n1', U1, notif),
  get('obcy czyta wpis', 'DENY', '/notifications/n1', X, notif),
  update('oznaczenie przeczytanego', 'ALLOW', '/notifications/chat_u1_u2', U1, notif, { read: true }),
  fsCase('K2 oznaczenie nieistniejącego wpisu (serwer zwróci NOT_FOUND)', 'ALLOW', 'update', '/notifications/chat_u1_u2', U1, { after: { read: true } }),
  update('zmiana treści wpisu', 'DENY', '/notifications/n1', U1, notif, { read: true, title: 'x' }),
  update('obcy oznacza cudzy wpis', 'DENY', '/notifications/n1', X, notif, { read: true }),
  create('klient tworzy wpis', 'DENY', '/notifications/n1', U1, notif),
  del('usunięcie swojego wpisu', 'ALLOW', '/notifications/n1', U1, notif),
  del('usunięcie cudzego wpisu', 'DENY', '/notifications/n1', X, notif),

  // ── reviewReminders (tylko Cloud Functions) ──
  get('odczyt przypomnień', 'DENY', '/reviewReminders/req_r1', U1, { userId: 'u1' }),
  create('zapis przypomnień', 'DENY', '/reviewReminders/req_r1', U1, { userId: 'u1' }),
];

// ── Storage ──
const object = (size, contentType) => ({ name: 'x', bucket: BUCKET, size, contentType, metadata: {} });
const stCase = (name, expectation, method, path, a, { before, after } = {}) => ({
  name, expectation,
  request: { auth: a, path: `/b/${BUCKET}/o/${path}`, method, time: NOW, ...(after ? { resource: after } : {}) },
  ...(before ? { resource: before } : {}),
});
const storageCases = [
  stCase('anon ogląda film prezentacji', 'ALLOW', 'get', 'files/c1/1.mp4', ANON, { before: object(50 * MB, 'video/mp4') }),
  stCase('anon ogląda stary plik (ścieżka bez uid)', 'ALLOW', 'get', 'files/vidc1.mp4', ANON, { before: object(50 * MB, 'video/mp4') }),
  stCase('listowanie plików', 'DENY', 'list', 'files/c1', U1),
  stCase('K8 film zgłoszenia/prezentacji', 'ALLOW', 'create', 'files/c1/1700000000000.mp4', C1, { after: object(150 * MB, 'video/mp4') }),
  stCase('K8 zdjęcie zgłoszenia', 'ALLOW', 'create', 'files/u1/1700000000000.heic', U1, { after: object(12 * MB, 'image/heic') }),
  stCase('K8 miniatura', 'ALLOW', 'create', 'thumbs/u1/1700000000000.jpg', U1, { after: object(300 * 1024, 'image/jpeg') }),
  stCase('K8 zdjęcie realizacji (Przed)', 'ALLOW', 'create', 'realizations/c1/1700000000000_before.jpg', C1, { after: object(8 * MB, 'image/jpeg') }),
  stCase('K8 klient dodaje własne zdjęcie realizacji', 'ALLOW', 'create', 'realizations/u1/1700000000000.png', U1, { after: object(3 * MB, 'image/png') }),
  stCase('QB-70 upload pod cudzy uid', 'DENY', 'create', 'files/c1/evil.mp4', X, { after: object(MB, 'video/mp4') }),
  stCase('QB-70 film 300 MB', 'DENY', 'create', 'files/c1/big.mp4', C1, { after: object(300 * MB, 'video/mp4') }),
  stCase('QB-70 zdjęcie 30 MB', 'DENY', 'create', 'files/u1/big.jpg', U1, { after: object(30 * MB, 'image/jpeg') }),
  stCase('QB-70 strona HTML', 'DENY', 'create', 'files/u1/x.html', U1, { after: object(1024, 'text/html') }),
  stCase('QB-70 film jako miniatura', 'DENY', 'create', 'thumbs/u1/x.mp4', U1, { after: object(MB, 'video/mp4') }),
  stCase('QB-70 film jako realizacja', 'DENY', 'create', 'realizations/u1/x.mp4', U1, { after: object(MB, 'video/mp4') }),
  stCase('QB-70 dowolny katalog (hosting plików)', 'DENY', 'create', 'cokolwiek/x1/film.bin', X, { after: object(MB, 'application/octet-stream') }),
  stCase('QB-70 stara ścieżka bez uid', 'DENY', 'create', 'files/evil.mp4', X, { after: object(MB, 'video/mp4') }),
  stCase('QB-70 nadpisanie cudzego pliku', 'DENY', 'update', 'files/c1/1.mp4', X, { before: object(50 * MB, 'video/mp4'), after: object(MB, 'video/mp4') }),
  stCase('nadpisanie własnego pliku', 'DENY', 'update', 'files/c1/1.mp4', C1, { before: object(50 * MB, 'video/mp4'), after: object(MB, 'video/mp4') }),
  stCase('QB-70 nadpisanie starego pliku bez uid', 'DENY', 'update', 'files/vidc1.mp4', X, { before: object(50 * MB, 'video/mp4'), after: object(MB, 'video/mp4') }),
  stCase('właściciel usuwa swój plik', 'ALLOW', 'delete', 'files/c1/1.mp4', C1, { before: object(50 * MB, 'video/mp4') }),
  stCase('QB-70 usunięcie cudzego pliku', 'DENY', 'delete', 'files/c1/1.mp4', X, { before: object(50 * MB, 'video/mp4') }),
  stCase('QB-70 usunięcie starego pliku bez uid', 'DENY', 'delete', 'thumbs/vidc1.jpg', X, { before: object(MB, 'image/jpeg') }),
  stCase('anon wgrywa pod własny uid', 'DENY', 'create', 'files/anon1/x.mp4', ANON, { after: object(MB, 'video/mp4') }),
];

// ── RTDB: lokalny ewaluator kaskady (.read/.write na ścieżce albo przodku, .validate na zapisanych węzłach) ──
const rtdbRules = JSON.parse(fs.readFileSync('../../database.rules.json', 'utf8')).rules;
const newData = (v) => ({
  val: () => v, exists: () => v !== null && v !== undefined,
  isBoolean: () => typeof v === 'boolean', isNumber: () => typeof v === 'number', isString: () => typeof v === 'string',
});
function rtdbExpr(expr, vars, a, value) {
  if (typeof expr === 'boolean') return expr;
  const names = Object.keys(vars);
  try {
    return !!new Function('auth', 'newData', ...names, `return (${expr.replace(/\.beginsWith\(/g, '.startsWith(')});`)(
      a, newData(value), ...names.map((n) => vars[n]));
  } catch (_) {
    return false;
  }
}
const childRule = (node, key, vars) => {
  if (node[key] !== undefined) return node[key];
  const wild = Object.keys(node).find((k) => k.startsWith('$'));
  if (!wild) return undefined;
  vars[wild] = key;
  return node[wild];
};
function rtdbValid(node, vars, a, value) {
  if (value === null || value === undefined) return true;
  if (node['.validate'] !== undefined && !rtdbExpr(node['.validate'], vars, a, value)) return false;
  if (typeof value !== 'object') return true;
  return Object.entries(value).every(([k, v]) => {
    const vs = { ...vars };
    const child = childRule(node, k, vs);
    return child === undefined || rtdbValid(child, vs, a, v);
  });
}
function rtdbCheck(kind, path, a, value) {
  let node = rtdbRules;
  const vars = {};
  let allowed = rtdbExpr(node['.' + kind] ?? false, vars, a, value);
  for (const seg of path.split('/').filter(Boolean)) {
    node = node && childRule(node, seg, vars);
    if (!node) break;
    if (!allowed && node['.' + kind] !== undefined) allowed = rtdbExpr(node['.' + kind], vars, a, value);
  }
  if (allowed && kind === 'write') allowed = node ? rtdbValid(node, vars, a, value) : true;
  return allowed ? 'ALLOW' : 'DENY';
}
const UA = auth('uA'), UB = auth('uB'), UC = auth('uC'), ANON_RT = auth('anonX', 'anonymous');
const rtdbCases = [
  ['getUserStatus: status rozmówcy', 'ALLOW', 'read', 'users/uB', UA],
  ['anon czyta status', 'DENY', 'read', 'users/uB', ANON_RT],
  ['QB-15 odczyt całego /users', 'DENY', 'read', 'users', UA],
  ['odczyt korzenia', 'DENY', 'read', '', UA],
  ['K3 obecność: online + last_seen', 'ALLOW', 'write', 'users/uA', UA, { online: true, last_seen: 1760263200000 }],
  ['K3 onDisconnect: online=false', 'ALLOW', 'write', 'users/uA', UA, { online: false, last_seen: 1760263200000 }],
  ['zapis statusu za kogoś', 'DENY', 'write', 'users/uB', UA, { online: false, last_seen: 1 }],
  ['anon zapisuje status', 'DENY', 'write', 'users/anonX', ANON_RT, { online: true, last_seen: 1 }],
  ['śmieci w węźle statusu', 'DENY', 'write', 'users/uA', UA, { online: true, last_seen: 1, notatka: 'x' }],
  ['online jako tekst', 'DENY', 'write', 'users/uA', UA, { online: 'tak', last_seen: 1 }],
  ['typingStream: rozmówca pisze', 'ALLOW', 'read', 'typing/uA_uB/uB', UA],
  ['typingStream druga strona', 'ALLOW', 'read', 'typing/uA_uB/uA', UB],
  ['QB-15 obcy czyta pisanie w cudzej rozmowie', 'DENY', 'read', 'typing/uA_uB/uB', UC],
  ['QB-15 obcy czyta całe /typing', 'DENY', 'read', 'typing', UC],
  ['anon czyta pisanie', 'DENY', 'read', 'typing/uA_uB/uB', ANON_RT],
  ['setTyping(true)', 'ALLOW', 'write', 'typing/uA_uB/uA', UA, true],
  ['setTyping(false) = remove', 'ALLOW', 'write', 'typing/uA_uB/uA', UA, null],
  ['QB-15 obcy pisze w cudzej rozmowie', 'DENY', 'write', 'typing/uA_uB/uC', UC, true],
  ['pisanie za rozmówcę', 'DENY', 'write', 'typing/uA_uB/uB', UA, true],
  ['pisanie: wartość nie-bool', 'DENY', 'write', 'typing/uA_uB/uA', UA, 'x'],
  ['id rozmowy tylko z prefiksem uid', 'DENY', 'read', 'typing/uAx_uB/uB', UA],
];

async function runApi(token, file, source, cases) {
  const out = [];
  for (let i = 0; i < cases.length; i += 50) {
    const part = cases.slice(i, i + 50);
    const r = await fetch('https://firebaserules.googleapis.com/v1/projects/qubdud-8f2b8:test', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        source: { files: [{ name: file, content: source }] },
        testSuite: { testCases: part.map(({ name, ...c }) => c) },
      }),
    });
    const j = await r.json();
    if (j.error) throw new Error(JSON.stringify(j.error));
    if (j.issues && j.issues.length) console.log('ISSUES:', JSON.stringify(j.issues, null, 1));
    (j.testResults || []).forEach((res, k) => out.push({
      name: part[k].name, expected: part[k].expectation, ok: res.state === 'SUCCESS',
      detail: JSON.stringify(res.debugMessages || res.errorPosition || res).slice(0, 300),
    }));
  }
  return out;
}

(async () => {
  const ga = new GoogleAuth({ keyFile: '../qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json',
    scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
  const token = (await (await ga.getClient()).getAccessToken()).token;
  const sections = [
    ['Firestore', await runApi(token, 'firestore.rules', fs.readFileSync('../../firestore.rules', 'utf8'), firestoreCases)],
    ['Storage', await runApi(token, 'storage.rules', fs.readFileSync('../../storage.rules', 'utf8'), storageCases)],
    ['RTDB', rtdbCases.map(([name, expected, kind, path, a, value]) => {
      const got = rtdbCheck(kind, path, a, value);
      return { name, expected, ok: got === expected, detail: got };
    })],
  ];
  let total = 0, fail = 0;
  for (const [title, results] of sections) {
    console.log(`\n── ${title} ──`);
    for (const r of results) {
      total++;
      if (!r.ok) fail++;
      console.log(`${r.ok ? 'OK  ' : 'FAIL'} [${r.expected}] ${r.name}${r.ok ? '' : '  → ' + r.detail}`);
    }
  }
  console.log(`\n${total - fail}/${total} testów przeszło`);
  process.exitCode = fail ? 1 : 0;
})().catch((e) => { console.error(e); process.exitCode = 2; });
