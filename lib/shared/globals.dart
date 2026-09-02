import 'package:latlong2/latlong.dart';

import '../domain_layer/domain_models/promoVideo.dart';

class Globals {
  Request? selectedRequest;

  /// Jednorazowe: który tab Startu otworzyć po GoToHomeEvent (np. Kalendarz).
  int? startTab;
  Promo? selectedPromo;
  Promo? selectedReview;

  List<Promo> lastSearch = [];
  int lastSearchIndex = 0;

  bool anonim = false;

  /// Konto firmowe może przełączyć się na widok prywatny (user).
  /// true = obsługuję firmę, false = działam jak zwykły user.
  bool companyView = true;
  String kategoria = '';
  String branza = '';
  LatLng pozycja = LatLng(52.237049, 21.017532);

  Globals._privateConstructor();

  static final Globals _instance = Globals._privateConstructor();

  static Globals get instance => _instance;
}

