import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Reports how much of a widget is currently visible inside the on-screen
/// viewport, as a fraction from `0.0` (fully off-screen / clipped away) to
/// `1.0` (entirely on-screen).
///
/// This is a small, self-contained re-implementation of the render-object
/// technique used by the (now unmaintained) `visibility_detector` package.
/// It carries NO dependency on ChampionForms and can be reused anywhere a
/// visibility signal is needed.
///
/// The detector works by intersecting the child's global bounds with the
/// window rect and with every ancestor paint clip (so a child buried inside a
/// clipped `ListView` or `SingleChildScrollView` is correctly reported as
/// partially or fully hidden). Computation is driven by paint — scrolling and
/// layout both repaint, which re-invokes the calculation — and is batched to a
/// single post-frame callback so many paints in one frame cost one measurement.
///
/// Example:
/// ```dart
/// ChampionVisibilityDetector(
///   threshold: 0.5,
///   onVisibilityChanged: (fraction) {
///     if (fraction >= 0.5) doSomething();
///   },
///   child: MyWidget(),
/// )
/// ```
class ChampionVisibilityDetector extends SingleChildRenderObjectWidget {
  const ChampionVisibilityDetector({
    super.key,
    required this.onVisibilityChanged,
    this.threshold = 0.5,
    required Widget child,
  }) : super(child: child);

  /// Called with the current visible fraction (`0.0`–`1.0`) whenever it
  /// changes meaningfully. Also called with `0.0` when the detector detaches,
  /// so a torn-down subtree never leaves a listener thinking it is visible.
  final void Function(double visibleFraction) onVisibilityChanged;

  /// The minimum change in visible fraction (in absolute terms) that counts as
  /// "meaningful" and triggers a callback. Kept small so consumers gating on a
  /// 0.5 crossover are notified promptly, without firing on sub-pixel jitter.
  final double threshold;

  @override
  RenderChampionVisibilityDetector createRenderObject(BuildContext context) {
    return RenderChampionVisibilityDetector(
      onVisibilityChanged: onVisibilityChanged,
      threshold: threshold,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderChampionVisibilityDetector renderObject,
  ) {
    renderObject
      ..onVisibilityChanged = onVisibilityChanged
      ..threshold = threshold;
  }
}

/// The render object backing [ChampionVisibilityDetector].
///
/// Extends [RenderProxyBox] so it is layout-transparent: it takes the size of
/// its child and simply forwards painting, hooking [paint] to schedule a
/// visibility measurement after the frame settles.
class RenderChampionVisibilityDetector extends RenderProxyBox {
  RenderChampionVisibilityDetector({
    required void Function(double visibleFraction) onVisibilityChanged,
    required double threshold,
  })  : _onVisibilityChanged = onVisibilityChanged,
        _threshold = threshold;

  void Function(double visibleFraction) _onVisibilityChanged;
  set onVisibilityChanged(void Function(double visibleFraction) value) {
    _onVisibilityChanged = value;
  }

  double _threshold;
  set threshold(double value) {
    _threshold = value;
  }

  /// Guards against scheduling more than one measurement per frame even though
  /// [paint] may fire many times as the tree repaints.
  bool _updateScheduled = false;

  /// The last fraction reported to [_onVisibilityChanged], used to suppress
  /// duplicate / negligible callbacks.
  double? _lastReportedFraction;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    _scheduleVisibilityUpdate();
  }

  /// Schedules a single post-frame visibility computation, coalescing repeated
  /// paints in the same frame into one measurement.
  void _scheduleVisibilityUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      _computeAndReport();
    });
  }

  /// Computes the current visible fraction and reports it if it changed
  /// meaningfully since the last report.
  void _computeAndReport() {
    final fraction = _computeVisibleFraction();
    final last = _lastReportedFraction;
    // Report on a genuine change, and always latch the 0/1 extremes so
    // fully-visible / fully-hidden transitions are never swallowed by the
    // epsilon.
    final changed = last == null ||
        (fraction - last).abs() >= _threshold ||
        (fraction == 0.0 && last != 0.0) ||
        (fraction == 1.0 && last != 1.0);
    if (!changed) return;
    _lastReportedFraction = fraction;
    _onVisibilityChanged(fraction);
  }

  /// Returns the fraction of this render object currently visible on screen,
  /// clamped to `0.0`–`1.0`. Returns `0.0` if detached, unsized, or fully
  /// clipped away.
  double _computeVisibleFraction() {
    if (!attached || !hasSize) return 0.0;

    final Size size = this.size;
    final double totalArea = size.width * size.height;
    if (totalArea <= 0.0) return 0.0;

    // The child's own bounds in global coordinates.
    final Offset topLeft = localToGlobal(Offset.zero);
    Rect bounds = topLeft & size;

    // Intersect against the on-screen window rect (logical pixels).
    final Rect windowRect = _windowRect();
    Rect visible = bounds.intersect(windowRect);
    if (visible.isEmpty) return 0.0;

    // Intersect against every ancestor's approximate paint clip so a child
    // inside a clipped scroll view is reported correctly. Clips are expressed
    // in the ancestor's local space, so map them into global space using the
    // transform from the ancestor down to this render object.
    RenderObject child = this;
    RenderObject? ancestor = parent;
    while (ancestor != null) {
      final Rect? clip = ancestor.describeApproximatePaintClip(child);
      if (clip != null) {
        // The clip is expressed in the ancestor's local coordinate space.
        // Map it into global space via the ancestor -> global transform.
        final Matrix4 transform = ancestor.getTransformTo(null);
        final Rect globalClip = MatrixUtils.transformRect(transform, clip);
        visible = visible.intersect(globalClip);
        if (visible.isEmpty) return 0.0;
      }
      child = ancestor;
      ancestor = ancestor.parent;
    }

    final double visibleArea = visible.width * visible.height;
    if (visibleArea <= 0.0) return 0.0;

    final double fraction = visibleArea / totalArea;
    return fraction.clamp(0.0, 1.0);
  }

  /// Returns the on-screen window rect in logical pixels, used as the outer
  /// bound for visibility. Prefers the platform's implicit view and falls back
  /// to the first available view.
  Rect _windowRect() {
    final view = ui.PlatformDispatcher.instance.implicitView ??
        (ui.PlatformDispatcher.instance.views.isNotEmpty
            ? ui.PlatformDispatcher.instance.views.first
            : null);
    if (view == null) return Rect.largest;
    return Offset.zero & (view.physicalSize / view.devicePixelRatio);
  }

  @override
  void detach() {
    // Report zero so a removed / disposed detector never leaves a listener
    // believing this subtree is still on screen.
    if (_lastReportedFraction != 0.0) {
      _lastReportedFraction = 0.0;
      _onVisibilityChanged(0.0);
    }
    super.detach();
  }
}
