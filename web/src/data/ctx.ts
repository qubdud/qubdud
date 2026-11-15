import type { Auth } from 'firebase/auth';
import type { Firestore } from 'firebase/firestore';
import type { FirebaseStorage } from 'firebase/storage';

/** Instancje Firebase jednego użytkownika — strona ma jedną, test po jednej na osobę. */
export interface Ctx {
  db: Firestore;
  auth: Auth;
  storage: FirebaseStorage;
}

/** Błąd z komunikatem do pokazania użytkownikowi. */
export class UserError extends Error {}

export function errorCode(e: unknown): string {
  return typeof e === 'object' && e !== null && 'code' in e ? String((e as { code: unknown }).code) : '';
}

/** uid gościa zalogowanego e-mailem; anonim nie zapisuje niczego poza odczytem wizytówek. */
export function myUid(ctx: Ctx): string {
  const u = ctx.auth.currentUser;
  if (!u || u.isAnonymous) throw new UserError('Zaloguj się, żeby kontynuować');
  return u.uid;
}

export function errorText(e: unknown, fallback = 'Nie udało się — spróbuj ponownie'): string {
  if (e instanceof UserError) return e.message;
  const code = errorCode(e);
  if (code === 'unavailable' || code === 'deadline-exceeded') return 'Brak połączenia — spróbuj ponownie';
  if (code === 'permission-denied') return 'Brak uprawnień do tej operacji';
  return fallback;
}
