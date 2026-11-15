import { arrayRemove, arrayUnion, deleteField, doc, getDoc, serverTimestamp, writeBatch } from 'firebase/firestore';
import type { DocumentSnapshot, Transaction, WriteBatch } from 'firebase/firestore';
import type { Ctx } from './ctx.ts';

const clientRef = (ctx: Ctx, companyId: string, userId: string) =>
  doc(ctx.db, 'users', companyId, 'clients', userId);
const myCompanyRef = (ctx: Ctx, userId: string, companyId: string) =>
  doc(ctx.db, 'users', userId, 'myCompanies', companyId);

/**
 * Relacja klient↔firma (users/{firma}/clients/{klient} i users/{klient}/myCompanies/{firma}),
 * jak _linkClient w apce. requestId: id zgłoszenia, 'slot_<id>' albo 'contact_<id>'.
 * Z [batch] zapis idzie razem z resztą operacji (commit robi wywołujący).
 */
export async function linkClient(
  ctx: Ctx,
  { companyId, userId, requestId, batch }: { companyId: string; userId: string; requestId: string; batch?: WriteBatch },
): Promise<void> {
  const [userDoc, companyDoc] = await Promise.all([
    getDoc(doc(ctx.db, 'users', userId)),
    getDoc(doc(ctx.db, 'users', companyId)),
  ]);
  const userData = userDoc.data() ?? {};
  const companyData = companyDoc.data() ?? {};

  const isSlot = requestId.startsWith('slot_');
  const isContact = requestId.startsWith('contact_');
  const linkFields: Record<string, unknown> = {
    ...(isSlot
      ? { slotIds: arrayUnion(requestId.substring(5)) }
      : isContact
        ? { contactRequestId: requestId.substring(8) }
        : { requestIds: arrayUnion(requestId) }),
    lastAt: serverTimestamp(),
  };
  const cRef = clientRef(ctx, companyId, userId);
  const mRef = myCompanyRef(ctx, userId, companyId);
  const firstTime = !(await getDoc(cRef)).exists();

  const b = batch ?? writeBatch(ctx.db);
  b.set(
    cRef,
    {
      userId,
      name: `${userData.firstName ?? ''} ${userData.lastName ?? ''}`.trim(),
      ...(firstTime ? { addedAt: serverTimestamp() } : {}),
      ...linkFields,
    },
    { merge: true },
  );
  b.set(
    mRef,
    {
      companyId,
      name: companyData.companyName ?? 'Firma',
      ...(firstTime ? { addedAt: serverTimestamp() } : {}),
      ...linkFields,
    },
    { merge: true },
  );
  if (!batch) await b.commit();
}

/** Dokumenty relacji — odczyt w transakcji przed zapisami. */
export async function readRelationTx(tx: Transaction, ctx: Ctx, companyId: string, userId: string) {
  return [await tx.get(clientRef(ctx, companyId, userId)), await tx.get(myCompanyRef(ctx, userId, companyId))];
}

/** Zdejmuje z relacji termin albo zgłoszenie; relacja bez żadnego źródła jest kasowana. */
export function unlinkTx(
  tx: Transaction,
  relation: DocumentSnapshot[],
  { slotId, requestId }: { slotId?: string; requestId?: string },
): void {
  for (const s of relation) {
    const d = s.data();
    if (!d) continue;
    const slotIds: string[] = d.slotIds ?? [];
    const requestIds: string[] = d.requestIds ?? [];
    const legacy: string = d.requestId ?? '';
    if (
      !(slotId !== undefined && slotIds.includes(slotId)) &&
      !(requestId !== undefined && requestIds.includes(requestId)) &&
      (requestId === undefined || legacy !== requestId)
    ) {
      continue;
    }
    const left =
      slotIds.some((id) => id !== slotId) ||
      requestIds.some((id) => id !== requestId) ||
      (legacy !== '' && legacy !== requestId) ||
      (d.contactRequestId ?? '') !== '';
    if (!left) {
      tx.delete(s.ref);
    } else if (slotId !== undefined) {
      tx.update(s.ref, { slotIds: arrayRemove(slotId) });
    } else {
      tx.update(s.ref, {
        requestIds: arrayRemove(requestId),
        ...(legacy === requestId ? { requestId: deleteField() } : {}),
      });
    }
  }
}
