#!/usr/bin/env dart

/// Test suite for the ChampionForms migration script
///
/// This script tests the migration tool by:
/// 1. Creating test projects with various scenarios
/// 2. Running the migration script on them
/// 3. Verifying the results
/// 4. Testing dry-run mode, error handling, and backup restoration

import 'dart:io';

class MigrationTestRunner {
  final String toolsDir = '/Users/fabier/Documents/code/championforms/tools';
  final String testProjectsDir =
      '/Users/fabier/Documents/code/championforms/tools/test_projects';
  final String migrationScript =
      '/Users/fabier/Documents/code/championforms/tools/project-migration.dart';

  int testsRun = 0;
  int testsPassed = 0;
  int testsFailed = 0;
  final List<String> failedTests = [];

  /// Run all migration tests
  Future<void> runAllTests() async {
    print('ChampionForms Migration Script Test Suite');
    print('=' * 60);
    print('');

    await testSimpleProjectMigration();
    await testComplexProjectMigration();
    await testEdgeCasesMigration();
    await testDryRunMode();
    await testErrorHandling();
    await testBackupCreation();
    await testAlreadyMigratedProject();
    await testNoChampionFormsImport();

    _printSummary();
  }

  /// Test 5.3.2: Test basic functionality
  Future<void> testSimpleProjectMigration() async {
    print('Test 5.3.2: Simple Project Migration');
    print('-' * 60);

    final testDir = '$testProjectsDir/simple';

    try {
      // Run migration script
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Simple migration failed with exit code ${result.exitCode}');
        print('STDERR: ${result.stderr}');
        return;
      }

      // Verify import was updated
      final file = File('$testDir/simple_form.dart');
      final content = await file.readAsString();

      _assert(
        content.contains(
            "import 'package:championforms/championforms.dart' as form;"),
        'Import statement should use namespace alias',
      );

      // Verify class names were replaced
      _assert(
        content.contains('form.FormController'),
        'ChampionFormController should be replaced with form.FormController',
      );

      _assert(
        content.contains('form.Form'),
        'ChampionForm should be replaced with form.Form',
      );

      _assert(
        content.contains('form.TextField'),
        'ChampionTextField should be replaced with form.TextField',
      );

      _assert(
        content.contains('form.Row'),
        'ChampionRow should be replaced with form.Row',
      );

      // Verify old class names are gone
      _assert(
        !content.contains('ChampionFormController'),
        'Old class name ChampionFormController should not exist',
      );

      _assert(
        !content.contains('ChampionForm('),
        'Old class name ChampionForm should not exist',
      );

      // Verify backup was created
      final backupDir = Directory('$testDir/backups');
      _assert(
        await backupDir.exists(),
        'Backup directory should be created',
      );

      print('✓ Simple project migration test passed\n');
      _pass();
    } catch (e) {
      _fail('Simple migration test error: $e');
    }
  }

  /// Test 5.3.3: Test complex scenarios
  Future<void> testComplexProjectMigration() async {
    print('Test 5.3.3: Complex Project Migration');
    print('-' * 60);

    final testDir = '$testProjectsDir/complex';

    try {
      // Run migration script
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Complex migration failed with exit code ${result.exitCode}');
        return;
      }

      final file = File('$testDir/complex_form.dart');
      final content = await file.readAsString();

      // Verify multiple controllers
      _assert(
        content.contains('form.FormController'),
        'Multiple controllers should be migrated',
      );

      // Verify generic types updated
      _assert(
        content.contains('List<form.FormElement>'),
        'Generic type List<ChampionFormElement> should be updated',
      );

      _assert(
        content.contains('form.FormElement?'),
        'Optional generic type should be updated',
      );

      // Verify all field types
      _assert(
        content.contains('form.TextField'),
        'TextField should be migrated',
      );

      _assert(
        content.contains('form.OptionSelect'),
        'OptionSelect should be migrated',
      );

      _assert(
        content.contains('form.CheckboxSelect'),
        'CheckboxSelect should be migrated',
      );

      _assert(
        content.contains('form.ChipSelect'),
        'ChipSelect should be migrated',
      );

      _assert(
        content.contains('form.FileUpload'),
        'FileUpload should be migrated',
      );

      // Verify layout classes
      _assert(
        content.contains('form.Row'),
        'Row should be migrated',
      );

      _assert(
        content.contains('form.Column'),
        'Column should be migrated',
      );

      // Verify FormFieldRegistry
      _assert(
        content.contains('form.FormFieldRegistry'),
        'FormFieldRegistry should be migrated',
      );

      print('✓ Complex project migration test passed\n');
      _pass();
    } catch (e) {
      _fail('Complex migration test error: $e');
    }
  }

  /// Test 5.3.4: Test edge cases
  Future<void> testEdgeCasesMigration() async {
    print('Test 5.3.4: Edge Cases Migration');
    print('-' * 60);

    final testDir = '$testProjectsDir/edge_cases';

    try {
      // Run migration script
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Edge cases migration failed with exit code ${result.exitCode}');
        return;
      }

      final file = File('$testDir/edge_cases_form.dart');
      final content = await file.readAsString();

      // Verify comments preserved
      _assert(
        content.contains('// Another comment mentioning ChampionTextField'),
        'Comments with Champion names should be preserved',
      );

      _assert(
        content.contains('* Mentioning ChampionFormController'),
        'Multi-line comments should be preserved',
      );

      // Verify string literals not modified
      _assert(
        content.contains("'This is a ChampionForm example'"),
        'String literals should not be modified',
      );

      _assert(
        content.contains('"Using ChampionTextField for input"'),
        'Double-quoted string literals should not be modified',
      );

      // Verify multi-line strings not modified
      _assert(
        content.contains('ChampionRow and ChampionColumn classes but'),
        'Multi-line strings should not be modified',
      );

      // Verify variable names not affected
      _assert(
        content.contains('championFormTitle'),
        'Variable names containing "champion" should not be affected',
      );

      _assert(
        content.contains('myChampionController'),
        'Variable names containing "Champion" should not be affected',
      );

      // Verify code was actually migrated
      _assert(
        content.contains('form.FormController'),
        'Actual code should be migrated',
      );

      _assert(
        content.contains('form.Form('),
        'Form widget should be migrated',
      );

      // Verify generic types updated
      _assert(
        content.contains('List<form.FormElement>'),
        'Generic types should be updated',
      );

      _assert(
        content.contains('Map<String, form.TextField>'),
        'Map generic types should be updated',
      );

      _assert(
        content.contains('Future<List<form.Field>>'),
        'FormFieldDef should be updated to Field',
      );

      _assert(
        content.contains('Set<form.FieldBase>'),
        'FormFieldBase should be updated to FieldBase',
      );

      print('✓ Edge cases migration test passed\n');
      _pass();
    } catch (e) {
      _fail('Edge cases test error: $e');
    }
  }

  /// Test 5.3.5: Test dry-run mode
  Future<void> testDryRunMode() async {
    print('Test 5.3.5: Dry-Run Mode');
    print('-' * 60);

    // Create a test file for dry-run
    final testDir = '$testProjectsDir/dryrun_test';
    await Directory(testDir).create(recursive: true);

    final testFile = File('$testDir/test.dart');
    const originalContent = '''
import 'package:championforms/championforms.dart';

class Test {
  ChampionFormController controller = ChampionFormController();
}
''';

    await testFile.writeAsString(originalContent);

    try {
      // Run migration with --dry-run
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir, '--dry-run'],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Dry-run failed with exit code ${result.exitCode}');
        return;
      }

      // Verify file was NOT modified
      final content = await testFile.readAsString();
      _assert(
        content == originalContent,
        'File should not be modified in dry-run mode',
      );

      // Verify output mentions dry-run
      _assert(
        result.stdout.toString().contains('DRY RUN'),
        'Output should mention dry-run mode',
      );

      _assert(
        result.stdout.toString().contains('Would modify'),
        'Output should show what would be modified',
      );

      // Verify no backup directory created
      final backupDir = Directory('$testDir/backups');
      _assert(
        !await backupDir.exists(),
        'Backup directory should not be created in dry-run mode',
      );

      print('✓ Dry-run mode test passed\n');
      _pass();

      // Cleanup
      await Directory(testDir).delete(recursive: true);
    } catch (e) {
      _fail('Dry-run test error: $e');
    }
  }

  /// Test 5.3.6: Test error handling
  Future<void> testErrorHandling() async {
    print('Test 5.3.6: Error Handling');
    print('-' * 60);

    try {
      // Test with non-existent directory
      final result1 = await Process.run(
        'dart',
        ['run', migrationScript, '/nonexistent/path'],
        workingDirectory: toolsDir,
      );

      _assert(
        result1.exitCode != 0,
        'Should fail with non-existent directory',
      );

      _assert(
        result1.stdout.toString().contains('ERROR'),
        'Should show error message for non-existent directory',
      );

      // Test with no arguments
      final result2 = await Process.run(
        'dart',
        ['run', migrationScript],
        workingDirectory: toolsDir,
      );

      _assert(
        result2.exitCode != 0,
        'Should fail with no arguments',
      );

      // Test with --help
      final result3 = await Process.run(
        'dart',
        ['run', migrationScript, '--help'],
        workingDirectory: toolsDir,
      );

      _assert(
        result3.stdout.toString().contains('Usage:'),
        'Should show usage with --help',
      );

      print('✓ Error handling test passed\n');
      _pass();
    } catch (e) {
      _fail('Error handling test error: $e');
    }
  }

  /// Test 5.3.7 & 5.3.8: Test backup creation and restoration
  Future<void> testBackupCreation() async {
    print('Test 5.3.7 & 5.3.8: Backup Creation and Restoration');
    print('-' * 60);

    final testDir = '$testProjectsDir/backup_test';
    await Directory(testDir).create(recursive: true);

    final testFile = File('$testDir/test.dart');
    const originalContent = '''
import 'package:championforms/championforms.dart';

class BackupTest {
  ChampionFormController controller = ChampionFormController();
}
''';

    await testFile.writeAsString(originalContent);

    try {
      // Run migration
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Backup test migration failed');
        return;
      }

      // Verify backup file exists
      final backupFile = File('$testDir/backups/test.dart.backup');
      _assert(
        await backupFile.exists(),
        'Backup file should exist',
      );

      // Verify backup contains original content
      final backupContent = await backupFile.readAsString();
      _assert(
        backupContent == originalContent,
        'Backup should contain original content',
      );

      // Verify original file was modified
      final modifiedContent = await testFile.readAsString();
      _assert(
        modifiedContent != originalContent,
        'Original file should be modified',
      );

      _assert(
        modifiedContent.contains('form.FormController'),
        'Modified file should have new class names',
      );

      // Test restoration
      await testFile.writeAsString(backupContent);
      final restoredContent = await testFile.readAsString();
      _assert(
        restoredContent == originalContent,
        'File should be restorable from backup',
      );

      print('✓ Backup creation and restoration test passed\n');
      _pass();

      // Cleanup
      await Directory(testDir).delete(recursive: true);
    } catch (e) {
      _fail('Backup test error: $e');
    }
  }

  /// Test already migrated project
  Future<void> testAlreadyMigratedProject() async {
    print('Test: Already Migrated Project');
    print('-' * 60);

    final testDir = '$testProjectsDir/already_migrated';
    await Directory(testDir).create(recursive: true);

    final testFile = File('$testDir/test.dart');
    const migratedContent = '''
import 'package:championforms/championforms.dart' as form;

class AlreadyMigrated {
  form.FormController controller = form.FormController();
}
''';

    await testFile.writeAsString(migratedContent);

    try {
      // Run migration on already migrated project
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Migration on already migrated project failed');
        return;
      }

      // Verify file was not changed
      final content = await testFile.readAsString();
      _assert(
        content == migratedContent,
        'Already migrated file should not be changed',
      );

      // Verify output mentions no changes
      _assert(
        result.stdout.toString().contains('No changes needed'),
        'Output should mention no changes needed',
      );

      print('✓ Already migrated project test passed\n');
      _pass();

      // Cleanup
      await Directory(testDir).delete(recursive: true);
    } catch (e) {
      _fail('Already migrated test error: $e');
    }
  }

  /// Test files without championforms import
  Future<void> testNoChampionFormsImport() async {
    print('Test: No ChampionForms Import');
    print('-' * 60);

    final testDir = '$testProjectsDir/no_import';
    await Directory(testDir).create(recursive: true);

    final testFile = File('$testDir/test.dart');
    const noImportContent = '''
import 'package:flutter/material.dart';

class NoImport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''';

    await testFile.writeAsString(noImportContent);

    try {
      // Run migration
      final result = await Process.run(
        'dart',
        ['run', migrationScript, testDir],
        workingDirectory: toolsDir,
      );

      if (result.exitCode != 0) {
        _fail('Migration failed on file without championforms import');
        return;
      }

      // Verify file was not changed
      final content = await testFile.readAsString();
      _assert(
        content == noImportContent,
        'File without championforms import should not be changed',
      );

      // Verify file was skipped
      _assert(
        result.stdout.toString().contains('Files skipped: 1'),
        'File should be counted as skipped',
      );

      print('✓ No ChampionForms import test passed\n');
      _pass();

      // Cleanup
      await Directory(testDir).delete(recursive: true);
    } catch (e) {
      _fail('No import test error: $e');
    }
  }

  /// Assert helper
  void _assert(bool condition, String message) {
    if (!condition) {
      throw AssertionError(message);
    }
  }

  /// Mark test as passed
  void _pass() {
    testsRun++;
    testsPassed++;
  }

  /// Mark test as failed
  void _fail(String message) {
    testsRun++;
    testsFailed++;
    failedTests.add(message);
    print('✗ Test failed: $message\n');
  }

  /// Print test summary
  void _printSummary() {
    print('');
    print('=' * 60);
    print('Migration Test Suite Summary');
    print('=' * 60);
    print('Tests run: $testsRun');
    print('Tests passed: $testsPassed');
    print('Tests failed: $testsFailed');

    if (failedTests.isNotEmpty) {
      print('\nFailed tests:');
      for (final test in failedTests) {
        print('  - $test');
      }
    }

    print('=' * 60);

    if (testsFailed == 0) {
      print('\n✓ All tests passed!');
      exit(0);
    } else {
      print('\n✗ Some tests failed.');
      exit(1);
    }
  }
}

Future<void> main() async {
  final runner = MigrationTestRunner();
  await runner.runAllTests();
}
