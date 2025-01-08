# ChampionForms

**ChampionForms** is a Flutter plugin for building robust, declarative, and accessible forms with minimal boilerplate. It now uses an internal form controller rather than Riverpod, making it easy to integrate into any Flutter app and providing powerful features like manual field updates.

## Table of Contents

1. [What’s New in 0.0.4](#whats-new-in-004)
2. [Features](#features)
3. [Installation](#installation)
4. [Quick Start Example](#quick-start-example)
5. [Basic Usage](#basic-usage)
   - [ChampionFormController](#championformcontroller)
   - [ChampionForm](#championform)
   - [ChampionTextField](#championtextfield)
   - [ChampionOptionSelect & ChampionCheckboxSelect](#championoptionselect--championcheckboxselect)
   - [Retrieving Form Results](#retrieving-form-results)
   - [Manually Setting Values](#manually-setting-values)
6. [Form Validation](#form-validation)
7. [Customizing Layout & Themes](#customizing-layout--themes)
8. [Advanced Usage](#advanced-usage)
   - [Custom Field Builders](#custom-field-builders)
9. [Contributing](#contributing)
10. [License](#license)

---

## What’s New in 0.0.4

- **Removed Riverpod Dependency**: You no longer need to wrap your app in a `ProviderScope`.
- **ChampionFormController**: A new controller-based API to manage the form’s state and retrieval of results.
- **No More Form ID**: Each form is tied to a `ChampionFormController` instead of a string ID. This simplifies usage and also allows coupling multiple `ChampionForm` widgets to a single controller.
- **Manually Setting Field Values**: You can now programmatically update text fields or toggle on/off multi-select fields using the controller (see [Manually Setting Values](#manually-setting-values)).

If you used an older version of ChampionForms, you’ll need to update your code to use `ChampionFormController` instead of the old `ref`/`formId` approach.

---

## Features

- **Declarative** form definition using Dart classes.
- **Accessible & Ergonomic**: Uses standard Flutter widgets under the hood with minimal custom painting, ensuring built-in accessibility.
- **Live Validation**: Easily add multiple validators (e.g., required, email, etc.), with automatic field-level error handling.
- **Extendable**: Create custom field builders, layouts, and theming.
- **Multiple Field Types**: Text input, drop-downs, checkboxes, multi-select, and more.
- **Manual Field Updates**: Programmatically set text fields, toggle multi-select options, and more.

---

## Installation

1. Add **ChampionForms** to your `pubspec.yaml`:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     championforms: ^0.0.4
   ```

2. Run `flutter pub get` in your project directory.

3. Import the package:

   ```dart
   import 'package:championforms/championforms.dart';
   ```

---

## Quick Start Example

Below is an example of how to use ChampionForms **without** Riverpod. Notice that you initialize a **ChampionFormController**, pass it to your `ChampionForm`, and later use it to retrieve form results or even manually set field values.

```dart
import 'package:championforms/championforms.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/formresults.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChampionForms Demo',
      theme: ThemeData(useMaterial3: true),
      home: const MyHomePage(title: 'ChampionForms Quick Start'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 1. Declare a ChampionFormController to manage your form state
  late ChampionFormController controller;

  @override
  void initState() {
    super.initState();
    controller = ChampionFormController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleFormSubmission() {
    // 2. Retrieve results and validate
    final FormResults results = FormResults.getResults(controller: controller);
    if (!results.errorState) {
      // All validations passed
      final email = results.grab("emailField").asString();
      final password = results.grab("passwordField").asString();
      debugPrint("Email: $email, Password: $password");
    } else {
      debugPrint("There are form errors:");
      for (var error in results.formErrors) {
        debugPrint("Field ${error.fieldId} => ${error.reason}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      ChampionTextField(
        id: "emailField",
        textFieldTitle: "Email",
        hintText: "Enter your email",
        validateLive: true,
      ),
      ChampionTextField(
        id: "passwordField",
        textFieldTitle: "Password",
        password: true,
        validateLive: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // 3. Use ChampionForm with the same controller
        child: Column(
          children: [
            ChampionForm(
              controller: controller,
              fields: fields,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text("Set Values"),
              onPressed: () {
                // 4. Manually set text fields or toggle multi-select fields
                controller.updateTextFieldValue("emailField", "hello@world.com");
                // For multi-select or dropdown fields, you can add or remove items from the selected set:
                // controller.toggleMultiSelectValue("myMultiSelectField", toggleOn: ["Option1"], toggleOff: ["Option2"]);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleFormSubmission,
        child: const Icon(Icons.save),
      ),
    );
  }
}
```

---

## Basic Usage

Below are more details on using **ChampionForm**, **ChampionFormController**, and different field types.

### ChampionFormController

This class manages the internal state of the form, including:

- Storing each field’s data
- Keeping track of validation errors
- Letting you fetch form results at any time
- **Manually setting field values** (e.g., toggling multi-select, updating text fields)

**Example**:

```dart
late ChampionFormController myFormController;

@override
void initState() {
  super.initState();
  myFormController = ChampionFormController();
}

@override
void dispose() {
  myFormController.dispose();
  super.dispose();
}
```

Then you pass this controller into `ChampionForm(controller: myFormController, ...)`.

### ChampionForm

`ChampionForm` is the root widget for your fields. You just supply:

- `controller`: The `ChampionFormController` managing this form’s state.
- `fields`: A List of `FormFieldBase` objects (e.g., `ChampionTextField`, `ChampionOptionSelect`, etc.).
- `theme` (optional): A custom `FormTheme`.
- `spacing` (optional): Vertical spacing between fields.

```dart
ChampionForm(
  controller: myFormController,
  fields: [
    ChampionTextField(id: "username", textFieldTitle: "Username"),
    ChampionOptionSelect(id: "countrySelect", /* ... */),
  ],
  spacing: 12,
  theme: softBlueColorTheme(context), // optional
),
```

### ChampionTextField

Defines a text input field with optional password hiding, live validation, and more:

```dart
ChampionTextField(
  id: "emailField",
  textFieldTitle: "Email",
  hintText: "Enter your email address",
  validateLive: true, // immediate validation on focus change
  validators: [
    FormBuilderValidator(
      validator: (input) => DefaultValidators().isEmpty(input),
      reason: "Field cannot be empty",
    ),
    FormBuilderValidator(
      validator: (input) => DefaultValidators().isEmail(input),
      reason: "Invalid email address",
    ),
  ],
  leading: const Icon(Icons.email),
)
```

### ChampionOptionSelect & ChampionCheckboxSelect

Used for **dropdown** or **multi-select checkboxes** by changing the underlying field builder.

```dart
// A simple dropdown (ChampionOptionSelect)
ChampionOptionSelect(
  id: "countrySelect",
  title: "Select Country",
  options: [
    MultiselectOption(label: "USA", value: "us"),
    MultiselectOption(label: "Canada", value: "ca"),
    MultiselectOption(label: "Mexico", value: "mx"),
  ],
  multiselect: false, // single selection
),
```

```dart
// A checkbox multi-select (ChampionCheckboxSelect)
ChampionCheckboxSelect(
  id: "platformSelect",
  title: "Preferred Gaming Platforms",
  options: [
    MultiselectOption(label: "PC", value: "pc"),
    MultiselectOption(label: "PlayStation", value: "ps"),
    MultiselectOption(label: "Xbox", value: "xbox"),
    MultiselectOption(label: "Nintendo Switch", value: "switch"),
  ],
  multiselect: true,
  validateLive: true,
  validators: [
    FormBuilderValidator(
      validator: (results) => DefaultValidators().isEmpty(results),
      reason: "Please select at least one platform",
    ),
  ],
),
```

### Retrieving Form Results

ChampionForms uses the `ChampionFormController` rather than an ID. To get the results:

```dart
final results = FormResults.getResults(controller: myFormController);

// Check if any errors
if (!results.errorState) {
  String email = results.grab("emailField").asString();
  String country = results.grab("countrySelect").asString();
  List<MultiselectOption> selectedPlatforms =
      results.grab("platformSelect").asMultiselectList();

  debugPrint("Email: $email, Country: $country");
  debugPrint("Platforms: ${selectedPlatforms.map((e) => e.value).join(', ')}");
} else {
  debugPrint("There are form errors. Details:");
  for (var error in results.formErrors) {
    debugPrint("Field ${error.fieldId} => ${error.reason}");
  }
}
```

---

### Manually Setting Values

One of the newest features in **0.0.4** is the ability to **manually update** fields via the controller—handy for resetting forms, pre-filling fields, or conditionally toggling multi-select options.

Use the following methods:

- **`updateTextFieldValue(fieldId, newValue)`**: Updates a text field’s value.
- **`toggleMultiSelectValue(fieldId, { List<String>? toggleOn, List<String>? toggleOff })`**: Toggles on or off specific choices for a multi-select field.

**Example**:

```dart
ElevatedButton(
  child: const Text("Set Values"),
  onPressed: () {
    // Set the "Email" text field
    controller.updateTextFieldValue("Email", "Hello@hello.com");

    // Toggle multi-select values on a dropdown or checkbox field
    controller.toggleMultiSelectValue(
      "DropdownField",
      toggleOn: ["Value 3", "Value 2"],
    );

    // Toggle on some options and toggle off others
    controller.toggleMultiSelectValue(
      "SelectBox",
      toggleOn: ["Hi", "Yoz"],
      toggleOff: ["Hiya"],
    );
  },
),
```

After calling these methods, the UI updates automatically to reflect the new values.

---

## Form Validation

ChampionForms supports **live validation** (`validateLive = true`) and batch validation when you call `FormResults.getResults()`. You can attach multiple validators per field:

```dart
validators: [
  FormBuilderValidator(
    validator: (value) => DefaultValidators().isEmpty(value),
    reason: "Field cannot be empty",
  ),
  FormBuilderValidator(
    validator: (value) => DefaultValidators().isEmail(value),
    reason: "Must be a valid email address",
  ),
],
```

If any validator fails, the field enters an error state, displays an error message, and the `FormResults.errorState` will be `true`.

---

## Customizing Layout & Themes

- **Layouts**: Each field’s title, description, and error message is wrapped in a simple layout by default. You can provide a custom layout with the `fieldLayout` parameter on each field.
- **Field Background**: The default is minimal. You can provide a custom container or your own widget by setting `fieldBackground`.
- **Theming**: Extend or tweak the `FormTheme` class or use the utility themes (like `softBlueColorTheme(context)`) to quickly style your fields.

Example custom layout:

```dart
ChampionTextField(
  id: "demoText",
  fieldLayout: (context, fieldDetails, currentColors, errors, renderedField) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fieldDetails.title ?? "", style: TextStyle(color: currentColors.textColor)),
        const SizedBox(height: 4),
        renderedField, // The actual text field
        // Possibly display errors differently here
      ],
    );
  },
)
```

---

## Advanced Usage

### Custom Field Builders

You can create bespoke UIs for selecting items or controlling how the field is rendered. A custom builder function receives multiple parameters, including the current `ChampionFormController`, the list of options (if applicable), current color scheme, etc. See the included [`checkboxFieldBuilder`](https://github.com/...) or [`dropdownFieldBuilder`](https://github.com/...) for reference.

```dart
Widget myCustomSelectBuilder(
  BuildContext context,
  ChampionFormController controller,
  List<MultiselectOption> choices,
  ChampionOptionSelect field,
  FieldState currentState,
  FieldColorScheme currentColors,
  List<String>? defaultValue,
) {
  // Return a widget tree that suits your needs
}
```

Then assign it to your field:

```dart
ChampionOptionSelect(
  id: "customSelect",
  options: [ /* ... */ ],
  fieldBuilder: myCustomSelectBuilder,
),
```

---

## Contributing

Contributions, issues, and feature requests are welcome! To get started:

1. **Fork** the repository
2. Create a new feature branch (`git checkout -b feature/my-awesome-feature`)
3. **Commit** your changes
4. **Push** to your branch (`git push origin feature/my-awesome-feature`)
5. Open a **Pull Request**

---

## License

[MIT License](LICENSE) © 2025 *Champions of the Web*

ChampionForms is free and open-source. See [LICENSE](LICENSE) for details.

---

That’s it! In **ChampionForms 0.0.4**, you can now declaratively define robust, validated, and accessible forms in Flutter using a simple controller-based API—and you can even set or toggle field values on-the-fly. Enjoy building forms with **ChampionForms**!
