import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain_layer/firebase_service.dart';
import 'functions/show_toast.dart';
import 'functions/show_toast_error.dart';
import 'globals.dart';
import 'widgets/anonim_gate.dart';

/// Zablokowani użytkownicy zalogowanego konta — ich rozmowy, filmy i opinie są ukrywane.
class BlockedUsers {
  static final ValueNotifier<Set<String>> ids = ValueNotifier(<String>{});

  static bool contains(String? uid) => uid != null && ids.value.contains(uid);

  static Future<void> load(FirebaseService firebase, String uid) async {
    try {
      ids.value = await firebase.getBlockedUsers(uid);
    } catch (_) {}
  }

  static void clear() => ids.value = <String>{};

  static Future<void> block(FirebaseService firebase, String otherUid) async {
    final me = FirebaseAuth.instance.currentUser!.uid;
    await firebase.blockUser(me, otherUid);
    ids.value = {...ids.value, otherUid};
  }

  static Future<void> unblock(FirebaseService firebase, String otherUid) async {
    final me = FirebaseAuth.instance.currentUser!.uid;
    await firebase.unblockUser(me, otherUid);
    ids.value = {...ids.value}..remove(otherUid);
  }
}

const _reasons = [
  'Spam lub oszustwo',
  'Treści obraźliwe lub nienawistne',
  'Treści erotyczne lub przemoc',
  'Podszywanie się / fałszywa firma',
  'Naruszenie praw autorskich',
  'Inne',
];

/// Zgłoszenie treści lub użytkownika do moderacji.
Future<void> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
  required String targetUserId,
}) async {
  if (Globals.instance.anonim) {
    showLoginPrompt(context, 'zgłosić treść');
    return;
  }
  final firebase = context.read<FirebaseService>();
  String? reason;
  final details = TextEditingController();
  final sent = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Zgłoś'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Co jest nie tak?'),
              for (final r in _reasons)
                RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r),
                  value: r,
                  groupValue: reason,
                  onChanged: (v) => setState(() => reason = v),
                ),
              TextField(
                controller: details,
                maxLength: 1000,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(hintText: 'Szczegóły (opcjonalnie)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
          TextButton(
            onPressed: reason == null ? null : () => Navigator.pop(ctx, true),
            child: const Text('Wyślij zgłoszenie'),
          ),
        ],
      ),
    ),
  );
  if (sent != true || reason == null) return;
  try {
    await firebase.reportContent(
      targetType: targetType,
      targetId: targetId,
      targetUserId: targetUserId,
      reason: reason!,
      details: details.text.trim(),
    );
    showToast(text: 'Dziękujemy, zgłoszenie trafi do moderacji');
  } catch (_) {
    showToastError(text: 'Nie udało się wysłać zgłoszenia');
  }
}

/// Blokuje albo odblokowuje użytkownika (z potwierdzeniem przy blokowaniu).
Future<void> toggleBlockUser(BuildContext context,
    {required String otherUid, required String name}) async {
  if (Globals.instance.anonim) {
    showLoginPrompt(context, 'zablokować użytkownika');
    return;
  }
  final firebase = context.read<FirebaseService>();
  if (BlockedUsers.contains(otherUid)) {
    try {
      await BlockedUsers.unblock(firebase, otherUid);
      showToast(text: 'Odblokowano: $name');
    } catch (_) {
      showToastError(text: 'Nie udało się odblokować');
    }
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Zablokować: $name?'),
      content: const Text(
          'Nie zobaczysz jego rozmów, prezentacji ani opinii, a on nie będzie mógł do Ciebie pisać. '
          'Możesz to cofnąć w tym samym miejscu.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Anuluj')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Zablokuj')),
      ],
    ),
  );
  if (ok != true) return;
  try {
    await BlockedUsers.block(firebase, otherUid);
    showToast(text: 'Zablokowano: $name');
  } catch (_) {
    showToastError(text: 'Nie udało się zablokować');
  }
}
