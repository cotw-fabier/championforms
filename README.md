# ChampionForms

**ChampionForms** is a Flutter plugin that enables you to build robust, declarative, and accessible forms with minimal boilerplate. It leverages [Riverpod](https://riverpod.dev/) for state management and validation, while offering an extensible API for custom field builders, layouts, and theming.

> **Important**: Since **ChampionForms** depends on Riverpod for data flow and state, make sure you wrap your application in a `ProviderScope` from `flutter_riverpod`. ChampionForms also relies on material theme for widgets.

## Table of Contents

1. [Features](#features)
2. [Installation](#installation)
3. [Quick Start](#quick-start)
4. [Basic Usage](#basic-usage)
   - [ChampionForm](#championform)
   - [ChampionTextField](#championtextfield)
   - [ChampionOptionSelect & ChampionCheckboxSelect](#championoptionselect--championcheckboxselect)
   - [Retrieving Form Results](#retrieving-form-results)
5. [Form Validation](#form-validation)
6. [Customizing Layout & Themes](#customizing-layout--themes)
7. [Advanced Usage](#advanced-usage)
   - [Custom Field Builders](#custom-field-builders)
8. [Contributing](#contributing)
9. [License](#license)

---

## Features

- **Declarative** form definition using Dart classes.
- **Accessible & Ergonomic**: Uses standard Flutter widgets under the hood with minimal custom painting, ensuring you get accessibility built-in.
- **Live Validation**: Add one or more validators (e.g., “required,” “must be an email,” etc.), and watch fields validate automatically.
- **Extendable**: Create custom field builders, layouts, and even define your own theming.
- **State Management with Riverpod**: Retrieve your form data from anywhere in your app, as long as your `formId` matches.
- **Multiple Field Types**: Text input, drop-downs, checkboxes, multi-select, and more.

---

## Installation

1. Add **ChampionForms** to your `pubspec.yaml`:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_riverpod: <latest_version>
     championforms:
       git:
         url: https://github.com/YourUserName/championforms.git
         # Or specify a tag/branch if needed
         # ref: main
   ```

2. Run `flutter pub get` in your project directory.

3. Import the package:

   ```dart
   import 'package:championforms/championforms.dart';
   ```

---

## Quick Start

Here’s the minimal setup to get a form on the screen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:championforms/championforms.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChampionForms Demo',
      theme: ThemeData(useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Define your fields
    final fields = [
      ChampionTextField(
        id: "username",
        textFieldTitle: "Username",
        validateLive: true,
      ),
      ChampionTextField(
        id: "password",
        textFieldTitle: "Password",
        password: true,
        validateLive: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ChampionForms Quick Start')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // 2. Place the ChampionForm widget
        child: ChampionForm(
          id: "loginForm",
          fields: fields,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 3. Grab Results
          final results = FormResults.getResults(ref: ref, formId: "loginForm");
          // 4. Check for errors
          if (!results.errorState) {
            final user = results.grab("username").asString();
            final pass = results.grab("password").asString();
            debugPrint("Username: $user, Password: $pass");
          } else {
            debugPrint("Form has errors!");
          }
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
```

---

## Basic Usage

Below is a breakdown of how to declare and use different field types and retrieve their values.

### ChampionForm

`ChampionForm` is the main widget to which you supply:

- `id`: A **unique** identifier for the form.
- `fields`: A **List** of `FormFieldBase` objects.
- `theme` (optional): A custom `FormTheme`.
- `spacing` (optional): Vertical spacing between fields.

```dart
ChampionForm(
  id: "myForm",
  fields: [
    // ChampionTextField, ChampionOptionSelect, etc.
  ],
  spacing: 12,
  theme: softBlueColorTheme(context), // or your custom theme
),
```

### ChampionTextField

The text field can be configured to handle single-line or multi-line input, passwords, live validation, etc.

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
),
```

### ChampionOptionSelect & ChampionCheckboxSelect

You can build dropdowns or multi-select checkboxes just by changing the field builder.
`ChampionOptionSelect` defaults to a **Dropdown** builder, while
`ChampionCheckboxSelect` defaults to a **Checkbox List** builder.

```dart
// A simple dropdown
ChampionOptionSelect(
  id: "country",
  title: "Select Country",
  options: [
    MultiselectOption(label: "USA", value: "us"),
    MultiselectOption(label: "Canada", value: "ca"),
    MultiselectOption(label: "Mexico", value: "mx"),
  ],
  // You can allow multiple selection by enabling multiselect
  multiselect: false,
),
```

```dart
// A checkbox multi-select
ChampionCheckboxSelect(
  id: "preferredPlatforms",
  title: "Preferred Gaming Platforms",
  options: [
    MultiselectOption(label: "PC", value: "pc"),
    MultiselectOption(label: "PlayStation", value: "ps"),
    MultiselectOption(label: "Xbox", value: "xbox"),
    MultiselectOption(label: "Nintendo Switch", value: "switch"),
  ],
  multiselect: true, // can check multiple boxes
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

Use `FormResults.getResults(ref: ref, formId: "myForm")` to obtain a snapshot of all field values in a single object.

```dart
final results = FormResults.getResults(ref: ref, formId: "myForm");

// Check if any errors
if (!results.errorState) {
  // For a text field:
  String email = results.grab("emailField").asString();

  // For a dropdown field:
  String country = results.grab("country").asString();

  // For multi-select checkboxes:
  List<MultiselectOption> selectedPlatforms =
      results.grab("preferredPlatforms").asMultiselectList();

  // Print them
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

## Form Validation

ChampionForms offers both **live validation** (`validateLive = true`) and on-demand validation when you call `FormResults.getResults()`. You can attach multiple validators per field:

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

If any validator fails, the field error state is triggered and displayed, and the `errorState` in `FormResults` is set to `true`.

---

## Customizing Layout & Themes

- **Layouts**: By default, each field’s title and description appear in a **simple layout**. You can provide a custom layout with the `fieldLayout` parameter on each field.
- **Background**: The default `fieldSimpleBackground` is a minimal container. You can wrap your fields in a card, or any other widget by providing a custom `fieldBackground`.
- **Themes**: Extend or tweak the `FormTheme` class or use utility themes (like `softBlueColorTheme(context)`) to quickly style your fields.

Example using a custom layout:

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
        // ... maybe show errors differently
      ],
    );
  },
)
```

---

## Advanced Usage

### Custom Field Builders

If you want a bespoke UI for selecting items, you can create your own builder function. See the included [`checkboxFieldBuilder`](https://github.com/...) and [`dropdownFieldBuilder`](https://github.com/...) for references. A custom builder function receives multiple parameters:

```dart
Widget myCustomSelectBuilder(
  BuildContext context,
  WidgetRef ref,
  String formId,
  List<MultiselectOption> choices,
  ChampionOptionSelect field,
  FieldState currentState,
  FieldColorScheme currentColors,
  List<String>? defaultValue,
  Function(bool focused) updateFocus,
  Function(MultiselectOption? selectedOption) updateSelectedOption,
) {
  // Return a widget tree that suits your needs
}
```

Then pass it into your field:

```dart
ChampionOptionSelect(
  id: "customSelect",
  options: [ /* ... */ ],
  fieldBuilder: myCustomSelectBuilder,
),
```

---

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to open a PR or file an issue to get in touch. Please follow the standard [Flutter code style guidelines](https://dart.dev/guides/language/effective-dart/style) and add tests when possible.

1. Fork the repository
2. Create a new feature branch (`git checkout -b feature/my-awesome-feature`)
3. Commit your changes
4. Push to your branch (`git push origin feature/my-awesome-feature`)
5. Open a Pull Request

---

## License

[MIT License](LICENSE) © 2025 *Champions of the Web*

ChampionForms is free and open-source. See [LICENSE](LICENSE) for more details.

---

That’s it! With **ChampionForms**, you can declaratively define powerful, validated, and accessible forms in Flutter. If you have any questions or issues, don’t hesitate to open an issue or discussion on the repository. Enjoy building great forms with **ChampionForms**!
