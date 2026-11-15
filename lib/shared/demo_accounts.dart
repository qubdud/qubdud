/// Szybkie wypełnianie loginu na ekranie logowania — w buildzie debug i w APK
/// dla testerów (`--dart-define=DEMO_LOGIN=true`). W buildzie do sklepu obie
/// flagi są fałszywe, więc lista nie trafia do skompilowanego kodu.
/// Konta firm to prawdziwe firmy ze wspólnym hasłem — tylko dla zamkniętej grupy.
const bool kDemoLogin = bool.fromEnvironment('DEMO_LOGIN');

class DemoAccount {
  final String label;
  final String email;
  final String password;

  const DemoAccount(this.label, this.email, this.password);
}

const String _userPass = 'Demo123!';
const String _firmPass = 'asdfghjkl';

const List<DemoAccount> demoAccounts = [
  // ── Użytkownicy ──────────────────────────────────────────
  DemoAccount('👤 Jan Testowy', 'demo.user1@qubdud-demo.pl', _userPass),
  DemoAccount('👤 Anna Przykładowa', 'demo.user2@qubdud-demo.pl', _userPass),
  DemoAccount('👤 Piotr Demo', 'demo.user3@qubdud-demo.pl', _userPass),

  // ── Firmy ────────────────────────────────────────────────
  DemoAccount('🏢 Protechnic — elektryk', 'e4w@a.pl', _firmPass),
  DemoAccount('🏢 ELEKTIM — elektryk', 'e6w@a.pl', _firmPass),
  DemoAccount('🏢 Hydro Instalex — hydraulik', 'h1w@a.pl', _firmPass),
  DemoAccount('🏢 Hydromen — hydraulik', 'h4w@a.pl', _firmPass),
  DemoAccount('🏢 New School Barber', 'bar3w@a.pl', _firmPass),
  DemoAccount('🏢 Oblivion Barbershop', 'bar6w@a.pl', _firmPass),
  DemoAccount('🏢 Denta City — dentysta', 'den4w@a.pl', _firmPass),
  DemoAccount('🏢 FeelDent — dentysta', 'den1w@a.pl', _firmPass),
  DemoAccount('🏢 PLPizza — restauracja', 're7w@a.pl', _firmPass),
  DemoAccount('🏢 Catering Smaki', 'ca2w@a.pl', _firmPass),
  DemoAccount('🏢 Best Clean — sprzątanie', 'sp2w@a.pl', _firmPass),
  DemoAccount('🏢 AUTO-KAM — mechanik', 'w10w@a.pl', _firmPass),
  DemoAccount('🏢 Kancelaria Pilawska', 'pr3w@a.pl', _firmPass),
  DemoAccount('🏢 Stolarnia GG Koncept', 'sto5w@a.pl', _firmPass),
  DemoAccount('🏢 Doggy Spa — zwierzęta', 'opz2w@a.pl', _firmPass),
  DemoAccount('🏢 Serwistel — telefony', 'na3w@a.pl', _firmPass),
];
