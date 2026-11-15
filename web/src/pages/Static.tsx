import { useEffect } from 'preact/hooks';
import { RULES } from '../generated/dictionaries.ts';
import { useSession } from '../session.ts';
import { useTitle } from '../ui/components.tsx';

export function Home() {
  useTitle('');
  const session = useSession();
  return (
    <main class="page" id="main">
      <section class="hero">
        <h1>
          Opisz, czego potrzebujesz.
          <br />
          Firmy z okolicy przyślą oferty.
        </h1>
        <p class="lead">
          QUBDUD łączy klientów z lokalnymi firmami usługowymi — od hydraulika po fryzjera. Zgłoszenie dodasz tutaj, bez
          instalowania aplikacji i bez hasła. Wystarczy adres e-mail.
        </p>
        <div class="row">
          <a class="btn btn--primary btn--lg" href="/zglos">
            Dodaj zgłoszenie
          </a>
          <a class="btn btn--ghost btn--lg" href="/moje">
            Moje sprawy
          </a>
        </div>
      </section>

      <section class="card">
        <h2>Jak to działa</h2>
        <ol class="steps">
          <li>
            <strong>Opisz sprawę.</strong> Kategoria, kilka słów, zdjęcie i miejsce. Firmy widzą tylko okolicę, nie Twój adres.
          </li>
          <li>
            <strong>Porównaj oferty.</strong> Cena, termin i opinie o firmie — oferty pojawiają się na żywo w „Moich sprawach”.
          </li>
          <li>
            <strong>Przyjmij i ustal szczegóły.</strong> Napisz do firmy albo zadzwoń. Po wykonaniu potwierdź realizację.
          </li>
        </ol>
      </section>

      <section class="card">
        <h2>Masz link do wizytówki firmy?</h2>
        <p>
          Na wizytówce zobaczysz opinie, zdjęcia realizacji i wolne terminy na najbliższy tydzień — termin zarezerwujesz jednym
          kliknięciem. Firmy obsługują zgłoszenia, rozmowy i rezerwacje w aplikacji QUBDUD.
        </p>
        {session.guest && (
          <p>
            <a href="/moje?tab=rezerwacje">Moje rezerwacje →</a>
          </p>
        )}
      </section>
    </main>
  );
}

export function Rules() {
  useTitle('Regulamin i polityka prywatności');
  useEffect(() => {
    if (location.hash) document.getElementById(location.hash.slice(1))?.scrollIntoView();
  }, []);
  return (
    <main class="page rules" id="main">
      {RULES.map((doc, i) => (
        <section key={doc.title} id={i === 0 ? 'regulamin' : 'rodo'} class="stack">
          {i === 0 ? <h1>{doc.title}</h1> : <h2 class="h1">{doc.title}</h2>}
          {doc.sections.map((s) => (
            <article class="card" key={s.title}>
              <h3>{s.title}</h3>
              {s.body.split('\n').map((line, j) => (
                <p key={j}>{line}</p>
              ))}
            </article>
          ))}
        </section>
      ))}
    </main>
  );
}

export function NotFound() {
  useTitle('Nie znaleziono');
  return (
    <main class="page" id="main">
      <div class="card empty">
        <h1>Nie ma takiej strony</h1>
        <a class="btn btn--primary" href="/">
          Strona główna
        </a>
      </div>
    </main>
  );
}

export function ConfigMissing({ keys }: { keys: string[] }) {
  return (
    <main class="page" id="main">
      <div class="card">
        <h1>Strona nie jest jeszcze skonfigurowana</h1>
        <p>Brakuje konfiguracji Firebase ({keys.join(', ')}). Uzupełnij plik .env.local według .env.example i zbuduj stronę ponownie.</p>
      </div>
    </main>
  );
}
