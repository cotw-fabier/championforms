import 'dart:math' as math;

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
/// horizontally each time [wiggleTick] changes while it is marked. The
/// shake is skipped when the platform asks for reduced motion.
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
    _wiggle.dispose();
    super.dispose();
  }

  void _onIssues() {
    if (mounted) setState(() {});
  }

  void _onWiggle() {
    if (!mounted || !_flagged) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _wiggle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final flagged = _flagged;
    return AnimatedBuilder(
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
      ..drawRect(
        Rect.fromLTWH(-6, 0, 3, size.height),
        Paint()..color = color,
      );
  }

  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_IssuePainter oldDelegate) => oldDelegate.color != color;
}
