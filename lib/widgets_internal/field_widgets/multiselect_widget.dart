import 'package:championforms/functions/geterrors.dart';
import 'package:championforms/providers/field_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

class MultiselectWidget extends ConsumerStatefulWidget {
  const MultiselectWidget({
    super.key,
    required this.id,
    required this.child,
    this.requestFocus = false,
  });
  final String id;
  final Widget child;
  final bool requestFocus;
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MultiselectWidgetState();
}

class _MultiselectWidgetState extends ConsumerState<MultiselectWidget> {
  late FocusNode _focusNode;
  late bool _gotFocus;
  late ValueKey<String> _focusKey;

  @override
  void initState() {
    super.initState();

    _focusKey = ValueKey("${widget.id}traversalgroup");

    _gotFocus = false;

    _focusNode = FocusNode();

    _focusNode.addListener(_onLoseFocus);

    if (widget.requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocusOnFirstChild();
      });
    }
  }

  void _requestFocusOnFirstChild() {
    // Replace 'myFocusScope' with the actual ValueKey string for your FocusScope
    _focusNode.requestFocus();
    FocusScope.of(context).nextFocus();
  }

  void _onLoseFocus() {
    // transmit focus state to provider
    ref
        .read(fieldFocusNotifierProvider(widget.id).notifier)
        .setFocus(_focusNode.hasFocus);

    setState(() {
      _gotFocus = true;
    });

    /*if (widget.validate != null && !_focusNode.hasFocus) {
      // if this field ever recieved focus then we can rely on the text controller
      // If not, then we'll run the validator on the initial value supplied
      widget
          .validate!(_gotFocus ? _controller.text : widget.initialValue ?? "");
    }*/
  }

  BuildContext? _findContextByKey(ValueKey key) {
    BuildContext? targetContext;

    void visit(Element element) {
      if (element.widget.key == key) {
        debugPrint(element.widget.key.toString());
        targetContext = element;
      } else {
        element.visitChildren(visit);
      }
    }

    WidgetsBinding.instance.rootElement?.visitChildren(visit);
    return targetContext;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: _focusKey,
      descendantsAreTraversable: true,
      descendantsAreFocusable: true,
      skipTraversal: true,
      focusNode: _focusNode,
      child: widget.child,
    );
  }
}
