// Podgląd struktury Excela: node inspect_xlsx.js [ścieżka]
const XLSX = require('xlsx');
const path = process.argv[2] || '../Lista testowa branż dla wojtek.xlsx';
const wb = XLSX.readFile(path);
for (const name of wb.SheetNames) {
  const rows = XLSX.utils.sheet_to_json(wb.Sheets[name], { header: 1, defval: '' });
  console.log(`=== Arkusz "${name}" — ${rows.length} wierszy`);
  rows.slice(0, 15).forEach((r, i) => console.log(i, JSON.stringify(r)));
}
