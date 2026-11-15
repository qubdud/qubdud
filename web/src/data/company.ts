import { collection, doc, getCountFromServer, getDoc, getDocs, orderBy, query, Timestamp, where } from 'firebase/firestore';
import type { DocumentData } from 'firebase/firestore';
import { errorCode } from './ctx.ts';
import type { Ctx } from './ctx.ts';
import { isCompanyDoc } from './profile.ts';

export interface Company {
  id: string;
  companyName: string;
  companyCity: string;
  companyCategory: string;
  companySector: string;
  bio: string;
  slotsInfo: string;
  phone: string;
  showPhone: boolean;
  showAddress: boolean;
  address: string;
  www: string;
  contactEmail: string;
  createdAt: Date | null;
}

function addressOf(a: DocumentData | undefined): string {
  if (!a) return '';
  const street = [a.street, a.buildingNr].filter((x) => typeof x === 'string' && x).join(' ');
  const flat = String(a.flatNr ?? '');
  const line1 = flat ? `${street}/${flat}` : street;
  const line2 = [a.postCode, a.city].filter((x) => typeof x === 'string' && x).join(' ');
  return [line1, line2].filter(Boolean).join(', ');
}

/** Profil firmy (anonim czyta wyłącznie konta firmowe); null, gdy to nie firma albo brak konta. */
export async function getCompany(ctx: Ctx, id: string): Promise<Company | null> {
  let snap;
  try {
    snap = await getDoc(doc(ctx.db, 'users', id));
  } catch (e) {
    if (errorCode(e) === 'permission-denied') return null;
    throw e;
  }
  const d = snap.data();
  if (!d || !isCompanyDoc(d)) return null;
  return {
    id,
    companyName: d.companyName ?? 'Firma',
    companyCity: d.companyCity ?? '',
    companyCategory: d.companyCategory ?? '',
    companySector: d.companySector ?? '',
    bio: (d.bio ?? '').trim(),
    slotsInfo: (d.slotsInfo ?? '').trim(),
    phone: (d.phone ?? '').trim(),
    showPhone: d.showPhone !== false,
    showAddress: d.showAddress !== false,
    address: addressOf(d.companyAddress),
    www: (d.www ?? '').trim(),
    contactEmail: (d.contactEmail ?? '').trim(),
    createdAt: d.createdAt instanceof Timestamp ? d.createdAt.toDate() : null,
  };
}

export interface Promo {
  id: string;
  fileUrl: string;
  thumbUrl: string;
  description: string;
}

export async function getCompanyPromos(ctx: Ctx, companyId: string): Promise<Promo[]> {
  const snap = await getDocs(
    query(collection(ctx.db, 'promos'), where('userId', '==', companyId), orderBy('timestamp', 'desc')),
  );
  return snap.docs.map((d) => ({
    id: d.id,
    fileUrl: d.data().fileUrl ?? '',
    thumbUrl: d.data().thumbUrl ?? '',
    description: d.data().description ?? '',
  }));
}

export interface ReviewComment {
  id: string;
  authorName: string;
  isOwner: boolean;
  text: string;
}

export interface Review {
  id: string;
  userId: string;
  authorName: string;
  score: number;
  description: string;
  thumbUrl: string;
  fileUrl: string;
  timestamp: Date | null;
  comments: ReviewComment[];
}

/** Opinie o firmie (najnowsze pierwsze) razem z komentarzami. */
export async function getCompanyReviews(ctx: Ctx, companyId: string): Promise<Review[]> {
  const snap = await getDocs(
    query(collection(ctx.db, 'reviews'), where('reviewedUserId', '==', companyId), orderBy('timestamp', 'desc')),
  );
  return Promise.all(
    snap.docs.map(async (d) => {
      const x = d.data();
      const comments = await getDocs(query(collection(d.ref, 'comments'), orderBy('timestamp')));
      return {
        id: d.id,
        userId: x.userId ?? '',
        authorName: x.authorName ?? '',
        score: typeof x.score === 'number' ? Math.round(x.score) : 0,
        description: x.description ?? '',
        thumbUrl: x.thumbUrl ?? '',
        fileUrl: x.fileUrl ?? '',
        timestamp: x.timestamp instanceof Timestamp ? x.timestamp.toDate() : null,
        comments: comments.docs.map((c) => ({
          id: c.id,
          authorName: c.data().authorName ?? '',
          isOwner: c.data().isOwner === true,
          text: c.data().text ?? '',
        })),
      };
    }),
  );
}

export const averageScore = (reviews: { score: number }[]): number =>
  reviews.length ? Math.round((reviews.reduce((s, r) => s + r.score, 0) / reviews.length) * 10) / 10 : 0;

export interface PortfolioPhoto {
  id: string;
  imageUrl: string;
  beforeUrl: string;
  category: string;
  byClient: boolean;
}

/** Realizacje widoczne publicznie (getRealizations w apce bez niepotwierdzonych). */
export async function getCompanyRealizations(ctx: Ctx, companyId: string): Promise<PortfolioPhoto[]> {
  const snap = await getDocs(
    query(collection(ctx.db, 'realizations'), where('companyId', '==', companyId), where('visible', '==', true)),
  );
  return snap.docs
    .map((d) => ({ id: d.id, ...d.data() }) as DocumentData)
    .filter((r) => (r.addedByRole === 'user' ? r.publishedByCompany === true : (r.status ?? 'approved') === 'approved'))
    .sort((a, b) =>
      a.timestamp instanceof Timestamp && b.timestamp instanceof Timestamp ? b.timestamp.toMillis() - a.timestamp.toMillis() : 0,
    )
    .slice(0, 30)
    .map((r) => ({
      id: r.id,
      imageUrl: r.imageUrl ?? '',
      beforeUrl: r.beforeUrl ?? '',
      category: r.category ?? '',
      byClient: r.addedByRole === 'user',
    }));
}

/** Zlecenia z realizacją potwierdzoną przez klienta (zgłoszenia czyta tylko zalogowany). */
export async function getCompletedJobsCount(ctx: Ctx, companyId: string): Promise<number> {
  const snap = await getCountFromServer(
    query(collection(ctx.db, 'requests'), where('takenBy', '==', companyId), where('realizationStatus', '==', 'approved')),
  );
  return snap.data().count;
}
