// Słowniki strony z kodu apki: node scripts/sync-from-dart.mjs [katalog repo] [plik wynikowy]
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join, relative, resolve as resolvePath } from 'node:path';
import { fileURLToPath } from 'node:url';

const webDir = join(dirname(fileURLToPath(import.meta.url)), '..');
const repo = process.argv[2] ? resolvePath(process.argv[2]) : join(webDir, '..');
const out = process.argv[3] ? resolvePath(process.argv[3]) : join(webDir, 'src', 'generated', 'dictionaries.ts');

const FILES = {
  constants: 'lib/shared/constants.dart',
  questions: 'lib/shared/request_questions.dart',
  offer: 'lib/shared/widgets/offer_dialog.dart',
  rules: 'lib/feature_layer/main_screen/pages/rules/view/rules_page.dart',
};

const read = (rel) => {
  const p = join(repo, rel);
  if (!existsSync(p)) throw new Error(`Brak pliku ${rel}`);
  return readFileSync(p, 'utf8');
};

// ── tokenizer literałów Darta ───────────────────────────────────────────────
function tokenize(src) {
  const t = [];
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (/\s/.test(c)) { i++; continue; }
    if (src.startsWith('//', i)) { while (i < n && src[i] !== '\n') i++; continue; }
    if (src.startsWith('/*', i)) { const e = src.indexOf('*/', i + 2); i = e < 0 ? n : e + 2; continue; }
    const raw = (c === 'r' || c === 'R') && (src[i + 1] === "'" || src[i + 1] === '"');
    if (c === "'" || c === '"' || raw) {
      if (raw) i++;
      const q = src[i];
      const triple = src.startsWith(q.repeat(3), i);
      const end = triple ? q.repeat(3) : q;
      i += end.length;
      let s = '';
      let interp = false;
      while (i < n && !src.startsWith(end, i)) {
        const ch = src[i];
        if (ch === '\\' && !raw) {
          const nx = src[i + 1];
          const map = { n: '\n', t: '\t', r: '\r', b: '\b', f: '\f', v: '\v', '0': '\0' };
          if (nx === 'u') {
            if (src[i + 2] === '{') {
              const e = src.indexOf('}', i);
              s += String.fromCodePoint(parseInt(src.slice(i + 3, e), 16));
              i = e + 1;
            } else {
              s += String.fromCharCode(parseInt(src.slice(i + 2, i + 6), 16));
              i += 6;
            }
            continue;
          }
          if (nx === 'x') { s += String.fromCharCode(parseInt(src.slice(i + 2, i + 4), 16)); i += 4; continue; }
          s += map[nx] ?? nx;
          i += 2;
          continue;
        }
        if (ch === '$' && !raw) {
          interp = true;
          if (src[i + 1] === '{') {
            const e = src.indexOf('}', i);
            s += `\u0000${src.slice(i + 2, e).trim()}\u0000`;
            i = e + 1;
          } else {
            const m = /^[A-Za-z_]\w*/.exec(src.slice(i + 1));
            s += `\u0000${m ? m[0] : ''}\u0000`;
            i += 1 + (m ? m[0].length : 0);
          }
          continue;
        }
        s += ch;
        i++;
      }
      i += end.length;
      const last = t[t.length - 1];
      // sąsiednie literały Darta łączą się w jeden
      if (last && last.type === 'str') { last.value += s; last.interp ||= interp; } else t.push({ type: 'str', value: s, interp });
      continue;
    }
    if (/[0-9]/.test(c) || (c === '-' && /[0-9]/.test(src[i + 1] ?? ''))) {
      const m = /^-?[0-9][0-9_]*(\.[0-9]+)?([eE][-+]?[0-9]+)?/.exec(src.slice(i));
      t.push({ type: 'num', value: Number(m[0].replace(/_/g, '')) });
      i += m[0].length;
      continue;
    }
    if (/[A-Za-z_$]/.test(c)) {
      const m = /^[A-Za-z_$][\w$]*/.exec(src.slice(i));
      t.push({ type: 'id', value: m[0] });
      i += m[0].length;
      continue;
    }
    t.push({ type: 'p', value: c });
    i++;
  }
  return t;
}

// ── parser wartości: mapy, listy, zbiory, wywołania konstruktorów, napisy ─────
class Parser {
  constructor(tokens, pos = 0) { this.t = tokens; this.i = pos; }
  peek(o = 0) { return this.t[this.i + o]; }
  isP(v, o = 0) { const x = this.peek(o); return x && x.type === 'p' && x.value === v; }
  eat(v) {
    if (!this.isP(v)) throw new Error(`Oczekiwano '${v}', jest ${JSON.stringify(this.peek())}`);
    this.i++;
  }
  skipTypeArgs() {
    if (!this.isP('<')) return;
    let depth = 0;
    do {
      if (this.isP('<')) depth++;
      else if (this.isP('>')) depth--;
      this.i++;
    } while (depth > 0 && this.i < this.t.length);
  }
  value() {
    const tok = this.peek();
    if (!tok) throw new Error('Nieoczekiwany koniec');
    if (tok.type === 'id' && (tok.value === 'const' || tok.value === 'final')) { this.i++; return this.value(); }
    if (this.isP('<')) { this.skipTypeArgs(); return this.value(); }
    if (tok.type === 'str') { this.i++; return tok.interp ? { $interp: tok.value } : tok.value; }
    if (tok.type === 'num') { this.i++; return tok.value; }
    if (this.isP('[')) return this.list();
    if (this.isP('{')) return this.mapOrSet();
    if (tok.type === 'id') {
      if (tok.value === 'true' || tok.value === 'false') { this.i++; return tok.value === 'true'; }
      if (tok.value === 'null') { this.i++; return null; }
      this.i++;
      let name = tok.value;
      while (this.isP('.') && this.peek(1)?.type === 'id') { name += '.' + this.peek(1).value; this.i += 2; }
      this.skipTypeArgs();
      if (this.isP('(')) return this.call(name);
      return { $ref: name };
    }
    throw new Error(`Nieobsługiwany token ${JSON.stringify(tok)}`);
  }
  list() {
    this.eat('[');
    const items = [];
    while (!this.isP(']')) {
      items.push(this.value());
      if (this.isP(',')) this.i++;
    }
    this.eat(']');
    return items;
  }
  mapOrSet() {
    this.eat('{');
    const entries = [];
    const set = [];
    while (!this.isP('}')) {
      const k = this.value();
      if (this.isP(':')) { this.i++; entries.push([k, this.value()]); } else set.push(k);
      if (this.isP(',')) this.i++;
    }
    this.eat('}');
    if (entries.length && set.length) throw new Error('Mieszana mapa/zbiór');
    return entries.length ? { $map: entries } : set;
  }
  call(name) {
    this.eat('(');
    const args = [];
    const named = {};
    while (!this.isP(')')) {
      if (this.peek()?.type === 'id' && this.isP(':', 1)) {
        const k = this.peek().value;
        this.i += 2;
        named[k] = this.value();
      } else args.push(this.value());
      if (this.isP(',')) this.i++;
    }
    this.eat(')');
    return { $call: name, args, named };
  }
}

/** Deklaracje `const|final [typ] nazwa = wartość;` (także static) — nazwa → wartość. */
function declarations(src) {
  const tokens = tokenize(src);
  const found = new Map();
  for (let i = 0; i < tokens.length; i++) {
    const tok = tokens[i];
    if (tok.type !== 'id' || (tok.value !== 'const' && tok.value !== 'final')) continue;
    let j = i + 1;
    let depth = 0;
    let name = null;
    while (j < tokens.length) {
      const x = tokens[j];
      if (x.type === 'p' && x.value === '<') depth++;
      else if (x.type === 'p' && x.value === '>') depth--;
      else if (depth === 0 && x.type === 'p' && x.value === '=') { name = tokens[j - 1]; break; }
      else if (depth === 0 && x.type === 'p' && x.value !== '?' && x.value !== ',') break;
      j++;
    }
    if (!name || name.type !== 'id') continue;
    try {
      const p = new Parser(tokens, j + 1);
      const value = p.value();
      if (!found.has(name.value)) found.set(name.value, value);
      i = p.i - 1;
    } catch {
      // wartość spoza obsługiwanych literałów (np. obiekt Color) — pomijamy
    }
  }
  return found;
}

const isStr = (v) => typeof v === 'string';
const isMap = (v) => v && typeof v === 'object' && Array.isArray(v.$map);
const toObj = (m) => Object.fromEntries(m.$map);

function question(v) {
  if (!v || v.$call === undefined || !/RequestQuestion$/.test(v.$call)) return null;
  const label = v.named.label ?? v.args[0];
  const options = v.named.options ?? v.args[1];
  if (!isStr(label) || !Array.isArray(options) || !options.every(isStr)) return null;
  const q = { label, options };
  for (const [k, val] of Object.entries(v.named)) {
    if (k !== 'label' && k !== 'options' && (isStr(val) || typeof val === 'boolean' || typeof val === 'number')) q[k] = val;
  }
  return q;
}

function questionsMap(v) {
  if (!isMap(v)) return null;
  const res = {};
  for (const [k, list] of v.$map) {
    if (!isStr(k) || !Array.isArray(list)) return null;
    const qs = list.map(question);
    if (qs.some((q) => !q)) return null;
    res[k] = qs;
  }
  return res;
}

// ── kategorie i branże ──────────────────────────────────────────────────────
const constDecl = declarations(read(FILES.constants));
const catRaw = constDecl.get('categories');
if (!isMap(catRaw)) throw new Error('Nie znaleziono mapy `categories` w ' + FILES.constants);
const CATEGORIES = toObj(catRaw);
for (const [k, v] of Object.entries(CATEGORIES)) {
  if (!Array.isArray(v) || !v.every(isStr)) throw new Error(`Kategoria ${k}: oczekiwano listy napisów`);
}
const allSectors = new Set(Object.values(CATEGORIES).flat());
const allCategories = new Set(Object.keys(CATEGORIES));

// ── pytania kreatora ────────────────────────────────────────────────────────
const qSrc = read(FILES.questions);
const qDecl = declarations(qSrc);
const timingRaw = qDecl.get('kRequestTiming');
if (!isMap(timingRaw)) throw new Error('Nie znaleziono kRequestTiming w ' + FILES.questions);
const REQUEST_TIMING = toObj(timingRaw);

let CATEGORY_QUESTIONS = null;
let SECTOR_QUESTIONS = {};
const warnings = [];
for (const [name, v] of qDecl) {
  const m = questionsMap(v);
  if (!m) continue;
  const keys = Object.keys(m);
  const byName = /categor|kategor/i.test(name) ? 'cat' : /sector|branz|branż|industry/i.test(name) ? 'sec' : null;
  const byKeys = keys.length && keys.every((k) => allCategories.has(k)) ? 'cat'
    : keys.length && keys.every((k) => allSectors.has(k)) ? 'sec' : null;
  const kind = byName ?? byKeys;
  const unknown = keys.filter((k) => !allCategories.has(k) && !allSectors.has(k));
  if (unknown.length) warnings.push(`${name}: klucze spoza słownika: ${unknown.join(', ')}`);
  if (kind === 'cat' && !CATEGORY_QUESTIONS) CATEGORY_QUESTIONS = m;
  else if (kind === 'sec') SECTOR_QUESTIONS = { ...SECTOR_QUESTIONS, ...m };
  else warnings.push(`${name}: nie wiem, czy to mapa kategorii czy branż — pominięta`);
}
if (!CATEGORY_QUESTIONS) throw new Error('Nie znaleziono mapy pytań kategorii w ' + FILES.questions);

// branże awaryjne (opcja „Awaria — 24 h”): lista/zbiór napisów o nazwie z emergency/urgent/awar/24
const EMERGENCY_SECTORS = [];
for (const decl of [qDecl, constDecl]) {
  for (const [name, v] of decl) {
    if (!/emergenc|urgent|awar|24/i.test(name) || !Array.isArray(v) || !v.length || !v.every(isStr)) continue;
    const known = v.filter((s) => allSectors.has(s));
    if (known.length !== v.length) warnings.push(`${name}: pominięto branże spoza słownika: ${v.filter((s) => !allSectors.has(s)).join(', ')}`);
    for (const s of known) if (!EMERGENCY_SECTORS.includes(s)) EMERGENCY_SECTORS.push(s);
  }
}

// ── terminy w ofercie ───────────────────────────────────────────────────────
const offerRaw = declarations(read(FILES.offer)).get('kOfferWhen');
if (!isMap(offerRaw)) throw new Error('Nie znaleziono kOfferWhen w ' + FILES.offer);
const OFFER_WHEN = toObj(offerRaw);

// ── regulamin i polityka prywatności ────────────────────────────────────────
const rulesSrc = read(FILES.rules);
const rulesDecl = declarations(rulesSrc);
const resolve = (s) => s.replace(/\u0000([^\u0000]*)\u0000/g, (_, name) => {
  const v = rulesDecl.get(name);
  if (!isStr(v)) throw new Error(`Regulamin: nieznana zmienna $${name}`);
  return v;
});
const text = (v) => (isStr(v) ? v : v && v.$interp !== undefined ? resolve(v.$interp) : null);
const RULES = [];
{
  const tokens = tokenize(rulesSrc);
  for (let i = 0; i < tokens.length; i++) {
    const tok = tokens[i];
    if (tok.type !== 'id' || (tok.value !== '_header' && tok.value !== '_section')) continue;
    if (!(tokens[i + 1]?.type === 'p' && tokens[i + 1].value === '(')) continue;
    if (tokens[i - 1]?.type === 'id' && /^(Widget|void)$/.test(tokens[i - 1].value)) continue;
    const p = new Parser(tokens, i + 1);
    let call;
    try { call = p.call(tok.value); } catch { continue; }
    const args = call.args.map(text);
    if (args.some((a) => a === null)) continue;
    if (tok.value === '_header') RULES.push({ title: args[0], sections: [] });
    else if (RULES.length) RULES[RULES.length - 1].sections.push({ title: args[0], body: args[1] });
    i = p.i - 1;
  }
}
if (RULES.length < 2 || RULES.some((r) => !r.sections.length)) throw new Error('Nie udało się odczytać regulaminu z ' + FILES.rules);

const j = (v) => JSON.stringify(v, null, 2);
const body = `// Wygenerowane przez scripts/sync-from-dart.mjs z ${Object.values(FILES).join(', ')} — nie edytuj ręcznie.

export interface RequestQuestion {
  label: string;
  options: string[];
}

export const CATEGORIES: Record<string, string[]> = ${j(CATEGORIES)};

export const REQUEST_TIMING: Record<string, string> = ${j(REQUEST_TIMING)};

export const CATEGORY_QUESTIONS: Record<string, RequestQuestion[]> = ${j(CATEGORY_QUESTIONS)};

export const SECTOR_QUESTIONS: Record<string, RequestQuestion[]> = ${j(SECTOR_QUESTIONS)};

export const EMERGENCY_SECTORS: string[] = ${j(EMERGENCY_SECTORS)};

export const OFFER_WHEN: Record<string, string> = ${j(OFFER_WHEN)};

export const RULES: { title: string; sections: { title: string; body: string }[] }[] = ${j(RULES)};
`;
writeFileSync(out, body.replace(/\r\n/g, '\n'));
for (const w of warnings) console.warn('uwaga:', w);
console.log(`${relative(webDir, out)}: ${Object.keys(CATEGORIES).length} kategorii, ${allSectors.size} branż, ` +
  `pytania: ${Object.keys(CATEGORY_QUESTIONS).length} kategorii / ${Object.keys(SECTOR_QUESTIONS).length} branż, ` +
  `awaryjne: ${EMERGENCY_SECTORS.length}, regulamin: ${RULES.map((r) => r.sections.length).join('+')} sekcji`);
