import 'package:flutter/material.dart';
import 'package:qb/shared/widgets/anonim_gate.dart';
import 'package:qb/shared/widgets/contact_request_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:qb/domain_layer/firebase_service.dart';
import 'package:qb/feature_layer/main_screen/bloc/main_bloc.dart';
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/mini_slots_bar.dart';

/// Pionowy feed wideo (styl TikTok): przesuwanie w górę/dół między filmami.
/// Bez playlisty gra pojedynczy film.
class SingleVideoPage extends StatefulWidget {
  final Promo promo;
  final List<Promo>? playlist;
  final int initialIndex;

  const SingleVideoPage({
    super.key,
    required this.promo,
    this.playlist,
    this.initialIndex = 0,
  });

  @override
  State<SingleVideoPage> createState() => _SingleVideoPageState();
}

class _SingleVideoPageState extends State<SingleVideoPage> {
  late final PageController _pageController;
  late final List<Promo> _videos;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _videos = (widget.playlist != null && widget.playlist!.isNotEmpty)
        ? widget.playlist!
        : [widget.promo];
    _current = widget.initialIndex.clamp(0, _videos.length - 1);
    _pageController = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) => _VideoItem(
          key: ValueKey(_videos[i].id),
          promo: _videos[i],
          isActive: i == _current,
        ),
      ),
    );
  }
}

class _VideoItem extends StatefulWidget {
  final Promo promo;
  final bool isActive;

  const _VideoItem({super.key, required this.promo, required this.isActive});

  @override
  State<_VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<_VideoItem> {
  VideoPlayerController? _controller;
  AppUser? _author;
  int _reviewCount = 0;
  double _rating = 0;
  bool _viewCounted = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _loadAuthor();
    if (widget.isActive) _countView();
  }

  void _initPlayer() {
    _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.promo.fileUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (widget.isActive) _controller!.play();
        _controller!.setLooping(true);
      });
  }

  Future<void> _loadAuthor() async {
    final firebase = context.read<FirebaseService>();
    try {
      final results = await Future.wait([
        firebase.fetchUser(widget.promo.userId),
        firebase.getReviewsMetadataByReviewedUser(widget.promo.userId),
      ]);
      final author = results[0] as AppUser?;
      final reviews = results[1] as List<Review>;
      if (!mounted) return;
      setState(() {
        _author = author;
        _reviewCount = reviews.length;
        _rating = reviews.isEmpty
            ? 0
            : reviews.map((r) => r.score).reduce((a, b) => a + b) /
                reviews.length;
      });
    } catch (_) {}
  }

  void _countView() {
    if (_viewCounted) return;
    _viewCounted = true;
    // anonim nie ma prawa zapisu (reguły) — licznik tylko dla zalogowanych
    if (!Globals.instance.anonim) {
      context
          .read<FirebaseService>()
          .incrementPromoViews(widget.promo.id)
          .catchError((_) {});
    }
  }

  @override
  void didUpdateWidget(covariant _VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
      _countView();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialized = _controller?.value.isInitialized ?? false;

    return Stack(
      children: [
        // ── Film ─────────────────────────────────────────
        if (initialized)
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          )
        else
          const Center(
              child: CircularProgressIndicator(color: Colors.white54)),

        // pauza/wznowienie tapnięciem
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              if (_controller == null || !initialized) return;
              setState(() {
                _controller!.value.isPlaying
                    ? _controller!.pause()
                    : _controller!.play();
              });
            },
          ),
        ),
        if (initialized && !_controller!.value.isPlaying)
          const Center(
            child: Icon(Icons.play_arrow, color: Colors.white70, size: 72),
          ),

        // ── Ikony akcji po prawej ─────────────────────────
        Positioned(
          right: 8,
          bottom: 140,
          child: Column(
            children: [
              _ActionIcon(
                icon: Icons.favorite_outline,
                tooltip: 'Ulubione',
                onTap: () async {
                  if (Globals.instance.anonim) {
                    showLoginPrompt(context, 'dodać do ulubionych');
                    return;
                  }
                  final myUid =
                      context.read<MainScreenBloc>().state.user?.id ?? '';
                  await context.read<FirebaseService>().addPromoToFavorites(
                      userId: myUid, promoId: widget.promo.id);
                  showToast(text: 'Dodano do ulubionych');
                },
              ),
              const SizedBox(height: 16),
              _ActionIcon(
                icon: Icons.person_add_outlined,
                tooltip: 'Dodaj do kontaktów',
                onTap: () async {
                  if (Globals.instance.anonim) {
                    showLoginPrompt(context, 'zapisać firmę w kontaktach');
                    return;
                  }
                  final myUid =
                      context.read<MainScreenBloc>().state.user?.id ?? '';
                  await context.read<FirebaseService>().addContact(
                      myUserId: myUid, contactUserId: widget.promo.userId);
                  showToast(text: 'Dodano do kontaktów');
                },
              ),
              const SizedBox(height: 16),
              ContactRequestButton(
                companyId: widget.promo.userId,
                companyName:
                    _author?.companyName ?? widget.promo.companyName,
              ),
              const SizedBox(height: 16),
              _ActionIcon(
                icon: Icons.share_outlined,
                tooltip: 'Udostępnij',
                onTap: () {
                  if (Globals.instance.anonim) {
                    showLoginPrompt(context, 'udostępnić firmę');
                    return;
                  }
                  final name =
                      _author?.companyName ?? widget.promo.companyName;
                  Share.share(
                      'Zobacz prezentację firmy $name w aplikacji QUBDUD:\nqubdud://promo/${widget.promo.id}');
                },
              ),
              const SizedBox(height: 16),
              // licznik wyświetleń
              Column(
                children: [
                  const Icon(Icons.visibility_outlined,
                      color: Colors.white70, size: 22),
                  Text(
                    '${widget.promo.views + (_viewCounted ? 1 : 0)}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Pasek firmy na dole (+ mini-mapka slotów) ─────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiniSlotsBar(companyId: widget.promo.userId),
              _companyBar(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _companyBar(BuildContext context) {
    return GestureDetector(
            onTap: () => context
                .read<MainScreenBloc>()
                .add(GoToProfilPublicznyFirmyEvent(widget.promo.userId)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: Colors.black.withOpacity(0.65),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Globals.instance.anonim
                        ? const Icon(Icons.lock_outline, color: Colors.white)
                        : Text(
                            (_author?.companyName ?? widget.promo.companyName)
                                    .isNotEmpty
                                ? (_author?.companyName ?? widget.promo.companyName)[0]
                                    .toUpperCase()
                                : 'F',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Globals.instance.anonim
                              ? kAnonimCompanyLabel
                              : (_author?.companyName ?? widget.promo.companyName),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        if (_reviewCount > 0)
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < _rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('($_reviewCount)',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          )
                        else
                          const Text('Brak opinii',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
