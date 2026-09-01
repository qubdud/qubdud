import 'dart:io';
import 'app/app.dart';
import 'bootstrap.dart';
import 'data_layer/api.dart';
import 'domain_layer/repository.dart';



class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  final appApi = AppApi();
  final appRepository = AppRepository(appApi: appApi);

  bootstrap(() => App(
        appRepository: appRepository,
      ));
}
