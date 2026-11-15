import { CATEGORY_QUESTIONS, EMERGENCY_SECTORS, SECTOR_QUESTIONS } from '../generated/dictionaries.ts';
import type { RequestQuestion } from '../generated/dictionaries.ts';

/** Pytania kreatora: nadpisanie dla branży, a gdy go nie ma — pytania kategorii. */
export const questionsFor = (category: string, sector: string): RequestQuestion[] =>
  SECTOR_QUESTIONS[sector] ?? CATEGORY_QUESTIONS[category] ?? [];

/** Opcja „Awaria — 24 h” tylko dla branż awaryjnych ze słownika apki. */
export const isEmergencySector = (sector: string): boolean => EMERGENCY_SECTORS.includes(sector);

/** Odpowiedzi tylko na bieżące pytania i tylko z dozwolonych opcji. */
export function cleanAnswers(category: string, sector: string, answers: Record<string, string>): Record<string, string> {
  const out: Record<string, string> = {};
  for (const q of questionsFor(category, sector)) {
    const v = answers[q.label];
    if (v && q.options.includes(v)) out[q.label] = v;
  }
  return out;
}
