// Powiadomienia push QUBDUD — Cloud Functions v2 (Firestore triggers + cron).
// Region = lokalizacja bazy Firestore (europe-central2).
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getDatabase } = require('firebase-admin/database');

setGlobalOptions({ region: 'europe-central2', maxInstances: 5 });
initializeApp();
const db = getFirestore();

const URGENT_RADIUS_KM = 30;
const REQUEST_TTL_DAYS = 10;        // po tylu dniach zgłoszenie zamyka się samo
const REVIEW_AFTER_BOOKING_H = 2;   // po zakończonym terminie
const REVIEW_AFTER_JOB_DAYS = 3;    // po zaakceptowanej ofercie

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

/** Wpis do dzwonka w apce (bez pushu). */
async function logNotification(uid, { title, body, data = {} }) {
  if (!uid) return;
  try {
    await db.collection('notifications').add({
      userId: uid,
      title,
      body,
      type: data.type || 'info',
      requestId: data.requestId || '',
      companyId: data.companyId || '',
      from: data.from || '',
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error('notification write failed', e);
  }
}

/** Powiadomienie: wpis w bazie (dzwonek w apce) + push na urządzenia. */
async function pushTo(uid, { title, body, data = {} }) {
  if (!uid) return;
  await logNotification(uid, { title, body, data });

  const ref = db.collection('users').doc(uid);
  const snap = await ref.get();
  const tokens = (snap.data() && snap.data().fcmTokens) || [];
  if (!tokens.length) return;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    android: { priority: 'high', notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  });

  const dead = [];
  res.responses.forEach((r, i) => {
    const code = r.error && r.error.code;
    if (code === 'messaging/registration-token-not-registered'
      || code === 'messaging/invalid-registration-token') dead.push(tokens[i]);
  });
  if (dead.length) await ref.update({ fcmTokens: FieldValue.arrayRemove(...dead) });
  console.log(`push → ${uid}: ok=${res.successCount} fail=${res.failureCount}`
    + (dead.length ? ` (usunięto ${dead.length} martwych tokenów)` : '') + ` | ${title}`);
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

// ── 1) pilne zgłoszenie → firmy z kategorii w promieniu ─────────────────────
exports.notifyUrgentRequest = onDocumentCreated('requests/{id}', async (event) => {
  const d = event.data && event.data.data();
  if (!d || d.is24 !== true || !d.location || typeof d.location.lat !== 'number') return;

  const firms = await db.collection('users')
    .where('firma', '==', true)
    .where('companyCategory', '==', d.category)
    .get();

  const body = `${d.sector || d.category}${d.city ? ' · ' + d.city : ''}: ${short(d.description)}`;
  console.log(`pilne ${event.params.id}: ${d.category}/${d.sector}, firm w kategorii: ${firms.size}`);
  const jobs = [];
  for (const f of firms.docs) {
    if (f.id === d.userId) continue;
    const loc = f.data().companyLocation;
    if (!loc || typeof loc.lat !== 'number') continue;
    if (kmBetween(d.location, loc) > URGENT_RADIUS_KM) continue;
    jobs.push(pushTo(f.id, {
      title: '🔴 Pilne zgłoszenie w pobliżu',
      body,
      data: { type: 'urgent_request', requestId: event.params.id },
    }));
  }
  await Promise.all(jobs);
});

// ── 2) nowa oferta → właściciel zgłoszenia ──────────────────────────────────
exports.notifyNewOffer = onDocumentCreated('requests/{id}/offers/{companyId}', async (event) => {
  const offer = event.data && event.data.data();
  if (!offer) return;
  const req = (await db.collection('requests').doc(event.params.id).get()).data();
  if (!req) return;
  await pushTo(req.userId, {
    title: `Nowa oferta: ${offer.companyName || 'firma'}`,
    body: short(offer.message, 100),
    data: { type: 'offer', requestId: event.params.id },
  });
});

// ── 3) decyzja klienta ✔/?/✖ → firma; akcept = planowana prośba o recenzję ──
exports.notifyOfferDecision = onDocumentUpdated('requests/{id}/offers/{companyId}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  if (before.status === after.status) return;

  const req = (await db.collection('requests').doc(event.params.id).get()).data() || {};
  const client = await userName(req.userId);
  const texts = {
    accepted: ['✅ Oferta przyjęta', `${client} wybrał Twoją ofertę. Skontaktuj się i ustal szczegóły.`],
    maybe: ['🤔 Klient się zastanawia', `${client} oznaczył Twoją ofertę jako „może". Warto dopytać.`],
    rejected: ['Oferta odrzucona', `${client} wybrał inną ofertę.`],
  };
  const t = texts[after.status];
  if (t) {
    await pushTo(event.params.companyId, {
      title: t[0], body: t[1],
      data: { type: 'offer_decision', requestId: event.params.id, status: after.status },
    });
  }

  if (after.status === 'accepted') {
    await db.collection('reviewReminders').doc(`req_${event.params.id}`).set({
      userId: req.userId,
      companyId: event.params.companyId,
      companyName: after.companyName || await userName(event.params.companyId),
      dueAt: Timestamp.fromMillis(Date.now() + REVIEW_AFTER_JOB_DAYS * 86400e3),
      source: 'request',
      sent: false,
    }, { merge: true });
  }
});

// ── 4) rezerwacja slotu → firma; decyzja firmy → klient ─────────────────────
exports.notifySlot = onDocumentUpdated('users/{companyId}/slots/{slotId}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  if (before.status === after.status) return;
  const when = fmtWhen(after.start);

  // ktoś kliknął kropkę
  if (after.status === 'pending' && after.bookedBy) {
    await pushTo(event.params.companyId, {
      title: '📅 Nowa rezerwacja',
      body: `${after.bookedByName || 'Klient'} · ${when}. Potwierdź lub odrzuć w kalendarzu.`,
      data: { type: 'booking', slotId: event.params.slotId },
    });
    return;
  }

  // firma zdecydowała
  const client = after.bookedBy || before.bookedBy;
  if (!client) return;
  const company = await userName(event.params.companyId);
  if (after.status === 'accepted') {
    await pushTo(client, {
      title: '✅ Termin potwierdzony',
      body: `${company} · ${when}`,
      data: { type: 'booking_decision', companyId: event.params.companyId, status: 'accepted' },
    });
    const startMs = after.start && after.start.toMillis ? after.start.toMillis() : Date.now();
    await db.collection('reviewReminders').doc(`slot_${event.params.slotId}`).set({
      userId: client,
      companyId: event.params.companyId,
      companyName: company,
      dueAt: Timestamp.fromMillis(startMs + REVIEW_AFTER_BOOKING_H * 3600e3),
      source: 'booking',
      sent: false,
    }, { merge: true });
  } else if (after.status === 'rejected') {
    await pushTo(client, {
      title: 'Termin odrzucony',
      body: `${company} nie może przyjąć Cię ${when}. Wybierz inny termin.`,
      data: { type: 'booking_decision', companyId: event.params.companyId, status: 'rejected' },
    });
  }
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
      data: { type: 'realization_from_user', requestId: d.requestId || '' },
    });
    return;
  }

  if (d.status !== 'pending') return;
  const company = await userName(d.companyId);
  await pushTo(d.userId, {
    title: `📷 ${company} prosi o potwierdzenie realizacji`,
    body: 'Potwierdź wykonanie — zdjęcia trafią do portfolio firmy, a zgłoszenie zostanie zamknięte.',
    data: { type: 'realization', requestId: d.requestId || '' },
  });
});

exports.notifyRealizationDecision = onDocumentUpdated('realizations/{id}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data() || {};
  if (before.status === after.status || !after.companyId) return;
  const client = await userName(after.userId);
  if (after.status === 'approved') {
    await pushTo(after.companyId, {
      title: '✅ Klient potwierdził realizację',
      body: `${client} potwierdził wykonanie — zdjęcia są już na Twoim profilu.`,
      data: { type: 'realization_decision', requestId: after.requestId || '', status: 'approved' },
    });
  } else if (after.status === 'rejected') {
    await pushTo(after.companyId, {
      title: 'Zdjęcia realizacji odrzucone',
      body: `${client} nie potwierdził zdjęć. Usuń je w zgłoszeniu i dodaj właściwe.`,
      data: { type: 'realization_decision', requestId: after.requestId || '', status: 'rejected' },
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
    data: { type: 'chat', from: m.from, fromName: names[m.from] || '' },
  };

  let online = false;
  try {
    // „online" bywa nieaktualne (apka ubita bez onDisconnect) — ufamy mu
    // tylko przez 10 minut od ostatniej zmiany stanu
    const st = (await getDatabase().ref(`users/${to}`).get()).val() || {};
    const fresh = typeof st.last_seen === 'number' && Date.now() - st.last_seen < 10 * 60e3;
    online = st.online === true && fresh;
  } catch (_) { /* brak RTDB = wysyłamy push */ }

  // wpis w dzwonku zawsze; push tylko, gdy odbiorca nie patrzy na apkę
  if (online) {
    console.log(`chat → ${to}: online, tylko wpis w powiadomieniach`);
    await logNotification(to, payload);
  } else {
    await pushTo(to, payload);
  }
});

// ── 7) cron: zgłoszenia starsze niż 10 dni zamykają się same ────────────────
exports.autoCloseRequests = onSchedule(
  { schedule: 'every 24 hours', timeZone: 'Europe/Warsaw' },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - REQUEST_TTL_DAYS * 86400e3);
    const old = await db.collection('requests')
      .where('timestamp', '<=', cutoff)
      .limit(400).get();

    let closed = 0;
    for (const doc of old.docs) {
      const d = doc.data();
      if (d.status === 'closed') continue;
      await doc.ref.update({
        status: 'closed',
        closedAt: FieldValue.serverTimestamp(),
        closedReason: 'expired',
      });
      closed++;
      await pushTo(d.userId, {
        title: 'Zgłoszenie zamknięte',
        body: `Twoje zgłoszenie (${d.sector || d.category}) wygasło po ${REQUEST_TTL_DAYS} dniach. Dodaj nowe, jeśli sprawa jest aktualna.`,
        data: { type: 'request_expired', requestId: doc.id },
      });
    }
    console.log(`autoClose: zamknięto ${closed} zgłoszeń`);
  });

// ── 8) cron: prośby o recenzję po zrealizowanej usłudze ─────────────────────
exports.askForReview = onSchedule({ schedule: 'every 60 minutes', timeZone: 'Europe/Warsaw' }, async () => {
  const due = await db.collection('reviewReminders')
    .where('sent', '==', false)
    .where('dueAt', '<=', Timestamp.now())
    .limit(200).get();

  for (const doc of due.docs) {
    const r = doc.data();
    if (!(await hasReview(r.userId, r.companyId))) {
      await pushTo(r.userId, {
        title: `Jak było w ${r.companyName}?`,
        body: 'Wystaw recenzję — zajmie chwilę, a pomoże innym wybrać.',
        data: { type: 'review', companyId: r.companyId },
      });
    }
    await doc.ref.update({ sent: true, sentAt: FieldValue.serverTimestamp() });
  }
});
