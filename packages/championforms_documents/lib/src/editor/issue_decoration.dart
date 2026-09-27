import 'dart:async';
import 'dart:math' as math;

// Internal to championforms (not exported): the same visibility detector
// that gates the core field wiggle. Both packages are released from one
// repository, so the path moves only together with this import.
import 'package:championforms/widgets_internal/visibility/champion_visibility_detector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart' as se;

/// Wraps another component builder so that blocks with a validation issue
/// are marked (an error-coloured bar and tint) and wiggle when asked to.
///
/// The wrapped component keeps its own key and state: the decoration is
/// always present and only its paint changes, so marking a block never
/// rebuilds or re-parents the block itself.
class IssueDecoratingComponentBuilder implements se.ComponentBuilder {
  const IssueDecoratingComponentBuilder(
    this.inner, {
    required this.issueNodeIds,
    required this.issueColor,
    this.wiggleTick,
  });

  final se.ComponentBuilder inner;
  final ValueListenable<Set<String>> issueNodeIds;
  final ValueListenable<int>? wiggleTick;
  final Color issueColor;

  @override
  se.SingleColumnLayoutComponentViewModel? createViewModel(
    se.Document document,
    se.DocumentNode node,
  ) => inner.createViewModel(document, node);

  @override
  Widget? createComponent(
    se.SingleColumnDocumentComponentContext componentContext,
    se.SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    final component = inner.createComponent(
      componentContext,
      componentViewModel,
    );
    if (component == null) return null;
    return IssueDecoration(
      nodeId: componentViewModel.nodeId,
      issueNodeIds: issueNodeIds,
      wiggleTick: wiggleTick,
      color: issueColor,
      child: component,
    );
  }
}

/// Marks [child] when [nodeId] is in [issueNodeIds], and shakes it
/// horizontally each time [wiggleTick] changes while it is marked.
///
/// Follows the core field wiggle (`FieldWiggleAnimator`):
///
/// - **Visibility gating.** A block that is less than half on screen when
///   the tick arrives holds the shake until it scrolls into view, then plays
///   it after a short settle delay. Visibility is measured only while a shake
///   is pending, so an ordinary document pays nothing for it.
/// - **Reduce motion.** Skipped when the platform asks for reduced motion.
///
/// Whether to shake at all (`animateValidationErrors` on the field, then
/// `FormFieldDefaults.instance.animateValidationErrors`) is the caller's
/// decision: `DocumentFieldWidget` only advances [wiggleTick] when it is on.
class IssueDecoration extends StatefulWidget {
  const IssueDecoration({
    super.key,
    required this.nodeId,
    required this.issueNodeIds,
    required this.color,
    required this.child,
    this.wiggleTick,
  });

  final String nodeId;
  final ValueListenable<Set<String>> issueNodeIds;
  final ValueListenable<int>? wiggleTick;
  final Color color;
  final Widget child;

  @override
  State<IssueDecoration> createState() => _IssueDecorationState();
}

class _IssueDecorationState extends State<IssueDecoration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  /// Wait after a pending block becomes visible, so the shake lands after
  /// the scroll settles. Matches the core field wiggle.
  static const _settleDelay = Duration(milliseconds: 300);

  /// A shake was requested and has not played yet.
  bool _pending = false;

  /// The visible fraction measured since the shake was requested, or null
  /// before the first measurement.
  double? _visibleFraction;

  Timer? _settleTimer;

  /// Scroll positions of every enclosing scrollable, watched while a shake
  /// is pending. The detector measures on paint, and a block inside a
  /// repaint boundary (the editor has them) is not repainted when an
  /// outer scroll view moves, so a scroll asks for a repaint instead.
  final List<ScrollPosition> _watchedScrolls = [];

  bool get _flagged => widget.issueNodeIds.value.contains(widget.nodeId);

  @override
  void initState() {
    super.initState();
    widget.issueNodeIds.addListener(_onIssues);
    widget.wiggleTick?.addListener(_onWiggle);
  }

  @override
  void didUpdateWidget(covariant IssueDecoration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issueNodeIds != widget.issueNodeIds) {
      oldWidget.issueNodeIds.removeListener(_onIssues);
      widget.issueNodeIds.addListener(_onIssues);
    }
    if (oldWidget.wiggleTick != widget.wiggleTick) {
      oldWidget.wiggleTick?.removeListener(_onWiggle);
      widget.wiggleTick?.addListener(_onWiggle);
    }
  }

  @override
  void dispose() {
    widget.issueNodeIds.removeListener(_onIssues);
    widget.wiggleTick?.removeListener(_onWiggle);
    _settleTimer?.cancel();
    _unwatchScrolls();
    _wiggle.dispose();
    super.dispose();
  }

  void _onIssues() {
    if (!mounted) return;
    setState(() {
      // A block that is no longer flagged has nothing left to point at.
      if (!_flagged) _cancelPending();
    });
  }

  void _onWiggle() {
    if (!mounted || !_flagged) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    // Arm the shake and start measuring; [_onVisibility] plays it.
    setState(() {
      _cancelPending();
      _pending = true;
    });
    _watchScrolls();
  }

  void _cancelPending() {
    _pending = false;
    _visibleFraction = null;
    _settleTimer?.cancel();
    _settleTimer = null;
    _unwatchScrolls();
  }

  void _watchScrolls() {
    _unwatchScrolls();
    var scrollable = context.findAncestorStateOfType<ScrollableState>();
    while (scrollable != null) {
      scrollable.position.addListener(_onScroll);
      _watchedScrolls.add(scrollable.position);
      scrollable = scrollable.context
          .findAncestorStateOfType<ScrollableState>();
    }
  }

  void _unwatchScrolls() {
    for (final position in _watchedScrolls) {
      position.removeListener(_onScroll);
    }
    _watchedScrolls.clear();
  }

  void _onScroll() {
    if (mounted) context.findRenderObject()?.markNeedsPaint();
  }

  void _onVisibility(double fraction) {
    if (!mounted || !_pending) return;
    final firstMeasurement = _visibleFraction == null;
    _visibleFraction = fraction;
    if (fraction >= 0.5) {
      if (firstMeasurement) {
        // On screen when the tick arrived: play now.
        _play();
      } else {
        // Scrolled into view: let the scroll settle first.
        _settleTimer ??= Timer(_settleDelay, () {
          _settleTimer = null;
          if (mounted && _pending && (_visibleFraction ?? 0) >= 0.5) _play();
        });
      }
    } else {
      _settleTimer?.cancel();
      _settleTimer = null;
    }
  }

  void _play() {
    setState(_cancelPending);
    _wiggle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final flagged = _flagged;
    // The detector is always in the tree (disabled unless a shake is
    // pending) so toggling it never re-parents the block.
    return ChampionVisibilityDetector(
      enabled: _pending,
      onVisibilityChanged: _onVisibility,
      child: AnimatedBuilder(
        animation: _wiggle,
        builder: (context, child) {
          final t = _wiggle.value;
          // A damped sine: three swings that settle.
          final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 6) * 6 * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        // A foreground painter, not a DecoratedBox: a decorated box registers
        // itself as a hit-test target, and super_editor then treats taps on
        // the block as taps on something other than document content.
        child: CustomPaint(
          key: flagged ? ValueKey('document-issue-${widget.nodeId}') : null,
          foregroundPainter: flagged ? _IssuePainter(widget.color) : null,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Paints the issue marker: a bar on the left and a light tint.
class _IssuePainter extends CustomPainter {
  _IssuePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas
      ..drawRect(rect, Paint()..color = color.withValues(alpha: 0.06))
      ..drawRect(Rect.fromLTWH(-6, 0, 3, size.height), Paint()..color = color);
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_IssuePainter oldDelegate) => oldDelegate.color != color;
}
