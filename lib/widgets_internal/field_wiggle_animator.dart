// Requires FormController.validationFailureTick (int getter) — added by the controller/hub change.

import 'dart:async';
import 'dart:math';

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/widgets_internal/visibility/champion_visibility_detector.dart';
import 'package:flutter/widgets.dart';

/// Plays a damped horizontal "wiggle" on a field when its validation fails —
/// but only while the field is actually on screen.
///
/// The shake is a quick, non-bouncy shudder: a decaying sine over ~500ms that
/// translates the child left/right and settles cleanly to zero. It is
/// deliberately assertive — big enough in its opening swings to catch the eye
/// and say "look here", then quickly damped so it reads as an attention cue
/// rather than a UI glitch.
///
/// Two behaviors keep it from firing at the wrong moment:
///
/// - **Visibility gating.** A field that fails validation while scrolled off
///   screen (e.g. the top field of a long form the user submits from the
///   bottom) should not "wiggle in the dark". The play is held pending until
///   the field scrolls into view (≥ 50% visible), then plays after a short
///   settle delay so the animation is seen, not missed.
/// - **Tick de-duplication.** Each play is armed by a NEW
///   `FormController.validationFailureTick`. The animation fires at most once
///   per tick and re-arms only when the controller reports a fresh failure.
///
/// This widget is private to the package; consumers opt in through the public
/// `animateValidationErrors` flag, and the caller decides whether to wrap at
/// all. It still independently honors the platform "reduce motion" setting.
class FieldWiggleAnimator extends StatefulWidget {
  const FieldWiggleAnimator({
    super.key,
    required this.controller,
    required this.fieldId,
    required this.child,
  });

  /// The form controller whose validation failures drive the shake.
  final FormController controller;

  /// The id of the field this animator wraps. Used to ask the controller
  /// whether THIS field is in error when a failure tick arrives.
  final String fieldId;

  /// The field widget to shake.
  final Widget child;

  @override
  State<FieldWiggleAnimator> createState() => _FieldWiggleAnimatorState();
}

class _FieldWiggleAnimatorState extends State<FieldWiggleAnimator>
    with SingleTickerProviderStateMixin {
  /// Drives the shake from 0 (start) to 1 (settled).
  late final AnimationController _controller;

  /// Peak horizontal displacement, in logical pixels. Sized to be clearly
  /// noticeable at a glance rather than a faint shimmer.
  static const double _amplitude = 14.0;

  /// Number of damped left/right oscillations across a single play.
  static const double _cycles = 3.5;

  /// How long to wait after a field becomes visible before playing a pending
  /// shake, so the animation lands after the scroll settles rather than
  /// racing it.
  static const Duration _settleDelay = Duration(milliseconds: 300);

  /// Last validation failure tick we have observed. A change signals a fresh
  /// failure that may need to play.
  late int _lastTick;

  /// True when a failure has been registered for this field but has not yet
  /// been played (typically because the field is not sufficiently visible).
  bool _pending = false;

  /// Most recent visible fraction reported by the visibility detector.
  double _visibleFraction = 0.0;

  /// Timer for the post-visibility settle delay; cancelled if the field
  /// scrolls back out of view before it fires.
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lastTick = widget.controller.validationFailureTick;
    widget.controller.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant FieldWiggleAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
      // Re-baseline against the new controller so we don't play spuriously.
      _lastTick = widget.controller.validationFailureTick;
      _pending = false;
    }
  }

  /// Responds to controller notifications, arming a shake when a NEW validation
  /// failure tick lands on a field that is currently in error.
  void _handleControllerChange() {
    final int tick = widget.controller.validationFailureTick;
    if (tick == _lastTick) return;
    _lastTick = tick;

    if (widget.controller.hasErrors(widget.fieldId)) {
      _pending = true;
      _tryPlay();
    }
    // A tick with no error on THIS field is intentionally ignored.
  }

  /// Reports a visibility change from the [ChampionVisibilityDetector] and,
  /// when a shake is pending, schedules or cancels the settle-then-play timer
  /// as the field crosses the 50% visibility line.
  void _handleVisibilityChanged(double fraction) {
    _visibleFraction = fraction;
    if (!_pending) return;

    if (fraction >= 0.5) {
      // Became visible: wait a beat for the scroll to settle, then play.
      _settleTimer ??= Timer(_settleDelay, () {
        _settleTimer = null;
        _tryPlay();
      });
    } else {
      // Dropped back out of view before playing: stay pending, drop the timer.
      _settleTimer?.cancel();
      _settleTimer = null;
    }
  }

  /// Plays the shake if one is pending and conditions allow. When the field is
  /// already visible this fires immediately; otherwise it no-ops and waits for
  /// [_handleVisibilityChanged] to bring it into view.
  void _tryPlay() {
    if (!_pending) return;
    if (_controller.isAnimating) return;

    if (_visibleFraction >= 0.5) {
      _pending = false;
      _settleTimer?.cancel();
      _settleTimer = null;
      _controller.forward(from: 0.0);
    }
    // Not visible enough: leave _pending true; visibility change will retry.
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    widget.controller.removeListener(_handleControllerChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Honor the platform "reduce motion" accessibility setting: skip the
    // animator entirely and return the bare child.
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return widget.child;
    }

    return ChampionVisibilityDetector(
      threshold: 0.5,
      onVisibilityChanged: _handleVisibilityChanged,
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) {
          final double t = _controller.value;
          // Decaying sine: full swings early, damped to nothing by t == 1.
          final double dx = t == 0.0 || t == 1.0
              ? 0.0
              : sin(t * pi * _cycles * 2) * (1.0 - t) * _amplitude;
          return Transform.translate(
            offset: Offset(dx, 0.0),
            child: child,
          );
        },
      ),
    );
  }
}
