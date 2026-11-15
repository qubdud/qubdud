import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';

/// Zasłania aplikację, gdy build jest niższy niż config/app.minBuild (iOS: minBuildIos).
/// Brak dokumentu, sieci albo uprawnień = aplikacja działa normalnie.
/// Nawigator zostaje pod spodem, bo toasty i pushe sięgają po navigatorKey.
class UpdateGate extends StatefulWidget {
  final Widget child;
  const UpdateGate({super.key, required this.child});

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  int? _build;
  Map<String, dynamic>? _config;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;
    PackageInfo.fromPlatform().then((p) {
      if (mounted) setState(() => _build = int.tryParse(p.buildNumber));
    }, onError: (_) {});
    _sub = FirebaseFirestore.instance.doc('config/app').snapshots().listen(
        (s) {
      if (mounted) setState(() => _config = s.data());
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool get _blocked {
    final min = _config?[Platform.isIOS ? 'minBuildIos' : 'minBuild'];
    return _build != null && min is num && _build! < min;
  }

  Uri? get _storeUrl {
    final custom = _config?[Platform.isIOS ? 'iosUrl' : 'androidUrl'];
    if (custom is String && custom.isNotEmpty) return Uri.tryParse(custom);
    if (Platform.isAndroid) {
      return Uri.parse(
          'https://play.google.com/store/apps/details?id=com.qb.zkv.pl.qb');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _blocked;
    return Stack(
      children: [
        ExcludeFocus(
          excluding: blocked,
          child: ExcludeSemantics(
            excluding: blocked,
            child: TickerMode(enabled: !blocked, child: widget.child),
          ),
        ),
        if (blocked)
          Positioned.fill(
              child: _UpdateScreen(
                  message: _config?['message'], url: _storeUrl)),
      ],
    );
  }
}

class _UpdateScreen extends StatelessWidget {
  final Object? message;
  final Uri? url;
  const _UpdateScreen({required this.message, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = message is String && (message as String).isNotEmpty
        ? message as String
        : 'Ta wersja QUBDUD nie jest już obsługiwana. Zainstaluj najnowszą '
            'wersję ze sklepu, żeby dalej korzystać z aplikacji.';
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(kGapL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update, size: 72, color: cDarkBlue),
                  const SizedBox(height: kGapL),
                  Text('Zaktualizuj aplikację',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: kGapS),
                  Text(text,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium),
                  if (url != null) ...[
                    const SizedBox(height: kGapXl),
                    FilledButton.icon(
                      onPressed: () =>
                          launchUrl(url!, mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.download),
                      label: const Text('Aktualizuj'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
