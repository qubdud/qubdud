import 'package:latlong2/latlong.dart';

import '../domain_layer/domain_models/promoVideo.dart';

class Globals {
  bool rememberMe = false;
  int appVerionCode = 10000;

  String actualId = '';

  Request? selectedRequest;
  Promo? selectedPromo;
  Promo? selectedReview;

  List<Promo> lastSearch = [];
  int lastSearchIndex = 0;



  String meId = '';



  bool anonim=false;
  String kategoria='';
  String branza='';
  LatLng pozycja = LatLng(52.237049, 21.017532);
  


  //Albedo//
   //String baseUrl = 'https://test-nexi2025.albedomarketing.net';
   //String baseUrl = 'https://nexi2025.albedomarketing.net';
   String baseUrl = 'https://klubpirelli.pl';

  Globals._privateConstructor();

  static final Globals _instance = Globals._privateConstructor();

  static Globals get instance => _instance;
}

