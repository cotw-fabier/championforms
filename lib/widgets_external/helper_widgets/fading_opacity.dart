import 'package:flutter/material.dart';

class FadingWidget extends StatefulWidget {
  final Widget child;

  const FadingWidget({Key? key, required this.child}) : super(key: key);

  @override
  State<FadingWidget> createState() => _FadingWidgetState();
}

class _FadingWidgetState extends State<FadingWidget>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger fade-in animation when widget is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  void dispose() {
    // Trigger fade-out animation before disposal
    setState(() {
      _opacity = 0.0;
    });
    Future.delayed(const Duration(milliseconds: 300), super.dispose);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 300),
      child: widget.child,
    );
  }
}
