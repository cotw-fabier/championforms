import 'package:flutter/widgets.dart';

/// Wraps a focusable field with a gentle "lift and settle" focus animation.
///
/// On focus gain, the child is translated upward ~1px and scaled up ~0.8% —
/// barely perceptible, but enough to feel alive. On focus loss it eases
/// back. Curves are exponential ease-out, never bouncy or elastic; the
/// reverse is slightly slower than the forward so the field feels like
/// it's settling rather than snapping.
///
/// All animation happens inside a [Transform] so layout never thrashes.
/// This widget is private to the package — consumers control it through
/// the public `animateInteractions` flag on field types.
class FieldInteractionAnimator extends StatefulWidget {
  const FieldInteractionAnimator({
    super.key,
    required this.focusNode,
    required this.child,
    this.scale = 1.008,
    this.lift = 1.0,
    this.duration = const Duration(milliseconds: 220),
    this.reverseDuration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
    this.reverseCurve = Curves.easeOutQuart,
  });

  final FocusNode focusNode;
  final Widget child;

  /// Target scale at full focus. Stay close to 1.0 — anything above ~1.02
  /// reads as a UI bug, not a friendly cue.
  final double scale;

  /// Pixels to translate upward at full focus. Negative-Y in screen space.
  final double lift;

  final Duration duration;
  final Duration reverseDuration;
  final Curve curve;
  final Curve reverseCurve;

  @override
  State<FieldInteractionAnimator> createState() =>
      _FieldInteractionAnimatorState();
}

class _FieldInteractionAnimatorState extends State<FieldInteractionAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      value: widget.focusNode.hasFocus ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
      reverseCurve: widget.reverseCurve,
    );
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant FieldInteractionAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      _syncToFocus();
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.reverseDuration != widget.reverseDuration) {
      _controller.reverseDuration = widget.reverseDuration;
    }
    if (oldWidget.curve != widget.curve ||
        oldWidget.reverseCurve != widget.reverseCurve) {
      _animation = CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
        reverseCurve: widget.reverseCurve,
      );
    }
  }

  void _handleFocusChange() => _syncToFocus();

  void _syncToFocus() {
    if (widget.focusNode.hasFocus) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final t = _animation.value;
        final s = 1.0 + (widget.scale - 1.0) * t;
        final dy = -widget.lift * t;
        return Transform.translate(
          offset: Offset(0.0, dy),
          child: Transform.scale(
            scale: s,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}
