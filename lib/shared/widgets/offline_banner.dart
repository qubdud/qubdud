import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Pasek „Brak połączenia" nad treścią — bez niego ekrany kręcą się
/// w nieskończoność, a użytkownik nie wie dlaczego.
class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then(_apply).catchError((_) {});
    _sub = Connectivity().onConnectivityChanged.listen(_apply, onError: (_) {});
  }

  void _apply(List<ConnectivityResult> results) {
    final off = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (off != _offline && mounted) setState(() => _offline = off);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _offline
              ? Material(
                  color: Colors.red.shade700,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.white, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Brak połączenia z internetem — dane mogą być nieaktualne',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(
          // baner już zajął pasek statusu — treść nie dokłada drugiego marginesu;
          // zawsze ten sam typ widgetu, inaczej zmiana łączności remontuje cały ekran
          child: MediaQuery.removePadding(
              context: context, removeTop: _offline, child: widget.child),
        ),
      ],
    );
  }
}
