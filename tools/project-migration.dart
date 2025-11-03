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

  MigrationConfig({
    required this.projectPath,
    this.dryRun = false,
    this.noBackup = false,
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
      final newContent = _migrateContent(content);

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
  String _migrateContent(String content) {
    String result = content;

    // Step 1: Update import statements
    result = _updateImports(result);

    // Step 2: Replace class names with namespace prefix
    result = _replaceClassNames(result);

    return result;
  }

  /// Update import statements to use namespace
  String _updateImports(String content) {
    // Check if already has namespace
    if (content.contains(
            "import 'package:championforms/championforms.dart' as form;") ||
        content.contains(
            'import "package:championforms/championforms.dart" as form;')) {
      return content;
    }

    // Replace single-quoted import
    content = content.replaceAll(
      "import 'package:championforms/championforms.dart';",
      "import 'package:championforms/championforms.dart' as form;",
    );

    // Replace double-quoted import
    content = content.replaceAll(
      'import "package:championforms/championforms.dart";',
      'import "package:championforms/championforms.dart" as form;',
    );

    return content;
  }

  /// Replace class names with namespace prefix
  String _replaceClassNames(String content) {
    String result = content;

    // Map of old class names to new names (with form. prefix)
    final classReplacements = {
      // Field types
      'ChampionTextField': 'form.TextField',
      'ChampionOptionSelect': 'form.OptionSelect',
      'ChampionFileUpload': 'form.FileUpload',
      'ChampionCheckboxSelect': 'form.CheckboxSelect',
      'ChampionChipSelect': 'form.ChipSelect',

      // Layout classes
      'ChampionRow': 'form.Row',
      'ChampionColumn': 'form.Column',

      // Form classes
      'ChampionForm': 'form.Form',
      'ChampionFormController': 'form.FormController',

      // Base classes
      'ChampionFormElement': 'form.FormElement',
      'FormFieldBase': 'form.FieldBase',
      'FormFieldDef': 'form.Field',
      'FormFieldNull': 'form.NullField',

      // Internal classes
      'ChampionAutocompleteWrapper': 'form.AutocompleteWrapper',
      'ChampionFormFieldRegistry': 'form.FormFieldRegistry',
    };

    // Process each replacement
    for (final entry in classReplacements.entries) {
      final oldName = entry.key;
      final newName = entry.value;

      // Use word boundary to avoid partial matches
      final pattern = RegExp('\\b$oldName\\b');

      // Replace outside of strings and comments
      result = _replaceOutsideStringsAndComments(result, pattern, newName);
    }

    // Special handling for theme classes (no namespace prefix)
    result = _replaceThemeClasses(result);

    return result;
  }

  /// Replace theme classes (these don't use form. namespace)
  String _replaceThemeClasses(String content) {
    // ChampionFormTheme → FormTheme (without namespace)
    final pattern = RegExp(r'\bChampionFormTheme\b');
    return _replaceOutsideStringsAndComments(content, pattern, 'FormTheme');
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

/// Parse command line arguments
MigrationConfig? parseArguments(List<String> args) {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return null;
  }

  String? projectPath;
  bool dryRun = false;
  bool noBackup = false;

  for (final arg in args) {
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--no-backup') {
      noBackup = true;
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
  --help, -h        Show this help message

Examples:
  dart run tools/project-migration.dart /path/to/my/project
  dart run tools/project-migration.dart /path/to/my/project --dry-run
  dart run tools/project-migration.dart . --dry-run

What this script does:
  1. Scans your project for .dart files using ChampionForms
  2. Updates import statements to use namespace (as form)
  3. Replaces Champion-prefixed classes with new names
  4. Creates backup files before modifications (unless --no-backup)
  5. Generates a summary report of changes

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
