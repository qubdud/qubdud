import { doc, getDoc, serverTimestamp, writeBatch } from 'firebase/firestore';
import type { DocumentData } from 'firebase/firestore';
import { UserError, myUid } from './ctx.ts';
import type { Ctx } from './ctx.ts';

export const isCompanyDoc = (d: DocumentData | undefined): boolean =>
  (d?.firma ?? d?.isCompany ?? false) === true;

export const personName = (d: DocumentData | undefined): string =>
  `${d?.firstName ?? ''} ${d?.lastName ?? ''}`.trim() || 'Użytkownik';

/** Mój profil users/{uid}; null, gdy konto nie ma jeszcze profilu (pierwsze logowanie). */
export async function loadMyProfile(ctx: Ctx): Promise<DocumentData | null> {
  const snap = await getDoc(doc(ctx.db, 'users', myUid(ctx)));
  return snap.exists() ? snap.data() : null;
}

export interface GuestProfileInput {
  firstName: string;
  lastName: string;
  phone: string;
}

export function validateGuestProfile(p: GuestProfileInput): Partial<Record<keyof GuestProfileInput, string>> {
  const errors: Partial<Record<keyof GuestProfileInput, string>> = {};
  if (!p.firstName.trim()) errors.firstName = 'Podaj imię';
  if (!p.lastName.trim()) errors.lastName = 'Podaj nazwisko';
  if (!p.phone.trim()) errors.phone = 'Podaj numer telefonu';
  else if (p.phone.trim().length > 50) errors.phone = 'Za długi numer';
  return errors;
}

/** Profil klienta jak rejestracja w apce: jawny e-mail i telefon puste, kontakt w private/contact. */
export async function createGuestProfile(ctx: Ctx, p: GuestProfileInput): Promise<void> {
  const uid = myUid(ctx);
  if (Object.keys(validateGuestProfile(p)).length) throw new UserError('Uzupełnij imię, nazwisko i telefon');
  const ref = doc(ctx.db, 'users', uid);
  await writeBatch(ctx.db)
    .set(ref, {
      email: '',
      firstName: p.firstName.trim(),
      lastName: p.lastName.trim(),
      phone: '',
      isCompany: false,
      firma: false,
      consents: { terms: true, rodo: true, acceptedAt: serverTimestamp() },
      createdAt: serverTimestamp(),
    })
    .set(doc(ref, 'private', 'contact'), {
      email: ctx.auth.currentUser?.email ?? '',
      phone: p.phone.trim(),
    })
    .commit();
}
