import { useEffect, useState } from 'preact/hooks';

interface Toast {
  id: number;
  text: string;
  error: boolean;
}

let items: Toast[] = [];
let seq = 0;
const subs = new Set<(t: Toast[]) => void>();
const emit = () => subs.forEach((f) => f(items));

export function toast(text: string, kind: 'ok' | 'error' = 'ok'): void {
  const t = { id: ++seq, text, error: kind === 'error' };
  items = [...items.slice(-2), t];
  emit();
  setTimeout(() => {
    items = items.filter((x) => x.id !== t.id);
    emit();
  }, t.error ? 7000 : 4500);
}

export function ToastHost() {
  const [list, setList] = useState(items);
  useEffect(() => {
    subs.add(setList);
    return () => {
      subs.delete(setList);
    };
  }, []);
  return (
    <div class="toasts" role="status" aria-live="polite">
      {list.map((t) => (
        <div key={t.id} class={`toast${t.error ? ' toast--error' : ''}`}>
          {t.text}
        </div>
      ))}
    </div>
  );
}
