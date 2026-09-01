import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../domain_layer/chat_service.dart';
import '../../../../../shared/widgets/before_after.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../profil_my/view/tab_kalendarz.dart' show dayLabel;
import '../../../../../domain_layer/domain_models/app_user.dart';
import '../../../../../domain_layer/domain_models/company_info.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/globals.dart';
import '../../../../../shared/widgets/loading.dart';
import '../../../../../shared/widgets/review.dart';
import '../../../../../shared/widgets/w_small_label.dart';
import '../../../bloc/main_bloc.dart';
import '../bloc/profil_my_page_bloc.dart';

class ProfilPubliczyPage extends StatelessWidget {
  final String userId;
  const ProfilPubliczyPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfilPubliczyPageBloc(
        firebase: context.read<FirebaseService>(),
        targetUserId: userId,
      ),
      child: const _ProfilView(),
    );
  }
}

class _ProfilView extends StatelessWidget {
  const _ProfilView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF16151A) : Colors.white,
      body: BlocBuilder<ProfilPubliczyPageBloc, ProfilPubliczyPageState>(
        builder: (context, state) {
          if (state is ProfilPubliczyPageLoadingState && state.targetUser == null) {
            return const Loading();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state.targetUser, state.companyInfo),

                if (state.targetUser != null)
                  _SlotsSection(companyId: state.targetUser!.id, companyName: state.targetUser!.companyName ?? "Firma"),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: WSmallLabel(text: 'Prezentacje firmy'),
                ),
                _buildVideosGrid(context, state.videos),

                if (state.targetUser != null)
                  _RealizationsSection(companyId: state.targetUser!.id),

                const SizedBox(height: 24),
                _ReviewsSection(
                  reviews: state.reviews,
                  avgScore: state.averageScore,
                  companyId: state.targetUser?.id ?? '',
                ),

                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user, ProfileInfo? info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1B21) : Colors.grey.shade50,
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.black87,
                child: Text(
                  user?.companyName?.isNotEmpty == true
                      ? user!.companyName![0].toUpperCase()
                      : 'F',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.companyName ?? 'Firma',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    if (user?.companyCity != null)
                      Text(user!.companyCity!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    if (user?.companyCategory != null)
                      Text(user!.companyCategory!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    if (user != null)
                      FutureBuilder<int>(
                        future: context
                            .read<FirebaseService>()
                            .getCompletedJobsCount(user.id),
                        builder: (context, snap) {
                          final n = snap.data ?? 0;
                          if (n == 0) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_outlined,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  n == 1
                                      ? '1 zrealizowane zlecenie'
                                      : '$n zrealizowanych zleceń',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 22),
                tooltip: 'Udostępnij profil',
                onPressed: () {
                  if (user == null) return;
                  Share.share(
                      'Sprawdź firmę ${user.companyName ?? ''} w aplikacji QUBDUD:\nqubdud://firma/${user.id}');
                },
              ),
            ],
          ),
          if (info?.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(info!.description,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Napisz'),
                  onPressed: () => context
                      .read<MainScreenBloc>()
                      .add(GoToChatEvent(user?.id ?? '', chatName: user?.companyName)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Kontakt'),
                  onPressed: () async {
                    final firebase = context.read<FirebaseService>();
                    final myUid =
                        context.read<MainScreenBloc>().state.user?.id ?? '';
                    await firebase.addContact(
                        myUserId: myUid, contactUserId: user?.id ?? '');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dodano do kontaktów')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.white12 : Colors.grey.shade200,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideosGrid(BuildContext context, List<Promo> videos) {
    if (videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Brak filmów.', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.6,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => context.read<MainScreenBloc>().add(
            GoToPromoFirmyEvent(videos[i], playlist: videos, initialIndex: i)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: videos[i].thumbUrl,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Realizacje — zdjęcia wykonanych zleceń (z potwierdzonych zadań)
// ─────────────────────────────────────────────────────────────────────────────
class _RealizationsSection extends StatefulWidget {
  final String companyId;
  const _RealizationsSection({required this.companyId});

  @override
  State<_RealizationsSection> createState() => _RealizationsSectionState();
}

class _RealizationsSectionState extends State<_RealizationsSection> {
  List<Map<String, dynamic>> _photos = [];

  @override
  void initState() {
    super.initState();
    context
        .read<FirebaseService>()
        .getRealizations(widget.companyId)
        .then((p) {
      if (mounted) setState(() => _photos = p);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: WSmallLabel(text: 'Realizacje'),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _photos.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: RealizationThumb(photo: _photos[i], size: 130),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            'Zdjęcia z zadań zrealizowanych i potwierdzonych przez klientów.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wolne terminy firmy (podgląd kalendarza — 7 dni)
// ─────────────────────────────────────────────────────────────────────────────
class _SlotsSection extends StatefulWidget {
  final String companyId;
  final String companyName;
  const _SlotsSection({required this.companyId, required this.companyName});

  @override
  State<_SlotsSection> createState() => _SlotsSectionState();
}

class _SlotsSectionState extends State<_SlotsSection> {
  List<Map<String, dynamic>> _slots = [];
  bool _loaded = false;

  Future<void> _bookSlot(BuildContext context, DateTime st) async {
    if (Globals.instance.anonim) {
      showToast(text: 'Zaloguj się, aby zapytać o termin');
      return;
    }
    final label = '${dayLabel(st)} o ${DateFormat('HH:mm').format(st)}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezerwacja terminu'),
        content: Text('Wysłać firmie zapytanie o termin:\n$label?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Wyślij')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ChatService>().sendMessage(
          widget.companyId,
          'Dzień dobry, chciałbym zarezerwować termin: $label. Czy jest dostępny?',
        );
    if (!mounted) return;
    context.read<MainScreenBloc>().add(GoToChatEvent(widget.companyId, chatName: widget.companyName));
  }

  @override
  void initState() {
    super.initState();
    context
        .read<FirebaseService>()
        .getSlots(widget.companyId)
        .then((slots) {
      if (mounted) setState(() { _slots = slots; _loaded = true; });
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _slots.isEmpty) return const SizedBox.shrink();

    // grupowanie po dniach (kolejność chronologiczna — sloty są posortowane)
    final byDay = <String, List<DateTime>>{};
    for (final s in _slots) {
      final st = s['start'] as DateTime;
      final key = dayLabel(st);
      byDay.putIfAbsent(key, () => []).add(st);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WSmallLabel(text: 'Wolne terminy (7 dni)'),
          const SizedBox(height: 8),
          ...byDay.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(e.key,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: e.value
                            .map((st) => GestureDetector(
                                  onTap: () => _bookSlot(context, st),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.green.shade200),
                                    ),
                                    child: Text(
                                      DateFormat('HH:mm').format(st),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade800),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Text('Dotknij terminu, aby zapytać o rezerwację na czacie.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sekcja opinii — StatefulWidget żeby sprawdzić czy user już dodał opinię
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewsSection extends StatefulWidget {
  final List<Review> reviews;
  final double avgScore;
  final String companyId;

  const _ReviewsSection({
    required this.reviews,
    required this.avgScore,
    required this.companyId,
  });

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  bool _alreadyReviewed = false;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (myUid.isEmpty || Globals.instance.anonim) {
      setState(() => _checked = true);
      return;
    }
    final firebase = context.read<FirebaseService>();
    final reviews = await firebase.getReviewsMetadataByReviewedUser(widget.companyId);
    final already = reviews.any((r) => r.userId == myUid);
    if (mounted) setState(() { _alreadyReviewed = already; _checked = true; });
  }

  @override
  Widget build(BuildContext context) {
    final isAnon = Globals.instance.anonim;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nagłówek z oceną i przyciskiem Dodaj ──────────
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                widget.avgScore.toStringAsFixed(1),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '  (${widget.reviews.length} opinii)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const Spacer(),
              // Przycisk Dodaj opinię
              if (_checked && !isAnon && !_alreadyReviewed)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Dodaj opinię', style: TextStyle(fontSize: 13)),
                  onPressed: () {
                    // Ustawiamy tymczasowe promo z userId firmy
                    // żeby bloc recenzji wiedział komu wystawić opinię
                    Globals.instance.selectedPromo = Promo(
                      id: 'profile_review',
                      userId: widget.companyId,
                      category: '',
                      sector: '',
                      location: const LatLng(0, 0),
                      fileUrl: '',
                      thumbUrl: '',
                      fileName: '',
                      timestamp: null,
                      description: '',
                    );
                    context.read<MainScreenBloc>().add(GoToDodajReviewEvent());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Colors.white24
                              : Colors.grey.shade300),
                    ),
                  ),
                )
              else if (_checked && !isAnon && _alreadyReviewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Oceniłeś', style: TextStyle(fontSize: 12, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Lista opinii ──────────────────────────────────
          if (widget.reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Ta firma nie ma jeszcze opinii.\nBądź pierwszy!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            ...widget.reviews.map((rev) => ReviewCard(review: rev)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Karta pojedynczej recenzji — płaska, małe zdjęcie + komentarze
// ─────────────────────────────────────────────────────────────────────────────
class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232228) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Zdjęcie po lewej + ReviewWithComments po prawej ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (review.thumbUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: review.thumbUrl,
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: ReviewWithComments(review: review)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}