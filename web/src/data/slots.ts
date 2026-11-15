import {
  collection,
  doc,
  getDoc,
  onSnapshot,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  Timestamp,
  where,
  writeBatch,
} from 'firebase/firestore';
import type { DocumentData, DocumentReference, Transaction, Unsubscribe } from 'firebase/firestore';
import { UserError, errorCode, myUid } from './ctx.ts';
import type { Ctx } from './ctx.ts';
import { linkClient, readRelationTx, unlinkTx } from './relations.ts';

// users/{companyId}/slots/{slotId}: {start, durationMin?, status: 'free'|'pending'|'accepted',
//   bookedBy ('' = wolny), bookedAt, releasedBy}
// users/{uid}/myBookings/{companyId}_{slotId}: kopia rezerwacji klienta

const PENDING_TTL_MS = 60 * 60 * 1000;
const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

const slotRef = (ctx: Ctx, companyId: string, slotId: string) => doc(ctx.db, 'users', companyId, 'slots', slotId);
const myBookingRef = (ctx: Ctx, uid: string, companyId: string, slotId: string) =>
  doc(ctx.db, 'users', uid, 'myBookings', `${companyId}_${slotId}`);

/** Żółta rezerwacja bez decyzji firmy wygasa po godzinie. */
export function pendingExpired(d: DocumentData): boolean {
  const bookedAt = d.bookedAt instanceof Timestamp ? d.bookedAt.toMillis() : null;
  return d.status === 'pending' && bookedAt !== null && Date.now() - bookedAt >= PENDING_TTL_MS;
}

export interface Slot {
  id: string;
  start: Date;
  durationMin: number | null;
  status: string;
  bookedBy: string;
}

/** Sloty z 7 dni do przodu; wygasła żółta rezerwacja wygląda jak wolna (jak w apce). */
export function slotsFromDocs(docs: { id: string; data: () => DocumentData }[]): Slot[] {
  const now = Date.now();
  const out: Slot[] = [];
  for (const d of docs) {
    const x = d.data();
    if (!(x.start instanceof Timestamp)) continue;
    const start = x.start.toDate();
    if (start.getTime() < now || start.getTime() > now + WEEK_MS) continue;
    const expired = pendingExpired(x) || x.status === 'rejected';
    out.push({
      id: d.id,
      start,
      durationMin: typeof x.durationMin === 'number' ? x.durationMin : null,
      status: expired ? 'free' : (x.status ?? 'free'),
      bookedBy: expired ? '' : (x.bookedBy ?? ''),
    });
  }
  return out;
}

/** Obcy widzi wolne i swoje terminy; niezalogowany (anonim) tylko wolne. */
export function slotsQuery(ctx: Ctx, companyId: string) {
  const u = ctx.auth.currentUser;
  const me = u && !u.isAnonymous ? u.uid : '';
  const col = collection(ctx.db, 'users', companyId, 'slots');
  return companyId === me
    ? query(col, orderBy('start'))
    : query(col, where('bookedBy', 'in', me ? ['', me] : ['']), orderBy('start'));
}

export function watchSlots(ctx: Ctx, companyId: string, next: (s: Slot[]) => void, error: (e: unknown) => void): Unsubscribe {
  return onSnapshot(slotsQuery(ctx, companyId), (snap) => next(slotsFromDocs(snap.docs)), error);
}

async function companyNameTx(tx: Transaction, ctx: Ctx, companyId: string): Promise<string> {
  const d = (await tx.get(doc(ctx.db, 'users', companyId))).data();
  return (d?.companyName as string | undefined) ?? 'Firma';
}

/**
 * Rezerwacja wolnego terminu jak bookSlot w apce: transakcja na slocie + kopia w myBookings,
 * potem relacja klient↔firma. Rzuca UserError z komunikatem dla użytkownika.
 */
export async function bookSlot(ctx: Ctx, companyId: string, slotId: string): Promise<void> {
  const me = myUid(ctx);
  if (companyId === me) throw new UserError('To Twój termin — nie możesz go zarezerwować');
  const ref = slotRef(ctx, companyId, slotId);
  try {
    await runTransaction(ctx.db, async (tx) => {
      let slot: DocumentData | undefined;
      try {
        slot = (await tx.get(ref)).data();
      } catch (e) {
        if (errorCode(e) === 'permission-denied') throw new UserError('Ten termin jest już niedostępny');
        throw e;
      }
      if (!slot) throw new UserError('Firma usunęła ten termin');
      const start = slot.start instanceof Timestamp ? slot.start.toDate() : null;
      if (!start || start.getTime() < Date.now()) throw new UserError('Ten termin już minął');
      const status = slot.status ?? 'free';
      if (status !== 'free' && status !== 'rejected' && !pendingExpired(slot)) {
        throw new UserError('Ten termin jest już zajęty');
      }
      const companyName = await companyNameTx(tx, ctx, companyId);
      tx.update(ref, { status: 'pending', bookedBy: me, bookedAt: serverTimestamp() });
      tx.set(myBookingRef(ctx, me, companyId, slotId), {
        companyId,
        companyName,
        slotId,
        start: Timestamp.fromDate(start),
        status: 'pending',
        bookedAt: serverTimestamp(),
      });
    });
  } catch (e) {
    if (e instanceof UserError) throw e;
    if (errorCode(e) === 'permission-denied') throw new UserError('Nie możesz zarezerwować terminu w tej firmie');
    throw e;
  }
  await linkClient(ctx, { companyId, userId: me, requestId: `slot_${slotId}` });
}

/**
 * Odwołanie rezerwacji albo usunięcie z listy wpisu odrzuconego/odwołanego przez firmę
 * (cancelSlotBooking w apce). Termin wraca do puli tylko, gdy nadal zajmuje go ten klient.
 */
export async function cancelSlotBooking(ctx: Ctx, companyId: string, slotId: string): Promise<void> {
  const me = myUid(ctx);
  const ref = slotRef(ctx, companyId, slotId);
  let visible = true;
  try {
    await getDoc(ref);
  } catch (e) {
    if (errorCode(e) !== 'permission-denied') throw e;
    visible = false;
  }
  await runTransaction(ctx.db, async (tx) => {
    const slot = visible ? (await tx.get(ref)).data() : undefined;
    const relation = await readRelationTx(tx, ctx, companyId, me);
    if (slot && slot.bookedBy === me && (slot.status === 'pending' || slot.status === 'accepted')) {
      tx.update(ref, { status: 'free', bookedBy: '', releasedBy: 'user' });
    }
    unlinkTx(tx, relation, { slotId });
    tx.delete(myBookingRef(ctx, me, companyId, slotId));
  });
}

export interface Booking {
  companyId: string;
  companyName: string;
  slotId: string;
  start: Date;
  status: string;
}

/**
 * Nadchodzące rezerwacje na żywo. Jak getMyBookings w apce sprząta wpisy minione i wygasłe
 * żółte (przyjęte zostają — są dowodem wizyty do recenzji).
 */
export function watchMyBookings(ctx: Ctx, next: (b: Booking[]) => void, error: (e: unknown) => void): Unsubscribe {
  const me = myUid(ctx);
  const cleaned = new Set<string>();
  return onSnapshot(
    collection(ctx.db, 'users', me, 'myBookings'),
    (snap) => {
      const now = Date.now();
      const out: Booking[] = [];
      const toDelete: DocumentReference[] = [];
      for (const d of snap.docs) {
        const x = d.data();
        const start = x.start instanceof Timestamp ? x.start.toDate() : null;
        if (!start || start.getTime() < now || pendingExpired(x)) {
          if (x.status !== 'accepted' && !cleaned.has(d.id)) {
            cleaned.add(d.id);
            toDelete.push(d.ref);
          }
          continue;
        }
        out.push({
          companyId: x.companyId ?? '',
          companyName: x.companyName ?? 'Firma',
          slotId: x.slotId ?? '',
          start,
          status: x.status ?? 'pending',
        });
      }
      if (toDelete.length) {
        const b = writeBatch(ctx.db);
        toDelete.forEach((r) => b.delete(r));
        b.commit().catch(() => {});
      }
      out.sort((a, b) => a.start.getTime() - b.start.getTime());
      next(out);
    },
    error,
  );
}
