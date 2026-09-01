import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain_layer/domain_models/promoVideo.dart';
import '../../domain_layer/firebase_service.dart';
import '../functions/show_toast.dart';
import '../functions/show_toast_error.dart';

/// Sekcja dla FIRMY na widoku zgłoszenia: podejmij się / wycofaj / status.
class CompanyTakeSection extends StatefulWidget {
  final Request request;
  final String myCompanyId;
  final String myCompanyName;

  const CompanyTakeSection({
    super.key,
    required this.request,
    required this.myCompanyId,
    required this.myCompanyName,
  });

  @override
  State<CompanyTakeSection> createState() => _CompanyTakeSectionState();
}

class _CompanyTakeSectionState extends State<CompanyTakeSection> {
  bool _busy = false;

  Future<void> _take() async {
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().takeRequest(
            requestId: widget.request.id,
            companyId: widget.myCompanyId,
            companyName: widget.myCompanyName,
          );
      widget.request.takenBy = widget.myCompanyId;
      widget.request.takenByName = widget.myCompanyName;
      widget.request.confirmedByCompany = true;
      showToast(text: 'Podjęto — czekamy na potwierdzenie klienta');
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().cancelTakeRequest(widget.request.id);
      widget.request.takenBy = '';
      widget.request.takenByName = '';
      widget.request.confirmedByCompany = false;
      widget.request.confirmedByUser = false;
      widget.request.status = 'open';
      showToast(text: 'Wycofano');
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // nikt się nie podjął
    if (req.takenBy.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.handshake_outlined, size: 18),
          label: const Text('Podejmuję się zadania'),
          onPressed: _take,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    // podjęła się moja firma
    if (req.takenBy == widget.myCompanyId) {
      if (req.status == 'taken') {
        return _badge(
          color: Colors.green,
          icon: Icons.check_circle_outline,
          text: 'Zadanie potwierdzone przez klienta — realizujesz je Ty',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _badge(
            color: Colors.orange,
            icon: Icons.hourglass_top_outlined,
            text: 'Podjąłeś się — czekamy na potwierdzenie klienta',
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _cancel,
            child: const Text('Wycofaj się',
                style: TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      );
    }

    // podjęła się inna firma (do potwierdzenia klienta wciąż widoczne)
    return _badge(
      color: Colors.grey,
      icon: Icons.info_outline,
      text: 'Tego zadania podjęła się już firma ${req.takenByName}',
    );
  }

  Widget _badge(
      {required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(fontSize: 13, color: color))),
        ],
      ),
    );
  }
}

/// Pasek dla USERA pod jego zgłoszeniem: potwierdź firmę / status realizacji.
class UserConfirmBar extends StatefulWidget {
  final Request request;
  final VoidCallback? onChanged;

  const UserConfirmBar({super.key, required this.request, this.onChanged});

  @override
  State<UserConfirmBar> createState() => _UserConfirmBarState();
}

class _UserConfirmBarState extends State<UserConfirmBar> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await context.read<FirebaseService>().confirmRequestByUser(widget.request);
      widget.request.confirmedByUser = true;
      if (widget.request.confirmedByCompany) {
        widget.request.status = 'taken';
      }
      showToast(text: 'Potwierdzono — zadanie w realizacji');
      widget.onChanged?.call();
    } catch (e) {
      showToastError(text: 'Błąd: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    if (req.takenBy.isEmpty) return const SizedBox.shrink();

    if (req.status == 'taken') {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 15, color: Colors.green),
            const SizedBox(width: 6),
            Flexible(
              child: Text('W realizacji: ${req.takenByName}',
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
            ),
          ],
        ),
      );
    }

    if (_busy) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: SizedBox(
            height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Podjęła się: ${req.takenByName}',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
          ),
          GestureDetector(
            onTap: _confirm,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Potwierdź',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
