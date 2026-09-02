import 'app_user.dart';
import 'promoVideo.dart';

/// Skąd wzięła się relacja klient↔firma: zgłoszenia i/lub rezerwacje.
class RelationLink {
  final AppUser user;
  final List<Request> requests;
  final List<SlotRef> slots;
  final DateTime? addedAt;
  final ContactRef? contact;

  const RelationLink({
    required this.user,
    this.requests = const [],
    this.slots = const [],
    this.addedAt,
    this.contact,
  });

  /// Relacja bez zgłoszeń i rezerwacji (np. tylko z notatki).
  bool get isManual =>
      requests.isEmpty && slots.isEmpty && contact == null;
}

/// Minimalny opis rezerwacji do pokazania na liście.
class SlotRef {
  final String id;
  final String companyId;
  final DateTime start;
  final String status; // pending | accepted | rejected

  const SlotRef({
    required this.id,
    required this.companyId,
    required this.start,
    required this.status,
  });
}

/// Prośba klienta o telefon od firmy.
class ContactRef {
  final String id;
  final String phone;
  final String note;
  final DateTime? createdAt;
  String status; // pending | done

  ContactRef({
    required this.id,
    required this.phone,
    required this.note,
    required this.status,
    this.createdAt,
  });
}
