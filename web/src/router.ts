import { useEffect, useState } from 'preact/hooks';

const listeners = new Set<() => void>();

function notify() {
  listeners.forEach((f) => f());
}

window.addEventListener('popstate', notify);

export function navigate(to: string, { replace = false } = {}): void {
  if (to === location.pathname + location.search) return;
  history[replace ? 'replaceState' : 'pushState'](null, '', to);
  notify();
  if (!replace) window.scrollTo(0, 0);
}

export interface Route {
  path: string;
  params: URLSearchParams;
}

export function useRoute(): Route {
  const [, force] = useState(0);
  useEffect(() => {
    const f = () => force((n) => n + 1);
    listeners.add(f);
    return () => {
      listeners.delete(f);
    };
  }, []);
  return { path: location.pathname, params: new URLSearchParams(location.search) };
}

/** Kliknięcia w wewnętrzne linki obsługuje router (bez przeładowania strony). */
export function interceptLinks(): void {
  document.addEventListener('click', (e) => {
    if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    const a = (e.target as Element | null)?.closest?.('a');
    if (!a || a.target || a.hasAttribute('download')) return;
    const url = new URL(a.href, location.href);
    if (url.origin !== location.origin) return;
    if (url.pathname === location.pathname && url.hash && url.search === location.search) return;
    e.preventDefault();
    navigate(url.pathname + url.search);
    if (url.hash) setTimeout(() => document.getElementById(url.hash.slice(1))?.scrollIntoView(), 60);
  });
}
