import {
  isSignInWithEmailLink,
  onAuthStateChanged,
  sendSignInLinkToEmail,
  signInAnonymously,
  signInWithEmailLink,
  signOut,
} from 'firebase/auth';
import type { User } from 'firebase/auth';
import type { DocumentData } from 'firebase/firestore';
import { useEffect, useState } from 'preact/hooks';
import { errorCode, errorText } from './data/ctx.ts';
import { createGuestProfile, loadMyProfile } from './data/profile.ts';
import type { GuestProfileInput } from './data/profile.ts';
import { bookSlot } from './data/slots.ts';
import { ctx } from './firebase.ts';
import { loadDraft } from './lib/draft.ts';
import { submitDraft } from './lib/submit.ts';
import { navigate } from './router.ts';
import { toast } from './ui/toast.tsx';

/** Co zrobić po powrocie z linku w e-mailu (i ewentualnym założeniu profilu). */
export type Pending =
  | { type: 'request' }
  | { type: 'book'; companyId: string; slotId: string }
  | { type: 'chat'; companyId: string }
  | { type: 'view' };

export interface Session {
  ready: boolean;
  user: User | null;
  /** zalogowany e-mailem (nie anonim) */
  guest: boolean;
  /** undefined = wczytywanie, null = brak profilu (pierwsze logowanie) */
  profile: DocumentData | null | undefined;
  profileError: boolean;
  /** link z e-maila otwarty w innej przeglądarce — trzeba podać adres */
  linkNeedsEmail: boolean;
  busy: string | null;
  fatal: string | null;
}

let state: Session = {
  ready: false,
  user: null,
  guest: false,
  profile: undefined,
  profileError: false,
  linkNeedsEmail: false,
  busy: null,
  fatal: null,
};
const subs = new Set<(s: Session) => void>();
const set = (patch: Partial<Session>) => {
  state = { ...state, ...patch };
  subs.forEach((f) => f(state));
};

export function useSession(): Session {
  const [s, setS] = useState(state);
  useEffect(() => {
    subs.add(setS);
    setS(state);
    return () => {
      subs.delete(setS);
    };
  }, []);
  return s;
}

export const getSession = () => state;

// ── localStorage (bywa niedostępny — wtedy po prostu nie pamiętamy) ──
const KEY_EMAIL = 'qubdud.emailForSignIn';
const KEY_PENDING = 'qubdud.pending';
const PENDING_TTL_MS = 24 * 3600 * 1000;

function lsGet(k: string): string | null {
  try {
    return localStorage.getItem(k);
  } catch {
    return null;
  }
}
function lsSet(k: string, v: string | null) {
  try {
    if (v === null) localStorage.removeItem(k);
    else localStorage.setItem(k, v);
  } catch {
    // tryb prywatny / zablokowane dane witryny
  }
}

export function setPending(p: Pending | null): void {
  lsSet(KEY_PENDING, p ? JSON.stringify({ ...p, at: Date.now() }) : null);
}

function takePending(): Pending | null {
  const raw = lsGet(KEY_PENDING);
  lsSet(KEY_PENDING, null);
  if (!raw) return null;
  try {
    const p = JSON.parse(raw) as Pending & { at?: number };
    return Date.now() - (p.at ?? 0) > PENDING_TTL_MS ? null : p;
  } catch {
    return null;
  }
}

export const rememberedEmail = () => lsGet(KEY_EMAIL) ?? '';

// ── logowanie ──
let anonymous: Promise<void> | null = null;

/** Przeglądanie bez konta = anonimowe logowanie (jak „Przeglądaj” w apce). */
function ensureAnonymous(): Promise<void> {
  const { auth } = ctx();
  if (auth.currentUser) return Promise.resolve();
  anonymous ??= signInAnonymously(auth)
    .then(() => undefined)
    .catch(() => set({ fatal: 'Nie udało się połączyć z QUBDUD. Sprawdź internet i odśwież stronę.' }))
    .finally(() => {
      anonymous = null;
    });
  return anonymous;
}

function stripLinkParams() {
  const url = new URL(location.href);
  for (const k of ['apiKey', 'oobCode', 'mode', 'lang', 'continueUrl', 'tenantId', 'link']) url.searchParams.delete(k);
  history.replaceState(null, '', url.pathname + url.search + url.hash);
}

/** Dokończenie logowania z linku w e-mailu. */
export async function completeEmailLink(email: string): Promise<boolean> {
  const { auth } = ctx();
  try {
    await signInWithEmailLink(auth, email.trim(), location.href);
    lsSet(KEY_EMAIL, null);
    stripLinkParams();
    set({ linkNeedsEmail: false });
    return true;
  } catch (e) {
    const code = errorCode(e);
    if (code === 'auth/invalid-email') {
      toast('Ten adres nie pasuje do linku — wpisz adres, na który przyszedł e-mail', 'error');
      return false;
    }
    stripLinkParams();
    set({ linkNeedsEmail: false });
    toast(
      code === 'auth/invalid-action-code' || code === 'auth/expired-action-code'
        ? 'Link wygasł albo został już użyty — wyślij nowy'
        : 'Nie udało się zalogować — spróbuj ponownie',
      'error',
    );
    return false;
  }
}

export function cancelEmailLink(): void {
  stripLinkParams();
  set({ linkNeedsEmail: false });
}

/** Link logowania wraca na stronę, z której gość zaczął; [pending] wykona się po powrocie. */
export async function sendLoginLink(email: string, pending: Pending): Promise<void> {
  const { auth } = ctx();
  await sendSignInLinkToEmail(auth, email.trim(), {
    url: location.origin + location.pathname + location.search,
    handleCodeInApp: true,
  });
  lsSet(KEY_EMAIL, email.trim());
  setPending(pending);
}

export async function logout(): Promise<void> {
  await signOut(ctx().auth);
  navigate('/');
}

async function refreshProfile() {
  set({ profile: undefined, profileError: false });
  try {
    const profile = await loadMyProfile(ctx());
    set({ profile });
    if (profile) void runPending();
  } catch {
    set({ profileError: true });
  }
}

export const retryProfile = () => void refreshProfile();

export async function saveProfile(p: GuestProfileInput): Promise<void> {
  await createGuestProfile(ctx(), p);
  await refreshProfile();
}

// ── zaległa akcja po zalogowaniu ──
let running = false;

async function runPending() {
  if (running || !state.guest) return;
  const p = takePending();
  if (!p) return;
  running = true;
  try {
    if (p.type === 'request') {
      const draft = await loadDraft();
      if (!draft) {
        toast('Szkic zgłoszenia został w przeglądarce, w której był wypełniany — wypełnij formularz ponownie', 'error');
        navigate('/zglos');
        return;
      }
      set({ busy: 'Wysyłamy zgłoszenie…' });
      await submitDraft(ctx(), draft, (s) => set({ busy: s }));
      navigate('/moje');
      toast('Zgłoszenie wysłane — firmy z okolicy już je widzą');
    } else if (p.type === 'book') {
      set({ busy: 'Rezerwujemy termin…' });
      await bookSlot(ctx(), p.companyId, p.slotId);
      navigate(`/f/${p.companyId}`);
      toast('Zarezerwowano — czeka na akceptację firmy');
    } else if (p.type === 'chat') {
      navigate(`/czat/${p.companyId}`);
    }
  } catch (e) {
    toast(errorText(e), 'error');
    if (p.type === 'request') navigate('/zglos');
  } finally {
    running = false;
    set({ busy: null });
  }
}

export async function initSession(): Promise<void> {
  const { auth } = ctx();
  await auth.authStateReady();
  if (isSignInWithEmailLink(auth, location.href)) {
    const email = rememberedEmail();
    if (email) await completeEmailLink(email);
    else set({ linkNeedsEmail: true });
  }
  onAuthStateChanged(auth, (user) => {
    const guest = !!user && !user.isAnonymous;
    if (user?.uid === state.user?.uid && guest === state.guest) return;
    set({ user, guest, profile: guest ? undefined : null, profileError: false });
    if (!user) void ensureAnonymous();
    else if (guest) void refreshProfile();
  });
  await ensureAnonymous();
  set({ ready: true });
}
