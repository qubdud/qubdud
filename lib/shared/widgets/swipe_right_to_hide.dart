import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Przesunięcie karty w prawo = ukryj. Ruch w lewo jest oddawany dalej
/// (np. zakładkom), czego zwykły Dismissible nie potrafi — łapie oba kierunki.
class SwipeRightToHide extends StatefulWidget {
  final Widget child;
  final Widget background;
  final bool enabled;
  final VoidCallback onHide;

  const SwipeRightToHide({
    super.key,
    required this.child,
    required this.background,
    required this.onHide,
    this.enabled = true,
  });

  @override
  State<SwipeRightToHide> createState() => _SwipeRightToHideState();
}

class _SwipeRightToHideState extends State<SwipeRightToHide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));
  double _dx = 0;
  bool _hiding = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_hiding) return;
    setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, double.infinity));
  }

  Future<void> _onEnd(DragEndDetails d, double width) async {
    if (_hiding) return;
    final fast = (d.primaryVelocity ?? 0) > 700;
    if (_dx > width * 0.4 || (fast && _dx > 24)) {
      _hiding = true;
      final from = _dx;
      _ctrl.reset();
      final anim = Tween<double>(begin: from, end: width)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      anim.addListener(() => setState(() => _dx = anim.value));
      await _ctrl.forward();
      if (mounted) widget.onHide();
    } else {
      final from = _dx;
      _ctrl.reset();
      final anim = Tween<double>(begin: from, end: 0.0)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      anim.addListener(() => setState(() => _dx = anim.value));
      await _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(
      builder: (context, c) => RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          _RightOnlyDragRecognizer:
              GestureRecognizerFactoryWithHandlers<_RightOnlyDragRecognizer>(
            () => _RightOnlyDragRecognizer(),
            (r) => r
              ..onUpdate = _onUpdate
              ..onEnd = (d) => _onEnd(d, c.maxWidth),
          ),
        },
        child: Stack(
          children: [
            if (_dx > 0) Positioned.fill(child: widget.background),
            Transform.translate(offset: Offset(_dx, 0), child: widget.child),
          ],
        ),
      ),
    );
  }
}

/// Poziomy drag, który przy pierwszym wyraźnym ruchu w lewo sam się
/// wycofuje z areny — wtedy gest dostaje TabBarView.
class _RightOnlyDragRecognizer extends HorizontalDragGestureRecognizer {
  double _acc = 0;
  bool _decided = false;
  bool _rejected = false;

  @override
  void handleEvent(PointerEvent event) {
    if (_rejected) return;
    if (event is PointerMoveEvent && !_decided) {
      _acc += event.delta.dx;
      if (_acc < -6) {
        _rejected = true;
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        return;
      }
      if (_acc > 6) _decided = true;
    }
    super.handleEvent(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _acc = 0;
    _decided = false;
    _rejected = false;
    super.addAllowedPointer(event);
  }
}
