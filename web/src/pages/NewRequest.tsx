import { useEffect, useMemo, useRef, useState } from 'preact/hooks';
import { errorText } from '../data/ctx.ts';
import type { LatLng } from '../data/requests.ts';
import { ctx } from '../firebase.ts';
import { CATEGORIES, REQUEST_TIMING } from '../generated/dictionaries.ts';
import { emptyDraft, loadDraft, saveDraft } from '../lib/draft.ts';
import type { RequestDraft } from '../lib/draft.ts';
import { currentPosition, reverseCity, searchPlace } from '../lib/geo.ts';
import { processPhoto } from '../lib/image.ts';
import { isEmergencySector, questionsFor } from '../lib/questions.ts';
import { draftErrors, submitDraft } from '../lib/submit.ts';
import { navigate } from '../router.ts';
import { useSession } from '../session.ts';
import { Chips, Field, Spinner, useTitle } from '../ui/components.tsx';
import { EmailLogin } from '../ui/EmailLogin.tsx';
import type { LocationMap as LocationMapType } from '../ui/LocationMap.tsx';
import { toast } from '../ui/toast.tsx';

const MAX_PHOTOS = 3;
const FIELD_ORDER = ['description', 'category', 'sector', 'location', 'budget'];

export function NewRequest() {
  useTitle('Dodaj zgłoszenie');
  const session = useSession();
  const [draft, setDraft] = useState<RequestDraft>(emptyDraft);
  const [loaded, setLoaded] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [photoBusy, setPhotoBusy] = useState(false);
  const [locating, setLocating] = useState(false);
  const [searching, setSearching] = useState(false);
  const [focusKey, setFocusKey] = useState(0);
  const [askLogin, setAskLogin] = useState(false);
  const [stage, setStage] = useState('');
  const searchTimer = useRef<number>();
  const loginRef = useRef<HTMLDivElement>(null);
  const [LocationMap, setLocationMap] = useState<typeof LocationMapType | null>(null);

  useEffect(() => {
    let alive = true;
    import('../ui/LocationMap.tsx')
      .then((m) => alive && setLocationMap(() => m.LocationMap))
      .catch(() => toast('Nie udało się wczytać mapy — wpisz miejscowość', 'error'));
    loadDraft().then((d) => {
      if (!alive) return;
      if (d) setDraft(d);
      setLoaded(true);
    });
    return () => {
      alive = false;
      clearTimeout(searchTimer.current);
    };
  }, []);

  // zapis tylko po zmianach użytkownika — wczytany szkic może właśnie wysyłać się po powrocie z linku
  const edited = useRef(false);
  useEffect(() => {
    if (!loaded || !edited.current) return;
    const t = setTimeout(() => void saveDraft(draft), 400);
    return () => clearTimeout(t);
  }, [draft, loaded]);
  const setDraftEdited: typeof setDraft = (v) => {
    edited.current = true;
    setDraft(v);
  };

  useEffect(() => {
    if (askLogin) loginRef.current?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, [askLogin]);

  const update = (patch: Partial<RequestDraft>) => {
    setDraftEdited((d) => ({ ...d, ...patch }));
    setErrors((e) => {
      const next = { ...e };
      for (const k of Object.keys(patch)) delete next[k];
      return next;
    });
  };

  const previews = useMemo(() => draft.photos.map((p) => URL.createObjectURL(p)), [draft.photos]);
  useEffect(() => () => previews.forEach((u) => URL.revokeObjectURL(u)), [previews]);

  const addPhotos = async (files: FileList | null) => {
    if (!files?.length) return;
    const room = MAX_PHOTOS - draft.photos.length;
    const picked = Array.from(files).slice(0, room);
    if (files.length > room) toast(`Możesz dodać najwyżej ${MAX_PHOTOS} zdjęcia`, 'error');
    setPhotoBusy(true);
    try {
      const out: Blob[] = [];
      for (const f of picked) out.push(await processPhoto(f));
      setDraftEdited((d) => ({ ...d, photos: [...d.photos, ...out].slice(0, MAX_PHOTOS) }));
      setErrors((e) => ({ ...e, description: '' }));
    } catch (e) {
      toast(errorText(e, 'Nie udało się odczytać zdjęcia — wybierz inne'), 'error');
    } finally {
      setPhotoBusy(false);
    }
  };

  const setPlace = (p: LatLng, refocus: boolean) => {
    update({ location: p });
    if (refocus) setFocusKey((k) => k + 1);
  };

  const onCity = (city: string) => {
    update({ city });
    clearTimeout(searchTimer.current);
    if (!city.trim()) return;
    searchTimer.current = window.setTimeout(async () => {
      setSearching(true);
      const p = await searchPlace(city.trim());
      setSearching(false);
      if (p) setPlace(p, true);
    }, 1100);
  };

  const useMyLocation = async () => {
    setLocating(true);
    clearTimeout(searchTimer.current);
    try {
      const p = await currentPosition();
      setPlace(p, true);
      const city = await reverseCity(p);
      if (city) update({ city });
    } catch (e) {
      toast(e instanceof Error ? e.message : 'Nie udało się ustalić lokalizacji', 'error');
    } finally {
      setLocating(false);
    }
  };

  const submit = async (e: Event) => {
    e.preventDefault();
    const errs = draftErrors(draft);
    setErrors(errs);
    const first = FIELD_ORDER.find((k) => errs[k]);
    if (first) {
      toast('Uzupełnij zaznaczone pola', 'error');
      document.getElementById(first === 'location' ? 'req-city' : `req-${first}`)?.focus();
      return;
    }
    if (!session.guest || !session.profile) {
      await saveDraft(draft);
      setAskLogin(true);
      return;
    }
    try {
      await submitDraft(ctx(), draft, setStage);
      setDraft(emptyDraft());
      toast('Zgłoszenie wysłane — firmy z okolicy już je widzą');
      navigate('/moje');
    } catch (err) {
      toast(errorText(err, 'Nie udało się dodać zgłoszenia — sprawdź internet i spróbuj ponownie'), 'error');
    } finally {
      setStage('');
    }
  };

  if (!loaded) return <Spinner />;

  const sectors = CATEGORIES[draft.category] ?? [];
  const questions = draft.category && draft.sector ? questionsFor(draft.category, draft.sector) : [];
  const describedBy = (k: string, hint = false) => (errors[k] ? `req-${k}-error` : hint ? `req-${k}-hint` : undefined);

  return (
    <main class="page" id="main">
      <h1>Dodaj zgłoszenie</h1>
      <p class="lead">Firmy z okolicy z wybranej branży zobaczą je od razu i przyślą oferty.</p>

      <form class="stack" onSubmit={submit} noValidate>
        <section class="card stack">
          <h2>Czego potrzebujesz?</h2>
          <Field
            id="req-description"
            label="Opis"
            error={errors.description}
            hint="Co dokładnie, wymiary, stan, na kiedy — konkretne zgłoszenia dostają więcej ofert."
          >
            <textarea
              id="req-description"
              rows={5}
              maxLength={3000}
              value={draft.description}
              onInput={(e) => update({ description: (e.target as HTMLTextAreaElement).value })}
              aria-invalid={!!errors.description}
              aria-describedby={describedBy('description', true)}
            />
          </Field>

          <div class="field">
            <span class="field__label" id="photos-label">
              Zdjęcia (do {MAX_PHOTOS}, opcjonalnie)
            </span>
            <div class="photos" aria-labelledby="photos-label">
              {previews.map((url, i) => (
                <figure class="photo" key={url}>
                  <img src={url} alt={`Zdjęcie ${i + 1}`} />
                  <button
                    type="button"
                    class="photo__remove"
                    aria-label={`Usuń zdjęcie ${i + 1}`}
                    onClick={() => setDraftEdited((d) => ({ ...d, photos: d.photos.filter((_, j) => j !== i) }))}
                  >
                    ×
                  </button>
                </figure>
              ))}
              {draft.photos.length < MAX_PHOTOS && (
                <label class="photo photo--add">
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    class="sr-only"
                    disabled={photoBusy}
                    onChange={(e) => {
                      const input = e.target as HTMLInputElement;
                      void addPhotos(input.files).finally(() => (input.value = ''));
                    }}
                  />
                  <span aria-hidden="true">＋</span>
                  <span>{photoBusy ? 'Przetwarzanie…' : 'Dodaj zdjęcie'}</span>
                </label>
              )}
            </div>
            <p class="field__hint">
              Możesz wysłać zgłoszenie bez zdjęcia. Zdjęcia zmniejszamy w przeglądarce i usuwamy z nich dane o miejscu
              wykonania (GPS). Kilka zdjęć firma zobaczy jako jedno zestawienie.
            </p>
          </div>
        </section>

        <section class="card stack">
          <h2>Branża</h2>
          <div class="grid2">
            <Field id="req-category" label="Kategoria" error={errors.category}>
              <select
                id="req-category"
                value={draft.category}
                onChange={(e) => update({ category: (e.target as HTMLSelectElement).value, sector: '', answers: {}, is24: false })}
                aria-invalid={!!errors.category}
                aria-describedby={describedBy('category')}
              >
                <option value="">Wybierz kategorię</option>
                {Object.keys(CATEGORIES).map((c) => (
                  <option key={c} value={c}>
                    {c}
                  </option>
                ))}
              </select>
            </Field>
            <Field id="req-sector" label="Branża" error={errors.sector}>
              <select
                id="req-sector"
                value={draft.sector}
                disabled={!draft.category}
                onChange={(e) => update({ sector: (e.target as HTMLSelectElement).value, answers: {}, is24: false })}
                aria-invalid={!!errors.sector}
                aria-describedby={describedBy('sector')}
              >
                <option value="">{draft.category ? 'Wybierz branżę' : 'Najpierw wybierz kategorię'}</option>
                {sectors.map((s) => (
                  <option key={s} value={s}>
                    {s}
                  </option>
                ))}
              </select>
            </Field>
          </div>

          {questions.map((q, i) => (
            <Chips
              key={q.label}
              name={`q${i}`}
              legend={q.label}
              options={q.options.map((o) => ({ value: o, label: o }))}
              value={draft.answers[q.label] ?? ''}
              onChange={(v) => {
                const answers = { ...draft.answers };
                if (v) answers[q.label] = v;
                else delete answers[q.label];
                update({ answers });
              }}
            />
          ))}

          {isEmergencySector(draft.sector) && (
            <div class="check check--urgent">
              <input id="req-is24" type="checkbox" checked={draft.is24} onChange={(e) => update({ is24: (e.target as HTMLInputElement).checked })} />
              <label for="req-is24">
                <strong>🔴 Awaria — 24 h</strong>
                <span class="muted"> Pilne zgłoszenie: firmy z okolicy dostaną wyraźne powiadomienie.</span>
              </label>
            </div>
          )}
        </section>

        <section class="card stack">
          <h2>Kiedy i za ile</h2>
          <Chips
            name="timing"
            legend="Kiedy?"
            options={Object.entries(REQUEST_TIMING).map(([value, label]) => ({ value, label }))}
            value={draft.timing}
            onChange={(timing) => update({ timing })}
          />
          <Field id="req-budget" label="Budżet (opcjonalnie, zł)" error={errors.budget}>
            <input
              id="req-budget"
              type="text"
              inputMode="numeric"
              autoComplete="off"
              placeholder="np. 500"
              maxLength={7}
              value={draft.budget}
              onInput={(e) => {
                const input = e.target as HTMLInputElement;
                const v = input.value.replace(/\D/g, '').slice(0, 7);
                input.value = v;
                update({ budget: v });
              }}
              aria-invalid={!!errors.budget}
              aria-describedby={describedBy('budget')}
            />
          </Field>
        </section>

        <section class="card stack">
          <h2>Gdzie?</h2>
          <Field
            id="req-city"
            label="Miejscowość"
            hint="Wpisz miejscowość albo użyj lokalizacji i popraw pinezkę na mapie."
          >
            <input
              id="req-city"
              type="text"
              autoComplete="address-level2"
              value={draft.city}
              onInput={(e) => onCity((e.target as HTMLInputElement).value)}
              aria-invalid={!!errors.location}
              aria-describedby={errors.location ? 'req-city-hint req-location-error' : 'req-city-hint'}
            />
          </Field>
          <div class="row">
            <button type="button" class="btn btn--ghost" onClick={() => void useMyLocation()} disabled={locating}>
              {locating ? 'Ustalanie lokalizacji…' : '📍 Użyj mojej lokalizacji'}
            </button>
            {searching && <span class="muted">Szukam na mapie…</span>}
          </div>
          <div class={`field${errors.location ? ' field--error' : ''}`}>
            <span class="field__label" id="req-location-label">
              Miejsce na mapie
            </span>
            {LocationMap ? (
              <LocationMap
                value={draft.location}
                onPick={(p) => {
                setPlace(p, false);
                if (!draft.city.trim()) void reverseCity(p).then((city) => city && setDraftEdited((d) => (d.city.trim() ? d : { ...d, city })));
              }}
                focusKey={focusKey}
                label="Mapa — kliknij, aby wskazać miejsce zlecenia"
              />
            ) : (
              <div class="map" aria-hidden="true" />
            )}
            {errors.location ? (
              <p class="field__error" id="req-location-error">
                {errors.location}
              </p>
            ) : (
              <p class="field__hint">
                Firmy zobaczą tylko okolicę (ok. 1 km). Dokładne miejsce pozna wyłącznie firma, której ofertę przyjmiesz.
              </p>
            )}
          </div>
        </section>

        {askLogin && !session.guest ? (
          <div ref={loginRef}>
            <EmailLogin
              pending={{ type: 'request' }}
              title="Ostatni krok: potwierdź e-mail"
              beforeSend={() => saveDraft(draft).then(() => undefined)}
              onCancel={() => setAskLogin(false)}
            >
              <p>
                Zgłoszenie jest zapisane w tej przeglądarce. Po kliknięciu w link z e-maila wyślemy je automatycznie, a oferty
                zobaczysz w „Moich sprawach”.
              </p>
            </EmailLogin>
          </div>
        ) : (
          <div class="submit-bar">
            <button class="btn btn--primary btn--lg btn--block" type="submit" disabled={!!stage || photoBusy}>
              {stage || 'Wyślij zgłoszenie'}
            </button>
            {!session.guest && <p class="muted center">Nie potrzebujesz konta ani hasła — poprosimy tylko o e-mail.</p>}
          </div>
        )}
      </form>
    </main>
  );
}
