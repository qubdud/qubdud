import type { ComponentChildren } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';

interface Request {
  title: string;
  body?: ComponentChildren;
  ok: string;
  cancel?: string;
  danger?: boolean;
  resolve: (v: boolean) => void;
}

let current: Request | null = null;
const subs = new Set<(r: Request | null) => void>();

/** Okno potwierdzenia (natywny <dialog>: pułapka fokusu, Esc = anuluj). */
export function confirmDialog(opts: Omit<Request, 'resolve'>): Promise<boolean> {
  current?.resolve(false);
  return new Promise((resolve) => {
    current = { ...opts, resolve };
    subs.forEach((f) => f(current));
  });
}

export function DialogHost() {
  const [req, setReq] = useState<Request | null>(current);
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => {
    subs.add(setReq);
    return () => {
      subs.delete(setReq);
    };
  }, []);
  useEffect(() => {
    const d = ref.current;
    if (d && req && !d.open) {
      d.returnValue = '';
      d.showModal();
    }
  }, [req]);

  const onClose = () => {
    const r = current;
    current = null;
    setReq(null);
    r?.resolve(ref.current?.returnValue === 'ok');
  };

  return (
    <dialog ref={ref} class="dialog" aria-labelledby="dialog-title" onClose={onClose}>
      {req && (
        <form method="dialog">
          <h2 id="dialog-title">{req.title}</h2>
          {req.body && <div class="dialog__body">{req.body}</div>}
          <div class="dialog__actions">
            <button class="btn btn--ghost" value="cancel">
              {req.cancel ?? 'Anuluj'}
            </button>
            <button class={`btn ${req.danger ? 'btn--danger' : 'btn--primary'}`} value="ok">
              {req.ok}
            </button>
          </div>
        </form>
      )}
    </dialog>
  );
}
