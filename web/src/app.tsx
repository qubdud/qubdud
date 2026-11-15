import { useEffect, useState } from 'preact/hooks';
import { watchChats } from './data/chat.ts';
import { ctx } from './firebase.ts';
import { ChatPage } from './pages/Chat.tsx';
import { CompanyPage } from './pages/Company.tsx';
import { Mine } from './pages/Mine.tsx';
import { NewRequest } from './pages/NewRequest.tsx';
import { Home, NotFound, Rules } from './pages/Static.tsx';
import { useRoute } from './router.ts';
import { retryProfile, useSession } from './session.ts';
import { Spinner } from './ui/components.tsx';
import { DialogHost } from './ui/dialog.tsx';
import { EmailLinkPrompt } from './ui/EmailLinkPrompt.tsx';
import { ProfileSetup } from './ui/ProfileSetup.tsx';
import { ToastHost } from './ui/toast.tsx';

function useUnreadTotal(enabled: boolean, uid: string | undefined): number {
  const [n, setN] = useState(0);
  useEffect(() => {
    setN(0);
    if (!enabled) return;
    return watchChats(ctx(), (c) => setN(c.reduce((s, x) => s + x.unread, 0)), () => setN(0));
  }, [enabled, uid]);
  return n;
}

function Header({ unread }: { unread: number }) {
  const { path } = useRoute();
  return (
    <header class="topbar">
      <div class="topbar__inner">
        <a href="/" class="logo" aria-label="QUBDUD — strona główna">
          <span class="logo__mark" aria-hidden="true">
            Q
          </span>
          <span class="logo__text">QUBDUD</span>
        </a>
        <nav class="topnav" aria-label="Główna nawigacja">
          <a href="/moje" class={path === '/moje' ? 'active' : ''} aria-current={path === '/moje' ? 'page' : undefined}>
            Moje sprawy
            {unread > 0 && (
              <span class="count" aria-label={`${unread} nieprzeczytanych wiadomości`}>
                {unread}
              </span>
            )}
          </a>
          <a href="/zglos" class="btn btn--primary btn--sm">
            + Zgłoszenie
          </a>
        </nav>
      </div>
    </header>
  );
}

function Routes() {
  const { path } = useRoute();
  if (path === '/') return <Home />;
  if (path === '/zglos') return <NewRequest />;
  if (path === '/moje') return <Mine />;
  if (path === '/regulamin') return <Rules />;
  const company = /^\/f\/([A-Za-z0-9_-]{6,128})\/?$/.exec(path);
  if (company) return <CompanyPage id={company[1]} key={company[1]} />;
  const chat = /^\/czat\/([A-Za-z0-9_-]{6,128})\/?$/.exec(path);
  if (chat) return <ChatPage otherUid={chat[1]} key={chat[1]} />;
  return <NotFound />;
}

export function App() {
  const s = useSession();
  const unread = useUnreadTotal(s.guest && !!s.profile, s.user?.uid);

  let content;
  if (s.fatal) {
    content = (
      <main class="page" id="main">
        <p class="card">{s.fatal}</p>
      </main>
    );
  } else if (!s.ready || !s.user) {
    content = <Spinner />;
  } else if (s.linkNeedsEmail) {
    content = <EmailLinkPrompt />;
  } else if (s.guest && s.profileError) {
    content = (
      <main class="page" id="main">
        <div class="card">
          <p>Nie udało się wczytać Twojego profilu. Sprawdź internet.</p>
          <button class="btn btn--primary" type="button" onClick={retryProfile}>
            Spróbuj ponownie
          </button>
        </div>
      </main>
    );
  } else if (s.guest && s.profile === undefined) {
    content = <Spinner />;
  } else if (s.guest && s.profile === null) {
    content = <ProfileSetup email={s.user.email ?? ''} />;
  } else {
    content = <Routes />;
  }

  return (
    <>
      <a href="#main" class="skip">
        Przejdź do treści
      </a>
      <Header unread={unread} />
      {content}
      <footer class="footer">
        <a href="/regulamin">Regulamin</a> · <a href="/regulamin#rodo">Prywatność</a> · <span>QUBDUD</span>
      </footer>
      {s.busy && (
        <div class="busy" role="alert" aria-busy="true">
          <Spinner label={s.busy} />
        </div>
      )}
      <ToastHost />
      <DialogHost />
    </>
  );
}
