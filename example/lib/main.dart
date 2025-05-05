// /Users/fabier/Documents/championforms/example/lib/main.dart

import 'package:championforms/championforms.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
// AutoCompleteType is implicitly imported via autocomplete_class.dart
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/material.dart';

void main() {
  // --- Global Theme Setup ---
  // You can set a global theme for all ChampionForm instances.
  // This theme will be used unless overridden by a theme passed directly
  // to the ChampionForm widget or an individual field.
  // We need a BuildContext to create the theme, so we do it inside a
  // Builder or similar widget that provides context *before* MaterialApp.
  // For simplicity in this example, we'll set it inside the MyApp build method,
  // but ideally, do it *outside* MaterialApp if possible using a root Builder.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Setting Global Theme (Example Placement) ---
    // Retrieve a pre-defined theme (or create your own FormTheme object)
    final globalTheme = softBlueColorTheme(context);
    // Set it using the singleton instance
    ChampionFormTheme.instance.setTheme(globalTheme);

    return MaterialApp(
      title: 'ChampionForms Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ChampionForms v0.0.5 Demo'),
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
  // --- Form Controller ---
  // The controller manages the state of the form fields.
  late ChampionFormController controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller
    controller = ChampionFormController(
        // Optionally give the controller an ID, useful if managing
        // multiple distinct logical forms that might share field IDs.
        // id: "myFormId"
        );
  }

  @override
  void dispose() {
    // --- IMPORTANT: Dispose the controller ---
    // This cleans up internal resources like TextEditingControllers.
    controller.dispose();
    super.dispose();
  }

  // --- Handling Form Submission ---
  void _executeLogin() {
    // Get results and trigger validation by creating FormResults instance.
    final FormResults results = FormResults.getResults(controller: controller);

    // Check the error state.
    final errors = results.errorState;
    debugPrint("Current Error State is: $errors");

    if (!errors) {
      // --- Accessing Results ---
      // Grab results by field ID and format them as needed.
      debugPrint("Email: ${results.grab("Email").asString()}");
      debugPrint(
          "Password Set: ${results.grab("Password").asString().isNotEmpty}"); // Example for password
      debugPrint("Dropdown: ${results.grab("DropdownField").asString()}");
      debugPrint(
          "Checkboxes: ${results.grab("SelectBox").asMultiselectList().map((field) => field.value).join(", ")}");
      debugPrint(
          "Autocomplete Field: ${results.grab("BottomText").asString()}");

      // --- Accessing File Upload Results ---
      final fileResults =
          results.grab("fileUpload").asFileList(); // Use asFileList()
      if (fileResults.isNotEmpty) {
        debugPrint("Uploaded Files (${fileResults.length}):");
        for (final fileData in fileResults) {
          // TODO: Fix path for file uploads
          // Path: ${fileData.filePath},
          debugPrint(
              "  - Name: ${fileData.fileName}, Mime: ${fileData.mimeData?.mime ?? 'N/A'}");
          // You can access file bytes (if fully read) or stream via fileData.fileDetails
          // Example: Accessing bytes (might be null if not read)
          // Uint8List? bytes = await fileData.fileDetails?.getFileBytes();
          // debugPrint("    Bytes length: ${bytes?.length ?? 'Not loaded'}");
        }
      } else {
        debugPrint("No files uploaded.");
      }
    } else {
      // --- Handling Errors ---
      debugPrint("The form had errors:");
      debugPrint(results.formErrors
          .map((error) => "Field '${error.fieldId}' Error: ${error.reason}")
          .join("\n"));
    }
  }

  // --- Interacting with Controller ---
  void _setValuesProgrammatically() {
    // Update text fields
    controller.updateFieldValue("Email", "programmatic@example.com");
    controller.updateFieldValue("Password", "newPassword123");

    // Toggle options in multiselect fields (like dropdowns, checkboxes)
    // Uses the 'value' property of the MultiselectOption
    controller.toggleMultiSelectValue("DropdownField", toggleOn: [
      "Value 3",
      "Value 2"
    ]); // Selects Value 3, ensures Value 2 is selected

    controller.toggleMultiSelectValue(
      "SelectBox",
      toggleOn: ["Hi", "Yoz"], // Checks "Hello" and "Sup"
      toggleOff: ["Hiya"], // Unchecks "Wat"
    );

    // Note: Programmatically adding files to ChampionFileUpload is complex
    // and usually handled via user interaction (picker/drag-drop).
    // You *can* clear files using:
    // controller.removeMultiSelectOptions("fileUpload");
    debugPrint("Values set programmatically.");
  }

  @override
  Widget build(BuildContext context) {
    // --- Defining Form Fields ---
    // Uses new features: ChampionRow, ChampionColumn, ChampionFileUpload, AutoCompleteBuilder
    final List<FormFieldBase> fields = [
      // --- Row & Column Layout ---
      ChampionRow(
        // collapse: true, // Set true to stack columns vertically (e.g., for mobile)
        rollUpErrors: false, // Set true to show all child errors under the row
        columns: [
          // --- Column 1 (Email) ---
          ChampionColumn(
            columnFlex: 2, // Takes 2/3 of the available width
            fields: [
              ChampionTextField(
                id: "Email",
                textFieldTitle: "Email Address",
                hintText: "Enter your email",
                description: "Your login email.",
                maxLines: 1,
                validateLive: true, // Validate on losing focus
                // --- Autocomplete Example ---
                autoComplete: AutoCompleteBuilder(
                  // type: AutoCompleteType.dropdown, // Default
                  initialOptions: [
                    AutoCompleteOption(value: "test1@example.com"),
                    AutoCompleteOption(value: "test2@example.com"),
                    AutoCompleteOption(value: "another@domain.net"),
                    AutoCompleteOption(value: "fabier@rogueskies.net"),
                  ],
                  // Example async update (can fetch from API)
                  updateOptions: (searchValue) async {
                    // Simulate network delay
                    await Future.delayed(const Duration(milliseconds: 300));
                    // Filter initial options (replace with actual API call)
                    return [
                      AutoCompleteOption(
                          value: "search-$searchValue@example.com"),
                      AutoCompleteOption(value: "$searchValue@rogueskies.net"),
                    ].where((opt) => opt.value.contains(searchValue)).toList();
                  },
                  debounceWait: const Duration(
                      milliseconds: 250), // Wait before calling updateOptions
                ),
                validators: [
                  FormBuilderValidator(
                    validator: (results) =>
                        DefaultValidators().stringIsEmpty(results),
                    reason: "Email cannot be empty.",
                  ),
                  FormBuilderValidator(
                    validator: (results) =>
                        DefaultValidators().stringIsEmail(results),
                    reason: "Please enter a valid email address.",
                  ),
                ],
                leading: const Icon(Icons.email),
              ),
            ],
          ),
          // --- Column 2 (Password) ---
          ChampionColumn(
            columnFlex: 1, // Takes 1/3 of the available width
            fields: [
              ChampionTextField(
                id: "Password", // Changed ID
                textFieldTitle: "Password",
                description: "Enter your password",
                maxLines: 1,
                password: true, // Obscures text
                validateLive: true,
                onSubmit: (results) => _executeLogin(), // Submit on Enter
                validators: [
                  FormBuilderValidator(
                      validator: (results) =>
                          DefaultValidators().isEmpty(results),
                      reason: "Password cannot be empty."),
                  // Add more password validators if needed (e.g., length)
                ],
                leading: const Icon(Icons.lock),
              ),
            ],
          )
        ],
      ),

      // --- Dropdown ---
      ChampionOptionSelect(
        id: "DropdownField",
        title: "Select an Option",
        // multiselect: true,
        description: "Choose one from the list.",
        defaultValue: [
          MultiselectOption(label: "Option 1", value: "Value 1"),
        ],
        options: [
          MultiselectOption(label: "Option 1", value: "Value 1"),
          MultiselectOption(label: "Option 2", value: "Value 2"),
          MultiselectOption(label: "Option 3", value: "Value 3"),
          MultiselectOption(label: "Option 4", value: "Value 4"),
        ],
        // defaultValue: ["Value 2"], // Set a default selection
      ),

      // --- Checkboxes ---
      ChampionCheckboxSelect(
        id: "SelectBox",
        title: "Choose Multiple",
        description: "Select all that apply.",
        // multiselect: true, // Allow multiple selections
        validateLive: true,
        validators: [
          // Example: require at least one selection
          FormBuilderValidator(
              validator: (results) =>
                  DefaultValidators().listIsNotEmpty(results),
              reason: "Please select at least one option."),
        ],
        defaultValue: [
          MultiselectOption(value: "Hiya", label: "Wat"),
        ],
        options: [
          MultiselectOption(value: "Hi", label: "Hello"),
          MultiselectOption(value: "Hiya", label: "Wat"),
          MultiselectOption(value: "Yoz", label: "Sup"),
        ],
        // defaultValue: ["Hiya", "Yoz"], // Set default checked items
      ),

      // --- File Upload ---
      ChampionFileUpload(
        id: "fileUpload",
        title: "Upload Images",
        description: "Drag & drop or click to upload (JPG, PNG only).",
        multiselect: true, // Allow multiple files
        validateLive: true,
        allowedExtensions: ['jpg', 'jpeg', 'png'], // Restrict file types
        // displayUploadedFiles: true, // Default is true
        // Custom display for the drop zone (optional)
        // dropDisplayWidget: (colors, field) => Container(
        //   padding: EdgeInsets.all(20),
        //   decoration: BoxDecoration(border: Border.all(color: colors.borderColor)),
        //   child: Center(child: Text("Custom Drop Zone Text", style: TextStyle(color: colors.textColor))),
        // ),
        validators: [
          // Example: Ensure at least one file is uploaded
          // FormBuilderValidator(
          //     validator: (results) => DefaultValidators().isEmpty(results),
          //     reason: "Please upload at least one image."),
          // Example: Validate that uploaded files are indeed images
          FormBuilderValidator(
            reason: "Only image files (JPG, PNG) are allowed.",
            validator: (results) => DefaultValidators().fileIsImage(results),
          ),
          // Or use a more specific validator:
          // FormBuilderValidator(
          //   reason: "Only JPG or PNG images allowed.",
          //   validator: (results) => DefaultValidators().fileIsCommonImage(results), // Checks common image types
          // ),
        ],
      ),

      // --- Another Text Field with Autocomplete ---
      ChampionTextField(
        id: "BottomText",
        textFieldTitle: "Autocomplete Example 2",
        hintText: "Start typing...",
        autoComplete: AutoCompleteBuilder(
            initialOptions: [
              AutoCompleteOption(value: "Apple"),
              AutoCompleteOption(value: "Banana"),
              AutoCompleteOption(value: "Cherry"),
              AutoCompleteOption(value: "Date"),
              AutoCompleteOption(value: "Fig"),
              AutoCompleteOption(value: "Grape"),
            ],
            // Simple filtering on initial options
            updateOptions: (searchValue) async {
              return [
                AutoCompleteOption(value: "Apple"),
                AutoCompleteOption(value: "Banana"),
                AutoCompleteOption(value: "Cherry"),
                AutoCompleteOption(value: "Date"),
                AutoCompleteOption(value: "Fig"),
                AutoCompleteOption(value: "Grape"),
              ]
                  .where((opt) => opt.value
                      .toLowerCase()
                      .contains(searchValue.toLowerCase()))
                  .toList();
            }),
      )
    ];

    // --- Building the UI ---
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Use SingleChildScrollView for long forms
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0), // Add padding around the form
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // --- ChampionForm Widget ---
              ChampionForm(
                // theme: specificTheme, // Optionally override the global theme here
                controller: controller,
                spacing: 12, // Spacing between fields
                fieldPadding: const EdgeInsets.symmetric(
                    vertical: 8.0), // Padding *within* each field layout
                fields: fields,
              ),
              const SizedBox(height: 20),
              // --- Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: _setValuesProgrammatically,
                      child: const Text("Set Values")),
                  ElevatedButton(
                      onPressed: _executeLogin, // Trigger submission/validation
                      child: const Text("Submit Form")),
                ],
              )
            ],
          ),
        ),
      ),
      // Floating action button removed for clarity, using ElevatedButton instead.
    );
  }
}
