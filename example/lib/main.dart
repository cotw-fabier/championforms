import 'package:championforms/championforms.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  late ChampionFormController controller;

  @override
  void initState() {
    super.initState();
    controller = ChampionFormController();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  void _executeLogin() {
    // Because championforms relies on riverpod. Field results
    // are accessible anywhere in the app as long as the form is still active.
    // You can simply build the FormResults object at any time to cause the form
    // to pass results and run validation.
    final FormResults results = FormResults.getResults(controller: controller);

    // Once run the form will tell you if it is in an error state.
    // If true, then stop processing.
    final errors = results.errorState;
    debugPrint("Current Error State is: $errors");
    if (errors == false) {
      // No errors, excellent!
      // Fields can be "grabbed" from the results by their ID.
      // Then you can format them .asString(), asStringList(), asMultiSelectList()
      debugPrint(results.grab("Email").asString());
      debugPrint(results.grab("DropdownField").asString());
      debugPrint(results
          .grab("SelectBox")
          .asMultiselectList()
          .map((field) => field.value)
          .join(", "));
    } else {
      debugPrint("The form had some errors.");
      debugPrint(results.formErrors
          .map((error) =>
              "Field ${error.fieldId} had the error: ${error.reason}")
          .join(", "));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Time to build a sample form:
    final List<FormFieldBase> fields = [
      ChampionTextField(
        id: "Email", // To ID the field, must be unique per form
        validateLive:
            true, // This causes the field to validate itself as soon as it loses focus -- defaults to false.
        maxLines: 1, // Forces field to one line
        hintText: "Email", // Hint text in the text field
        textFieldTitle:
            "Email", // This is the title which displays in the field until you click on it, then moves to the border
        description:
            "Enter your email Address", // Description by default displays above the field below the title
        // Validators are a list of FormBuilderValidator objects which run a bool function on the results to determine if the input is satisfactory.
        // Default validators are provided in the DefaultValidators() object. The most important one there is the dependency on valid emails.
        // If a field isn't valid, then the field state is set to error causing the colors to change and the error is displayed (by default) below the field in errorBorder color.
        validators: [
          FormBuilderValidator(
            validator: (results) => DefaultValidators().isEmpty(results),
            reason: "Field is empty",
          ),
          FormBuilderValidator(
            validator: (results) => DefaultValidators().isEmail(results),
            reason: "This isn't an email address",
          ),
        ],
        // Leading icon. Can make clickable with MouseRegion, and GestureDetector
        leading: const Icon(Icons.verified_user),
      ),
      ChampionTextField(
          id: "Text Field 1",
          textFieldTitle: "Password",
          maxLines: 1,
          password: true, // Password being true obscures the text in the field
          validateLive: true,

          // The onSubmit will fire when the user presses enter.
          // If maxLines is null or set to a larger number then onSubmit will fire on enter and
          // new line will be triggered on shift + enter.
          // If no onSubmit is present, then enter will add a new line as normal.
          onSubmit: (results) => debugPrint("Login"),
          validators: [
            FormBuilderValidator(
                validator: (results) => DefaultValidators().isEmpty(results),
                reason: "Password is Empty"),
          ],
          leading: const Icon(Icons.password)),

      // Champion option fields utilize a builder to handle the elements in the field.
      // Currently, this is the base implementation which spits out a Dropdown.
      // The setup should work for any multi-select object being used.
      // Custom builders can be inserted via the fieldBuilder property.
      // See the widgets_external/field_builders/checkboxfield_builder.dart file for details
      // on constructing your own custom builder.
      ChampionOptionSelect(
          id: "DropdownField", // ID can be anything but should be unique
          title: "Quick Dropdown",
          // MultiselectOption by default will pass through the label and value when the form is submitted.
          // However the additionalData property will accept any object? allowing you to pass through any element you desire to the formResults.
          options: [
            MultiselectOption(
              label: "Option 1",
              value: "Value 1",
            ),
            MultiselectOption(
              label: "Option 2",
              value: "Value 2",
            ),
            MultiselectOption(
              label: "Option 3",
              value: "Value 3",
            ),
            MultiselectOption(
              label: "Option 4",
              value: "Value 4",
            ),
          ]),
      // ChampionCheckboxSelect extends ChampionOptionSelect simply swapping out the fieldBuilder
      // For one which displays the options as checkboxes.
      ChampionCheckboxSelect(
        id: "SelectBox",
        requestFocus: true,
        multiselect: true,
        validateLive: true,
        validators: [
          FormBuilderValidator(
              validator: (results) => DefaultValidators().isEmpty(results),
              reason: "Nothing is checked"),
        ],

        title: "Choose your weapon",
        //defaultValue: ["Hiya"],icon: const Icon(Icons.title),
        leading: const MouseRegion(
            cursor: SystemMouseCursors.click, child: Icon(Icons.mic)),
        trailing: const Icon(Icons.search),

        options: [
          MultiselectOption(value: "Hi", label: "Hello"),
          MultiselectOption(value: "Hiya", label: "Wat"),
          MultiselectOption(value: "Yoz", label: "Sup"),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Champion Forms Example"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // The ChampionForm widget actually displays a form.
            // Throw in the fields defined above.
            // The ID keeps forms seperate when pulling results.
            // If two forms have the same ID and different fields, then all fields
            // will appear in the results when the form is evaluated.
            ChampionForm(
              theme: softBlueColorTheme(context),
              controller: controller,
              spacing: 10,
              fields: fields,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _executeLogin,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
