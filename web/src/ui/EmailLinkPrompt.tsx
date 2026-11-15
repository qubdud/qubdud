import { useState } from 'preact/hooks';
import { cancelEmailLink, completeEmailLink } from '../session.ts';
import { useTitle } from './components.tsx';

/** Link z e-maila otwarty w innej przeglądarce: trzeba potwierdzić adres. */
export function EmailLinkPrompt() {
  useTitle('Logowanie');
  const [email, setEmail] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e: Event) => {
    e.preventDefault();
    if (!email.trim()) return;
    setBusy(true);
    await completeEmailLink(email);
    setBusy(false);
  };

  return (
    <main class="page" id="main">
      <form class="card" onSubmit={submit}>
        <h1>Potwierdź adres e-mail</h1>
        <p>
          Ten link logowania został zamówiony w innej przeglądarce albo na innym urządzeniu. Wpisz adres, na który przyszedł
          e-mail. Niewysłany szkic zgłoszenia (jeśli był) został w tamtej przeglądarce.
        </p>
        <div class="field">
          <label class="field__label" for="link-email">
            Adres e-mail
          </label>
          <input
            id="link-email"
            type="email"
            autoComplete="email"
            required
            value={email}
            onInput={(e) => setEmail((e.target as HTMLInputElement).value)}
          />
        </div>
        <div class="row">
          <button class="btn btn--primary" type="submit" disabled={busy}>
            {busy ? 'Logowanie…' : 'Zaloguj'}
          </button>
          <button class="btn btn--ghost" type="button" onClick={cancelEmailLink}>
            Anuluj
          </button>
        </div>
      </form>
    </main>
  );
}
