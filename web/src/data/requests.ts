import {
  collection,
  doc,
  getDoc,
  getDocs,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  where,
  writeBatch,
} from 'firebase/firestore';
import type { DocumentData, DocumentSnapshot, Unsubscribe } from 'firebase/firestore';
import { getDownloadURL, ref as storageRef, uploadBytes } from 'firebase/storage';
import { UserError, myUid } from './ctx.ts';
import type { Ctx } from './ctx.ts';
import { linkClient } from './relations.ts';

export interface LatLng {
  lat: number;
  lng: number;
}

/** Siatka 0,01° (~1 km) — to samo zaokrąglenie co approxLocation w apce i hideRequestLocation. */
export const approxLocation = (l: LatLng): LatLng => ({
  lat: Math.round(l.lat * 100) / 100,
  lng: Math.round(l.lng * 100) / 100,
});

export interface NewRequest {
  category: string;
  sector: string;
  description: string;
  city: string;
  location: LatLng;
  is24: boolean;
  timing: string;
  budget: number | null;
  answers: Record<string, string>;
}

export interface Media {
  fileName: string;
  fileUrl: string;
  thumbUrl: string;
}

export const TIMING_KEYS = ['asap', 'week', 'month', 'flexible'];

/** Te same warunki co formularz apki i reguła validNewRequest. Zwraca pola z błędami. */
export function validateRequest(r: NewRequest, hasMedia: boolean): Record<string, string> {
  const e: Record<string, string> = {};
  if (!r.category) e.category = 'Wybierz kategorię';
  if (!r.sector) e.sector = 'Wybierz branżę';
  if (!r.location || !Number.isFinite(r.location.lat) || !Number.isFinite(r.location.lng)) {
    e.location = 'Wpisz miejscowość albo wskaż punkt na mapie';
  }
  if (!hasMedia && r.description.trim().length < 10) {
    e.description = 'Bez zdjęcia opisz dokładniej, czego potrzebujesz (min. 10 znaków)';
  }
  if (r.timing && !TIMING_KEYS.includes(r.timing)) e.timing = 'Nieznany termin';
  if (r.budget !== null && (!Number.isInteger(r.budget) || r.budget < 0 || r.budget > 9999999)) {
    e.budget = 'Budżet: liczba od 0 do 9 999 999 zł';
  }
  if (Object.keys(r.answers).length > 10) e.answers = 'Za dużo odpowiedzi';
  return e;
}

/** Zdjęcie zgłoszenia + miniatura (files/{uid}, thumbs/{uid}) jak uploadMedia w apce. */
export async function uploadRequestMedia(ctx: Ctx, file: Blob, thumb: Blob): Promise<Media> {
  const uid = myUid(ctx);
  if (file.size > 25 * 1024 * 1024) throw new UserError('Zdjęcie jest za duże');
  const put = async (folder: string, blob: Blob) => {
    const r = storageRef(ctx.storage, `${folder}/${uid}/${Date.now()}.jpg`);
    await uploadBytes(r, blob, { contentType: 'image/jpeg' });
    return r;
  };
  const thumbRef = await put('thumbs', thumb);
  const fileRef = await put('files', file);
  const [fileUrl, thumbUrl] = await Promise.all([getDownloadURL(fileRef), getDownloadURL(thumbRef)]);
  return { fileName: fileRef.name, fileUrl, thumbUrl };
}

/**
 * Zapis jak saveRequestMetadata w apce: zgłoszenie z okolicą (0,01°), dokładne miejsce
 * w requests/{id}/private/location — w jednym batchu. Zwraca id zgłoszenia.
 */
export async function createRequest(ctx: Ctx, r: NewRequest, media: Media | null): Promise<string> {
  const uid = myUid(ctx);
  const errors = validateRequest(r, media !== null);
  const first = Object.values(errors)[0];
  if (first) throw new UserError(first);
  const ref = doc(collection(ctx.db, 'requests'));
  const answers = Object.fromEntries(Object.entries(r.answers).filter(([, v]) => v));
  await writeBatch(ctx.db)
    .set(ref, {
      userId: uid,
      category: r.category,
      sector: r.sector,
      location: approxLocation(r.location),
      city: r.city.trim(),
      fileUrl: media?.fileUrl ?? '',
      thumbUrl: media?.thumbUrl ?? '',
      fileName: media?.fileName ?? '',
      mediaType: media ? 'image' : 'none',
      timestamp: serverTimestamp(),
      is24: r.is24,
      ...(r.timing ? { timing: r.timing } : {}),
      ...(r.budget !== null ? { budget: r.budget } : {}),
      ...(Object.keys(answers).length ? { answers } : {}),
      description: r.description.trim(),
      status: 'open',
      takenBy: '',
      takenByName: '',
      confirmedByCompany: false,
      confirmedByUser: false,
    })
    .set(doc(ref, 'private', 'location'), { lat: r.location.lat, lng: r.location.lng })
    .commit();
  return ref.id;
}

export interface RequestDoc {
  id: string;
  userId: string;
  category: string;
  sector: string;
  city: string;
  description: string;
  fileUrl: string;
  thumbUrl: string;
  mediaType: string;
  is24: boolean;
  timing: string;
  budget: number | null;
  answers: Record<string, string>;
  status: string;
  takenBy: string;
  takenByName: string;
  realizationStatus: string;
  closedReason: string;
  timestamp: Date | null;
}

const toDate = (v: unknown): Date | null => (v instanceof Timestamp ? v.toDate() : null);

export function requestFromDoc(d: DocumentSnapshot): RequestDoc {
  const x: DocumentData = d.data({ serverTimestamps: 'estimate' }) ?? {};
  return {
    id: d.id,
    userId: x.userId ?? '',
    category: x.category ?? '',
    sector: x.sector ?? '',
    city: x.city ?? '',
    description: x.description ?? '',
    fileUrl: x.fileUrl ?? '',
    thumbUrl: x.thumbUrl ?? '',
    mediaType: x.mediaType ?? (x.fileUrl ? 'image' : 'none'),
    is24: x.is24 === true,
    timing: x.timing ?? '',
    budget: typeof x.budget === 'number' ? x.budget : null,
    answers: Object.fromEntries(Object.entries(x.answers ?? {}).map(([k, v]) => [k, String(v)])),
    status: x.status ?? 'open',
    takenBy: x.takenBy ?? '',
    takenByName: x.takenByName ?? '',
    realizationStatus: x.realizationStatus ?? '',
    closedReason: x.closedReason ?? '',
    timestamp: toDate(x.timestamp),
  };
}

export type RequestStage = 'open' | 'inProgress' | 'photosPending' | 'photosRejected' | 'realized' | 'expired' | 'closed';

export function requestStage(r: RequestDoc): RequestStage {
  if (r.realizationStatus === 'approved') return 'realized';
  if (r.status === 'closed') return r.closedReason === 'expired' ? 'expired' : 'closed';
  if (r.realizationStatus === 'pending') return 'photosPending';
  if (r.realizationStatus === 'rejected') return 'photosRejected';
  if (r.status === 'taken') return 'inProgress';
  return 'open';
}

/** Moje zgłoszenia na żywo, najnowsze pierwsze. */
export function watchMyRequests(ctx: Ctx, next: (list: RequestDoc[]) => void, error: (e: unknown) => void): Unsubscribe {
  const q = query(collection(ctx.db, 'requests'), where('userId', '==', myUid(ctx)), orderBy('timestamp', 'desc'));
  return onSnapshot(q, (snap) => next(snap.docs.map(requestFromDoc)), error);
}

export interface Offer {
  companyId: string;
  companyName: string;
  message: string;
  status: string;
  price: number | null;
  priceTo: number | null;
  when: string;
  timestamp: Date | null;
}

function offerFromData(x: DocumentData): Offer {
  return {
    companyId: x.companyId ?? '',
    companyName: x.companyName ?? 'Firma',
    message: x.message ?? '',
    status: x.status ?? 'pending',
    price: typeof x.price === 'number' ? x.price : null,
    priceTo: typeof x.priceTo === 'number' ? x.priceTo : null,
    when: x.when ?? '',
    timestamp: toDate(x.timestamp),
  };
}

/** Oferty zgłoszenia na żywo (lista z subkolekcji offers — reguła wpuszcza właściciela). */
export function watchOffers(ctx: Ctx, requestId: string, next: (o: Offer[]) => void, error: (e: unknown) => void): Unsubscribe {
  const q = query(collection(ctx.db, 'requests', requestId, 'offers'), orderBy('timestamp'));
  return onSnapshot(q, (snap) => next(snap.docs.map((d) => offerFromData(d.data({ serverTimestamps: 'estimate' })))), error);
}

export async function listOffers(ctx: Ctx, requestId: string): Promise<Offer[]> {
  const snap = await getDocs(query(collection(ctx.db, 'requests', requestId, 'offers'), orderBy('timestamp')));
  return snap.docs.map((d) => offerFromData(d.data()));
}

/**
 * Decyzja o ofercie jak setOfferStatus w apce. 'accepted' blokuje zgłoszenie na tę firmę,
 * zamyka pozostałe oferty ('closed') i w tym samym batchu tworzy relację klient↔firma.
 */
export async function setOfferStatus(
  ctx: Ctx,
  request: { id: string; userId: string },
  companyId: string,
  companyName: string,
  status: 'accepted' | 'rejected' | 'maybe',
): Promise<void> {
  myUid(ctx);
  const reqRef = doc(ctx.db, 'requests', request.id);
  const offersCol = collection(reqRef, 'offers');
  const batch = writeBatch(ctx.db);
  batch.update(doc(offersCol, companyId), { status, decidedAt: serverTimestamp() });
  if (status === 'accepted') {
    const others = await getDocs(query(offersCol, where('status', 'in', ['pending', 'maybe'])));
    for (const d of others.docs) {
      if (d.id === companyId) continue;
      batch.update(d.ref, { status: 'closed', decidedAt: serverTimestamp() });
    }
    batch.update(reqRef, {
      takenBy: companyId,
      takenByName: companyName,
      confirmedByCompany: true,
      confirmedByUser: true,
      status: 'taken',
      takenAt: serverTimestamp(),
    });
    await linkClient(ctx, { companyId, userId: request.userId, requestId: request.id, batch });
  }
  await batch.commit();
}

export interface Realization {
  id: string;
  imageUrl: string;
  beforeUrl: string;
  addedByRole: string;
  status: string;
}

/** Zdjęcia realizacji mojego zgłoszenia (klient widzi wszystkie swoje). */
export async function myRequestRealizations(ctx: Ctx, requestId: string): Promise<Realization[]> {
  const snap = await getDocs(
    query(collection(ctx.db, 'realizations'), where('requestId', '==', requestId), where('userId', '==', myUid(ctx))),
  );
  return snap.docs.map((d) => {
    const x = d.data();
    return {
      id: d.id,
      imageUrl: x.imageUrl ?? '',
      beforeUrl: x.beforeUrl ?? '',
      addedByRole: x.addedByRole ?? 'company',
      status: x.status ?? 'approved',
    };
  });
}

/**
 * Decyzja klienta, gdy firma prosi o potwierdzenie (realizationStatus == 'pending'), jak
 * setRealizationStatus w apce: 'approved' zamyka zgłoszenie jako zrealizowane,
 * 'rejected' zostawia je w realizacji.
 */
export async function setRealizationStatus(ctx: Ctx, requestId: string, status: 'approved' | 'rejected'): Promise<void> {
  const me = myUid(ctx);
  const pending = await getDocs(
    query(
      collection(ctx.db, 'realizations'),
      where('requestId', '==', requestId),
      where('userId', '==', me),
      where('status', '==', 'pending'),
    ),
  );
  const companyPhotos = pending.docs.filter((d) => d.data().addedByRole !== 'user');
  const reqRef = doc(ctx.db, 'requests', requestId);
  if (!companyPhotos.length && (await getDoc(reqRef)).data()?.realizationStatus !== 'pending') {
    throw new UserError('Firma cofnęła prośbę o potwierdzenie');
  }
  const batch = writeBatch(ctx.db);
  for (const d of companyPhotos) {
    batch.update(d.ref, { status, decidedAt: serverTimestamp(), visible: status === 'approved' });
  }
  batch.update(reqRef, {
    realizationStatus: status,
    ...(status === 'approved' ? { status: 'closed', closedReason: 'realized', closedAt: serverTimestamp() } : {}),
  });
  await batch.commit();
}
