import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../../shared/widgets/anonim_gate.dart';
import 'package:qb/domain_layer/domain_models/app_user.dart';
import 'package:qb/shared/globals.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qb/shared/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../shared/widgets/before_after.dart';
import '../../../../../shared/functions/show_toast.dart';
import '../../../../../shared/functions/show_toast_error.dart';
import '../../../../../shared/widgets/mini_slots_bar.dart' show bookingName;
import '../../../../../shared/widgets/load_error.dart';
import '../../profil_my/view/tab_kalendarz.dart' show dayLabel;
import '../../../../../domain_layer/domain_models/company_info.dart';
import '../../../../../domain_layer/domain_models/promoVideo.dart';
import '../../../../../domain_layer/firebase_service.dart';
import '../../../../../shared/moderation.dart';
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

class _ProfilView extends StatefulWidget {
  const _ProfilView();

  @override
  State<_ProfilView> createState() => _ProfilViewState();
}

class _ProfilViewState extends State<_ProfilView> {
  final _slotsKey = GlobalKey();
  final _scroll = ScrollController();
  bool _showCta = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateCta);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCta());
  }

  @override
  void dispose() {
    _scroll.removeListener(_updateCta);
    _scroll.dispose();
    super.dispose();
  }

  /// Przycisk ma sens tylko wtedy, gdy sloty zniknęły z ekranu.
  void _updateCta() {
    final ctx = _slotsKey.currentContext;
    if (!mounted || ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    // firma bez terminów (np. hydraulik) → brak sekcji i brak przycisku
    if (box.size.height < 40) {
      if (_showCta) setState(() => _showCta = false);
      return;
    }
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final screenH = MediaQuery.of(context).size.height;
    final slotsVisible = bottom > 140 && top < screenH - 180;
    if (_showCta == slotsVisible) setState(() => _showCta = !slotsVisible);
  }

  void _scrollToSlots() {
    final ctx = _slotsKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400),
        alignment: 0.05,
        curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF16151A) : Colors.white,
      body: BlocBuilder<ProfilPubliczyPageBloc, ProfilPubliczyPageState>(
        builder: (context, state) {
          if (state is ProfilPubliczyPageLoadingState && state.targetUser == null) {
            return const Loading();
          }
          if (state is ProfilPubliczyPageErrorState) {
            return LoadError(
              message: state.errorMessage,
              onRetry: () => context
                  .read<ProfilPubliczyPageBloc>()
                  .add(GetDataProfilPubliczyPageEvent()),
            );
          }

          final canBook = state.targetUser != null &&
              state.targetUser!.id != myUid &&
              !Globals.instance.anonim;

          return Stack(
            children: [
              SingleChildScrollView(
            controller: _scroll,
            padding: EdgeInsets.only(bottom: canBook ? 88 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state.targetUser, state.companyInfo),

                if (state.targetUser != null)
                  KeyedSubtree(
                    key: _slotsKey,
                    child: _SlotsSection(
                        companyId: state.targetUser!.id,
                        companyName: state.targetUser!.companyName ?? "Firma",
                        info: state.targetUser!.slotsInfo),
                  ),

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
                  companyName: state.targetUser?.companyName ?? 'Firma',
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
              // przyklejone CTA — sloty są w środku strony, przycisk zawsze widoczny
              if (canBook && _showCta)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _scrollToSlots,
                      icon: const Icon(Icons.event_available, size: 22),
                      label: const Text('Umów',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cDarkBlue,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user, ProfileInfo? info) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final own = user != null &&
        user.id == (FirebaseAuth.instance.currentUser?.uid ?? '');
    final bio = user?.bio?.trim() ?? '';
    // EXPIRES: po uruchomieniu demo/_seed/migrate_profile_bio.js --apply (zostaje samo bio)
    final description = bio.isNotEmpty ? bio : (info?.description.trim() ?? '');
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
                        style: TextStyle(
                            fontSize:
                                (user?.companyName?.length ?? 0) > 40 ? 16 : 20,
                            fontWeight: FontWeight.bold)),
                    if (user?.companyCity != null)
                      Text(user!.companyCity!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    if (user?.companyCategory != null)
                      Text(user!.companyCategory!,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    if (user != null && user.firma == true && !Globals.instance.anonim)
                      _CompanyContact(user: user),
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
              if (!own && user != null)
                ValueListenableBuilder<Set<String>>(
                  valueListenable: BlockedUsers.ids,
                  builder: (context, blocked, _) => PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 22),
                    onSelected: (v) {
                      if (v == 'report') {
                        showReportDialog(context,
                            targetType: 'profile', targetId: user.id, targetUserId: user.id);
                      } else {
                        toggleBlockUser(context,
                            otherUid: user.id, name: user.companyName ?? 'Firma');
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'report', child: Text('Zgłoś profil')),
                      PopupMenuItem(
                          value: 'block',
                          child: Text(blocked.contains(user.id) ? 'Odblokuj' : 'Zablokuj')),
                    ],
                  ),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(description,
                style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
          if (!own) ...[
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
                      backgroundColor: cDarkBlue,
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
                    icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('Zapisz'),
                    onPressed: () async {
                      final firebase = context.read<FirebaseService>();
                      final myUid =
                          context.read<MainScreenBloc>().state.user?.id ?? '';
                      try {
                        await firebase.addContact(
                            myUserId: myUid, contactUserId: user?.id ?? '');
                      } catch (_) {
                        showToastError(text: 'Nie udało się zapisać kontaktu');
                        return;
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Zapisano w Kontakty → Zapisani')),
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
  final Map<String, String> _authorInitials = {};

  bool get _isOwner =>
      (FirebaseAuth.instance.currentUser?.uid ?? '') == widget.companyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final firebase = context.read<FirebaseService>();
      final p = await firebase.getRealizations(widget.companyId,
          includeUnapproved: _isOwner);
      // inicjały klientów przy zdjęciach, które sami dodali
      for (final r in p.where((r) => r['addedByRole'] == 'user')) {
        final uid = r['userId'] as String? ?? '';
        if (uid.isEmpty || _authorInitials.containsKey(uid)) continue;
        final u = await firebase.fetchUser(uid);
        final name = '${u?.firstName ?? ''}'.trim();
        _authorInitials[uid] = name.isNotEmpty ? name[0] : '?';
      }
      if (mounted) setState(() => _photos = p);
    } catch (_) {}
  }

  Future<void> _remove(Map<String, dynamic> photo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć realizację z profilu?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Anuluj')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Usuń', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final firebase = context.read<FirebaseService>();
      final requestId = (photo['requestId'] as String?) ?? '';
      // czekające zdjęcia firmy: wycofanie zdejmuje też realizationStatus ze zgłoszenia
      if (photo['addedByRole'] != 'user' && photo['status'] == 'pending' && requestId.isNotEmpty) {
        await firebase.withdrawRealization(photo['id'] as String, requestId);
      } else {
        await firebase.deleteRealization(photo['id'] as String);
      }
      await _load();
    } catch (_) {}
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
            itemBuilder: (context, i) {
              final photo = _photos[i];
              final status = (photo['status'] as String?) ?? 'approved';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    RealizationThumb(
                        photo: photo,
                        size: 130,
                        authorInitial:
                            _authorInitials[photo['userId'] as String? ?? '']),
                    // zdjęcia od klienta: firma decyduje o publikacji
                    if (_isOwner && photo['addedByRole'] == 'user')
                      Positioned(
                        left: 4,
                        bottom: 4,
                        child: GestureDetector(
                          onTap: () async {
                            final publish = photo['publishedByCompany'] != true;
                            await context
                                .read<FirebaseService>()
                                .setRealizationPublished(
                                    photo['id'] as String, publish);
                            showToast(
                                text: publish
                                    ? 'Opublikowano w portfolio'
                                    : 'Ukryto w portfolio');
                            _load();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: photo['publishedByCompany'] == true
                                  ? Colors.green.shade600
                                  : Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              photo['publishedByCompany'] == true
                                  ? 'w portfolio'
                                  : 'opublikuj',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    if (_isOwner && photo['addedByRole'] != 'user' && status != 'approved')
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: status == 'rejected' ? Colors.red.shade600 : Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status == 'rejected' ? 'odrzucone' : 'czeka na klienta',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (_isOwner)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: GestureDetector(
                          onTap: () => _remove(photo),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          child: Text(
            _isOwner
                ? 'Klienci widzą tylko realizacje, które potwierdzili. Zdjęcia dodane przez klientów pokazujesz przyciskiem „opublikuj".'
                : 'Zdjęcia z zadań zrealizowanych i potwierdzonych przez klientów.',
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
  final String? info;
  const _SlotsSection(
      {required this.companyId, required this.companyName, this.info});

  @override
  State<_SlotsSection> createState() => _SlotsSectionState();
}

class _SlotsSectionState extends State<_SlotsSection> {
  List<Map<String, dynamic>> _slots = [];
  bool _loaded = false;
  bool _error = false;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _anonim => Globals.instance.anonim || _myUid.isEmpty;
  bool get _own => widget.companyId == _myUid;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  /// Podgląd na żywo — rezerwacje innych osób widać od razu.
  /// Anonim nie czyta slotów (reguły) — widzi zachętę do logowania.
  void _listen() {
    _sub?.cancel();
    if (_anonim) return;
    _sub = context
        .read<FirebaseService>()
        .slotsStream(widget.companyId)
        .listen((slots) {
      if (mounted) {
        setState(() {
          _slots = slots;
          _loaded = true;
          _error = false;
        });
      }
    }, onError: (_) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _error = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _tapSlot(Map<String, dynamic> s) async {
    if (_own) {
      showToast(text: 'To Twoje terminy — zarządzasz nimi w Kalendarzu');
      return;
    }
    final firebase = context.read<FirebaseService>();
    final status = s['status'] as String;
    final mine = s['bookedBy'] == _myUid;

    // wolny → popup z terminem i opisem firmy, potem rezerwacja
    if (status == 'free') {
      final st = s['start'] as DateTime;
      final when = '${dayLabel(st)}, '
          '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
      final info = widget.info?.trim() ?? '';
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Zarezerwować termin?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.companyName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_available, size: 20, color: cDarkBlue),
                  const SizedBox(width: 8),
                  Text(when,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              if (info.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cDarkBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(info,
                      style: const TextStyle(
                          fontSize: 14,
                          color: cDarkBlue,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                ),
              ],
              const SizedBox(height: 12),
              Text('Firma zobaczy Twój telefon i e-mail, potwierdzi albo odrzuci rezerwację — dostaniesz powiadomienie.',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Anuluj')),
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Rezerwuj'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
      try {
        await firebase.bookSlot(
          companyId: widget.companyId,
          slotId: s['id'] as String,
          myUid: _myUid,
          myName: bookingName(context.read<MainScreenBloc>().state.user),
        );
        showToast(text: 'Zarezerwowano — czeka na akceptację firmy');
      } catch (e) {
        showToastError(text: slotErrorText(e));
      }
      return;
    }

    // moja rezerwacja → można odwołać
    if (mine) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Twoja rezerwacja'),
          content: Text(status == 'accepted'
              ? 'Termin zaakceptowany przez firmę. Odwołać rezerwację? Firma dostanie powiadomienie.'
              : 'Czeka na akceptację firmy. Odwołać rezerwację?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Zostaw')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Odwołaj',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      try {
        await firebase.cancelSlotBooking(
            companyId: widget.companyId,
            slotId: s['id'] as String,
            myUid: _myUid);
        showToast(text: 'Odwołano rezerwację');
      } catch (e) {
        showToastError(text: slotErrorText(e));
      }
      return;
    }

    showToast(text: 'Ten termin jest już zajęty');
  }

  @override
  Widget build(BuildContext context) {
    if (_anonim) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WSmallLabel(text: 'Umów (najbliższe 7 dni)'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.lock_outline, size: 18),
              label: const Text('Zaloguj się, aby zobaczyć terminy'),
              onPressed: () => showLoginPrompt(context, 'zobaczyć terminy'),
            ),
          ],
        ),
      );
    }
    if (_error) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: LoadError(
          message: 'Nie udało się wczytać terminów',
          compact: true,
          onRetry: () {
            setState(() => _error = false);
            _listen();
          },
        ),
      );
    }
    if (!_loaded || _slots.isEmpty) return const SizedBox.shrink();

    // grupowanie po dniach (kolejność chronologiczna — sloty są posortowane)
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final s in _slots) {
      final st = s['start'] as DateTime;
      byDay.putIfAbsent(dayLabel(st), () => []).add(s);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WSmallLabel(text: 'Umów (najbliższe 7 dni)'),
          if (widget.info?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Center(
              child: Text(widget.info!.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cDarkBlue,
                      height: 1.3)),
            ),
            const SizedBox(height: 6),
          ],
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
                        children: e.value.map((s) => _slotDot(s)).toList(),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          Text(
            _own
                ? 'Tak klienci widzą Twoje terminy. Zarządzasz nimi w Profilu → Kalendarz.'
                : 'Kliknij kropkę, aby zarezerwować. Żółta — czeka na akceptację, zielona — przyjęta.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _slotDot(Map<String, dynamic> s) {
    final st = s['start'] as DateTime;
    final status = s['status'] as String;
    final mine = s['bookedBy'] == _myUid;

    late final Color color;
    var takenByOther = false;
    if (status == 'free') {
      color = Colors.green.shade400;
    } else if (mine) {
      color = status == 'accepted' ? Colors.green : Colors.amber;
    } else {
      color = Colors.grey.shade400;
      takenByOther = true;
    }

    return GestureDetector(
      onTap: () => _tapSlot(s),
      child: Opacity(
        opacity: takenByOther ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: mine ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: mine ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                DateFormat('HH:mm').format(st),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: mine ? FontWeight.w700 : FontWeight.w400,
                  decoration:
                      takenByOther ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
        ),
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
  final String companyName;

  const _ReviewsSection({
    required this.reviews,
    required this.avgScore,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  bool _alreadyReviewed = false;
  bool _canReview = false;
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
    // opinie są już w stanie strony — bez drugiego zapytania
    final already = widget.reviews.any((r) => r.userId == myUid);
    var can = false;
    try {
      can = await firebase.canReviewCompany(myUid, widget.companyId);
    } catch (_) {
      // bez sprawdzenia nie pokazujemy „Dodaj opinię" — lista opinii działa dalej
    }
    if (mounted) {
      setState(() {
        _alreadyReviewed = already;
        _canReview = can;
        _checked = true;
      });
    }
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
              if (_checked && !isAnon && !_alreadyReviewed && _canReview)
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
                      companyName: widget.companyName,
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
                  _canReview
                      ? 'Ta firma nie ma jeszcze opinii.\nBądź pierwszy!'
                      : 'Ta firma nie ma jeszcze opinii.',
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
  final String? subjectName;
  const ReviewCard({super.key, required this.review, this.subjectName});

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
                Expanded(
                    child: ReviewWithComments(
                        review: review, subjectName: subjectName)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Telefon / adres / www / e-mail firmy — to, co firma zgodziła się pokazać.
class _CompanyContact extends StatelessWidget {
  final AppUser user;
  const _CompanyContact({required this.user});

  Future<void> _open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final addr = user.companyAddress ?? const {};
    final street = [addr['street'], addr['buildingNr']]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(' ');
    final flat = (addr['flatNr'] ?? '').toString();
    final line1 = flat.isNotEmpty ? '$street/$flat' : street;
    final line2 = [addr['postCode'], addr['city']]
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .join(' ');
    final address = [line1, line2].where((e) => e.isNotEmpty).join(', ');
    final phone = (user.phone ?? '').trim();
    final www = (user.www ?? '').trim();
    final email = (user.contactEmail ?? '').trim();

    final rows = <Widget>[];
    if (user.showPhone && phone.isNotEmpty) {
      rows.add(_row(Icons.phone_outlined, phone,
          () => _open(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), '')))));
    }
    if (user.showAddress && address.isNotEmpty) {
      rows.add(_row(Icons.place_outlined, address,
          () => _open(Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}'))));
    }
    if (www.isNotEmpty) {
      rows.add(_row(Icons.language, www.replaceFirst(RegExp(r'^https?://'), ''),
          () => _open(Uri.parse(www.startsWith('http') ? www : 'https://$www'))));
    }
    if (email.isNotEmpty) {
      rows.add(_row(Icons.mail_outline, email,
          () => _open(Uri(scheme: 'mailto', path: email))));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
    );
  }

  Widget _row(IconData icon, String text, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(icon, size: 14, color: cDarkBlue),
              const SizedBox(width: 6),
              Flexible(
                child: Text(text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: cDarkBlue,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}
