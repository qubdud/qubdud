import type { Ctx } from '../data/ctx.ts';
import { UserError } from '../data/ctx.ts';
import { createRequest, uploadRequestMedia, validateRequest } from '../data/requests.ts';
import type { NewRequest } from '../data/requests.ts';
import { clearDraft } from './draft.ts';
import type { RequestDraft } from './draft.ts';
import { composeRequestMedia } from './image.ts';
import { cleanAnswers, isEmergencySector } from './questions.ts';

export function draftToRequest(d: RequestDraft): NewRequest {
  const budget = d.budget.trim();
  return {
    category: d.category,
    sector: d.sector,
    description: d.description,
    city: d.city,
    location: d.location ?? { lat: NaN, lng: NaN },
    is24: d.is24 && isEmergencySector(d.sector),
    timing: d.timing,
    budget: budget ? Number.parseInt(budget, 10) : null,
    answers: cleanAnswers(d.category, d.sector, d.answers),
  };
}

export const draftErrors = (d: RequestDraft): Record<string, string> =>
  validateRequest(draftToRequest(d), d.photos.length > 0);

/** Zdjęcia → kolaż i miniatura → Storage → zgłoszenie. Po sukcesie szkic znika. */
export async function submitDraft(c: Ctx, d: RequestDraft, onStage: (s: string) => void = () => {}): Promise<string> {
  const first = Object.values(draftErrors(d))[0];
  if (first) throw new UserError(first);
  let media = null;
  if (d.photos.length) {
    onStage('Przygotowujemy zdjęcia…');
    const { file, thumb } = await composeRequestMedia(d.photos);
    onStage('Wysyłamy zdjęcia…');
    media = await uploadRequestMedia(c, file, thumb);
  }
  onStage('Zapisujemy zgłoszenie…');
  const id = await createRequest(c, draftToRequest(d), media);
  await clearDraft();
  return id;
}
