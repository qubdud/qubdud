import { useState } from 'preact/hooks';
import { errorText } from '../data/ctx.ts';
import { validateGuestProfile } from '../data/profile.ts';
import type { GuestProfileInput } from '../data/profile.ts';
import { logout, saveProfile } from '../session.ts';
import { Field, useTitle } from './components.tsx';
import { toast } from './toast.tsx';

/** Pierwsze logowanie: profil jak rejestracja klienta w apce (imię, nazwisko, telefon, zgody). */
export function ProfileSetup({ email }: { email: string }) {
  useTitle('Twoje dane');
  const [form, setForm] = useState<GuestProfileInput>({ firstName: '', lastName: '', phone: '' });
  const [terms, setTerms] = useState(false);
  const [rodo, setRodo] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);

  const input = (k: keyof GuestProfileInput) => (e: Event) => setForm({ ...form, [k]: (e.target as HTMLInputElement).value });

  const submit = async (e: Event) => {
    e.preventDefault();
    const errs: Record<string, string> = { ...validateGuestProfile(form) };
    if (!terms) errs.terms = 'Zaakceptuj regulamin';
    if (!rodo) errs.rodo = 'Wyraź zgodę na przetwarzanie danych';
    setErrors(errs);
    if (Object.keys(errs).length) {
      document.getElementById(`profile-${Object.keys(errs)[0]}`)?.focus();
      return;
    }
    setSaving(true);
    try {
      await saveProfile(form);
    } catch (err) {
      toast(errorText(err, 'Nie udało się zapisać danych — spróbuj ponownie'), 'error');
      setSaving(false);
    }
  };

  const text = (k: keyof GuestProfileInput, label: string, autoComplete: string, type = 'text') => (
    <Field id={`profile-${k}`} label={label} error={errors[k]}>
      <input
        id={`profile-${k}`}
        type={type}
        autoComplete={autoComplete}
        value={form[k]}
        onInput={input(k)}
        maxLength={k === 'phone' ? 50 : 80}
        aria-invalid={!!errors[k]}
        aria-describedby={errors[k] ? `profile-${k}-error` : undefined}
        required
      />
    </Field>
  );

  return (
    <main class="page" id="main">
      <form class="card" onSubmit={submit} noValidate>
        <h1>Jeszcze chwila</h1>
        <p>
          Logujesz się jako <strong>{email}</strong>. Uzupełnij dane kontaktowe — bez nich firma nie skontaktuje się z Tobą
          w sprawie zlecenia ani rezerwacji.
        </p>
        <div class="grid2">
          {text('firstName', 'Imię', 'given-name')}
          {text('lastName', 'Nazwisko', 'family-name')}
        </div>
        {text('phone', 'Telefon', 'tel', 'tel')}

        <div class="info">
          Telefon i e-mail zobaczy tylko firma, której ofertę przyjmiesz albo u której zarezerwujesz termin. Firmy z okolicy
          widzą treść zgłoszenia, przybliżone miejsce oraz Twoje imię i nazwisko. Wiadomości widzą wyłącznie uczestnicy rozmowy.
        </div>

        <div class={`check${errors.terms ? ' field--error' : ''}`}>
          <input id="profile-terms" type="checkbox" checked={terms} onChange={(e) => setTerms((e.target as HTMLInputElement).checked)} />
          <label for="profile-terms">
            Akceptuję{' '}
            <a href="/regulamin" target="_blank" rel="noopener">
              regulamin QUBDUD
            </a>
            .
          </label>
          {errors.terms && <p class="field__error">{errors.terms}</p>}
        </div>
        <div class={`check${errors.rodo ? ' field--error' : ''}`}>
          <input id="profile-rodo" type="checkbox" checked={rodo} onChange={(e) => setRodo((e.target as HTMLInputElement).checked)} />
          <label for="profile-rodo">
            Wyrażam zgodę na przetwarzanie moich danych osobowych (imię, nazwisko, e-mail, telefon) w celu świadczenia usług
            QUBDUD, zgodnie z{' '}
            <a href="/regulamin#rodo" target="_blank" rel="noopener">
              polityką prywatności (RODO)
            </a>
            .
          </label>
          {errors.rodo && <p class="field__error">{errors.rodo}</p>}
        </div>

        <div class="row">
          <button class="btn btn--primary btn--lg" type="submit" disabled={saving}>
            {saving ? 'Zapisywanie…' : 'Zapisz i kontynuuj'}
          </button>
          <button class="btn btn--ghost" type="button" onClick={() => void logout()}>
            Wyloguj
          </button>
        </div>
      </form>
    </main>
  );
}
