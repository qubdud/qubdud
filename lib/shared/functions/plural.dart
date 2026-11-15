/// Odmiana po liczebniku: 1 opinia, 2–4 opinie (bez 12–14), 5+ opinii.
String plural(int n, String one, String few, String many) {
  if (n == 1) return one;
  final d = n % 10, h = n % 100;
  return d >= 2 && d <= 4 && (h < 12 || h > 14) ? few : many;
}
