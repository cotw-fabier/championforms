#!/usr/bin/env dart

/// ChampionForms Migration Tool v0.4.0
///
/// Automated migration script to update projects from ChampionForms v0.3.x to v0.4.0
///
/// This script:
/// - Updates import statements to use namespace approach
/// - Replaces all Champion-prefixed class names with new names
/// - Creates backup files before modifications
/// - Provides dry-run mode for preview
///
/// Usage:
///   dart run tools/project-migration.dart /path/to/your/project
///   dart run tools/project-migration.dart /path/to/your/project --dry-run
///   dart run tools/project-migration.dart --help

import 'dart:io';

/// Configuration class for migration options
class MigrationConfig {
  final String projectPath;
  final bool dryRun;
  final bool noBackup;
  final String namespace;

  MigrationConfig({
    required this.projectPath,
    this.dryRun = false,
    this.noBackup = false,
    this.namespace = 'form',
  });
}

/// Statistics for migration summary
class MigrationStats {
  int filesScanned = 0;
  int filesModified = 0;
  int filesSkipped = 0;
  int backupsCreated = 0;
  final List<String> modifiedFiles = [];
  final List<String> errors = [];

  void addModification(String filePath) {
    filesModified++;
    modifiedFiles.add(filePath);
  }

  void addError(String error) {
    errors.add(error);
  }
}

/// Main migration orchestrator
class ChampionFormsMigrator {
  final MigrationConfig config;
  final MigrationStats stats = MigrationStats();

  /// Directories to exclude from scanning
  static const excludeDirs = {
    'build',
    '.dart_tool',
    '.git',
    '.idea',
    '.vscode',
    'ios',
    'android',
    'windows',
    'macos',
    'linux',
    'web',
  };

  /// File patterns to exclude
  static const excludePatterns = [
    '.g.dart',
    '.freezed.dart',
    '.gr.dart',
  ];

  ChampionFormsMigrator(this.config);

  /// Main migration entry point
  Future<void> migrate() async {
    print('ChampionForms Migration Tool v0.4.0');
    print('=' * 50);
    print('Scanning: ${config.projectPath}');

    if (config.dryRun) {
      print('DRY RUN MODE - No files will be modified');
    }

    if (config.noBackup && !config.dryRun) {
      print('WARNING: Running without backups');
    }

    print('=' * 50);
    print('');

    final projectDir = Directory(config.projectPath);
    if (!await projectDir.exists()) {
      print('ERROR: Directory does not exist: ${config.projectPath}');
      exit(1);
    }

    // Find all Dart files
    final dartFiles = await _scanForDartFiles(projectDir);
    stats.filesScanned = dartFiles.length;

    print('Found ${dartFiles.length} Dart files to analyze\n');

    if (dartFiles.isEmpty) {
      print('No Dart files found in the project.');
      return;
    }

    // Process each file
    for (final file in dartFiles) {
      await _processFile(file);
    }

    // Print summary
    _printSummary();
  }

  /// Scan directory recursively for Dart files
  Future<List<File>> _scanForDartFiles(Directory dir) async {
    final dartFiles = <File>[];

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Check if file should be excluded
        final pathParts = entity.path.split(Platform.pathSeparator);

        // Skip if in excluded directory
        if (pathParts.any((part) => excludeDirs.contains(part))) {
          continue;
        }

        // Skip if matches excluded pattern
        if (excludePatterns.any((pattern) => entity.path.endsWith(pattern))) {
          continue;
        }

        dartFiles.add(entity);
      }
    }

    return dartFiles;
  }

  /// Process a single Dart file
  Future<void> _processFile(File file) async {
    try {
      final content = await file.readAsString();

      // Check if file imports championforms
      if (!_hasChampionFormsImport(content)) {
        stats.filesSkipped++;
        return;
      }

      // Perform migrations
      final newContent = _migrateContent(content, config.namespace);

      // Check if content changed
      if (newContent == content) {
        stats.filesSkipped++;
        print('○ ${_relativePath(file.path)} - No changes needed');
        return;
      }

      // Create backup if not in dry-run and backups are enabled
      if (!config.dryRun && !config.noBackup) {
        await _createBackup(file);
        stats.backupsCreated++;
      }

      // Write new content if not dry-run
      if (!config.dryRun) {
        await file.writeAsString(newContent);
        print('✓ ${_relativePath(file.path)} - Modified');
      } else {
        print('✓ ${_relativePath(file.path)} - Would modify');
      }

      stats.addModification(_relativePath(file.path));
    } catch (e) {
      final error = 'Error processing ${_relativePath(file.path)}: $e';
      stats.addError(error);
      print('✗ $error');
    }
  }

  /// Check if content imports championforms
  bool _hasChampionFormsImport(String content) {
    return content.contains('package:championforms/championforms.dart');
  }

  /// Migrate file content
  String _migrateContent(String content, String namespace) {
    String result = content;

    // Step 1: Update import statements
    result = _updateImports(result, namespace);

    // Step 2: Replace class names with namespace prefix
    result = _replaceClassNames(result, namespace);

    return result;
  }

  /// Update import statements to use namespace
  String _updateImports(String content, String namespace) {
    // Check if already has namespace
    if (content.contains(
            "import 'package:championforms/championforms.dart' as $namespace;") ||
        content.contains(
            'import "package:championforms/championforms.dart" as $namespace;')) {
      return content;
    }

    // Replace single-quoted import
    content = content.replaceAll(
      "import 'package:championforms/championforms.dart';",
      "import 'package:championforms/championforms.dart' as $namespace;",
    );

    // Replace double-quoted import
    content = content.replaceAll(
      'import "package:championforms/championforms.dart";',
      'import "package:championforms/championforms.dart" as $namespace;',
    );

    return content;
  }

  /// Replace class names with namespace prefix
  String _replaceClassNames(String content, String namespace) {
    String result = content;

    // Map of old class names to new names (without namespace prefix)
    final classReplacements = {
      // Field types
      'ChampionTextField': 'TextField',
      'ChampionOptionSelect': 'OptionSelect',
      'ChampionFileUpload': 'FileUpload',
      'ChampionCheckboxSelect': 'CheckboxSelect',
      'ChampionChipSelect': 'ChipSelect',

      // Layout classes
      'ChampionRow': 'Row',
      'ChampionColumn': 'Column',

      // Form classes
      'ChampionForm': 'Form',
      'ChampionFormController': 'FormController',

      // Base classes
      'ChampionFormElement': 'FormElement',
      'FormFieldBase': 'FieldBase',
      'FormFieldDef': 'Field',
      'FormFieldNull': 'NullField',

      // Internal classes
      'ChampionAutocompleteWrapper': 'AutocompleteWrapper',
      'ChampionFormFieldRegistry': 'FormFieldRegistry',

      // Validators
      'FormBuilderValidator': 'Validator',
      'DefaultValidators': 'Validators',

      // Options
      'MultiselectOption': 'FieldOption',
      'AutoCompleteOption': 'CompleteOption',
    };

    // Process each replacement
    for (final entry in classReplacements.entries) {
      final oldName = entry.key;
      final newName = '$namespace.${entry.value}';

      // Use word boundary to avoid partial matches
      final pattern = RegExp('\\b$oldName\\b');

      // Replace outside of strings and comments
      result = _replaceOutsideStringsAndComments(result, pattern, newName);
    }

    // Special handling for theme classes (no namespace prefix)
    result = _replaceThemeClasses(result);

    // Remove Validators instantiation (change to static usage)
    result = _removeValidatorsInstantiation(result, namespace);

    return result;
  }

  /// Replace theme classes (these don't use form. namespace)
  String _replaceThemeClasses(String content) {
    // ChampionFormTheme → FormTheme (without namespace)
    final pattern = RegExp(r'\bChampionFormTheme\b');
    return _replaceOutsideStringsAndComments(content, pattern, 'FormTheme');
  }

  /// Remove Validators() instantiation for static method usage
  /// Changes namespace.Validators() to namespace.Validators (static class reference)
  String _removeValidatorsInstantiation(String content, String namespace) {
    // Pattern: namespace.Validators() → namespace.Validators
    // This handles both standalone and chained usage:
    // - namespace.Validators().isEmail(r) → namespace.Validators.isEmail(r)
    // - namespace.Validators() → namespace.Validators
    final pattern = RegExp('$namespace\\.Validators\\(\\)');
    return _replaceOutsideStringsAndComments(content, pattern, '$namespace.Validators');
  }

  /// Replace pattern outside of strings and comments
  String _replaceOutsideStringsAndComments(
    String content,
    RegExp pattern,
    String replacement,
  ) {
    final buffer = StringBuffer();
    var position = 0;

    // Track if we're inside a string or comment
    bool isInString = false;
    bool isInSingleQuote = false;
    bool isInDoubleQuote = false;
    bool isInTripleQuote = false;
    bool isInComment = false;
    bool isInMultiLineComment = false;

    while (position < content.length) {
      // Check for comment start
      if (!isInString && position + 1 < content.length) {
        if (content.substring(position, position + 2) == '//') {
          isInComment = true;
          buffer.write('//');
          position += 2;
          continue;
        } else if (content.substring(position, position + 2) == '/*') {
          isInMultiLineComment = true;
          buffer.write('/*');
          position += 2;
          continue;
        }
      }

      // Check for comment end
      if (isInComment && content[position] == '\n') {
        isInComment = false;
        buffer.write('\n');
        position++;
        continue;
      }

      if (isInMultiLineComment && position + 1 < content.length) {
        if (content.substring(position, position + 2) == '*/') {
          isInMultiLineComment = false;
          buffer.write('*/');
          position += 2;
          continue;
        }
      }

      // If in comment, just copy
      if (isInComment || isInMultiLineComment) {
        buffer.write(content[position]);
        position++;
        continue;
      }

      // Check for string delimiters
      if (position + 2 < content.length) {
        final threeChars = content.substring(position, position + 3);
        if (threeChars == "'''" || threeChars == '"""') {
          isInTripleQuote = !isInTripleQuote;
          isInString = isInTripleQuote;
          buffer.write(threeChars);
          position += 3;
          continue;
        }
      }

      if (!isInTripleQuote) {
        if (content[position] == "'" &&
            (position == 0 || content[position - 1] != '\\')) {
          isInSingleQuote = !isInSingleQuote;
          isInString = isInSingleQuote || isInDoubleQuote;
        } else if (content[position] == '"' &&
            (position == 0 || content[position - 1] != '\\')) {
          isInDoubleQuote = !isInDoubleQuote;
          isInString = isInSingleQuote || isInDoubleQuote;
        }
      }

      // If not in string or comment, try to match pattern
      if (!isInString && !isInComment && !isInMultiLineComment) {
        final match = pattern.matchAsPrefix(content, position);
        if (match != null) {
          buffer.write(replacement);
          position = match.end;
          continue;
        }
      }

      // Default: copy character
      buffer.write(content[position]);
      position++;
    }

    return buffer.toString();
  }

  /// Create backup file
  Future<void> _createBackup(File file) async {
    final backupDir = Directory('${config.projectPath}/backups');
    await backupDir.create(recursive: true);

    final relativePath = _relativePath(file.path);
    final backupPath = '${backupDir.path}/$relativePath.backup';
    final backupFile = File(backupPath);

    await backupFile.create(recursive: true);
    await file.copy(backupPath);
  }

  /// Get relative path from project root
  String _relativePath(String filePath) {
    final projectPath = config.projectPath;
    if (filePath.startsWith(projectPath)) {
      return filePath.substring(projectPath.length + 1);
    }
    return filePath;
  }

  /// Print migration summary
  void _printSummary() {
    print('\n' + '=' * 50);
    print('Migration Summary:');
    print('=' * 50);
    print('Files scanned: ${stats.filesScanned}');
    print('Files modified: ${stats.filesModified}');
    print('Files skipped: ${stats.filesSkipped}');

    if (!config.noBackup && !config.dryRun) {
      print('Backups created: ${stats.backupsCreated}');
      print('Backup location: ${config.projectPath}/backups/');
    }

    if (stats.errors.isNotEmpty) {
      print('\nErrors:');
      for (final error in stats.errors) {
        print('  - $error');
      }
    }

    print('=' * 50);

    if (config.dryRun) {
      print('\nDRY RUN complete. No files were modified.');
      print('Run without --dry-run to apply changes.');
    } else {
      print('\nMigration complete!');
      print('Please review changes and test your application.');

      if (!config.noBackup) {
        print('Backup files can be found in: backups/');
      }
    }
  }
}

/// Validate that a namespace is a valid Dart identifier
bool _isValidDartIdentifier(String namespace) {
  // Must start with letter or underscore, followed by alphanumeric or underscore
  final pattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
  return pattern.hasMatch(namespace);
}

/// Parse command line arguments
MigrationConfig? parseArguments(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return null;
  }

  String? projectPath;
  bool dryRun = false;
  bool noBackup = false;
  String namespace = 'form';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];

    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--no-backup') {
      noBackup = true;
    } else if (arg == '--namespace') {
      // Look ahead for namespace value
      if (i + 1 >= args.length) {
        print('ERROR: --namespace requires a value\n');
        _printUsage();
        return null;
      }
      namespace = args[i + 1];

      // Validate namespace is a valid Dart identifier
      if (!_isValidDartIdentifier(namespace)) {
        print('ERROR: Invalid namespace "$namespace"');
        print('Namespace must be a valid Dart identifier:');
        print('  - Start with a letter or underscore');
        print('  - Contain only letters, numbers, and underscores\n');
        _printUsage();
        return null;
      }

      i++; // Skip next arg since we consumed it as namespace value
    } else if (!arg.startsWith('--')) {
      projectPath = arg;
    }
  }

  if (projectPath == null) {
    print('ERROR: Project path is required\n');
    _printUsage();
    return null;
  }

  return MigrationConfig(
    projectPath: projectPath,
    dryRun: dryRun,
    noBackup: noBackup,
    namespace: namespace,
  );
}

/// Print usage instructions
void _printUsage() {
  print('''
ChampionForms Migration Tool v0.4.0

Migrates ChampionForms projects from v0.3.x to v0.4.0

Usage:
  dart run tools/project-migration.dart <project-path> [options]

Arguments:
  <project-path>    Path to your Flutter project directory

Options:
  --dry-run         Preview changes without modifying files
  --no-backup       Skip creating backup files (not recommended)
  --namespace <ns>  Use custom namespace alias (default: 'form')
                    Must be a valid Dart identifier
  --help, -h        Show this help message

Examples:
  dart run tools/project-migration.dart /path/to/my/project
  dart run tools/project-migration.dart /path/to/my/project --dry-run
  dart run tools/project-migration.dart . --dry-run
  dart run tools/project-migration.dart /path/to/my/project --namespace cf

What this script does:
  1. Scans your project for .dart files using ChampionForms
  2. Updates import statements to use namespace (default: 'as form')
  3. Replaces Champion-prefixed classes with new names
  4. Replaces model class names (with namespace prefix):
     - FormBuilderValidator → <namespace>.Validator
     - DefaultValidators → <namespace>.Validators
     - MultiselectOption → <namespace>.FieldOption
     - AutoCompleteOption → <namespace>.CompleteOption
  5. Converts Validators to static usage:
     - <namespace>.Validators() → <namespace>.Validators
     - <namespace>.Validators().isEmail() → <namespace>.Validators.isEmail()
  6. Creates backup files before modifications (unless --no-backup)
  7. Generates a summary report of changes

After migration:
  1. Review the changes
  2. Run 'flutter pub get'
  3. Run 'flutter analyze' to check for issues
  4. Test your application thoroughly
  5. If satisfied, delete backup files

For more information, see MIGRATION-0.4.0.md
''');
}

/// Main entry point
Future<void> main(List<String> args) async {
  final config = parseArguments(args);

  if (config == null) {
    exit(1);
  }

  final migrator = ChampionFormsMigrator(config);
  await migrator.migrate();
}
