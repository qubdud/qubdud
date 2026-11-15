// Emulatory z regułami i indeksami z repo, na projekcie demo i niestandardowych portach.
// node test/emulators.mjs exec|start [auth,firestore,storage]
// firebase-tools nie przyjmuje reguł spoza katalogu configu, więc config i kopie reguł idą do katalogu tymczasowego.
import { copyFileSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const web = join(here, '..');
const repo = join(web, '..');
const mode = process.argv[2] === 'start' ? 'start' : 'exec';
const only = process.argv[3] ?? 'auth,firestore,storage';
const win = process.platform === 'win32';
const q = (s) => (win ? `"${s}"` : s);

const dir = mkdtempSync(join(tmpdir(), 'qubdud-web-emu-'));
for (const f of ['firestore.rules', 'storage.rules', 'firestore.indexes.json']) copyFileSync(join(repo, f), join(dir, f));
writeFileSync(
  join(dir, 'firebase.json'),
  JSON.stringify({
    firestore: { rules: 'firestore.rules', indexes: 'firestore.indexes.json' },
    storage: { rules: 'storage.rules' },
    emulators: {
      auth: { host: '127.0.0.1', port: 9199 },
      firestore: { host: '127.0.0.1', port: 8185, websocketPort: 9185 },
      storage: { host: '127.0.0.1', port: 9299 },
      hub: { host: '127.0.0.1', port: 4419 },
      logging: { host: '127.0.0.1', port: 4519 },
      ui: { enabled: false },
      singleProjectMode: true,
    },
  }, null, 2),
);

const args = [`emulators:${mode}`, '--project', 'demo-qubdud', '--config', q(join(dir, 'firebase.json')), '--only', only];
if (mode === 'exec') args.push(q('node test/flow.test.mjs'));
const r = spawnSync('firebase', args, { cwd: web, stdio: 'inherit', shell: win });
rmSync(dir, { recursive: true, force: true });
process.exit(r.status ?? 1);
