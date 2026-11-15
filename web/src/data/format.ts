import type { RequestStage } from './requests.ts';

/** Odmiana po liczebniku: 1 opinia, 2–4 opinie (bez 12–14), 5+ opinii. */
export function plural(n: number, one: string, few: string, many: string): string {
  if (n === 1) return one;
  const d = n % 10;
  const h = n % 100;
  return d >= 2 && d <= 4 && (h < 12 || h > 14) ? few : many;
}

const WEEKDAYS = ['Niedziela', 'Poniedziałek', 'Wtorek', 'Środa', 'Czwartek', 'Piątek', 'Sobota'];

const sameDay = (a: Date, b: Date) =>
  a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();

/** „Dziś, 15.11”, „Jutro, 16.11”, „Środa, 19.11”. */
export function dayLabel(d: Date): string {
  const today = new Date();
  const tomorrow = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1);
  const name = sameDay(d, today) ? 'Dziś' : sameDay(d, tomorrow) ? 'Jutro' : WEEKDAYS[d.getDay()];
  return `${name}, ${String(d.getDate()).padStart(2, '0')}.${String(d.getMonth() + 1).padStart(2, '0')}`;
}

export const timeLabel = (d: Date): string =>
  `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;

export const dateTimeLabel = (d: Date): string => `${dayLabel(d)}, ${timeLabel(d)}`;

export function shortDate(d: Date | null): string {
  if (!d) return '';
  return d.toLocaleDateString('pl-PL', { day: 'numeric', month: 'long', year: 'numeric' });
}

export const formatZl = (n: number): string => `${n.toLocaleString('pl-PL')} zł`;

/** Cena oferty: „250 zł”, „250–400 zł” albo null (offerPriceLabel w apce). */
export function offerPriceLabel(o: { price: number | null; priceTo: number | null }): string | null {
  if (o.price === null) return null;
  return o.priceTo !== null && o.priceTo > o.price ? `${o.price}–${o.priceTo} zł` : `${o.price} zł`;
}

/** Adres z bazy jako link — tylko http(s), żeby wpis firmy nie przemycił „javascript:”. */
export const httpUrl = (u: string): string => (/^https?:\/\//i.test(u) ? u : '');

/** Źródło obrazka z bazy: http(s) albo osadzony obraz. */
export const imageSrc = (u: string): string => (/^(https?:\/\/|data:image\/)/i.test(u) ? u : '');

/** Kod sprawy do rozmowy telefonicznej z firmą. */
export const caseCode = (requestId: string): string => requestId.substring(0, 6).toUpperCase();

export const STAGE_LABEL: Record<RequestStage, string> = {
  open: 'czeka na oferty',
  inProgress: 'w realizacji',
  photosPending: 'firma prosi o potwierdzenie',
  photosRejected: 'w realizacji — nie potwierdzono wykonania',
  realized: 'zrealizowane i potwierdzone',
  expired: 'wygasło',
  closed: 'zamknięte',
};

export const BOOKING_LABEL: Record<string, string> = {
  pending: 'czeka na potwierdzenie firmy',
  accepted: 'potwierdzona',
  rejected: 'odrzucona przez firmę',
  cancelled: 'odwołana przez firmę',
};
