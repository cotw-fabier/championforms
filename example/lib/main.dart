import 'package:championforms/championforms.dart';
import 'package:championforms/functions/defaultvalidators/defaultvalidators.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/providers/multiselect_provider.dart';
import 'package:championforms/widgets_external/championform.dart';
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;

      final FormResults results =
          FormResults.getResults(ref: ref, formId: "myForm");
      final errors = results.errorState;
      debugPrint("Current Error State is: $errors");
      if (errors) {
        debugPrint(results.formErrors.map((error) => error.reason).join(", "));
      }
      debugPrint(results.grab("Text Field").asString());
      debugPrint(results.grab("Dropdown").asString());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Time to build a sample form:
    final List<FormFieldDef> fields = [
      ChampionTextField(
        id: "Text Field",
        validateLive: true,
        maxLines: 1,
        hintText: "Type here",
        title: "My field",
        textFieldTitle: "My Field",
        description: "Fill in this field for glory",
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
      ),
      ChampionTextField(
        id: "Text Field 1",
        maxLines: 1,
        trailing: const Icon(Icons.search),
      ),
      ChampionCheckboxSelect(
        id: "Dropdown",
        requestFocus: true,
        multiselect: true,

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

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ChampionForm(
              theme: softBlueColorTheme(context),
              id: "myForm",
              spacing: 10,
              fields: fields,
            ),
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
