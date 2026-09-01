import 'package:shared_preferences/shared_preferences.dart';

import '../../domain_layer/domain_models/app_user.dart';
import '../globals.dart';

/// Efektywna rola: konto firmowe działa jako firma tylko w trybie firmowym.
bool isCompanyMode(AppUser? user) =>
    (user?.firma ?? false) && Globals.instance.companyView;

Future<void> loadCompanyView() async {
  final prefs = await SharedPreferences.getInstance();
  Globals.instance.companyView = prefs.getBool('company_view') ?? true;
}

Future<void> setCompanyView(bool value) async {
  Globals.instance.companyView = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('company_view', value);
}
