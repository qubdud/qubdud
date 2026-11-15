import { useEffect, useRef, useState } from 'preact/hooks';
import { displayNameOf, markChatRead, sendMessage, watchMessages } from '../data/chat.ts';
import type { Message } from '../data/chat.ts';
import { errorCode, errorText } from '../data/ctx.ts';
import { dateTimeLabel, timeLabel } from '../data/format.ts';
import { ctx } from '../firebase.ts';
import { useSession } from '../session.ts';
import { Avatar, Spinner, useTitle } from '../ui/components.tsx';
import { EmailLogin } from '../ui/EmailLogin.tsx';
import { toast } from '../ui/toast.tsx';

const PAGE = 50;

export function ChatPage({ otherUid }: { otherUid: string }) {
  const session = useSession();
  const [other, setOther] = useState<{ name: string; isCompany: boolean } | null>(null);
  useTitle(other ? `Rozmowa: ${other.name}` : 'Rozmowa');

  useEffect(() => {
    if (!session.user) return;
    displayNameOf(ctx(), otherUid)
      .then(setOther)
      .catch(() => setOther({ name: 'Rozmówca', isCompany: false }));
  }, [otherUid, session.user?.uid]);

  if (!session.guest) {
    return (
      <main class="page" id="main">
        <h1>Rozmowa{other ? ` z ${other.name}` : ''}</h1>
        <EmailLogin pending={{ type: 'chat', companyId: otherUid }} title="Zaloguj się, żeby napisać">
          <p>Wiadomości widzicie tylko Ty i firma. Odpowiedź zobaczysz tutaj i w „Moich sprawach”.</p>
        </EmailLogin>
      </main>
    );
  }
  if (!session.profile) return <Spinner />;
  if (otherUid === session.user?.uid) {
    return (
      <main class="page" id="main">
        <p class="card">Nie możesz pisać do samego siebie.</p>
      </main>
    );
  }
  return <Conversation otherUid={otherUid} other={other} me={session.user?.uid ?? ''} />;
}

function Conversation({ otherUid, other, me }: { otherUid: string; other: { name: string; isCompany: boolean } | null; me: string }) {
  const [messages, setMessages] = useState<Message[] | undefined>(undefined);
  const [count, setCount] = useState(PAGE);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState(false);
  const listRef = useRef<HTMLOListElement>(null);
  const stick = useRef(true);

  useEffect(() => {
    setError(false);
    return watchMessages(ctx(), otherUid, count, setMessages, () => setError(true));
  }, [otherUid, count]);

  const unreadIncoming = (messages ?? []).filter((m) => m.from === otherUid && !m.read).length;
  useEffect(() => {
    if (document.visibilityState === 'visible') markChatRead(ctx(), otherUid).catch(() => {});
  }, [unreadIncoming, otherUid]);
  useEffect(() => {
    const onVisible = () => document.visibilityState === 'visible' && markChatRead(ctx(), otherUid).catch(() => {});
    document.addEventListener('visibilitychange', onVisible);
    return () => document.removeEventListener('visibilitychange', onVisible);
  }, [otherUid]);

  useEffect(() => {
    const el = listRef.current;
    if (el && stick.current) el.scrollTop = el.scrollHeight;
  }, [messages]);

  const send = async (e?: Event) => {
    e?.preventDefault();
    const v = text.trim();
    if (!v || sending) return;
    setSending(true);
    stick.current = true;
    try {
      await sendMessage(ctx(), otherUid, v);
      setText('');
    } catch (err) {
      toast(errorCode(err) === 'permission-denied' ? 'Nie możesz pisać do tej osoby' : errorText(err, 'Nie udało się wysłać wiadomości'), 'error');
    } finally {
      setSending(false);
    }
  };

  const name = other?.name ?? 'Rozmówca';
  return (
    <main class="page page--chat" id="main">
      <header class="chat-head">
        <a href="/moje?tab=wiadomosci" class="btn btn--ghost btn--icon" aria-label="Wróć do wiadomości">
          ←
        </a>
        <Avatar name={name} company={other?.isCompany} />
        <h1>{other?.isCompany ? <a href={`/f/${otherUid}`}>{name}</a> : name}</h1>
      </header>

      {error ? (
        <p class="card">Nie udało się wczytać rozmowy. Odśwież stronę.</p>
      ) : messages === undefined ? (
        <Spinner />
      ) : (
        <ol
          class="messages"
          ref={listRef}
          aria-live="polite"
          aria-label={`Wiadomości z ${name}`}
          onScroll={(e) => {
            const el = e.currentTarget as HTMLElement;
            stick.current = el.scrollHeight - el.scrollTop - el.clientHeight < 80;
          }}
        >
          {messages.length >= count && (
            <li class="messages__more">
              <button class="btn btn--ghost" type="button" onClick={() => ((stick.current = false), setCount((c) => c + PAGE))}>
                Wczytaj starsze
              </button>
            </li>
          )}
          {!messages.length && <li class="muted center">Napisz pierwszą wiadomość — firma odpowie w aplikacji QUBDUD.</li>}
          {messages.map((m) => {
            const mine = m.from === me;
            return (
              <li key={m.id} class={`msg${mine ? ' msg--mine' : ''}`}>
                <span class="sr-only">{mine ? 'Ty' : name}: </span>
                <span class="msg__text">{m.content}</span>
                <span class="msg__meta" title={dateTimeLabel(new Date(m.timestamp))}>
                  {timeLabel(new Date(m.timestamp))}
                  {mine && (m.pending ? ' · wysyłanie' : m.read ? ' · przeczytana' : '')}
                </span>
              </li>
            );
          })}
        </ol>
      )}

      <form class="composer" onSubmit={send}>
        <label for="chat-input" class="sr-only">
          Wiadomość do {name}
        </label>
        <textarea
          id="chat-input"
          rows={2}
          maxLength={2000}
          placeholder="Napisz wiadomość…"
          value={text}
          onInput={(e) => setText((e.target as HTMLTextAreaElement).value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) {
              e.preventDefault();
              void send();
            }
          }}
        />
        <button class="btn btn--primary" type="submit" disabled={sending || !text.trim()}>
          Wyślij
        </button>
      </form>
    </main>
  );
}
