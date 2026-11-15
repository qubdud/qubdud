// Powiadomienia push QUBDUD — Cloud Functions v2 (Firestore triggers + cron + callable).
// Region = lokalizacja bazy Firestore (europe-central2).
const { onDocumentCreated, onDocumentUpdated, onDocumentWritten, onDocumentDeleted } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getDatabase } = require('firebase-admin/database');
const { getAuth } = require('firebase-admin/auth');
const { getStorage } = require('firebase-admin/storage');

setGlobalOptions({ region: 'europe-central2', maxInstances: 5 });
initializeApp();
const db = getFirestore();

const URGENT_RADIUS_KM = 30;
const NEW_REQUEST_RADIUS_KM = 30;
const REQUEST_TTL_DAYS = 10;        // po tylu dniach otwarte zgłoszenie zamyka się samo
const REVIEW_AFTER_BOOKING_H = 2;   // po zakończonym terminie
const REVIEW_AFTER_JOB_H = 2;       // po potwierdzonej realizacji
const ONLINE_FRESH_MS = 5 * 60e3;   // apka odświeża last_seen co 3 min
const PENDING_TTL_MS = 60 * 60e3;   // żółta rezerwacja bez decyzji firmy wygasa (jak w apce)
const BATCH_MAX = 400;
const BOOKED = ['pending', 'accepted'];
const DEAD_TOKEN = ['messaging/registration-token-not-registered', 'messaging/invalid-registration-token'];
const DELETED_NAME = 'Konto usunięte';

// ── narzędzia ────────────────────────────────────────────────────────────────
function kmBetween(a, b) {
  const R = 6371;
  const dLat = (b.lat - a.lat) * Math.PI / 180;
  const dLng = (b.lng - a.lng) * Math.PI / 180;
  const s = Math.sin(dLat / 2) ** 2
    + Math.cos(a.lat * Math.PI / 180) * Math.cos(b.lat * Math.PI / 180) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(s));
}

const short = (s, n = 90) => {
  const t = String(s || '').replace(/\s+/g, ' ').trim();
  return t.length > n ? t.slice(0, n - 1) + '…' : t;
};

const fmtWhen = (ts) => {
  if (!ts) return '';
  const d = ts.toDate ? ts.toDate() : new Date(ts);
  return d.toLocaleString('pl-PL', {
    timeZone: 'Europe/Warsaw', weekday: 'short', day: 'numeric', month: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
};

/** Zapisy partiami po ≤ BATCH_MAX; op = (batch) => batch.update/delete/set(...). */
async function commitAll(ops) {
  for (let i = 0; i < ops.length; i += BATCH_MAX) {
    const batch = db.batch();
    ops.slice(i, i + BATCH_MAX).forEach((op) => op(batch));
    await batch.commit();
  }
}

/** Wpis do dzwonka w apce (bez pushu). Zwraca id wpisu ('' przy błędzie). */
async function logNotification(uid, { title, body, data = {} }, docId) {
  if (!uid) return '';
  const col = db.collection('notifications');
  const ref = docId ? col.doc(docId) : col.doc();
  try {
    await ref.set({
      userId: uid,
      title,
      body,
      type: data.type || 'info',
      // 'company' = widoczne w trybie firmowym, 'user' = w trybie klienta,
      // 'both' = zawsze (np. rozmowy)
      audience: data.audience || 'both',
      requestId: data.requestId || '',
      companyId: data.companyId || '',
      from: data.senderId || '',
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return ref.id;
  } catch (e) {
    console.error('notification write failed', e);
    return '';
  }
}

/** Powiadomienie: wpis w bazie (dzwonek w apce) + push na urządzenia. */
async function pushTo(uid, payload, notifDocId) {
  if (!uid) return;
  const notifId = await logNotification(uid, payload, notifDocId);
  try {
    const ref = db.collection('users').doc(uid);
    const pushRef = ref.collection('private').doc('push');
    const [user, push] = await Promise.all([ref.get(), pushRef.get()]);
    // EXPIRES (pole users.fcmTokens): po migrate_fcm_tokens.js --apply
    const legacy = (user.data() || {}).fcmTokens || [];
    const tokens = [...new Set([...((push.data() || {}).fcmTokens || []), ...legacy])];
    if (!tokens.length) return;

    // 'from' jest zarezerwowane przez FCM — nadawca idzie jako 'senderId'
    const data = { ...payload.data, ...(notifId && { notifId }) };
    // ten sam wątek zastępuje poprzedni push: zwiniętej grupy Android nie otwiera z danymi
    const tag = data.type === 'chat' && data.senderId ? `chat_${data.senderId}`
      : data.requestId ? `req_${data.requestId}`
      : data.slotId ? `slot_${data.slotId}`
      : data.type || 'info';
    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: payload.title, body: payload.body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high', notification: { sound: 'default', tag } },
      apns: { payload: { aps: { sound: 'default', badge: 1 } } },
    });

    const dead = [];
    const errors = {};
    res.responses.forEach((r, i) => {
      const code = r.error && r.error.code;
      if (!code) return;
      if (DEAD_TOKEN.includes(code)) dead.push(tokens[i]);
      else errors[code] = r.error.message;
    });
    if (dead.length) {
      await Promise.all([
        push.exists && pushRef.update({ fcmTokens: FieldValue.arrayRemove(...dead) }),
        legacy.some((t) => dead.includes(t)) && ref.update({ fcmTokens: FieldValue.arrayRemove(...dead) }),
      ]);
    }
    console.log(`push → ${uid}: ok=${res.successCount} fail=${res.failureCount}`
      + (dead.length ? ` (usunięto ${dead.length} martwych tokenów)` : '') + ` | ${payload.title}`);
    if (Object.keys(errors).length) console.error(`push → ${uid}: błędy FCM ${JSON.stringify(errors)}`);
  } catch (e) {
    console.error(`push → ${uid} nieudany | ${payload.title}`, e);
  }
}

const personName = (d) => `${d.firstName || ''} ${d.lastName || ''}`.trim() || 'Użytkownik';

/** Ścieżka pliku w Storage z download URL, o ile leży pod {folder}/{uid}/ (K8). */
function ownFilePath(url, uid) {
  const m = /\/o\/([^?]+)/.exec(url || '');
  const path = m ? decodeURIComponent(m[1]) : '';
  return uid && /^(files|thumbs|realizations)\//.test(path) && path.split('/')[1] === uid ? path : '';
}

/** Kasuje pliki właściciela; pliki spoza jego ścieżek (np. współdzielone z seedów) zostają. */
async function deleteOwnFiles(uid, urls) {
  const bucket = getStorage().bucket();
  await Promise.all(urls.map((u) => ownFilePath(u, uid)).filter(Boolean)
    .map((path) => bucket.file(path).delete({ ignoreNotFound: true })));
}

async function userName(uid) {
  const d = (await db.collection('users').doc(uid).get()).data() || {};
  return d.companyName || `${d.firstName || ''} ${d.lastName || ''}`.trim() || 'Użytkownik';
}

async function hasReview(userId, companyId) {
  const q = await db.collection('reviews')
    .where('userId', '==', userId)
    .where('reviewedUserId', '==', companyId)
    .limit(1).get();
  return !q.empty;
}

/** Czy klient nadal może wystawić recenzję — te same warunki co canReviewCompany w apce. */
async function reviewAllowed(reminderId, r) {
  if (reminderId.startsWith('slot_')) {
    const b = (await db.doc(`users/${r.userId}/myBookings/${r.companyId}_${reminderId.slice(5)}`).get()).data();
    return !!b && b.status === 'accepted';
  }
  const q = (await db.doc(`requests/${reminderId.slice(4)}`).get()).data();
  return !!q && q.userId === r.userId && q.takenBy === r.companyId && q.realizationStatus === 'approved';
}

/** Klient traci rezerwację: wygasła, firma ją odrzuciła albo odwołała termin. */
async function notifyBookingLost(client, companyId, when, status, company) {
  const [title, tail] = {
    expired: ['Rezerwacja wygasła', 'firma nie potwierdziła jej na czas. Wybierz inny termin.'],
    rejected: ['Firma odrzuciła rezerwację', 'wybierz inny termin.'],
    cancelled: ['Firma odwołała termin', 'wybierz inny termin.'],
  }[status];
  await pushTo(client, {
    title,
    body: `${company || await userName(companyId)} · ${when} – ${tail}`,
    data: { type: 'booking_decision', companyId, status, audience: 'user' },
  });
}

// ── 1) nowe zgłoszenie → firmy z tej samej branży w promieniu ────────────────
// Pilne (is24) z czerwonym tytułem; zablokowani w którąkolwiek stronę nie dostają pusha.
exports.notifyUrgentRequest = onDocumentCreated('requests/{id}', async (event) => {
  const d = event.data && event.data.data();
  if (!d || !d.userId || !d.sector || !d.location || typeof d.location.lat !== 'number') return;
  const urgent = d.is24 === true;

  const [firms, clientBlocked] = await Promise.all([
    db.collection('users')
      .where('firma', '==', true)
      .where('companyCategory', '==', d.category)
      .where('companySector', '==', d.sector)
      .get(),
    db.collection('users').doc(d.userId).collection('blocked').get(),
  ]);
  const skip = new Set(clientBlocked.docs.map((b) => b.id));

  const text = `${d.city ? d.city + ': ' : ''}${short(d.description)}`;
  console.log(`zgłoszenie ${event.params.id}${urgent ? ' (pilne)' : ''}: ${d.category}/${d.sector}, firm w branży: ${firms.size}`);
  const jobs = [];
  for (const f of firms.docs) {
    if (f.id === d.userId || skip.has(f.id)) continue;
    const loc = f.data().companyLocation;
    if (!loc || typeof loc.lat !== 'number') continue;
    const km = kmBetween(d.location, loc);
    if (km > (urgent ? URGENT_RADIUS_KM : NEW_REQUEST_RADIUS_KM)) continue;
    jobs.push((async () => {
      if ((await f.ref.collection('blocked').doc(d.userId).get()).exists) return;
      await pushTo(f.id, {
        title: `${urgent ? '🔴 Pilne zgłoszenie' : '🆕 Nowe zgłoszenie'}: ${d.sector}`,
        body: `${Math.max(1, Math.round(km))} km · ${text}`,
        data: { type: urgent ? 'urgent_request' : 'new_request', requestId: event.params.id, audience: 'company' },
      });
    })());
  }
  await Promise.all(jobs);
});

// ── 1b) dokładne miejsce zgłoszenia → requests/{id}/private/location ────────
// Nowa apka sama zapisuje okolicę i private; starsze APK piszą dokładne location.
// Siatka 0,01° — to samo zaokrąglenie co approxLocation w apce.
const approx = (v) => Math.round(v * 100) / 100;
exports.hideRequestLocation = onDocumentCreated({ document: 'requests/{id}', retry: true }, async (event) => {
  const ref = event.data && event.data.ref;
  if (!ref) return;
  const priv = ref.collection('private').doc('location');
  await db.runTransaction(async (tx) => {
    const [cur, p] = await Promise.all([tx.get(ref), tx.get(priv)]);
    const l = cur.exists && cur.get('location');
    if (!l || typeof l.lat !== 'number' || typeof l.lng !== 'number') return;
    if (!p.exists) tx.set(priv, { lat: l.lat, lng: l.lng });
    const near = { lat: approx(l.lat), lng: approx(l.lng) };
    if (near.lat !== l.lat || near.lng !== l.lng) tx.update(ref, { location: near });
  });
});

// ── 2) nowa oferta → właściciel zgłoszenia ──────────────────────────────────
exports.notifyNewOffer = onDocumentCreated('requests/{id}/offers/{companyId}', async (event) => {
  const offer = event.data && event.data.data();
  if (!offer) return;
  const req = (await db.collection('requests').doc(event.params.id).get()).data();
  if (!req) return;
  const price = Number.isInteger(offer.price)
    ? (Number.isInteger(offer.priceTo) ? `${offer.price}–${offer.priceTo} zł` : `${offer.price} zł`)
    : '';
  await pushTo(req.userId, {
    title: `Nowa oferta: ${offer.companyName || 'firma'}`,
    body: price ? `${price} · ${short(offer.message, 80)}` : short(offer.message, 100),
    data: { type: 'offer', requestId: event.params.id, audience: 'user' },
  });
});

// ── 3) decyzja klienta o ofercie → firma ────────────────────────────────────
// 'closed' ustawia apka pozostałym ofertom przy akceptacji jednej z nich.
exports.notifyOfferDecision = onDocumentUpdated('requests/{id}/offers/{companyId}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  if (before.status === after.status) return;

  const req = (await db.collection('requests').doc(event.params.id).get()).data() || {};
  const client = await userName(req.userId);
  const texts = {
    accepted: ['✅ Oferta przyjęta', `${client} wybrał Twoją ofertę. Skontaktuj się i ustal szczegóły.`],
    maybe: ['🤔 Klient się zastanawia', `${client} oznaczył Twoją ofertę jako „może". Warto dopytać.`],
    rejected: ['Oferta odrzucona', `${client} odrzucił Twoją ofertę.`],
    closed: ['Wybrano inną ofertę', `${client} wybrał inną ofertę.`],
  };
  // odblokowanie zlecenia przez klienta: przyjęta oferta wraca do 'pending'
  const reopened = before.status === 'accepted' && after.status === 'pending';
  const t = reopened
    ? ['Zlecenie wróciło do puli', `${client} odblokował zgłoszenie — Twoja oferta znów czeka na decyzję.`]
    : texts[after.status];
  if (!t) return;
  await pushTo(event.params.companyId, {
    title: t[0], body: t[1],
    data: {
      type: 'offer_decision', requestId: event.params.id,
      status: reopened ? 'reopened' : after.status, audience: 'company',
    },
  });
});

// ── 4) rezerwacje slotów ────────────────────────────────────────────────────
// Powrót terminu do puli zawsze niesie releasedBy: 'user' | 'expired' | 'rejected'.
exports.notifySlot = onDocumentUpdated('users/{companyId}/slots/{slotId}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  const { companyId, slotId } = event.params;
  // ten sam klient ponownie rezerwuje swoją wygasłą żółtą (nowy bookedAt)
  const rebooked = after.status === 'pending' && !!before.bookedAt && !!after.bookedAt
    && !before.bookedAt.isEqual(after.bookedAt);
  if (before.status === after.status && before.bookedBy === after.bookedBy && !rebooked) return;
  const when = fmtWhen(after.start);
  const wasBooked = BOOKED.includes(before.status) && !!before.bookedBy;
  // klient stracił termin (zwolnienie, przejęcie, dowolna zmiana statusu przez firmę) —
  // relacja nie może dalej dawać firmie dostępu do jego telefonu
  if (wasBooked && (after.bookedBy !== before.bookedBy || !BOOKED.includes(after.status))) {
    await unlinkSlot(companyId, before.bookedBy, slotId);
  }

  // ktoś kliknął kropkę (także przejęcie wygasłej żółtej rezerwacji)
  if (after.status === 'pending' && after.bookedBy) {
    if (wasBooked && before.bookedBy !== after.bookedBy) {
      await notifyBookingLost(before.bookedBy, companyId, when, 'expired');
    }
    await pushTo(companyId, {
      title: '📅 Nowa rezerwacja',
      body: `${after.bookedByName || 'Klient'} · ${when}. Potwierdź lub odrzuć w kalendarzu.`,
      data: { type: 'booking', slotId, audience: 'company' },
    });
    return;
  }

  if (after.status === 'accepted' && after.bookedBy) {
    const company = await userName(companyId);
    await pushTo(after.bookedBy, {
      title: '✅ Termin potwierdzony',
      body: `${company} · ${when}`,
      data: { type: 'booking_decision', companyId, status: 'accepted', audience: 'user' },
    });
    const startMs = after.start && after.start.toMillis ? after.start.toMillis() : Date.now();
    await db.collection('reviewReminders').doc(`slot_${slotId}`).set({
      userId: after.bookedBy,
      companyId,
      companyName: company,
      dueAt: Timestamp.fromMillis(startMs + REVIEW_AFTER_BOOKING_H * 3600e3),
      source: 'booking',
      sent: false,
    }, { merge: true });
    return;
  }

  // termin wrócił do puli
  if ((after.status || 'free') !== 'free' || !wasBooked) return;
  await db.collection('reviewReminders').doc(`slot_${slotId}`).delete();
  if (after.releasedBy === 'user') {
    await pushTo(companyId, {
      title: 'Klient odwołał rezerwację',
      body: `${before.bookedByName || 'Klient'} · ${when}. Termin wrócił do puli.`,
      data: { type: 'booking', slotId, status: 'cancelled', audience: 'company' },
    });
  } else if (after.releasedBy === 'expired' || after.releasedBy === 'rejected') {
    await notifyBookingLost(before.bookedBy, companyId, when, after.releasedBy);
  }
});

// cron: żółta rezerwacja bez decyzji firmy wraca do puli — klient dostaje
// „Rezerwacja wygasła” z notifySlot, także gdy nikt nie otworzył kalendarza
exports.expirePendingSlots = onSchedule({ schedule: 'every 15 minutes', timeZone: 'Europe/Warsaw' }, async () => {
  const stale = await db.collectionGroup('slots')
    .where('status', '==', 'pending')
    .where('bookedAt', '<=', Timestamp.fromMillis(Date.now() - PENDING_TTL_MS))
    .get();
  // warunek na wersję dokumentu: decyzja firmy w międzyczasie wygrywa
  const res = await Promise.allSettled(stale.docs.map((s) => s.ref.update({
    status: 'free', bookedBy: '', bookedByName: '', releasedBy: 'expired',
  }, { lastUpdateTime: s.updateTime })));
  const freed = res.filter((r) => r.status === 'fulfilled').length;
  if (stale.size) console.log(`expirePendingSlots: zwolniono ${freed}/${stale.size}`);
});

// ── 3c) przypomnienie o potwierdzonej wizycie: 24 h i 1 h przed ─────────────
// Znacznik visitReminders/{slot}_{klient}_{rodzaj} tworzony przed pushem: ponowne
// uruchomienie nie wyśle drugi raz. Termin zarezerwowany już w oknie przypomnienia
// (np. na dziś po południu) nie dostaje przypomnienia „jutro”.
const VISIT_REMINDERS = [
  { key: '1h', beforeMs: 3600e3 },
  { key: '24h', beforeMs: 24 * 3600e3 },
];
const plDay = (ms) => new Date(ms).toLocaleDateString('pl-PL', { timeZone: 'Europe/Warsaw' });
exports.remindVisits = onSchedule({ schedule: 'every 15 minutes', timeZone: 'Europe/Warsaw' }, async () => {
  const now = Date.now();
  const slots = await db.collectionGroup('slots')
    .where('status', '==', 'accepted')
    .where('start', '>', Timestamp.fromMillis(now))
    .where('start', '<=', Timestamp.fromMillis(now + 24 * 3600e3 + 8 * 60e3))
    .get();
  let sent = 0;
  for (const s of slots.docs) {
    const d = s.data();
    if (!d.bookedBy || !d.start || !d.start.toMillis) continue;
    const startMs = d.start.toMillis();
    // harmonogram co 15 min: przypomnienie z przebiegu najbliższego pełnej godzinie / dobie
    const r = VISIT_REMINDERS.find((x) => startMs - now <= x.beforeMs + 8 * 60e3);
    if (!r) continue;
    const bookedMs = d.bookedAt && d.bookedAt.toMillis ? d.bookedAt.toMillis() : 0;
    if (bookedMs > startMs - r.beforeMs) continue;
    const id = `${s.id}_${d.bookedBy}_${r.key}`;
    try {
      await db.collection('visitReminders').doc(id).create({
        startAt: d.start, slotId: s.id, userId: d.bookedBy, at: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e.code === 6) continue; // ALREADY_EXISTS — już wysłane
      throw e;
    }
    const companyId = s.ref.parent.parent.id;
    const when = fmtWhen(d.start);
    const title = r.key === '1h' ? '⏰ Za godzinę wizyta'
      : plDay(startMs) === plDay(now) ? '⏰ Dziś wizyta' : '⏰ Jutro wizyta';
    await Promise.all([
      pushTo(d.bookedBy, {
        title,
        body: `${await userName(companyId)} · ${when}`,
        data: { type: 'booking_reminder', companyId, slotId: s.id, audience: 'user' },
      }, `remind_${id}`),
      pushTo(companyId, {
        title,
        body: `${d.bookedByName || 'Klient'} · ${when}`,
        data: { type: 'booking_reminder', slotId: s.id, audience: 'company' },
      }, `remind_${id}_c`),
    ]);
    sent++;
  }
  const old = await db.collection('visitReminders')
    .where('startAt', '<', Timestamp.fromMillis(now - 2 * 24 * 3600e3)).limit(BATCH_MAX).get();
  await commitAll(old.docs.map((x) => (b) => b.delete(x.ref)));
  if (sent || old.size) console.log(`remindVisits: wysłano ${sent}, usunięto znaczników ${old.size}`);
});

exports.notifySlotDeleted = onDocumentDeleted('users/{companyId}/slots/{slotId}', async (event) => {
  const s = event.data && event.data.data();
  const { companyId, slotId } = event.params;
  // przeszłe terminy kasuje sprzątanie kalendarza — to nie odwołanie,
  // a przypomnienie o recenzji ma zostać
  if (!s || !BOOKED.includes(s.status) || !s.bookedBy || !s.start || s.start.toMillis() <= Date.now()) return;
  await unlinkSlot(companyId, s.bookedBy, slotId);
  await db.collection('reviewReminders').doc(`slot_${slotId}`).delete();
  // nazwa z kopii u klienta: przy usuwaniu konta firmy jej dokumentu może już nie być
  const copy = (await db.doc(`users/${s.bookedBy}/myBookings/${companyId}_${slotId}`).get()).data() || {};
  await notifyBookingLost(s.bookedBy, companyId, fmtWhen(s.start), 'cancelled', copy.companyName);
});

// ── 5) realizacje: firma dodała zdjęcia → klient; decyzja klienta → firma ──
exports.notifyRealizationAdded = onDocumentCreated('realizations/{id}', async (event) => {
  const d = event.data && event.data.data();
  if (!d || !d.userId || !d.companyId) return;

  // zdjęcia od klienta → firma decyduje, czy pokazać je na swoim profilu
  if (d.addedByRole === 'user') {
    const client = await userName(d.userId);
    await pushTo(d.companyId, {
      title: `📷 ${client} dodał zdjęcia z realizacji`,
      body: 'Możesz opublikować je w swoim portfolio.',
      data: { type: 'realization_from_user', requestId: d.requestId || '', audience: 'company' },
    });
    return;
  }

  if (d.status !== 'pending') return;
  const company = await userName(d.companyId);
  await pushTo(d.userId, {
    title: `📷 ${company} prosi o potwierdzenie realizacji`,
    body: 'Potwierdź wykonanie — zdjęcia trafią do portfolio firmy, a zgłoszenie zostanie zamknięte.',
    data: { type: 'realization', requestId: d.requestId || '', audience: 'user' },
  });
});

// dopiero potwierdzona realizacja pozwala klientowi wystawić recenzję
async function scheduleJobReview(requestId, userId, companyId) {
  const reminder = db.collection('reviewReminders').doc(`req_${requestId}`);
  if ((await reminder.get()).exists) return;
  await reminder.set({
    userId,
    companyId,
    companyName: await userName(companyId),
    dueAt: Timestamp.fromMillis(Date.now() + REVIEW_AFTER_JOB_H * 3600e3),
    source: 'request',
    sent: false,
  });
}

exports.notifyRealizationDecision = onDocumentUpdated('realizations/{id}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  if (before.status === after.status || !after.companyId) return;
  const client = await userName(after.userId);
  if (after.status === 'approved') {
    await pushTo(after.companyId, {
      title: '✅ Klient potwierdził realizację',
      body: `${client} potwierdził wykonanie — zdjęcia są już na Twoim profilu.`,
      data: { type: 'realization_decision', requestId: after.requestId || '', status: 'approved', audience: 'company' },
    });
    if (after.requestId) await scheduleJobReview(after.requestId, after.userId, after.companyId);
  } else if (after.status === 'rejected') {
    await pushTo(after.companyId, {
      title: 'Zdjęcia realizacji odrzucone',
      body: `${client} nie potwierdził zdjęć. Zlecenie jest nadal aktywne — dodaj właściwe zdjęcia.`,
      data: { type: 'realization_decision', requestId: after.requestId || '', status: 'rejected', audience: 'company' },
    });
  }
});

// ── 9b) zlecenie wykonane bez zdjęć: firma → prośba do klienta → decyzja do firmy ──
// Ze zdjęciami powiadamiają notifyRealizationAdded i notifyRealizationDecision.
exports.notifyJobDone = onDocumentUpdated('requests/{id}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  const status = after.realizationStatus || '';
  if ((before.realizationStatus || '') === status || !status || !after.takenBy) return;
  const id = event.params.id;
  const photos = await db.collection('realizations')
    .where('requestId', '==', id).where('companyId', '==', after.takenBy).limit(1).get();
  if (!photos.empty) return;
  const what = after.sector || after.category || 'zlecenie';
  if (status === 'pending') {
    const company = after.takenByName || await userName(after.takenBy);
    await pushTo(after.userId, {
      title: `✅ ${company} zakończył zlecenie`,
      body: `${what}: potwierdź wykonanie — zgłoszenie zostanie zamknięte.`,
      data: { type: 'realization', requestId: id, audience: 'user' },
    });
  } else if (status === 'approved') {
    const client = await userName(after.userId);
    await pushTo(after.takenBy, {
      title: '✅ Klient potwierdził wykonanie',
      body: `${client} · ${what}`,
      data: { type: 'realization_decision', requestId: id, status: 'approved', audience: 'company' },
    });
    await scheduleJobReview(id, after.userId, after.takenBy);
  } else if (status === 'rejected') {
    const client = await userName(after.userId);
    await pushTo(after.takenBy, {
      title: 'Klient nie potwierdził wykonania',
      body: `${client} · ${what}. Zlecenie jest nadal aktywne — ustalcie szczegóły na czacie.`,
      data: { type: 'realization_decision', requestId: id, status: 'rejected', audience: 'company' },
    });
  }
});

// ── 6) nowa wiadomość → odbiorca (o ile nie ma apki na wierzchu) ────────────
exports.notifyNewMessage = onDocumentCreated('chats/{chatId}/messages/{msgId}', async (event) => {
  const m = event.data && event.data.data();
  if (!m || !m.from) return;
  const chat = (await db.collection('chats').doc(event.params.chatId).get()).data();
  if (!chat) return;
  const to = (chat.participants || []).find((p) => p !== m.from);
  if (!to) return;
  const names = chat.names || {};
  const payload = {
    title: names[m.from] || 'Nowa wiadomość',
    body: short(m.content, 100),
    data: { type: 'chat', senderId: m.from, fromName: names[m.from] || '' },
  };
  // jeden wpis w dzwonku na rozmowę; apka oznacza go jako przeczytany przy czytaniu rozmowy
  const notifDocId = `chat_${to}_${m.from}`;

  let online = false;
  try {
    // „online" bywa nieaktualne (apka ubita bez onDisconnect) — ufamy mu,
    // dopóki heartbeat last_seen jest świeży
    const st = (await getDatabase().ref(`users/${to}`).get()).val() || {};
    online = st.online === true && typeof st.last_seen === 'number' && Date.now() - st.last_seen < ONLINE_FRESH_MS;
  } catch (_) { /* brak RTDB = wysyłamy push */ }

  if (online) {
    console.log(`chat → ${to}: online, tylko wpis w powiadomieniach`);
    await logNotification(to, payload, notifDocId);
  } else {
    await pushTo(to, payload, notifDocId);
  }
});

// ── 7) cron: otwarte zgłoszenia starsze niż 10 dni zamykają się same ────────
// Przyjęte (taken) nie wygasają — zlecenie trwa.
exports.autoCloseRequests = onSchedule(
  { schedule: 'every 24 hours', timeZone: 'Europe/Warsaw', timeoutSeconds: 540 },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - REQUEST_TTL_DAYS * 86400e3);
    // zamknięte wypadają z zapytania, więc każda kolejna strona to następne otwarte
    const nextPage = () => db.collection('requests')
      .where('status', '==', 'open')
      .where('timestamp', '<=', cutoff)
      .orderBy('timestamp')
      .limit(BATCH_MAX).get();

    let closed = 0;
    for (let page = await nextPage(); !page.empty; page = await nextPage()) {
      await commitAll(page.docs.map((doc) => (b) => b.update(doc.ref, {
        status: 'closed',
        closedAt: FieldValue.serverTimestamp(),
        closedReason: 'expired',
      })));
      closed += page.size;
      await Promise.all(page.docs.map((doc) => {
        const d = doc.data();
        return pushTo(d.userId, {
          title: 'Zgłoszenie zamknięte',
          body: `Twoje zgłoszenie (${d.sector || d.category}) wygasło po ${REQUEST_TTL_DAYS} dniach. Dodaj nowe, jeśli sprawa jest aktualna.`,
          data: { type: 'request_expired', requestId: doc.id, audience: 'user' },
        });
      }));
    }
    console.log(`autoClose: zamknięto ${closed} zgłoszeń`);
  });

// ── 7b) prośba o telefon → firma ─────────────────────────────────────────────
exports.notifyContactRequest = onDocumentWritten('contactRequests/{id}', async (event) => {
  const after = event.data.after.exists ? event.data.after.data() : null;
  if (!after || after.status !== 'pending') return;
  const before = event.data.before.exists ? event.data.before.data() : null;
  // ponowna prośba ma nowy createdAt; sama zmiana statusu nic nie wysyła
  if (before && before.status === 'pending' && before.createdAt && after.createdAt
      && before.createdAt.isEqual(after.createdAt)) return;
  const who = after.userName || await userName(after.userId);
  const note = after.note ? ' · ' + short(after.note, 60) : '';
  await pushTo(after.companyId, {
    title: '📞 Prośba o kontakt',
    body: `${who} prosi o telefon · ${after.phone}${note}`,
    data: { type: 'contact_request', senderId: after.userId, audience: 'company' },
  });
});

// ── 8) cron: prośby o recenzję po zrealizowanej usłudze ─────────────────────
exports.askForReview = onSchedule({ schedule: 'every 60 minutes', timeZone: 'Europe/Warsaw' }, async () => {
  const due = await db.collection('reviewReminders')
    .where('sent', '==', false)
    .where('dueAt', '<=', Timestamp.now())
    .limit(200).get();

  for (const doc of due.docs) {
    const r = doc.data();
    // odwołany termin / niepotwierdzona realizacja: prośba prowadziłaby na profil bez „Dodaj opinię"
    if (!(await reviewAllowed(doc.id, r))) {
      await doc.ref.delete();
      continue;
    }
    if (!(await hasReview(r.userId, r.companyId))) {
      await pushTo(r.userId, {
        title: `Jak było w ${r.companyName}?`,
        body: 'Wystaw recenzję — zajmie chwilę, a pomoże innym wybrać.',
        data: { type: 'review', companyId: r.companyId, audience: 'user' },
      });
    }
    await doc.ref.update({ sent: true, sentAt: FieldValue.serverTimestamp() });
  }
});

// ── 9) usunięte zgłoszenie → sprzątanie, informacja dla wykonawcy ───────────
exports.cleanupDeletedRequest = onDocumentDeleted('requests/{id}', async (event) => {
  const d = event.data && event.data.data();
  if (!d) return;
  const id = event.params.id;
  const [offers, photos, notifs] = await Promise.all([
    db.collection('requests').doc(id).collection('offers').get(),
    db.collection('realizations').where('requestId', '==', id).get(),
    db.collection('notifications').where('requestId', '==', id).get(),
  ]);
  await commitAll([
    ...[...offers.docs, ...photos.docs, ...notifs.docs].map((s) => (b) => b.delete(s.ref)),
    (b) => b.delete(db.collection('reviewReminders').doc(`req_${id}`)),
    (b) => b.delete(db.collection('requests').doc(id).collection('private').doc('location')),
  ]);
  await deleteOwnFiles(d.userId, [d.fileUrl, d.thumbUrl]);
  if (d.takenBy) await unlinkRequest(d.takenBy, d.userId, id);

  if (d.status === 'taken' && d.takenBy) {
    await pushTo(d.takenBy, {
      title: 'Zlecenie usunięte',
      body: `Klient usunął zgłoszenie (${d.sector || d.category}), które realizowałeś.`,
      data: { type: 'request_deleted', audience: 'company' },
    });
  }
});

/** Zgłoszenie znika z relacji klient↔firma; relacja bez żadnego źródła
 *  (zgłoszenia, rezerwacji, prośby o kontakt) jest kasowana — jak w apce. */
async function unlinkRequest(companyId, userId, requestId) {
  const refs = [db.doc(`users/${companyId}/clients/${userId}`), db.doc(`users/${userId}/myCompanies/${companyId}`)];
  await db.runTransaction(async (tx) => {
    for (const s of await tx.getAll(...refs)) {
      const d = s.data();
      // EXPIRES (pole requestId): po uruchomieniu demo/_seed/migrate_relation_request_id.js --apply
      const ids = (d && d.requestIds) || [];
      if (!d || (!ids.includes(requestId) && d.requestId !== requestId)) continue;
      const left = ids.some((x) => x !== requestId) || (!!d.requestId && d.requestId !== requestId)
        || (d.slotIds || []).length > 0 || !!d.contactRequestId;
      if (!left) {
        tx.delete(s.ref);
        continue;
      }
      tx.update(s.ref, {
        requestIds: FieldValue.arrayRemove(requestId),
        ...(d.requestId === requestId && { requestId: FieldValue.delete() }),
      });
    }
  });
}

/** Termin znika z relacji klient↔firma, gdy wraca do puli albo przejmuje go inny klient
 *  (apka robi to sama tylko przy odwołaniu, odrzuceniu i usunięciu). Od relacji zależy
 *  dostęp firmy do users/{klient}/private/contact. */
async function unlinkSlot(companyId, userId, slotId) {
  const refs = [db.doc(`users/${companyId}/clients/${userId}`), db.doc(`users/${userId}/myCompanies/${companyId}`)];
  const slotRef = db.doc(`users/${companyId}/slots/${slotId}`);
  await db.runTransaction(async (tx) => {
    const [slotSnap, ...snaps] = await tx.getAll(slotRef, ...refs);
    const slot = slotSnap.data();
    // klient zdążył ponownie zarezerwować ten termin — relacja zostaje
    if (slot && slot.bookedBy === userId && BOOKED.includes(slot.status)) return;
    for (const s of snaps) {
      const d = s.data();
      const ids = (d && d.slotIds) || [];
      // EXPIRES (pole requestId): po uruchomieniu demo/_seed/migrate_relation_request_id.js --apply
      const legacy = !!d && d.requestId === `slot_${slotId}`;
      if (!d || (!ids.includes(slotId) && !legacy)) continue;
      const left = ids.some((x) => x !== slotId) || (d.requestIds || []).length > 0
        || (!!d.requestId && !legacy) || !!d.contactRequestId;
      if (!left) {
        tx.delete(s.ref);
        continue;
      }
      tx.update(s.ref, {
        slotIds: FieldValue.arrayRemove(slotId),
        ...(legacy && { requestId: FieldValue.delete() }),
      });
    }
  });
}

// zdjęcia realizacji: plik leży pod uid tego, kto go wgrał
exports.cleanupDeletedRealization = onDocumentDeleted('realizations/{id}', async (event) => {
  const d = event.data && event.data.data();
  if (!d) return;
  await deleteOwnFiles(d.addedByRole === 'user' ? d.userId : d.companyId, [d.imageUrl, d.beforeUrl]);
});

// ── 10) usunięcie konta (RODO) — wywoływane z apki ──────────────────────────
exports.deleteAccount = onCall({ timeoutSeconds: 300 }, async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Zaloguj się ponownie.');
  try {
    await deleteUserData(uid);
  } catch (e) {
    console.error(`deleteAccount ${uid} nieudane`, e);
    throw new HttpsError('internal', 'Nie udało się usunąć konta. Spróbuj ponownie.');
  }
  return { ok: true };
});

async function deleteUserData(uid) {
  const me = db.collection('users').doc(uid);
  const docs = (q) => q.get().then((s) => s.docs);
  const where = (coll, field, op = '==') => docs(db.collection(coll).where(field, op, uid));

  // najpierw wszystkie odczyty — brak indeksu przerwie operację, zanim cokolwiek zniknie
  const [offers, comments, requests, taken, promos, reviewsBy, reviewsOf, photos, photosOf,
    contacts, contactsOf, notifs, notifsFrom, reminders, remindersOf, chats,
    slots, bookings, myCompanies, clients, meSnap] = await Promise.all([
    docs(db.collectionGroup('offers').where('companyId', '==', uid)),
    docs(db.collectionGroup('comments').where('authorId', '==', uid)),
    where('requests', 'userId'),
    where('requests', 'takenBy'),
    where('promos', 'userId'),
    where('reviews', 'userId'),
    where('reviews', 'reviewedUserId'),
    where('realizations', 'userId'),
    where('realizations', 'companyId'),
    where('contactRequests', 'userId'),
    where('contactRequests', 'companyId'),
    where('notifications', 'userId'),
    where('notifications', 'from'),
    where('reviewReminders', 'userId'),
    where('reviewReminders', 'companyId'),
    where('chats', 'participants', 'array-contains'),
    docs(me.collection('slots')),
    docs(me.collection('myBookings')),
    docs(me.collection('myCompanies')),
    docs(me.collection('clients')),
    me.get(),
  ]);
  const now = Date.now();
  const future = (ts) => !!ts && ts.toMillis() > now;

  // rezerwacje u firm wracają do puli (firma dostaje „Klient odwołał rezerwację")
  const booked = await Promise.all(bookings.map((b) => {
    const [companyId, slotId] = b.id.split('_');
    return db.doc(`users/${companyId}/slots/${slotId}`).get();
  }));
  const freeSlots = booked.filter((s) => {
    const d = s.data();
    return d && d.bookedBy === uid && BOOKED.includes(d.status) && future(d.start);
  });

  // klienci terminów firmy widzą odwołaną rezerwację (push wyśle notifySlotDeleted)
  const companyName = (meSnap.data() || {}).companyName || 'Firma';
  const lostBookings = slots.filter((s) => {
    const d = s.data();
    return d.bookedBy && BOOKED.includes(d.status) && future(d.start);
  });

  const reopen = taken.filter((r) => r.data().status === 'taken');
  // oferty innych firm zamknięte przy akceptacji wracają — klient wybierze inną
  const closedOffers = (await Promise.all(reopen.map((r) => docs(r.ref.collection('offers')
    .where('status', '==', 'closed'))))).flat();

  await commitAll([
    ...freeSlots.map((s) => (b) => b.update(s.ref, {
      status: 'free', bookedBy: '', bookedByName: '', releasedBy: 'user',
    })),
    ...lostBookings.map((s) => (b) => b.set(db.doc(`users/${s.data().bookedBy}/myBookings/${uid}_${s.id}`), {
      companyId: uid, companyName, slotId: s.id, start: s.data().start,
      status: 'cancelled', decidedAt: FieldValue.serverTimestamp(),
    }, { merge: true })),
    ...reopen.map((r) => (b) => b.update(r.ref, {
      status: 'open', takenBy: '', takenByName: '', confirmedByCompany: false, confirmedByUser: false,
      realizationStatus: FieldValue.delete(),
    })),
    ...closedOffers.map((o) => (b) => b.update(o.ref, { status: 'pending' })),
    ...chats.map((c) => (b) => b.update(c.ref, { [`names.${uid}`]: DELETED_NAME })),
  ]);

  await Promise.all(reopen.map((r) => pushTo(r.data().userId, {
    title: 'Wykonawca usunął konto',
    body: `Zgłoszenie (${r.data().sector || r.data().category}) wróciło do puli — możesz wybrać inną ofertę.`,
    data: { type: 'request_reopened', requestId: r.id, audience: 'user' },
  })));

  // zgłoszenia bez podkolekcji — oferty, zdjęcia i przypomnienia sprząta cleanupDeletedRequest
  const refs = [
    ...[offers, comments, requests, promos, photos, photosOf, contacts, contactsOf,
      notifs, notifsFrom, reminders, remindersOf].flat().map((s) => s.ref),
    ...myCompanies.flatMap((c) => [
      db.doc(`users/${c.id}/clients/${uid}`),
      db.doc(`users/${c.id}/clientNotes/${uid}`),
    ]),
    ...clients.map((c) => db.doc(`users/${c.id}/myCompanies/${uid}`)),
    db.collection('profile').doc(uid),
  ];
  const unique = [...new Map(refs.map((r) => [r.path, r])).values()];
  await commitAll(unique.map((ref) => (b) => b.delete(ref)));
  for (const r of new Map([...reviewsBy, ...reviewsOf].map((s) => [s.id, s.ref])).values()) {
    await db.recursiveDelete(r);
  }
  await db.recursiveDelete(me);
  // syncPrivateContact z zapisu sprzed usunięcia nie odtworzy już danych (sprawdza users/{uid}),
  // ale kasujemy też jawnie — recursiveDelete nie widzi dokumentu dopisanego w trakcie
  // (tak samo token FCM z onTokenRefresh)
  await Promise.all(['contact', 'push'].map((id) => me.collection('private').doc(id).delete()));

  await getDatabase().ref(`users/${uid}`).remove();
  const bucket = getStorage().bucket();
  await Promise.all(['files', 'thumbs', 'realizations']
    .map((dir) => bucket.deleteFiles({ prefix: `${dir}/${uid}/` })));
  // podwójne wywołanie (token ważny do wygaśnięcia): konta Auth może już nie być
  await getAuth().deleteUser(uid).catch((e) => {
    if (e.code !== 'auth/user-not-found') throw e;
  });

  console.log(`deleteAccount ${uid}: zgłoszeń ${requests.length}, prezentacji ${promos.length}, `
    + `recenzji ${reviewsBy.length + reviewsOf.length}, rozmów ${chats.length}, `
    + `zwolnionych terminów ${freeSlots.length}, odwołanych rezerwacji klientów ${lostBookings.length}, `
    + `zleceń wróconych do puli ${reopen.length}`);
}

// ── 11) zmiana profilu: nazwa w rozmowach, token FCM przy jednym koncie ─────
// ── 11b) telefon i e-mail → users/{uid}/private/contact (RODO) ──────────────
// users/{uid} czyta każde zalogowane konto, private/contact tylko właściciel i firma z relacją.
// Apka ≤1.4.0+22 zapisuje je jawnie (rejestracja, edycja profilu): niepustą wartość kopiujemy
// i czyścimy jawne pole. Pusta nie nadpisuje zapisanej. Telefon firmy jest jawny i zostaje.
const contactFields = (d) => (d.firma === true || d.isCompany === true ? ['email'] : ['email', 'phone'])
  .filter((k) => typeof d[k] === 'string' && d[k]);

exports.syncPrivateContact = onDocumentWritten('users/{uid}', async (event) => {
  if (!event.data.after.exists || !contactFields(event.data.after.data()).length) return;
  const ref = db.collection('users').doc(event.params.uid);
  // bieżący stan, nie migawka: konto mogło zostać usunięte, a pole zmienione ponownie
  await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (!s.exists) return;
    const d = s.data();
    const found = contactFields(d);
    if (!found.length) return;
    tx.set(ref.collection('private').doc('contact'),
      Object.fromEntries(found.map((k) => [k, d[k]])), { merge: true });
    tx.update(ref, Object.fromEntries(found.map((k) => [k, ''])));
  });
});

exports.onUserUpdated = onDocumentUpdated('users/{uid}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  const { uid } = event.params;
  await syncChatNames(uid, before, after);
});

/** Rozmowa niesie nazwę z ostatniej wiadomości nadawcy; konto firmowe pisze jako firma
 *  albo jako osoba (tryb), więc podmieniamy tylko tę nazwę, która była stara. */
async function syncChatNames(uid, before, after) {
  const renames = [
    [before.companyName || 'Firma', after.companyName || 'Firma'],
    [personName(before), personName(after)],
  ].filter(([from, to]) => from !== to);
  if (!renames.length) return;
  const chats = await db.collection('chats').where('participants', 'array-contains', uid).get();
  const ops = [];
  for (const c of chats.docs) {
    const hit = renames.find(([from]) => from === (c.data().names || {})[uid]);
    if (hit) ops.push((b) => b.update(c.ref, { [`names.${uid}`]: hit[1] }));
  }
  await commitAll(ops);
}

/** Telefon zalogowany na nowe konto: jego token znika z poprzedniego, nawet gdy
 *  wylogowanie offline nie zdążyło go usunąć. Stare pole users.fcmTokens czyścimy
 *  u wszystkich (EXPIRES: po migrate_fcm_tokens.js --apply). */
exports.releasePushTokens = onDocumentWritten('users/{uid}/private/push', async (event) => {
  const own = `users/${event.params.uid}/private/push`;
  const tokens = (s) => (s.exists && s.get('fcmTokens')) || [];
  const known = new Set(tokens(event.data.before));
  const added = tokens(event.data.after).filter((t) => !known.has(t));
  const holders = await Promise.all(added.map((t) => Promise.all([
    db.collectionGroup('private').where('fcmTokens', 'array-contains', t).get(),
    db.collection('users').where('fcmTokens', 'array-contains', t).get(),
  ])));
  await commitAll(holders.flatMap(([priv, legacy], i) => [
    ...priv.docs.filter((d) => d.ref.path !== own),
    ...legacy.docs,
  ].map((d) => (b) => b.update(d.ref, { fcmTokens: FieldValue.arrayRemove(added[i]) }))));
});
