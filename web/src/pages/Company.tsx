import { useEffect, useState } from 'preact/hooks';
import {
  averageScore,
  getCompany,
  getCompanyPromos,
  getCompanyRealizations,
  getCompanyReviews,
  getCompletedJobsCount,
} from '../data/company.ts';
import type { Company, PortfolioPhoto, Promo, Review } from '../data/company.ts';
import { errorText } from '../data/ctx.ts';
import { dateTimeLabel, dayLabel, httpUrl, imageSrc, plural, shortDate, timeLabel } from '../data/format.ts';
import { bookSlot, cancelSlotBooking, watchSlots } from '../data/slots.ts';
import type { Slot } from '../data/slots.ts';
import { ctx } from '../firebase.ts';
import { useSession } from '../session.ts';
import { Avatar, Spinner, Stars, useTitle } from '../ui/components.tsx';
import { confirmDialog } from '../ui/dialog.tsx';
import { EmailLogin } from '../ui/EmailLogin.tsx';
import { toast } from '../ui/toast.tsx';

interface CardData {
  company: Company;
  promos: Promo[];
  reviews: Review[];
  photos: PortfolioPhoto[];
}

export function CompanyPage({ id }: { id: string }) {
  const session = useSession();
  const [data, setData] = useState<CardData | null | undefined>(undefined);
  const [jobs, setJobs] = useState(0);
  useTitle(data?.company.companyName ?? 'Firma');

  useEffect(() => {
    if (!session.user) return;
    let alive = true;
    (async () => {
      const c = ctx();
      const company = await getCompany(c, id);
      if (!company) return null;
      const [promos, reviews, photos] = await Promise.all([
        getCompanyPromos(c, id).catch(() => []),
        getCompanyReviews(c, id).catch(() => []),
        getCompanyRealizations(c, id).catch(() => []),
      ]);
      return { company, promos, reviews, photos };
    })()
      .then((d) => alive && setData(d))
      .catch(() => alive && setData(null));
    return () => {
      alive = false;
    };
  }, [id, session.user?.uid]);

  useEffect(() => {
    if (!session.guest || !data) return;
    getCompletedJobsCount(ctx(), id).then(setJobs).catch(() => {});
  }, [id, session.guest, !!data]);

  if (data === undefined) return <Spinner />;
  if (data === null) {
    return (
      <main class="page" id="main">
        <div class="card empty">
          <h1>Nie znaleziono firmy</h1>
          <p>Link może być nieaktualny albo firma usunęła konto.</p>
          <a class="btn btn--primary" href="/">
            Strona główna
          </a>
        </div>
      </main>
    );
  }

  const { company: c, promos, reviews, photos } = data;
  const avg = averageScore(reviews);
  const own = session.user?.uid === c.id;

  return (
    <main class="page" id="main">
      <header class="card company">
        <div class="company__head">
          <Avatar name={c.companyName} company />
          <div>
            <h1>{c.companyName}</h1>
            <p class="muted">{[c.companySector || c.companyCategory, c.companyCity].filter(Boolean).join(' · ')}</p>
            <p class="small">
              {reviews.length ? (
                <>
                  <Stars score={avg} /> <strong>{avg.toLocaleString('pl-PL')}</strong> ({reviews.length}{' '}
                  {plural(reviews.length, 'opinia', 'opinie', 'opinii')})
                </>
              ) : (
                <span class="muted">Bez opinii</span>
              )}
              {jobs > 0 && (
                <span class="ok-text">
                  {' '}
                  · ✓ {jobs} {plural(jobs, 'zrealizowane zlecenie', 'zrealizowane zlecenia', 'zrealizowanych zleceń')}
                </span>
              )}
            </p>
          </div>
        </div>
        {c.bio && <p class="company__bio">{c.bio}</p>}
        {session.guest ? <CompanyContact c={c} /> : <p class="muted small">Telefon i adres firmy zobaczysz po zalogowaniu.</p>}
        {!own && (
          <div class="row">
            <a class="btn btn--primary" href={`/czat/${c.id}`}>
              💬 Napisz
            </a>
            <a class="btn btn--ghost" href="#terminy">
              📅 Umów termin
            </a>
          </div>
        )}
      </header>

      <SlotsSection company={c} own={own} />

      {promos.length > 0 && (
        <section class="card">
          <h2>Prezentacje firmy</h2>
          <div class="videos">
            {promos.map((p) => (
              <video key={p.id} src={httpUrl(p.fileUrl)} poster={imageSrc(p.thumbUrl) || undefined} controls preload="none" playsInline>
                Twoja przeglądarka nie odtwarza filmów.
              </video>
            ))}
          </div>
        </section>
      )}

      {photos.length > 0 && (
        <section class="card">
          <h2>Realizacje</h2>
          <div class="portfolio">
            {photos.map((p) => (
              <figure key={p.id}>
                <a href={httpUrl(p.imageUrl) || undefined} target="_blank" rel="noopener">
                  <img src={imageSrc(p.imageUrl)} alt={`Realizacja: ${p.category || c.companySector}`} loading="lazy" />
                </a>
                {httpUrl(p.beforeUrl) && (
                  <a href={httpUrl(p.beforeUrl)} target="_blank" rel="noopener" class="small">
                    Zobacz „przed”
                  </a>
                )}
                {p.byClient && <figcaption class="small muted">zdjęcie od klienta</figcaption>}
              </figure>
            ))}
          </div>
          <p class="muted small">Zdjęcia z zadań zrealizowanych i potwierdzonych przez klientów.</p>
        </section>
      )}

      <section class="card">
        <h2>Opinie</h2>
        {reviews.length === 0 ? (
          <p class="muted">Ta firma nie ma jeszcze opinii.</p>
        ) : (
          <ul class="stack">
            {reviews.map((r) => (
              <li key={r.id} class="review">
                <div class="review__head">
                  <Stars score={r.score} label={`Ocena ${r.score} na 5`} />
                  <strong>{r.authorName || 'Klient'}</strong>
                  <span class="muted small">{shortDate(r.timestamp)}</span>
                </div>
                <div class="review__body">
                  {imageSrc(r.thumbUrl) && (
                    <a href={httpUrl(r.fileUrl) || httpUrl(r.thumbUrl) || undefined} target="_blank" rel="noopener">
                      <img src={imageSrc(r.thumbUrl)} alt="Zdjęcie do opinii" loading="lazy" />
                    </a>
                  )}
                  {r.description && <p>{r.description}</p>}
                </div>
                {r.comments.map((cm) => (
                  <div key={cm.id} class={`comment${cm.isOwner ? ' comment--owner' : ''}`}>
                    <strong>{cm.authorName || 'Użytkownik'}</strong>{' '}
                    {cm.isOwner && <span class="badge badge--info">firma</span>} {cm.text}
                  </div>
                ))}
              </li>
            ))}
          </ul>
        )}
        <p class="muted small">Opinię może wystawić klient po potwierdzonej realizacji albo przyjętym terminie — w aplikacji QUBDUD.</p>
      </section>
    </main>
  );
}

function CompanyContact({ c }: { c: Company }) {
  const rows: { icon: string; text: string; href: string }[] = [];
  if (c.showPhone && c.phone) rows.push({ icon: '📞', text: c.phone, href: `tel:${c.phone.replace(/[^0-9+]/g, '')}` });
  if (c.showAddress && c.address) {
    rows.push({ icon: '📍', text: c.address, href: `https://www.openstreetmap.org/search?query=${encodeURIComponent(c.address)}` });
  }
  if (c.www) rows.push({ icon: '🌐', text: c.www.replace(/^https?:\/\//, ''), href: /^https?:\/\//.test(c.www) ? c.www : `https://${c.www}` });
  if (c.contactEmail) rows.push({ icon: '✉️', text: c.contactEmail, href: `mailto:${c.contactEmail}` });
  if (!rows.length) return null;
  return (
    <ul class="contact">
      {rows.map((r) => (
        <li key={r.href}>
          <span aria-hidden="true">{r.icon}</span>{' '}
          <a href={r.href} target={r.href.startsWith('http') ? '_blank' : undefined} rel="noopener">
            {r.text}
          </a>
        </li>
      ))}
    </ul>
  );
}

function SlotsSection({ company, own }: { company: Company; own: boolean }) {
  const session = useSession();
  const [slots, setSlots] = useState<Slot[] | undefined>(undefined);
  const [error, setError] = useState(false);
  const [busy, setBusy] = useState(false);
  const [loginFor, setLoginFor] = useState<Slot | null>(null);
  const me = session.guest ? (session.user?.uid ?? '') : '';

  useEffect(() => {
    if (!session.user) return;
    setSlots(undefined);
    setError(false);
    return watchSlots(ctx(), company.id, setSlots, () => setError(true));
  }, [company.id, session.user?.uid]);

  const tap = async (s: Slot) => {
    if (own) return;
    const mine = !!me && s.bookedBy === me;
    if (s.status === 'free') {
      if (!session.guest) {
        setLoginFor(s);
        return;
      }
      const ok = await confirmDialog({
        title: 'Zarezerwować termin?',
        body: (
          <>
            <p>
              <strong>{company.companyName}</strong>
            </p>
            <p class="big">📅 {dateTimeLabel(s.start)}</p>
            {company.slotsInfo && <p class="info">{company.slotsInfo}</p>}
            <p class="muted small">Firma zobaczy Twój telefon i e-mail, potwierdzi albo odrzuci rezerwację — status zobaczysz w „Moich sprawach”.</p>
          </>
        ),
        ok: 'Rezerwuj',
      });
      if (!ok) return;
      setBusy(true);
      try {
        await bookSlot(ctx(), company.id, s.id);
        toast('Zarezerwowano — czeka na akceptację firmy');
      } catch (e) {
        toast(errorText(e), 'error');
      } finally {
        setBusy(false);
      }
      return;
    }
    if (mine) {
      const ok = await confirmDialog({
        title: 'Twoja rezerwacja',
        body:
          s.status === 'accepted'
            ? 'Termin zaakceptowany przez firmę. Odwołać rezerwację? Firma dostanie powiadomienie.'
            : 'Czeka na akceptację firmy. Odwołać rezerwację?',
        ok: 'Odwołaj',
        cancel: 'Zostaw',
        danger: true,
      });
      if (!ok) return;
      setBusy(true);
      try {
        await cancelSlotBooking(ctx(), company.id, s.id);
        toast('Odwołano rezerwację');
      } catch (e) {
        toast(errorText(e), 'error');
      } finally {
        setBusy(false);
      }
    }
  };

  const byDay = new Map<string, Slot[]>();
  for (const s of slots ?? []) {
    const k = dayLabel(s.start);
    byDay.set(k, [...(byDay.get(k) ?? []), s]);
  }

  return (
    <section class="card" id="terminy" aria-labelledby="slots-title">
      <h2 id="slots-title">Umów (najbliższe 7 dni)</h2>
      {company.slotsInfo && <p class="slots-info">{company.slotsInfo}</p>}
      {error ? (
        <p class="muted">Nie udało się wczytać terminów.</p>
      ) : slots === undefined ? (
        <Spinner label="Wczytywanie terminów…" />
      ) : !slots.length ? (
        <p class="muted">Firma nie ma teraz wolnych terminów. Napisz do niej, żeby umówić się inaczej.</p>
      ) : (
        <>
          <div class="slots">
            {[...byDay.entries()].map(([day, list]) => (
              <div class="slots__day" key={day}>
                <h3>{day}</h3>
                <div class="slots__list">
                  {list.map((s) => {
                    const mine = !!me && s.bookedBy === me;
                    const cls = s.status === 'free' ? 'slot--free' : mine ? (s.status === 'accepted' ? 'slot--accepted' : 'slot--pending') : 'slot--taken';
                    const what = s.status === 'free' ? 'wolny — zarezerwuj' : mine ? (s.status === 'accepted' ? 'Twoja rezerwacja, potwierdzona' : 'Twoja rezerwacja, czeka na firmę') : 'zajęty';
                    return (
                      <button
                        key={s.id}
                        type="button"
                        class={`slot ${cls}${loginFor?.id === s.id ? ' slot--selected' : ''}`}
                        disabled={busy || own || (s.status !== 'free' && !mine)}
                        aria-label={`${day}, ${timeLabel(s.start)} — ${what}`}
                        onClick={() => void tap(s)}
                      >
                        {timeLabel(s.start)}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
          <p class="muted small">
            {own
              ? 'Tak klienci widzą Twoje terminy. Zarządzasz nimi w aplikacji.'
              : 'Kliknij godzinę, aby zarezerwować. Żółta — czeka na akceptację firmy, zielona — przyjęta.'}
          </p>
        </>
      )}
      {loginFor && !session.guest && (
        <EmailLogin
          pending={{ type: 'book', companyId: company.id, slotId: loginFor.id }}
          title={`Rezerwacja: ${dateTimeLabel(loginFor.start)}`}
          onCancel={() => setLoginFor(null)}
        >
          <p>
            Podaj e-mail — wyślemy link logowania. Po powrocie zarezerwujemy ten termin automatycznie. Firma zobaczy Twój telefon
            i e-mail, potwierdzi albo odrzuci rezerwację.
          </p>
        </EmailLogin>
      )}
      {session.guest && !own && (
        <p class="small">
          <a href="/moje?tab=rezerwacje">Moje rezerwacje →</a>
        </p>
      )}
    </section>
  );
}
