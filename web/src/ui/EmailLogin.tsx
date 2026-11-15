import type { ComponentChildren } from 'preact';
import { useState } from 'preact/hooks';
import { errorCode } from '../data/ctx.ts';
import { rememberedEmail, sendLoginLink } from '../session.ts';
import type { Pending } from '../session.ts';

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;

function linkErrorText(e: unknown): string {
  switch (errorCode(e)) {
    case 'auth/invalid-email':
      return 'Nieprawidłowy adres e-mail';
    case 'auth/too-many-requests':
    case 'auth/quota-exceeded':
      return 'Za dużo prób — spróbuj ponownie za kilka minut';
    case 'auth/operation-not-allowed':
      return 'Logowanie linkiem jest chwilowo niedostępne';
    case 'auth/unauthorized-continue-uri':
    case 'auth/unauthorized-domain':
      return 'Ta strona nie może jeszcze wysyłać linków logowania';
    case 'auth/network-request-failed':
      return 'Brak połączenia — sprawdź internet';
    default:
      return 'Nie udało się wysłać linku — spróbuj ponownie';
  }
}

/** Logowanie bez hasła: e-mail → link → powrót na tę stronę i wykonanie [pending]. */
export function EmailLogin({
  pending,
  title = 'Zaloguj się adresem e-mail',
  children,
  beforeSend,
  onCancel,
}: {
  pending: Pending;
  title?: string;
  children?: ComponentChildren;
  beforeSend?: () => Promise<void>;
  onCancel?: () => void;
}) {
  const [email, setEmail] = useState(rememberedEmail());
  const [error, setError] = useState('');
  const [sending, setSending] = useState(false);
  const [sentTo, setSentTo] = useState('');

  const send = async (e?: Event) => {
    e?.preventDefault();
    const v = email.trim();
    if (!EMAIL_RE.test(v)) {
      setError('Wpisz poprawny adres e-mail');
      return;
    }
    setError('');
    setSending(true);
    try {
      await beforeSend?.();
      await sendLoginLink(v, pending);
      setSentTo(v);
    } catch (err) {
      setError(linkErrorText(err));
    } finally {
      setSending(false);
    }
  };

  if (sentTo) {
    return (
      <section class="card card--accent" aria-live="polite">
        <h2>Sprawdź skrzynkę</h2>
        <p>
          Wysłaliśmy link logowania na <strong>{sentTo}</strong>. Otwórz go <strong>na tym urządzeniu, w tej przeglądarce</strong> —
          wrócisz tutaj i dokończymy sprawę automatycznie.
        </p>
        <p class="muted">Nie widzisz wiadomości? Zajrzyj do folderu Spam lub Oferty. Link działa jednorazowo.</p>
        <div class="row">
          <button class="btn btn--ghost" type="button" onClick={() => void send()} disabled={sending}>
            Wyślij ponownie
          </button>
          <button class="btn btn--ghost" type="button" onClick={() => setSentTo('')}>
            Zmień adres
          </button>
        </div>
      </section>
    );
  }

  return (
    <section class="card card--accent">
      <h2>{title}</h2>
      {children}
      <p class="muted">Bez hasła i bez instalowania aplikacji — wyślemy jednorazowy link na Twój e-mail.</p>
      <form class="inline-form" onSubmit={send} noValidate>
        <div class={`field${error ? ' field--error' : ''}`}>
          <label class="field__label" for="login-email">
            Adres e-mail
          </label>
          <input
            id="login-email"
            type="email"
            inputMode="email"
            autoComplete="email"
            required
            value={email}
            onInput={(e) => setEmail((e.target as HTMLInputElement).value)}
            aria-invalid={!!error}
            aria-describedby={error ? 'login-email-error' : undefined}
          />
          {error && (
            <p class="field__error" id="login-email-error" role="alert">
              {error}
            </p>
          )}
        </div>
        <div class="row">
          <button class="btn btn--primary" type="submit" disabled={sending}>
            {sending ? 'Wysyłanie…' : 'Wyślij link'}
          </button>
          {onCancel && (
            <button class="btn btn--ghost" type="button" onClick={onCancel}>
              Anuluj
            </button>
          )}
        </div>
      </form>
    </section>
  );
}
