import { useEffect, useState } from 'preact/hooks';
import type { ChatOverview } from '../data/chat.ts';
import { watchChats } from '../data/chat.ts';
import { averageScore, getCompany, getCompanyReviews } from '../data/company.ts';
import type { Company } from '../data/company.ts';
import { errorText } from '../data/ctx.ts';
import {
  BOOKING_LABEL,
  STAGE_LABEL,
  caseCode,
  dateTimeLabel,
  httpUrl,
  imageSrc,
  offerPriceLabel,
  plural,
  shortDate,
} from '../data/format.ts';
import {
  myRequestRealizations,
  requestStage,
  setOfferStatus,
  setRealizationStatus,
  watchMyRequests,
  watchOffers,
} from '../data/requests.ts';
import type { Offer, Realization, RequestDoc } from '../data/requests.ts';
import { cancelSlotBooking, watchMyBookings } from '../data/slots.ts';
import type { Booking } from '../data/slots.ts';
import { ctx } from '../firebase.ts';
import { OFFER_WHEN, REQUEST_TIMING } from '../generated/dictionaries.ts';
import { useRoute } from '../router.ts';
import { logout, useSession } from '../session.ts';
import { Avatar, Badge, Spinner, Stars, useTitle } from '../ui/components.tsx';
import { confirmDialog } from '../ui/dialog.tsx';
import { EmailLogin } from '../ui/EmailLogin.tsx';
import { toast } from '../ui/toast.tsx';

type Tab = 'zgloszenia' | 'rezerwacje' | 'wiadomosci';
const TABS: { id: Tab; label: string }[] = [
  { id: 'zgloszenia', label: 'Zgłoszenia' },
  { id: 'rezerwacje', label: 'Rezerwacje' },
  { id: 'wiadomosci', label: 'Wiadomości' },
];

/** Nasłuch Firestore jako stan komponentu: undefined = wczytywanie. */
function useLive<T>(
  subscribe: ((next: (v: T) => void, error: (e: unknown) => void) => () => void) | null,
  deps: unknown[],
): { data: T | undefined; error: boolean } {
  const [data, setData] = useState<T | undefined>(undefined);
  const [error, setError] = useState(false);
  useEffect(() => {
    setData(undefined);
    setError(false);
    if (!subscribe) return;
    return subscribe(setData, () => setError(true));
  }, deps);
  return { data, error };
}

export function Mine() {
  useTitle('Moje sprawy');
  const session = useSession();
  const { params } = useRoute();
  const tab = (TABS.find((t) => t.id === params.get('tab'))?.id ?? 'zgloszenia') as Tab;
  const ready = session.guest && !!session.profile;

  const chats = useLive<ChatOverview[]>(ready ? (n, e) => watchChats(ctx(), n, e) : null, [ready, session.user?.uid]);
  const unread = (chats.data ?? []).reduce((s, c) => s + c.unread, 0);

  if (!session.guest) {
    return (
      <main class="page" id="main">
        <h1>Moje sprawy</h1>
        <EmailLogin pending={{ type: 'view' }} title="Zaloguj się, żeby zobaczyć swoje sprawy">
          <p>Tu zobaczysz swoje zgłoszenia i oferty firm, rezerwacje terminów i wiadomości — wszystko na żywo.</p>
        </EmailLogin>
      </main>
    );
  }
  if (!session.profile) return <Spinner />;

  return (
    <main class="page" id="main">
      <div class="page-head">
        <h1>Moje sprawy</h1>
        <div class="muted small">
          {session.user?.email} ·{' '}
          <button class="link" type="button" onClick={() => void logout()}>
            Wyloguj
          </button>
        </div>
      </div>
      <nav class="tabs" aria-label="Moje sprawy">
        {TABS.map((t) => (
          <a
            key={t.id}
            href={`/moje?tab=${t.id}`}
            class={`tabs__tab${tab === t.id ? ' tabs__tab--on' : ''}`}
            aria-current={tab === t.id ? 'page' : undefined}
          >
            {t.label}
            {t.id === 'wiadomosci' && unread > 0 && (
              <span class="count" aria-label={`${unread} nieprzeczytanych`}>
                {unread}
              </span>
            )}
          </a>
        ))}
      </nav>
      {tab === 'zgloszenia' && <RequestsTab />}
      {tab === 'rezerwacje' && <BookingsTab />}
      {tab === 'wiadomosci' && <ChatsTab chats={chats.data} error={chats.error} />}
    </main>
  );
}

// ── zgłoszenia ──────────────────────────────────────────────────────────────

function RequestsTab() {
  const { data, error } = useLive<RequestDoc[]>((n, e) => watchMyRequests(ctx(), n, e), []);
  if (error) return <p class="card">Nie udało się wczytać zgłoszeń. Odśwież stronę.</p>;
  if (!data) return <Spinner />;
  if (!data.length) {
    return (
      <div class="card empty">
        <p>Nie masz jeszcze zgłoszeń.</p>
        <a class="btn btn--primary" href="/zglos">
          Dodaj zgłoszenie
        </a>
      </div>
    );
  }
  return (
    <div class="stack">
      {data.map((r) => (
        <RequestCard key={r.id} request={r} />
      ))}
    </div>
  );
}

const STAGE_TONE = {
  open: 'info',
  inProgress: 'ok',
  photosPending: 'warn',
  photosRejected: 'warn',
  realized: 'ok',
  expired: 'neutral',
  closed: 'neutral',
} as const;

function RequestCard({ request: r }: { request: RequestDoc }) {
  const stage = requestStage(r);
  const brief = [REQUEST_TIMING[r.timing], r.budget !== null ? `budżet do ${r.budget} zł` : '', ...Object.values(r.answers)]
    .filter(Boolean)
    .join(' · ');
  return (
    <article class="card request" aria-labelledby={`req-${r.id}`}>
      <div class="request__head">
        {imageSrc(r.thumbUrl) ? (
          <img class="request__thumb" src={imageSrc(r.thumbUrl)} alt="" loading="lazy" />
        ) : (
          <div class="request__thumb request__thumb--empty" aria-hidden="true">
            📝
          </div>
        )}
        <div class="request__meta">
          <h2 id={`req-${r.id}`}>
            {r.sector}
            {r.is24 && <span class="urgent"> · 🔴 24 h</span>}
          </h2>
          <p class="muted small">
            {[r.city, shortDate(r.timestamp)].filter(Boolean).join(' · ')}
          </p>
          <Badge tone={STAGE_TONE[stage]}>{STAGE_LABEL[stage]}</Badge>
        </div>
      </div>
      {r.description && <p class="request__desc">{r.description}</p>}
      {brief && <p class="muted small">{brief}</p>}
      {stage === 'open' && <OffersSection request={r} />}
      {r.takenBy && (stage === 'inProgress' || stage === 'photosPending' || stage === 'photosRejected' || stage === 'realized') && (
        <TakenSection request={r} stage={stage} />
      )}
    </article>
  );
}

interface CompanyStats {
  rating: number;
  reviews: number;
}

function useCompanyStats(ids: string[]): Record<string, CompanyStats> {
  const [stats, setStats] = useState<Record<string, CompanyStats>>({});
  const key = ids.join(',');
  useEffect(() => {
    let alive = true;
    for (const id of ids) {
      if (stats[id]) continue;
      getCompanyReviews(ctx(), id)
        .then((r) => alive && setStats((s) => ({ ...s, [id]: { rating: averageScore(r), reviews: r.length } })))
        .catch(() => {});
    }
    return () => {
      alive = false;
    };
  }, [key]);
  return stats;
}

function OffersSection({ request }: { request: RequestDoc }) {
  const { data, error } = useLive<Offer[]>((n, e) => watchOffers(ctx(), request.id, n, e), [request.id]);
  const [busy, setBusy] = useState(false);
  const visible = (data ?? []).filter((o) => o.status !== 'rejected' && o.status !== 'closed');
  const stats = useCompanyStats(visible.map((o) => o.companyId));

  if (error) return <p class="muted">Nie udało się wczytać ofert.</p>;
  if (!data) return <Spinner label="Wczytywanie ofert…" />;
  if (!visible.length) {
    return (
      <div class="info">
        Czekamy na oferty firm z okolicy — pojawią się tutaj od razu, bez odświeżania. Czasem odpowiedź przychodzi następnego
        dnia.
      </div>
    );
  }

  const prices = visible.map((o) => o.price).filter((p): p is number => p !== null);
  const cheapest = prices.length > 1 ? Math.min(...prices) : null;

  const decide = async (o: Offer, status: 'accepted' | 'rejected') => {
    const accept = status === 'accepted';
    const ok = await confirmDialog({
      title: accept ? `Przyjąć ofertę firmy ${o.companyName}?` : `Odrzucić ofertę firmy ${o.companyName}?`,
      body: accept
        ? 'Firma dostanie powiadomienie i zobaczy Twój telefon, e-mail i dokładne miejsce, żeby się z Tobą skontaktować. Zgłoszenie zniknie z listy innych firm, a ich oferty zostaną zamknięte.'
        : 'Firma dostanie powiadomienie, że jej oferta została odrzucona.',
      ok: accept ? 'Przyjmij' : 'Odrzuć',
      danger: !accept,
    });
    if (!ok) return;
    setBusy(true);
    try {
      await setOfferStatus(ctx(), { id: request.id, userId: request.userId }, o.companyId, o.companyName, status);
      toast(accept ? 'Przyjęto ofertę — firma się z Tobą skontaktuje' : 'Odrzucono ofertę');
    } catch (e) {
      toast(errorText(e, 'Nie udało się zapisać decyzji'), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <section class="offers" aria-label="Oferty">
      <h3>
        {visible.length} {plural(visible.length, 'oferta', 'oferty', 'ofert')}
      </h3>
      <ul class="stack">
        {visible.map((o) => {
          const s = stats[o.companyId];
          const price = offerPriceLabel(o);
          return (
            <li key={o.companyId} class="offer">
              <div class="offer__head">
                <a href={`/f/${o.companyId}`} class="offer__name">
                  {o.companyName}
                </a>
                {s && s.reviews > 0 ? (
                  <span class="small">
                    <Stars score={s.rating} /> {s.rating.toLocaleString('pl-PL')} ({s.reviews} {plural(s.reviews, 'opinia', 'opinie', 'opinii')})
                  </span>
                ) : (
                  s && <span class="muted small">Bez opinii</span>
                )}
              </div>
              {(price || OFFER_WHEN[o.when]) && (
                <p class="offer__price">
                  {price && <strong>{price}</strong>}
                  {cheapest !== null && o.price === cheapest && <Badge tone="ok">najtańsza</Badge>}
                  {OFFER_WHEN[o.when] && <span class="muted"> · {OFFER_WHEN[o.when]}</span>}
                </p>
              )}
              {o.message && <p class="offer__msg">{o.message}</p>}
              {o.status === 'maybe' && <p class="muted small">Oznaczona w aplikacji: „zastanawiam się”</p>}
              <div class="row">
                <button class="btn btn--primary" type="button" disabled={busy} onClick={() => void decide(o, 'accepted')}>
                  Przyjmij
                </button>
                <button class="btn btn--ghost" type="button" disabled={busy} onClick={() => void decide(o, 'rejected')}>
                  Odrzuć
                </button>
                <a class="btn btn--ghost" href={`/czat/${o.companyId}`}>
                  Napisz
                </a>
              </div>
            </li>
          );
        })}
      </ul>
    </section>
  );
}

function TakenSection({ request: r, stage }: { request: RequestDoc; stage: ReturnType<typeof requestStage> }) {
  const [company, setCompany] = useState<Company | null>(null);
  const [photos, setPhotos] = useState<Realization[] | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    getCompany(ctx(), r.takenBy).then(setCompany).catch(() => {});
  }, [r.takenBy]);
  useEffect(() => {
    if (stage !== 'photosPending') return;
    myRequestRealizations(ctx(), r.id).then(setPhotos).catch(() => setPhotos([]));
  }, [r.id, stage, r.realizationStatus]);

  const pendingPhotos = (photos ?? []).filter((p) => p.addedByRole !== 'user' && p.status === 'pending');
  const name = r.takenByName || company?.companyName || 'Firma';
  const phone = company?.showPhone && company.phone ? company.phone : '';

  const decide = async (status: 'approved' | 'rejected') => {
    const approve = status === 'approved';
    const withPhotos = pendingPhotos.length > 0;
    const ok = await confirmDialog({
      title: approve ? 'Potwierdzasz wykonanie?' : withPhotos ? 'To nie Twoje zdjęcia?' : 'Zlecenie nie jest skończone?',
      body: approve
        ? withPhotos
          ? 'Zdjęcia pojawią się na profilu firmy, a zgłoszenie zostanie zamknięte jako zrealizowane.'
          : 'Zgłoszenie zostanie zamknięte jako zrealizowane.'
        : withPhotos
          ? 'Firma dostanie informację i będzie mogła dodać właściwe zdjęcia.'
          : 'Firma dostanie informację, że zlecenie nie jest jeszcze skończone.',
      ok: approve ? 'Potwierdzam' : withPhotos ? 'Odrzuć' : 'Jeszcze nie',
      danger: !approve,
    });
    if (!ok) return;
    setBusy(true);
    try {
      await setRealizationStatus(ctx(), r.id, status);
      toast(approve ? 'Potwierdzone — zlecenie zamknięte' : 'Firma dostanie informację, że zlecenie nie jest skończone');
    } catch (e) {
      toast(errorText(e, 'Nie udało się zapisać decyzji'), 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <section class="taken" aria-label="Realizacja">
      <div class="taken__company">
        <Avatar name={name} company />
        <div>
          <p>
            {stage === 'realized' ? 'Wykonała' : 'Realizuje'}: <a href={`/f/${r.takenBy}`}>{name}</a>
          </p>
          <p class="small">
            Kod sprawy: <strong class="code">{caseCode(r.id)}</strong>
            <span class="muted"> — podaj go w rozmowie z firmą</span>
          </p>
        </div>
      </div>
      <div class="row">
        {phone && (
          <a class="btn btn--ghost" href={`tel:${phone.replace(/[^0-9+]/g, '')}`}>
            📞 {phone}
          </a>
        )}
        <a class="btn btn--primary" href={`/czat/${r.takenBy}`}>
          Napisz do firmy
        </a>
      </div>
      {stage === 'photosPending' && (
        <div class="confirm-box">
          {pendingPhotos.length > 0 && (
            <div class="photos photos--small">
              {pendingPhotos.map((p) => (
                <a key={p.id} href={httpUrl(p.imageUrl) || undefined} target="_blank" rel="noopener">
                  <img src={imageSrc(p.imageUrl)} alt="Zdjęcie realizacji od firmy" loading="lazy" />
                </a>
              ))}
            </div>
          )}
          <p>
            <strong>{name}</strong>{' '}
            {pendingPhotos.length
              ? 'prosi o potwierdzenie realizacji (zdjęcia powyżej).'
              : 'prosi o potwierdzenie, że zlecenie jest wykonane.'}{' '}
            Potwierdzenie zamyka zgłoszenie.
          </p>
          <div class="row">
            <button class="btn btn--success" type="button" disabled={busy || photos === null} onClick={() => void decide('approved')}>
              Potwierdź wykonanie
            </button>
            <button class="btn btn--ghost" type="button" disabled={busy || photos === null} onClick={() => void decide('rejected')}>
              {pendingPhotos.length ? 'To nie moje zdjęcia' : 'Jeszcze nie'}
            </button>
          </div>
        </div>
      )}
      {stage === 'photosRejected' && (
        <p class="muted small">Zlecenie oznaczone jako jeszcze nieskończone — firma poprosi o potwierdzenie ponownie.</p>
      )}
    </section>
  );
}

// ── rezerwacje ──────────────────────────────────────────────────────────────

const BOOKING_TONE: Record<string, 'warn' | 'ok' | 'bad'> = { pending: 'warn', accepted: 'ok', rejected: 'bad', cancelled: 'bad' };

function BookingsTab() {
  const { data, error } = useLive<Booking[]>((n, e) => watchMyBookings(ctx(), n, e), []);
  const [busy, setBusy] = useState('');

  if (error) return <p class="card">Nie udało się wczytać rezerwacji. Odśwież stronę.</p>;
  if (!data) return <Spinner />;
  if (!data.length) {
    return (
      <div class="card empty">
        <p>Nie masz nadchodzących rezerwacji. Wolne terminy znajdziesz na wizytówce firmy.</p>
      </div>
    );
  }

  const cancel = async (b: Booking) => {
    const active = b.status === 'pending' || b.status === 'accepted';
    if (active) {
      const ok = await confirmDialog({
        title: 'Odwołać rezerwację?',
        body:
          b.status === 'accepted'
            ? `Termin ${dateTimeLabel(b.start)} w firmie ${b.companyName} jest potwierdzony. Firma dostanie powiadomienie o odwołaniu.`
            : `Rezerwacja ${dateTimeLabel(b.start)} w firmie ${b.companyName} czeka na akceptację.`,
        ok: 'Odwołaj',
        cancel: 'Zostaw',
        danger: true,
      });
      if (!ok) return;
    }
    setBusy(b.slotId);
    try {
      await cancelSlotBooking(ctx(), b.companyId, b.slotId);
      toast(active ? 'Odwołano rezerwację' : 'Usunięto z listy');
    } catch (e) {
      toast(errorText(e), 'error');
    } finally {
      setBusy('');
    }
  };

  return (
    <ul class="stack">
      {data.map((b) => (
        <li key={`${b.companyId}_${b.slotId}`} class="card booking">
          <div>
            <a href={`/f/${b.companyId}`} class="booking__company">
              {b.companyName}
            </a>
            <p class="booking__when">{dateTimeLabel(b.start)}</p>
            <Badge tone={BOOKING_TONE[b.status] ?? 'neutral'}>{BOOKING_LABEL[b.status] ?? b.status}</Badge>
          </div>
          <div class="row">
            <a class="btn btn--ghost" href={`/czat/${b.companyId}`}>
              Napisz
            </a>
            <button class="btn btn--ghost" type="button" disabled={busy === b.slotId} onClick={() => void cancel(b)}>
              {b.status === 'pending' || b.status === 'accepted' ? 'Odwołaj' : 'Usuń z listy'}
            </button>
          </div>
        </li>
      ))}
    </ul>
  );
}

// ── wiadomości ──────────────────────────────────────────────────────────────

function ChatsTab({ chats, error }: { chats: ChatOverview[] | undefined; error: boolean }) {
  if (error) return <p class="card">Nie udało się wczytać rozmów. Odśwież stronę.</p>;
  if (!chats) return <Spinner />;
  if (!chats.length) {
    return (
      <div class="card empty">
        <p>Nie masz jeszcze rozmów. Napisz do firmy z jej wizytówki albo z oferty.</p>
      </div>
    );
  }
  return (
    <ul class="chat-list">
      {chats.map((c) => (
        <li key={c.otherUid}>
          <a href={`/czat/${c.otherUid}`} class={`chat-item${c.unread ? ' chat-item--unread' : ''}`}>
            <Avatar name={c.name} company={c.isCompany} />
            <span class="chat-item__body">
              <span class="chat-item__name">{c.name}</span>
              <span class="chat-item__last">{c.lastMessage}</span>
            </span>
            <span class="chat-item__side">
              <span class="muted small">{dateTimeLabel(new Date(c.timestamp))}</span>
              {c.unread > 0 && (
                <span class="count" aria-label={`${c.unread} nieprzeczytanych`}>
                  {c.unread}
                </span>
              )}
            </span>
          </a>
        </li>
      ))}
    </ul>
  );
}
