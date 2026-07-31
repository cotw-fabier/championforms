import 'package:championforms/championforms.dart' as form;
// FormFieldDefaults lives in the themes export and is NOT namespaced.
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';

/// Demonstration page for two new field presentation features:
///
/// 1. **Field emphasis colors** (`colors: form.FieldColors.destructive`)
///    A field flagged as destructive renders using the theme's ERROR palette
///    while it is empty AND unfocused. As soon as the user focuses it and/or
///    types a value, it reverts to its normal appearance. This is handy for
///    drawing the eye to a required field before the user has interacted with
///    the form, without it being a "real" validation error.
///
/// 2. **Validation wiggle**
///    When validation fails (either on submit via
///    `FormResults.getResults()` or live/on-blur), the offending field plays a
///    small horizontal "wiggle" animation. The animation is visibility-gated:
///    fields already on screen wiggle immediately, while fields scrolled off
///    screen defer their wiggle until they are scrolled into view. It also
///    respects the OS "reduce motion" accessibility setting, and can be
///    toggled app-wide via `FormFieldDefaults.instance.animateValidationErrors`.
///
/// The form on this page is intentionally LONG so the off-screen deferral
/// behavior can be observed: submit with empty fields, then scroll down to the
/// bottom field to watch it wiggle as it enters the viewport.
class EmphasisAndWiggleDemo extends StatefulWidget {
  const EmphasisAndWiggleDemo({super.key});

  @override
  State<EmphasisAndWiggleDemo> createState() => _EmphasisAndWiggleDemoState();
}

class _EmphasisAndWiggleDemoState extends State<EmphasisAndWiggleDemo> {
  // The FormController is the single source of truth for this form. It is
  // created in initState and MUST be disposed in dispose (see below).
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    // Always dispose the controller to release TextEditingControllers,
    // FocusNodes and ValueNotifiers it manages internally.
    controller.dispose();
    super.dispose();
  }

  /// Runs validation across the whole form. The wiggle animation is automatic
  /// on failure, so there is nothing special to do here other than surface a
  /// hint to the user.
  void _validate() {
    final results = form.FormResults.getResults(controller: controller);

    if (results.errorState) {
      // The wiggle happens automatically for the failing fields. Off-screen
      // fields will wiggle once scrolled into view.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fix the highlighted fields. '
            'Scroll down to see off-screen fields wiggle as they appear.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All good! Form submitted.')),
      );
    }
  }

  /// A simple "required" validator: fails when the field's string value is
  /// empty. `Validators.stringIsNotEmpty` is the built-in helper used
  /// throughout the example app.
  form.Validator _required(String reason) => form.Validator(
        validator: (results) => form.Validators.stringIsNotEmpty(results),
        reason: reason,
      );

  List<form.FormElement> _buildFields() {
    return [
      // --- DESTRUCTIVE EMPHASIS FIELD (near the top) ---
      // This field renders in the theme's ERROR palette while it is empty and
      // unfocused, drawing the user's attention. Focus it or type into it and
      // it reverts to the normal palette. It also has a required validator so
      // it participates in the wiggle-on-submit behavior.
      form.TextField(
        id: 'destructive_field',
        textFieldTitle: 'Critical Field (destructive emphasis)',
        description:
            'Renders in the error palette until you focus it or fill it in. '
            'This is emphasis, not a validation error.',
        hintText: 'Type something to clear the emphasis',
        maxLines: 1,
        colors: form.FieldColors.destructive,
        validateLive: true,
        validators: [
          _required('This field is required.'),
        ],
      ),

      // --- A normal field just below it for contrast ---
      form.TextField(
        id: 'normal_top_field',
        textFieldTitle: 'Normal Field',
        description: 'A standard field for visual comparison.',
        hintText: 'Optional',
        maxLines: 1,
      ),

      // --- FILLER FIELDS ---
      // These push the bottom required field below the fold on a typical phone
      // screen so the off-screen wiggle deferral can be demonstrated.
      for (int i = 1; i <= 6; i++)
        form.TextField(
          id: 'filler_$i',
          textFieldTitle: 'Filler Field $i',
          description:
              'Scroll past me. These exist to push the required field below '
              'the fold so its wiggle is deferred until it scrolls into view.',
          hintText: 'Not required',
          maxLines: 3,
        ),

      // --- BOTTOM REQUIRED FIELD (below the fold) ---
      // Leave this empty and press "Validate / Submit" at the top. Because it
      // starts off screen, its wiggle is deferred; scroll down and watch it
      // wiggle the moment it enters the viewport.
      form.TextField(
        id: 'bottom_required_field',
        textFieldTitle: 'Bottom Required Field (off-screen wiggle)',
        description:
            'Leave this empty, submit, then scroll down to watch it wiggle as '
            'it enters the viewport.',
        hintText: 'Required',
        maxLines: 1,
        validateLive: true,
        validators: [
          _required('This required field is empty.'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Read the current global animation toggle so the Switch reflects state.
    final animateOn = FormFieldDefaults.instance.animateValidationErrors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emphasis & Wiggle Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // The whole page scrolls so we can reach the bottom field. The form
      // itself is laid out inside this SingleChildScrollView.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top controls: global animation toggle + submit ---
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controls',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    // Global toggle for the wiggle animation. Flipping this
                    // mutates FormFieldDefaults.instance.animateValidationErrors
                    // which controls the behavior app-wide.
                    SwitchListTile(
                      title: const Text('Animate validation errors (wiggle)'),
                      subtitle: const Text(
                        'Toggles FormFieldDefaults.instance.'
                        'animateValidationErrors app-wide.',
                      ),
                      value: animateOn,
                      onChanged: (value) {
                        setState(() {
                          FormFieldDefaults.instance.animateValidationErrors =
                              value;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Note: disable your OS "reduce motion" accessibility '
                      'setting to see the wiggles.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _validate,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Validate / Submit'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- The form ---
            form.Form(
              controller: controller,
              spacing: 12,
              fieldPadding: const EdgeInsets.symmetric(vertical: 8.0),
              fields: _buildFields(),
            ),

            const SizedBox(height: 24),

            // A second submit button at the bottom so you can trigger
            // validation without scrolling back to the top.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _validate,
                icon: const Icon(Icons.check_circle),
                label: const Text('Validate / Submit (bottom)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Explanation card ---
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'What to try',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Notice the top "Critical Field" starts in the error '
                      'palette (destructive emphasis) while empty & unfocused.\n'
                      '2. Focus it or type a value — the emphasis clears.\n'
                      '3. With the fields empty, press "Validate / Submit". '
                      'On-screen fields wiggle immediately.\n'
                      '4. Scroll to the bottom required field and watch it '
                      'wiggle as it scrolls into view (deferred off-screen '
                      'wiggle).\n'
                      '5. Toggle "Animate validation errors" off and submit '
                      'again to confirm wiggles stop.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
