import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain_layer/domain_models/app_user.dart';
import '../domain_layer/domain_models/promoVideo.dart';
import '../domain_layer/firebase_service.dart';

/// Liczniki „co nowego" na zakładkach Startu. Nowe = powstałe po ostatnim
/// otwarciu danej zakładki (znacznik w SharedPreferences, per konto).
/// Klucze: firma → zgloszenia / kalendarz / recenzje,
///         użytkownik → zgloszenia / rezerwacje.
class NewCounts {
  static final Map<String, int> counts = {};
  static String _uid = '';

  static String _key(String tab) => 'seen_${_uid}_$tab';

  static Future<DateTime> _seen(SharedPreferences prefs, String tab) async {
    final ms = prefs.getInt(_key(tab));
    if (ms == null) {
      // pierwsze uruchomienie: nie pokazujemy całej historii jako „nowe"
      await prefs.setInt(_key(tab), DateTime.now().millisecondsSinceEpoch);
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> markSeen(String tab) async {
    if (_uid.isEmpty) return;
    counts[tab] = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(tab), DateTime.now().millisecondsSinceEpoch);
  }

  static void clear() {
    counts.clear();
    _uid = '';
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  /// Przelicza liczniki. [requests]/[myOffers]/[myRequests]/[reviews] to dane
  /// już pobrane przez StartPageBloc — nie dublujemy zapytań.
  static Future<void> refresh({
    required FirebaseService firebase,
    required AppUser user,
    required bool companyMode,
    required List<Request> requests,
    required Map<String, Map<String, dynamic>> myOffers,
    required List<Request> myRequests,
    required List<Review> reviews,
  }) async {
    _uid = user.id;
    if (_uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final fs = FirebaseFirestore.instance;

    try {
      if (companyMode) {
        // ── zgłoszenia: nowe w okolicy + decyzje klientów o moich ofertach ──
        final seenReq = await _seen(prefs, 'zgloszenia');
        var n = requests
            .where((r) => r.timestamp != null && r.timestamp!.isAfter(seenReq))
            .length;
        n += myOffers.values.where((o) {
          final decided = _ts(o['decidedAt']);
          return decided != null && decided.isAfter(seenReq);
        }).length;
        counts['zgloszenia'] = n;

        // ── kalendarz: rezerwacje czekające na decyzję (zawsze, bez seen) ──
        final slots = await firebase.getSlots(user.id);
        counts['kalendarz'] =
            slots.where((s) => s['status'] == 'pending').length;

        // ── recenzje: nowe otrzymane ──
        final seenRev = await _seen(prefs, 'recenzje');
        counts['recenzje'] = reviews
            .where((r) => r.timestamp != null && r.timestamp!.isAfter(seenRev))
            .length;
      } else {
        // ── zgłoszenia: nowe oferty + zdjęcia realizacji do potwierdzenia ──
        final seenReq = await _seen(prefs, 'zgloszenia');
        final active = myRequests.where((r) => r.status != 'closed').toList();
        final activeIds = active.map((r) => r.id).toSet();
        final offers =
            await Future.wait(active.map((r) => firebase.getOffers(r.id)));
        var n = offers.expand((o) => o).where((o) {
          final t = _ts(o['timestamp']);
          return t != null && t.isAfter(seenReq);
        }).length;
        // zdjęcia do potwierdzenia liczą się tylko przy otwartych zgłoszeniach
        final pendingReal = await fs
            .collection('realizations')
            .where('userId', isEqualTo: user.id)
            .where('status', isEqualTo: 'pending')
            .get();
        n += pendingReal.docs
            .where((d) =>
                d.data()['addedByRole'] != 'user' &&
                activeIds.contains(d.data()['requestId']))
            .length;
        counts['zgloszenia'] = n;

        // ── rezerwacje: decyzje firm od ostatniego zajrzenia ──
        final seenBook = await _seen(prefs, 'rezerwacje');
        final bookings = await firebase.getMyBookings(user.id);
        counts['rezerwacje'] = bookings.where((b) {
          final t = _ts(b['decidedAt']);
          return t != null && t.isAfter(seenBook);
        }).length;
      }
    } catch (_) {
      // liczniki są pomocnicze — błąd nie może wywrócić Startu
    }
  }
}
