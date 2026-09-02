import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain_layer/firebase_service.dart';

import '../../domain_layer/domain_models/promoVideo.dart';
import '../globals.dart';

/// Kafelek prezentacji firmy (Odkrywaj, Ulubione): miniatura, nazwa firmy
/// i branża na gradiencie, ikona play. Opcjonalny przycisk w rogu (np. usuń).
class PromoTile extends StatefulWidget {
  final Promo promo;
  final VoidCallback onTap;
  final Widget? cornerAction;

  const PromoTile({
    super.key,
    required this.promo,
    required this.onTap,
    this.cornerAction,
  });

  @override
  State<PromoTile> createState() => _PromoTileState();
}

class _PromoTileState extends State<PromoTile> {
  static final Map<String, String> _nameCache = {};
  String? _fetched;

  @override
  void initState() {
    super.initState();
    // starsze prezentacje nie mają zapisanej nazwy firmy — dociągamy raz
    if (widget.promo.companyName.isEmpty && !Globals.instance.anonim) {
      final cached = _nameCache[widget.promo.userId];
      if (cached != null) {
        _fetched = cached;
      } else {
        context
            .read<FirebaseService>()
            .fetchUser(widget.promo.userId)
            .then((u) {
          final n = u?.companyName ?? '';
          _nameCache[widget.promo.userId] = n;
          if (mounted && n.isNotEmpty) setState(() => _fetched = n);
        }).catchError((_) {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final promo = widget.promo;
    final onTap = widget.onTap;
    final cornerAction = widget.cornerAction;
    final name = Globals.instance.anonim
        ? 'Firma · zaloguj się'
        : (promo.companyName.isNotEmpty
            ? promo.companyName
            : (_fetched ?? 'Firma'));

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (promo.thumbUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: promo.thumbUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.videocam_off_outlined,
                        color: Colors.grey)),
              )
            else
              Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.videocam_outlined,
                      color: Colors.grey, size: 40)),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.15)),
                    const SizedBox(height: 2),
                    Text(promo.sector,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: cornerAction ??
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black45,
                    child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
