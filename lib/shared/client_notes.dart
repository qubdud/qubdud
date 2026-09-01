import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain_layer/firebase_service.dart';
import '../feature_layer/main_screen/bloc/main_bloc.dart';
import 'functions/effective_role.dart';

/// Prywatne notatki firmy o klientach — wspólne dla całej apki
/// (lista zgłoszeń, rozmowy, kontakty, profil użytkownika).
class ClientNotes {
  static final Map<String, String> _notes = {};
  static String _companyId = '';

  static String get(String userId) => _notes[userId] ?? '';

  static Map<String, String> get all => Map.unmodifiable(_notes);

  static Future<void> load(FirebaseService firebase, String companyId) async {
    _companyId = companyId;
    try {
      final loaded = await firebase.getClientNotes(companyId);
      _notes
        ..clear()
        ..addAll(loaded);
    } catch (_) {}
  }

  static Future<void> save(
      FirebaseService firebase, String userId, String note) async {
    if (_companyId.isEmpty) return;
    await firebase.setClientNote(
        companyId: _companyId, userId: userId, note: note);
    if (note.trim().isEmpty) {
      _notes.remove(userId);
    } else {
      _notes[userId] = note.trim();
    }
  }

  static void clear() {
    _notes.clear();
    _companyId = '';
  }
}

/// Dialog dodania/edycji notatki. Zwraca true, gdy coś zapisano.
Future<bool> showClientNoteDialog(
    BuildContext context, String userId, String personName) async {
  final current = ClientNotes.get(userId);
  final ctrl = TextEditingController(text: current);
  final saved = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(personName.isEmpty ? 'Notatka' : 'Notatka: $personName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            maxLength: 200,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'np. spoko klient / odwołuje / płaci gotówką',
              border: OutlineInputBorder(),
            ),
          ),
          const Text('Widoczna tylko dla Ciebie.',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
        if (current.isNotEmpty)
          TextButton(
              onPressed: () => Navigator.pop(ctx, ''),
              child: const Text('Usuń', style: TextStyle(color: Colors.red))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Zapisz')),
      ],
    ),
  );
  if (saved == null || !context.mounted) return false;
  await ClientNotes.save(context.read<FirebaseService>(), userId, saved);
  return true;
}

/// Żółta karteczka z notatką — pokazuje się tylko firmie i tylko gdy jest treść.
class ClientNoteBadge extends StatelessWidget {
  final String userId;
  final String personName;
  final VoidCallback? onChanged;
  final int maxLines;

  const ClientNoteBadge({
    super.key,
    required this.userId,
    this.personName = '',
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCompanyMode(context.read<MainScreenBloc>().state.user)) {
      return const SizedBox.shrink();
    }
    final note = ClientNotes.get(userId);
    if (note.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        final changed = await showClientNoteDialog(context, userId, personName);
        if (changed) onChanged?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE8D67A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sticky_note_2, size: 12, color: Color(0xFF8A6D1B)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(note,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6B540F)),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
