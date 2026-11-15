import type { LatLng } from '../data/requests.ts';

/** Szkic zgłoszenia — przetrwa przejście przez link z e-maila (IndexedDB trzyma też zdjęcia). */
export interface RequestDraft {
  description: string;
  category: string;
  sector: string;
  city: string;
  location: LatLng | null;
  is24: boolean;
  timing: string;
  budget: string;
  answers: Record<string, string>;
  photos: Blob[];
  savedAt: number;
}

export const emptyDraft = (): RequestDraft => ({
  description: '',
  category: '',
  sector: '',
  city: '',
  location: null,
  is24: false,
  timing: '',
  budget: '',
  answers: {},
  photos: [],
  savedAt: 0,
});

const DB = 'qubdud-web';
const STORE = 'drafts';
const KEY = 'request';
const MAX_AGE_MS = 7 * 24 * 3600 * 1000;

function open(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB, 1);
    req.onupgradeneeded = () => req.result.createObjectStore(STORE);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function run<T>(mode: IDBTransactionMode, fn: (s: IDBObjectStore) => IDBRequest<T>): Promise<T> {
  const db = await open();
  try {
    return await new Promise<T>((resolve, reject) => {
      const tx = db.transaction(STORE, mode);
      const r = fn(tx.objectStore(STORE));
      tx.oncomplete = () => resolve(r.result);
      tx.onerror = () => reject(tx.error);
      tx.onabort = () => reject(tx.error);
    });
  } finally {
    db.close();
  }
}

export async function loadDraft(): Promise<RequestDraft | null> {
  try {
    const d = (await run('readonly', (s) => s.get(KEY))) as RequestDraft | undefined;
    if (!d || Date.now() - (d.savedAt || 0) > MAX_AGE_MS) return null;
    return { ...emptyDraft(), ...d };
  } catch {
    return null;
  }
}

export async function saveDraft(d: RequestDraft): Promise<boolean> {
  try {
    await run('readwrite', (s) => s.put({ ...d, savedAt: Date.now() }, KEY));
    return true;
  } catch {
    return false;
  }
}

export async function clearDraft(): Promise<void> {
  try {
    await run('readwrite', (s) => s.delete(KEY));
  } catch {
    // brak IndexedDB (np. tryb prywatny) — nie ma czego czyścić
  }
}
