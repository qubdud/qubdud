// Generuje obrazki-ikony dla fake zgłoszeń (tło + nazwa branży).
const { spawnSync } = require('child_process');
const reqs = require('./requests.json');

for (const r of reqs) {
  const color = r.color.replace('0x', '');
  const filter =
    "drawtext=fontfile='C\\:/Windows/Fonts/arialbd.ttf'" +
    `:text='${r.label}':fontcolor=white:fontsize=64` +
    ':x=(w-text_w)/2:y=(h-text_h)/2';
  const res = spawnSync(
    'ffmpeg',
    [
      '-y', '-loglevel', 'error',
      '-f', 'lavfi', '-i', `color=c=${color}:s=480x640`,
      '-frames:v', '1',
      '-vf', filter,
      `../_reqimg/${r.file}.jpg`,
    ],
    { stdio: 'inherit' }
  );
  if (res.status !== 0) {
    console.error('FAIL', r.file);
    process.exit(1);
  }
}
console.log('OK', reqs.length);
