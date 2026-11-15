import type { ComponentChildren } from 'preact';
import { useEffect } from 'preact/hooks';

export function useTitle(title: string): void {
  useEffect(() => {
    document.title = title ? `${title} · QUBDUD` : 'QUBDUD — zgłoszenia i oferty firm z okolicy';
  }, [title]);
}

export function Spinner({ label = 'Wczytywanie…' }: { label?: string }) {
  return (
    <div class="spinner" role="status">
      <span class="spinner__dot" aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}

export function Stars({ score, label }: { score: number; label?: string }) {
  const full = Math.round(score);
  return (
    <span class="stars" aria-label={label ?? `Ocena ${score.toLocaleString('pl-PL')} na 5`} role="img">
      {[1, 2, 3, 4, 5].map((i) => (
        <span key={i} aria-hidden="true" class={i <= full ? 'stars__on' : 'stars__off'}>
          ★
        </span>
      ))}
    </span>
  );
}

export function Avatar({ name, company }: { name: string; company?: boolean }) {
  return (
    <span class={`avatar${company ? ' avatar--company' : ''}`} aria-hidden="true">
      {(name.trim()[0] ?? '?').toUpperCase()}
    </span>
  );
}

export function Badge({ tone = 'neutral', children }: { tone?: 'neutral' | 'ok' | 'warn' | 'bad' | 'info'; children: ComponentChildren }) {
  return <span class={`badge badge--${tone}`}>{children}</span>;
}

export function Field({
  id,
  label,
  error,
  hint,
  children,
}: {
  id: string;
  label: ComponentChildren;
  error?: string;
  hint?: ComponentChildren;
  children: ComponentChildren;
}) {
  return (
    <div class={`field${error ? ' field--error' : ''}`}>
      <label for={id} class="field__label">
        {label}
      </label>
      {children}
      {hint && !error && (
        <p class="field__hint" id={`${id}-hint`}>
          {hint}
        </p>
      )}
      {error && (
        <p class="field__error" id={`${id}-error`}>
          {error}
        </p>
      )}
    </div>
  );
}

/** Pytanie z jedną odpowiedzią jako „chipsy” (radio); ponowne kliknięcie odznacza. */
export function Chips({
  name,
  legend,
  options,
  value,
  onChange,
}: {
  name: string;
  legend: string;
  options: { value: string; label: string }[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <fieldset class="chips">
      <legend class="field__label">{legend}</legend>
      <div class="chips__list">
        {options.map((o) => (
          <label key={o.value} class={`chip${value === o.value ? ' chip--on' : ''}`}>
            <input
              type="radio"
              name={name}
              value={o.value}
              checked={value === o.value}
              onClick={() => value === o.value && onChange('')}
              onChange={() => onChange(o.value)}
            />
            <span>{o.label}</span>
          </label>
        ))}
      </div>
    </fieldset>
  );
}
