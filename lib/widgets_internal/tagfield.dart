//String Tags with AutoComplete
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/providers/formliststringsprovider.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textfield_tags/textfield_tags.dart';

class FormBuilderStringAutoCompleteTags extends ConsumerStatefulWidget {
  const FormBuilderStringAutoCompleteTags({
    super.key,
    required this.initialValues,
    required this.id,
    required this.field,
    this.expanded = false,
    this.width,
    this.height,
    this.maxHeight,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;

  final List<String>? initialValues;
  final String id;
  final FormFieldDef field;
  final bool expanded;
  final double? width;
  final double? height;
  final double? maxHeight;
  final Widget Function({required Widget child})? fieldBuilder;

  // Default implementation for the fieldBuilder.
  static Widget defaultFieldBuilder({required Widget child}) {
    // Replace this with the implementation of `FormFieldWrapperDesignWidget`.
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  ConsumerState<FormBuilderStringAutoCompleteTags> createState() =>
      _FormBuilderStringAutoCompleteTagsState();
}

class _FormBuilderStringAutoCompleteTagsState
    extends ConsumerState<FormBuilderStringAutoCompleteTags> {
  late double _distanceToField;
  late StringTagController _stringTagController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void initState() {
    super.initState();
    _stringTagController = StringTagController();

    _stringTagController.addListener(() {
      ref
          .read(
              formListStringsNotifierProvider("${widget.id}${widget.field.id}")
                  .notifier)
          .populate(_stringTagController.getTags!);
      //debugPrint("Tag field ID is: ${widget.id}${widget.field.id}");
      //debugPrint("Tags: ${_stringTagController.getTags?.join(", ")}");
    });
  }

  @override
  void dispose() {
    super.dispose();
    _stringTagController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _initialTags = widget.initialValues ?? [];
    return Column(
      children: [
        LayoutBuilder(builder: (context, constraints) {
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
            child: Autocomplete<String>(
              optionsViewBuilder: (context, onSelected, options) {
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 4.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Material(
                      elevation: 4.0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return TextButton(
                              onPressed: () {
                                onSelected(option);
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '#$option',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return _initialTags.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selectedTag) {
                _stringTagController.onTagSubmitted(selectedTag);
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                return TextFieldTags<String>(
                  textEditingController: textEditingController,
                  focusNode: focusNode,
                  textfieldTagsController: _stringTagController,
                  initialTags: widget.initialValues,
                  textSeparators: const [' ', ','],
                  letterCase: LetterCase.normal,
                  validator: (String tag) {
                    if (_stringTagController.getTags!.contains(tag)) {
                      return 'You\'ve already entered that';
                    }
                    return null;
                  },
                  inputFieldBuilder: (context, inputFieldValues) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: widget.fieldBuilder!(
                        child: TextField(
                          controller: inputFieldValues.textEditingController,
                          focusNode: inputFieldValues.focusNode,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors
                                .transparent, // To ensure the background is visible
                            border: const OutlineInputBorder(
                              borderSide: BorderSide
                                  .none, // No additional border needed
                            ),
                            helperText: widget.field?.hintText ?? "",
                            helperStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                            ),
                            hintText: inputFieldValues.tags.isNotEmpty
                                ? ''
                                : widget.field?.hintText ?? "",
                            errorText: inputFieldValues.error,
                            prefixIconConstraints: BoxConstraints(
                                maxWidth: _distanceToField * 0.74),
                            prefixIcon: inputFieldValues.tags.isNotEmpty
                                ? SingleChildScrollView(
                                    controller:
                                        inputFieldValues.tagScrollController,
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                        children: inputFieldValues.tags
                                            .map((String tag) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(20.0),
                                          ),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                        ),
                                        margin:
                                            const EdgeInsets.only(right: 10.0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0, vertical: 4.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              child: Text(
                                                '$tag',
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary),
                                              ),
                                              onTap: () {
                                                //print("$tag selected");
                                              },
                                            ),
                                            const SizedBox(width: 4.0),
                                            InkWell(
                                              child: Icon(
                                                Icons.cancel,
                                                size: 14.0,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              onTap: () {
                                                inputFieldValues
                                                    .onTagRemoved(tag);
                                                ref
                                                    .read(formListStringsNotifierProvider(
                                                            "${widget.id}${widget.field.id}")
                                                        .notifier)
                                                    .remove(tag);
                                              },
                                            )
                                          ],
                                        ),
                                      );
                                    }).toList()),
                                  )
                                : null,
                          ),
                          onChanged: inputFieldValues.onTagChanged,
                          onSubmitted: inputFieldValues.onTagSubmitted,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(
              Theme.of(context).colorScheme.secondaryContainer,
            ),
          ),
          onPressed: () {
            _stringTagController.clearTags();
          },
          child: Text(
            'CLEAR TAGS',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
