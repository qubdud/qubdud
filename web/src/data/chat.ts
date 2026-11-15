import {
  arrayRemove,
  collection,
  doc,
  getDoc,
  getDocs,
  increment,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';
import type { DocumentData, Unsubscribe } from 'firebase/firestore';
import { UserError, myUid } from './ctx.ts';
import type { Ctx } from './ctx.ts';
import { isCompanyDoc, personName } from './profile.ts';

// chats/{chatId} — chatId = posortowane "uidA_uidB"; names/isCompany/unread per uid
// chats/{chatId}/messages/{msgId} — from, content, timestamp, read (jak chat_service.dart)

export function chatIdWith(me: string, other: string): string {
  if (!other || other === me) throw new UserError('Nie możesz pisać do samego siebie');
  const ids = [me, other].sort();
  return `${ids[0]}_${ids[1]}`;
}

const millis = (v: unknown): number => (v instanceof Timestamp ? v.toMillis() : Date.now());

const profileCache = new Map<string, DocumentData>();

async function profileOf(ctx: Ctx, uid: string): Promise<DocumentData> {
  const key = `${ctx.db.app.name}:${uid}`;
  const cached = profileCache.get(key);
  if (cached) return cached;
  const snap = await getDoc(doc(ctx.db, 'users', uid));
  const data = snap.data() ?? {};
  if (snap.exists()) profileCache.set(key, data);
  return data;
}

/** Nazwa rozmówcy: firma pod nazwą firmy, osoba imieniem i nazwiskiem. */
export async function displayNameOf(ctx: Ctx, uid: string): Promise<{ name: string; isCompany: boolean }> {
  const d = await profileOf(ctx, uid);
  const company = isCompanyDoc(d);
  return { name: company ? (d.companyName ?? 'Firma') : personName(d), isCompany: company };
}

/** Rozmowa i wiadomość w jednym batchu (sendMessage w apce); gość pisze zawsze jako osoba. */
export async function sendMessage(ctx: Ctx, toUid: string, content: string): Promise<void> {
  const me = myUid(ctx);
  const text = content.trim();
  if (!text) throw new UserError('Wpisz wiadomość');
  const chatId = chatIdWith(me, toUid);
  const myName = personName(await profileOf(ctx, me));
  const chatRef = doc(ctx.db, 'chats', chatId);
  await writeBatch(ctx.db)
    .set(
      chatRef,
      {
        participants: chatId.split('_'),
        names: { [me]: myName },
        isCompany: { [me]: false },
        lastMessage: text,
        lastTimestamp: serverTimestamp(),
        unread: { [toUid]: increment(1) },
        hiddenFor: arrayRemove(me, toUid),
      },
      { merge: true },
    )
    .set(doc(collection(chatRef, 'messages')), {
      from: me,
      content: text,
      timestamp: serverTimestamp(),
      read: false,
    })
    .commit();
}

export interface Message {
  id: string;
  from: string;
  content: string;
  timestamp: number;
  read: boolean;
  pending: boolean;
}

/** [count] najnowszych wiadomości na żywo, od najstarszej. */
export function watchMessages(
  ctx: Ctx,
  otherUid: string,
  count: number,
  next: (m: Message[]) => void,
  error: (e: unknown) => void,
): Unsubscribe {
  const chatId = chatIdWith(myUid(ctx), otherUid);
  const q = query(collection(ctx.db, 'chats', chatId, 'messages'), orderBy('timestamp', 'desc'), limit(count));
  return onSnapshot(
    q,
    { includeMetadataChanges: true },
    (snap) => {
      if (!snap.docs.length && snap.metadata.fromCache) return;
      next(
        snap.docs
          .map((d) => {
            const x = d.data({ serverTimestamps: 'estimate' });
            return {
              id: d.id,
              from: x.from ?? '',
              content: x.content ?? '',
              timestamp: millis(x.timestamp),
              read: x.read === true,
              pending: d.metadata.hasPendingWrites,
            };
          })
          .reverse(),
      );
    },
    error,
  );
}

/**
 * Zeruje mój licznik i oznacza wiadomości rozmówcy jako przeczytane
 * (markAllMessagesFromUserAsRead w apce). Rozmowa musi już istnieć.
 */
export async function markChatRead(ctx: Ctx, otherUid: string): Promise<void> {
  const me = myUid(ctx);
  const chatRef = doc(ctx.db, 'chats', chatIdWith(me, otherUid));
  updateDoc(doc(ctx.db, 'notifications', `chat_${me}_${otherUid}`), { read: true }).catch(() => {});
  const [chat, unreadMsgs] = await Promise.all([
    getDoc(chatRef),
    getDocs(query(collection(chatRef, 'messages'), where('from', '==', otherUid), where('read', '==', false))),
  ]);
  if (!chat.exists()) return;
  if (!unreadMsgs.size && !(chat.data().unread?.[me] > 0)) return;
  const batch = writeBatch(ctx.db).update(chatRef, { [`unread.${me}`]: 0 });
  unreadMsgs.docs.forEach((d) => batch.update(d.ref, { read: true }));
  await batch.commit();
}

export interface ChatOverview {
  otherUid: string;
  name: string;
  isCompany: boolean;
  lastMessage: string;
  timestamp: number;
  unread: number;
}

/** Lista rozmów (poza koszem), najnowsze pierwsze. */
export function watchChats(ctx: Ctx, next: (c: ChatOverview[]) => void, error: (e: unknown) => void): Unsubscribe {
  const me = myUid(ctx);
  const q = query(
    collection(ctx.db, 'chats'),
    where('participants', 'array-contains', me),
    orderBy('lastTimestamp', 'desc'),
    limit(200),
  );
  let seq = 0;
  return onSnapshot(
    q,
    async (snap) => {
      const mine = ++seq;
      const out: ChatOverview[] = [];
      for (const d of snap.docs) {
        const x = d.data({ serverTimestamps: 'estimate' });
        const other = ((x.participants ?? []) as string[]).find((p) => p !== me) ?? '';
        if (!other || ((x.hiddenFor ?? []) as string[]).includes(me)) continue;
        let name: string = x.names?.[other] ?? '';
        let isCompany = x.isCompany?.[other] === true;
        if (!name) {
          try {
            ({ name, isCompany } = await displayNameOf(ctx, other));
          } catch {
            name = 'Użytkownik';
          }
        }
        out.push({
          otherUid: other,
          name,
          isCompany,
          lastMessage: x.lastMessage ?? '',
          timestamp: millis(x.lastTimestamp),
          unread: Number(x.unread?.[me] ?? 0),
        });
      }
      if (mine === seq) next(out);
    },
    error,
  );
}
