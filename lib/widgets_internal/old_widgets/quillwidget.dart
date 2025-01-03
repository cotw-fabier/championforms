import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/providers/textformfieldbyid.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parchment_delta/parchment_delta.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:championforms/models/fleathercustomembeds.dart';
import 'package:championforms/providers/fleathercustomembedprovider.dart';
import 'package:championforms/providers/quillcontrollerprovider.dart';
import 'package:championforms/providers/recentquillprovider.dart';
import 'package:championforms/widgets_internal/draggablewidget.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'dart:io' show Platform;

class QuillWidgetTextArea extends ConsumerStatefulWidget {
  const QuillWidgetTextArea({
    super.key,
    required this.id,
    this.fieldId = "",
    this.formId = "",
    required this.field,
    this.requestFocus = false,
    this.active = true,
    this.password = false,
    this.onChanged,
    this.onSubmitted,
    this.validate,
    this.icon,
    this.initialValue,
    this.hintText = '',
    this.maxLines,
    this.width,
    this.height,
    this.maxHeight,
    this.expanded = false,
    //this.embeds = const [],
    this.onDrop,
    this.formats,
    this.draggable = true,
    this.onPaste,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;
  final String id;
  final String fieldId;
  final String formId;
  final FormFieldDef field;
  final bool requestFocus;
  final bool active;
  final bool password;
  final Function(String value, FormResults results)? onChanged;
  final Function(String value)? onSubmitted;
  final Function(String value)? validate;
  final Delta? initialValue;
  final Icon? icon;
  final String hintText;
  final int? maxLines;
  final double? width;
  final double? height;
  final double? maxHeight;
  final bool expanded;
  final Widget Function({required Widget child})? fieldBuilder;
  //final List<EmbedBuilder> embeds;
  final Future<void> Function({
    FleatherController? fleatherController,
    TextEditingController? controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onDrop;
  final List<DataFormat<Object>>? formats;
  final bool draggable;
  final Future<void> Function({
    FleatherController? fleatherController,
    TextEditingController? controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onPaste;

  // Default implementation for the fieldBuilder.
  static Widget defaultFieldBuilder({required Widget child}) {
    // Replace this with the implementation of `FormFieldWrapperDesignWidget`.
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _QuillWidgetTextAreaState();
}

class _QuillWidgetTextAreaState extends ConsumerState<QuillWidgetTextArea> {
  late FocusNode _focusNode;
  late FocusNode _pasteFocusNode;
  late bool _gotFocus;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();

    _gotFocus = false;

    _focusNode = FocusNode();
    _pasteFocusNode = FocusNode();

    _focusNode.addListener(_focusListener);

    // Lets read in our custom embeds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final registerEmbeds = ref.watch(embedRegistryNotifierProvider.notifier);
      registerEmbeds.registerEmbed(YoutubeEmbed());

      // Register listener on the controller
      final controller = ref.watch(
          quillControllerNotifierProvider(widget.formId, widget.fieldId));
      controller.addListener(_onChangeListener);
    });
  }

  void _onChangeListener() {
    final controller = ref
        .read(quillControllerNotifierProvider(widget.formId, widget.fieldId));
    if (widget.onChanged != null) {
      widget.onChanged!(
          controller.document.toPlainText(),
          FormResults.getResults(
              ref: ref, formId: widget.formId, fields: [widget.field]));
    }
  }

  void _focusListener() {
    if (_focusNode.hasFocus) {
      ref.read(recentQuillNotifierProvider.notifier).updateRecentQuillSelected(
          formId: widget.formId, fieldId: widget.fieldId);
    }

    setState(() {
      _gotFocus = true;
    });

    final controller = ref
        .read(quillControllerNotifierProvider(widget.formId, widget.fieldId));

    if (widget.validate != null && !_focusNode.hasFocus) {
      // if this field ever recieved focus then we can rely on the text controller
      // If not, then we'll run the validator on the initial value supplied
      widget.validate!(_gotFocus
          ? controller.document.toPlainText()
          : widget.initialValue.toString());
    }
  }

  final List<String> imageFileExtensions = [
    '.jpeg',
    '.png',
    '.jpg',
    '.gif',
    '.webp',
    '.tif',
    '.heic'
  ];

  /* OnDragDoneCallback get _onDragDone {
    final controller = ref.read(quillControllerNotifierProvider(
      widget.formId,
      widget.fieldId,
    ));
    return (details) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final file = details.files.first;
      final isSupported =
          imageFileExtensions.any((ext) => file.name.endsWith(ext));
      if (!isSupported) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Only images are supported right now: ${file.mimeType}, ${file.name}, ${file.path}, $imageFileExtensions',
            ),
          ),
        );
        return;
      }
      // To get this extension function please import flutter_quill_extensions
      controller.insertImageBlock(
        imageSource: file.path,
      );
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Image is inserted.'),
        ),
      );
    };
  } */

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    _pasteFocusNode.dispose();
    super.dispose();
  }

  void _handlePaste() async {
    /* final controller = ref.read(quillControllerNotifierProvider(
      widget.formId,
      widget.fieldId,
    ));

    final clipboard = SystemClipboard.instance;
    final reader = await clipboard?.read();
    final plainTextData = reader?.canProvide(Formats.plainText) ?? false
        ? await reader!.readValue(Formats.plainText)
        : null;
    final htmlData = reader?.canProvide(Formats.htmlText) ?? false
        ? await reader!.readValue(Formats.htmlText)
        : null;

    debugPrint("Can Provide HTML: ${reader?.canProvide(Formats.htmlText)}");
    debugPrint("Can Provide Text: ${reader?.canProvide(Formats.plainText)}");
    //debugPrint(htmlData ?? "No HTML Data");

    if (htmlData != null) {
      //print('Pasting rich text');
      final markdownText = html2md.convert(htmlData);
      final htmlText = md.markdownToHtml(markdownText);
      /* final mdDocument = md.Document(encodeHtml: false);

      final mdToDelta = MarkdownToDelta(markdownDocument: mdDocument);
      //final document = Document.from(markdownText);
      final delta = mdToDelta.convert(markdownText);
 */

      final richTextDocument = Document.fromHtml(htmlText);
      final delta = richTextDocument.toDelta();

      controller.replaceText(
        controller.selection.baseOffset,
        controller.selection.extentOffset - controller.selection.baseOffset,
        delta,
        selection: TextSelection.collapsed(
            offset: controller.selection.baseOffset + delta.length),
      );

      /* controller.compose(
        delta,
        controller.selection,
        ChangeSource.local,
      ); */
    } else if (plainTextData != null) {
      //print('Pasting plain text');
      controller.replaceText(
        controller.selection.baseOffset,
        controller.selection.extentOffset - controller.selection.baseOffset,
        plainTextData,
        selection: TextSelection.collapsed(
            offset: controller.selection.baseOffset + plainTextData.length),
      );
    } */
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref
        .watch(quillControllerNotifierProvider(widget.formId, widget.fieldId));

    // Use a different context menu on desktop
    final bool isDesktop = !(kIsWeb || Platform.isWindows || Platform.isMacOS);

    // Pull in any custom embeds we have defined

    final _embedBuilder = ref.watch(fleatherCustomEmbedNotifierProvider);

    //ref.listen(textFormFieldValueById(widget.id), _onRiverpodControllerUpdate);
    final ThemeData theme = Theme.of(context);
    final textValue = ref.watch(textFormFieldValueById(widget.id));
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: widget.width ??
            (constraints.maxWidth < double.infinity && widget.expanded
                ? constraints.maxWidth
                : null),
        height: widget.height ??
            (constraints.maxHeight < double.infinity && widget.expanded
                ? constraints.maxHeight
                : null),
        constraints: widget.maxHeight != null
            ? BoxConstraints(maxHeight: widget.maxHeight!)
            : null,
        child: widget.fieldBuilder!(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: MouseRegion(
              cursor: SystemMouseCursors.text,
              child: Focus(
                focusNode: _pasteFocusNode,
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  final isPasteEvent = event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.keyV &&
                      (HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.controlLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.controlRight) ||
                          HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.metaLeft) ||
                          HardwareKeyboard.instance.logicalKeysPressed
                              .contains(LogicalKeyboardKey.metaRight));

                  if (isPasteEvent) {
                    debugPrint("Paste Function: ${widget.onPaste.toString()}");
                    widget.onPaste == null
                        ? _handlePaste()
                        : widget.onPaste!(
                            fleatherController: controller,
                            ref: ref,
                            formId: widget.formId,
                            fieldId: widget.fieldId,
                          );
                    return KeyEventResult.handled;
                  } else {
                    return KeyEventResult.ignored;
                  }
                },
                child: FleatherEditor(
                  controller: controller,
                  focusNode: _focusNode,
                  autofocus: widget.requestFocus,
                  readOnly: !widget.active,
                  embedBuilder: _embedBuilder,
                ),

                /* QuillEditor(
                  scrollController: _scrollController,
                  focusNode: _focusNode,
                  configurations: QuillEditorConfigurations(
                    /* contextMenuBuilder: (context, rawEditorState) {
                      return AdaptiveTextSelectionToolbar.editable(
                        onPaste: () => print("Paste Event Detected"),
                        clipboardStatus: ClipboardStatus.pasteable,
                        onCopy: () => rawEditorState
                            .copySelection(SelectionChangedCause.toolbar),
                        onCut: () => rawEditorState
                            .cutSelection(SelectionChangedCause.toolbar),
                        onSelectAll: () => rawEditorState
                            .selectAll(SelectionChangedCause.toolbar),
                        onLookUp: () => rawEditorState
                            .lookUpSelection(SelectionChangedCause.toolbar),
                        onSearchWeb: () => rawEditorState
                            .searchWebForSelection(SelectionChangedCause.toolbar),
                        onShare: () => rawEditorState
                            .shareSelection(SelectionChangedCause.toolbar),
                        onLiveTextInput: null,
                        anchors: const TextSelectionToolbarAnchors(
                          primaryAnchor: Offset(0, 0),
                          secondaryAnchor: Offset(0, 0),
                        ),
                      );
                    }, */
                    placeholder: widget.hintText,
                    controller: controller,
                    autoFocus: widget.requestFocus,
                    //enableSelectionToolbar: true,
                    enableSelectionToolbar: isDesktop,
                    //enableInteractiveSelection: false,
                    maxHeight: widget.maxHeight,
                    builder: (context, rawEditor) {
                      return ConditionalDraggableDropZone(
                          onDrop: widget.onDrop,
                          formats: widget.formats,
                          draggable: widget.draggable,
                          fletherController: controller,
                          fieldId: widget.fieldId,
                          formId: widget.formId,
                          child: rawEditor);
                    },
                    embedBuilders: kIsWeb
                        ? FlutterQuillEmbeds.editorWebBuilders()
                        : [
                            ...FlutterQuillEmbeds.editorBuilders(),
                            ...widget.embeds
                          ],
                  ),
                ), */
              ),
            ),
          ),
        ),
      );
    });
  }
}
