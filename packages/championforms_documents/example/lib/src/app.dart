import 'package:flutter/material.dart';

import 'draft_storage.dart';
import 'home_page.dart';
import 'templates.dart';

/// The Agreement Builder: Material 3, light and dark.
class AgreementBuilderApp extends StatefulWidget {
  const AgreementBuilderApp({
    super.key,
    this.storage,
    this.library,
    this.initialTemplateId = 'service_agreement',
  });

  /// Where Save / Load keep the draft (default: a file, or memory on web).
  final DraftStorage? storage;

  /// Preloaded templates (tests); loaded from the assets when null.
  final TemplateLibrary? library;

  final String initialTemplateId;

  @override
  State<AgreementBuilderApp> createState() => _AgreementBuilderAppState();
}

class _AgreementBuilderAppState extends State<AgreementBuilderApp> {
  static const _seed = Color(0xFF2E5AAC);

  ThemeMode _mode = ThemeMode.light;
  late final DraftStorage _storage = widget.storage ?? defaultDraftStorage();
  late final Future<TemplateLibrary> _library = widget.library != null
      ? Future.value(widget.library)
      : TemplateLibrary.load();

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agreement Builder',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _mode,
      home: FutureBuilder<TemplateLibrary>(
        future: _library,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text('Could not load templates: ${snapshot.error}'),
              ),
            );
          }
          final library = snapshot.data;
          if (library == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return HomePage(
            library: library,
            storage: _storage,
            initialTemplateId: widget.initialTemplateId,
            dark: _mode == ThemeMode.dark,
            onToggleTheme: () => setState(
              () => _mode = _mode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          );
        },
      ),
    );
  }
}
