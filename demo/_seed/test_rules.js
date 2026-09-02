// Testy reguł Firestore przez Firebase Rules API (bez emulatora i bez deployu).
// Uruchom: node test_rules.js   (z demo/_seed)
const fs = require('fs');
const { GoogleAuth } = require('google-auth-library');

const DOC = '/databases/(default)/documents';
const auth = (uid, provider = 'password') => ({
  uid, token: { firebase: { sign_in_provider: provider } },
});
const ANON = auth('anon1', 'anonymous');
const U1 = auth('u1'), U2 = auth('u2'), C1 = auth('c1'), C2 = auth('c2');

const T = (name, expectation, method, path, a, extra = {}) => ({
  name, expectation,
  request: { auth: a, path: DOC + path, method, ...(extra.request || {}) },
  ...(extra.resource ? { resource: extra.resource } : {}),
  ...(extra.functionMocks ? { functionMocks: extra.functionMocks } : {}),
});

const cases = [
  // anonim: tylko promos
  T('anon czyta promo', 'ALLOW', 'get', '/promos/p1', ANON),
  T('anon czyta firmę', 'DENY', 'get', '/users/c1', ANON),
  T('anon listuje zgłoszenia', 'DENY', 'list', '/requests', ANON),
  T('anon czyta sloty', 'DENY', 'get', '/users/c1/slots/s1', ANON),
  T('anon czyta czat', 'DENY', 'get', '/chats/u1_u2', ANON),
  T('anon zwiększa views', 'DENY', 'update', '/promos/p1', ANON,
    { resource: { data: { userId: 'c1', views: 1 } }, request: { resource: { data: { userId: 'c1', views: 2 } } } }),
  // zalogowany
  T('user czyta firmę', 'ALLOW', 'get', '/users/c1', U1),
  T('user edytuje cudzy profil', 'DENY', 'update', '/users/c1', U1,
    { resource: { data: { firstName: 'A' } }, request: { resource: { data: { firstName: 'B' } } } }),
  T('user edytuje własny profil', 'ALLOW', 'update', '/users/u1', U1,
    { resource: { data: { firstName: 'A' } }, request: { resource: { data: { firstName: 'B' } } } }),
  T('user zwiększa views cudzego promo', 'ALLOW', 'update', '/promos/p1', U1,
    { resource: { data: { userId: 'c1', views: 1 } }, request: { resource: { data: { userId: 'c1', views: 2 } } } }),
  T('user zmienia opis cudzego promo', 'DENY', 'update', '/promos/p1', U1,
    { resource: { data: { userId: 'c1', description: 'x' } }, request: { resource: { data: { userId: 'c1', description: 'y' } } } }),
  // sloty
  T('user rezerwuje wolny slot', 'ALLOW', 'update', '/users/c1/slots/s1', U1,
    { resource: { data: { status: 'free' } }, request: { resource: { data: { status: 'pending', bookedBy: 'u1' } } } }),
  T('user odwołuje swój slot', 'ALLOW', 'update', '/users/c1/slots/s1', U1,
    { resource: { data: { status: 'pending', bookedBy: 'u1' } }, request: { resource: { data: { status: 'free', bookedBy: '' } } } }),
  T('user2 rusza cudzą rezerwację', 'DENY', 'update', '/users/c1/slots/s1', U2,
    { resource: { data: { status: 'pending', bookedBy: 'u1' } }, request: { resource: { data: { status: 'accepted', bookedBy: 'u1' } } } }),
  T('firma akceptuje slot', 'ALLOW', 'update', '/users/c1/slots/s1', C1,
    { resource: { data: { status: 'pending', bookedBy: 'u1' } }, request: { resource: { data: { status: 'accepted', bookedBy: 'u1' } } } }),
  T('user dodaje slot cudzej firmie', 'DENY', 'create', '/users/c1/slots/s9', U1,
    { request: { resource: { data: { status: 'free' } } } }),
  // relacje
  T('klient czyta swój wpis u firmy', 'ALLOW', 'get', '/users/c1/clients/u1', U1),
  T('klient czyta cudzy wpis u firmy', 'DENY', 'get', '/users/c1/clients/u9', U1),
  T('firma czyta listę klientów', 'ALLOW', 'list', '/users/c1/clients/anyDoc', C1),
  T('user czyta cudze notatki', 'DENY', 'get', '/users/c1/clientNotes/u1', U1),
  // zgłoszenia i oferty
  T('user tworzy zgłoszenie', 'ALLOW', 'create', '/requests/r1', U1,
    { request: { resource: { data: { userId: 'u1' } } } }),
  T('user tworzy zgłoszenie na kogoś', 'DENY', 'create', '/requests/r1', U1,
    { request: { resource: { data: { userId: 'u2' } } } }),
  T('firma składa ofertę', 'ALLOW', 'create', '/requests/r1/offers/c1', C1,
    { request: { resource: { data: { companyId: 'c1', status: 'pending' } } } }),
  T('firma składa ofertę jako inna firma', 'DENY', 'create', '/requests/r1/offers/c1', C2,
    { request: { resource: { data: { companyId: 'c1', status: 'pending' } } } }),
  T('właściciel zgłoszenia akceptuje ofertę', 'ALLOW', 'update', '/requests/r1/offers/c1', U1, {
    resource: { data: { status: 'pending' } },
    request: { resource: { data: { status: 'accepted' } } },
    functionMocks: [{ function: 'get', args: [{ exactValue: DOC + '/requests/r1' }],
      result: { value: { data: { userId: 'u1' } } } }],
  }),
  T('obcy user akceptuje ofertę', 'DENY', 'update', '/requests/r1/offers/c1', U2, {
    resource: { data: { status: 'pending' } },
    request: { resource: { data: { status: 'accepted' } } },
    functionMocks: [{ function: 'get', args: [{ exactValue: DOC + '/requests/r1' }],
      result: { value: { data: { userId: 'u1' } } } }],
  }),
  // czat
  T('uczestnik czyta czat', 'ALLOW', 'get', '/chats/u1_u2', U1,
    { resource: { data: { participants: ['u1', 'u2'] } } }),
  T('obcy czyta czat', 'DENY', 'get', '/chats/u1_u2', C1,
    { resource: { data: { participants: ['u1', 'u2'] } } }),
  T('uczestnik pisze wiadomość', 'ALLOW', 'create', '/chats/u1_u2/messages/m1', U1, {
    request: { resource: { data: { from: 'u1', content: 'hej' } } },
    functionMocks: [{ function: 'get', args: [{ exactValue: DOC + '/chats/u1_u2' }],
      result: { value: { data: { participants: ['u1', 'u2'] } } } }],
  }),
  T('obcy pisze wiadomość', 'DENY', 'create', '/chats/u1_u2/messages/m1', C1, {
    request: { resource: { data: { from: 'c1', content: 'hej' } } },
    functionMocks: [{ function: 'get', args: [{ exactValue: DOC + '/chats/u1_u2' }],
      result: { value: { data: { participants: ['u1', 'u2'] } } } }],
  }),
  // recenzje / realizacje / cron
  T('user dodaje recenzję', 'ALLOW', 'create', '/reviews/rv1', U1,
    { request: { resource: { data: { userId: 'u1', reviewedUserId: 'c1' } } } }),
  T('user kasuje cudzą recenzję', 'DENY', 'delete', '/reviews/rv1', U2,
    { resource: { data: { userId: 'u1' } } }),
  T('firma dodaje realizację', 'ALLOW', 'create', '/realizations/x1', C1,
    { request: { resource: { data: { companyId: 'c1' } } } }),
  T('user czyta reviewReminders', 'DENY', 'get', '/reviewReminders/x', U1),
];

(async () => {
  const ga = new GoogleAuth({ keyFile: '../qubdud-8f2b8-firebase-adminsdk-fbsvc-9af9e72f1b.json',
    scopes: ['https://www.googleapis.com/auth/cloud-platform'] });
  const token = (await (await ga.getClient()).getAccessToken()).token;
  const source = fs.readFileSync('../../firestore.rules', 'utf8');
  const r = await fetch('https://firebaserules.googleapis.com/v1/projects/qubdud-8f2b8:test', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + token, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      source: { files: [{ name: 'firestore.rules', content: source }] },
      testSuite: { testCases: cases.map(({ name, ...c }) => c) },
    }),
  });
  const j = await r.json();
  if (j.issues && j.issues.length) { console.log('ISSUES:', JSON.stringify(j.issues, null, 1)); }
  const results = j.testResults || [];
  let fail = 0;
  results.forEach((res, i) => {
    const ok = res.state === 'SUCCESS';
    if (!ok) fail++;
    console.log((ok ? 'OK   ' : 'FAIL ') + cases[i].name + (ok ? '' : '  → ' + JSON.stringify(res.debugMessages || res.errorPosition || res).slice(0, 200)));
  });
  console.log(`\n${results.length - fail}/${results.length} testów przeszło`);
  process.exit(fail ? 1 : 0);
})().catch((e) => { console.error(e); process.exit(2); });
