import 'package:flutter/material.dart';
import 'anonim_gate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain_layer/firebase_service.dart';
import '../../feature_layer/main_screen/bloc/main_bloc.dart';
import '../functions/show_toast.dart';
import '../functions/show_toast_error.dart';
import '../globals.dart';

/// Słuchawka na filmie: „Poproś firmę o kontakt”.
/// Szara = można poprosić, żółta = prośba czeka, zielona = firma się odezwała.
class ContactRequestButton extends StatefulWidget {
  final String companyId;
  final String companyName;

  const ContactRequestButton({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<ContactRequestButton> createState() => _ContactRequestButtonState();
}

class _ContactRequestButtonState extends State<ContactRequestButton> {
  /// status prośby per konto i firma — jeden odczyt na sesję, nie przy
  /// każdym filmie
  static final Map<String, String> _cache = {};
  String? _status;

  String get _myUid => context.read<MainScreenBloc>().state.user?.id ?? '';
  String get _key => '${_myUid}_${widget.companyId}';
  bool get _own => _myUid == widget.companyId;

  @override
  void initState() {
    super.initState();
    if (Globals.instance.anonim || _myUid.isEmpty || _own) return;
    _status = _cache[_key];
    // bez odczytu słuchawka jest szara — prośbę i tak można wysłać
    if (_status == null) _refresh().ignore();
  }

  @override
  void didUpdateWidget(covariant ContactRequestButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId == widget.companyId) return;
    _status = _cache[_key];
    if (_status == null && !Globals.instance.anonim && _myUid.isNotEmpty && !_own) {
      _refresh().ignore();
    }
  }

  Future<String> _refresh() async {
    final key = _key;
    final r = await context
        .read<FirebaseService>()
        .getContactRequest(myUid: _myUid, companyId: widget.companyId);
    final s = r?['status'] as String? ?? '';
    _cache[key] = s;
    if (mounted && key == _key) setState(() => _status = s);
    return s;
  }

  Future<void> _tap() async {
    if (Globals.instance.anonim) {
      showLoginPrompt(context, 'poprosić o kontakt');
      return;
    }
    try {
      // firma mogła już oznaczyć prośbę jako załatwioną — sprawdzamy na świeżo
      if (_status == 'pending' && await _refresh() == 'pending') {
        showToast(text: 'Prośba już wysłana — firma do Ciebie zadzwoni');
        return;
      }
      if (!mounted) return;
      final me = context.read<MainScreenBloc>().state.user;
      final sent = await showContactRequestDialog(
        context,
        companyName: widget.companyName,
        phone: me?.phone ?? '',
      );
      if (sent == null || !mounted) return;
      await context.read<FirebaseService>().sendContactRequest(
            myUid: _myUid,
            companyId: widget.companyId,
            companyName: widget.companyName,
            phone: sent.phone,
            note: sent.note,
          );
      _cache[_key] = 'pending';
      if (mounted) setState(() => _status = 'pending');
      showToast(
          text: 'Wysłano. Firma dostała powiadomienie, masz ją w Kontaktach.');
    } catch (_) {
      showToastError(text: 'Nie udało się wysłać prośby — spróbuj ponownie');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_own) return const SizedBox.shrink();
    final (bg, fg) = switch (_status) {
      'pending' => (Colors.amber.shade600, Colors.black87),
      'done' => (Colors.green.shade600, Colors.white),
      _ => (Colors.black.withOpacity(0.45), Colors.white),
    };
    return Tooltip(
      message: switch (_status) {
        'pending' => 'Prośba o kontakt wysłana',
        'done' => 'Firma się skontaktowała',
        _ => 'Poproś o kontakt',
      },
      child: GestureDetector(
        onTap: _tap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(
            _status == 'pending' ? Icons.phone_in_talk : Icons.phone_outlined,
            color: fg,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class ContactRequestInput {
  final String phone;
  final String note;
  const ContactRequestInput(this.phone, this.note);
}

/// Popup „Poproś o kontakt”: numer (z profilu, do poprawki) + krótka notka.
Future<ContactRequestInput?> showContactRequestDialog(
  BuildContext context, {
  required String companyName,
  required String phone,
}) {
  final phoneCtrl = TextEditingController(text: phone);
  final noteCtrl = TextEditingController();
  return showDialog<ContactRequestInput>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Poproś o kontakt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(companyName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Firma dostanie Twój numer i powiadomienie, że czekasz na telefon.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Twój telefon',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLength: 100,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Krótka wiadomość (opcjonalnie)',
                hintText: 'np. proszę o telefon po 16',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Anuluj')),
          FilledButton.icon(
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Wyślij'),
            onPressed: phoneCtrl.text.trim().length >= 7
                ? () => Navigator.pop(
                    ctx,
                    ContactRequestInput(
                        phoneCtrl.text.trim(), noteCtrl.text.trim()))
                : null,
          ),
        ],
      ),
    ),
  );
}
