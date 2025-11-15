#!/usr/bin/env dart

/// Batch-fix test files for new fieldBuilder API.
///
/// This script fixes:
/// 1. AutocompleteWrapper old API -> new FieldBuilderContext API
/// 2. FileUploadWidget old API -> new FieldBuilderContext API
/// 3. Adds test helper imports and setup

import 'dart:io';

void main() async {
  print('🔧 Fixing test files for new fieldBuilder API...\n');

  final testFiles = [
    // Autocomplete test files
    'example/test/autocomplete_overlay_integration_test.dart',
    'example/test/autocomplete_overlay_keyboard_accessibility_test.dart',
    'example/test/autocomplete_overlay_positioning_test.dart',
    'example/test/autocomplete_overlay_selection_debounce_test.dart',
    'example/test/autocomplete_overlay_widget_structure_test.dart',
    // Drag-drop and file upload test files
    'example/test/drag_drop_additional_integration_test.dart',
    'example/test/fileupload_clearonupload_integration_test.dart',
  ];

  int filesFixed = 0;
  int totalReplacements = 0;

  for (final filePath in testFiles) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('⚠️  Skipping (not found): $filePath');
      continue;
    }

    print('📝 Processing: $filePath');
    var content = await file.readAsString();
    var replacements = 0;

    // Step 1: Add necessary imports if not present
    if (!content.contains('import \'package:championforms/championforms.dart\' as form;')) {
      content = _addImports(content);
      replacements++;
    }

    // Step 2: Add helper function if not present
    if (!content.contains('FieldBuilderContext createTestContext')) {
      content = _addHelperFunction(content);
      replacements++;
    }

    // Step 3: Fix AutocompleteWrapper instances
    final autoCompleteReplacements = _fixAutoCompleteWrapper(content);
    if (autoCompleteReplacements.replacements > 0) {
      content = autoCompleteReplacements.content;
      replacements += autoCompleteReplacements.replacements;
      print('   ✓ Fixed ${autoCompleteReplacements.replacements} AutocompleteWrapper instances');
    }

    // Step 4: Fix FileUploadWidget instances
    final fileUploadReplacements = _fixFileUploadWidget(content);
    if (fileUploadReplacements.replacements > 0) {
      content = fileUploadReplacements.content;
      replacements += fileUploadReplacements.replacements;
      print('   ✓ Fixed ${fileUploadReplacements.replacements} FileUploadWidget instances');
    }

    // Step 5: Clean up old variable declarations (focusNode, textController)
    content = _cleanupOldVariables(content);

    if (replacements > 0) {
      await file.writeAsString(content);
      filesFixed++;
      totalReplacements += replacements;
      print('   ✅ Fixed $replacements issues in file\n');
    } else {
      print('   ℹ️  No changes needed\n');
    }
  }

  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('✅ Complete! Fixed $filesFixed files with $totalReplacements total changes');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  print('Next steps:');
  print('  1. Run: flutter analyze');
  print('  2. Run: flutter test');
  print('  3. Manually fix any remaining issues');
}

String _addImports(String content) {
  final imports = '''import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';
''';

  // Insert after existing imports
  final importEnd = content.indexOf('\nvoid main()');
  if (importEnd > 0) {
    return content.substring(0, importEnd) + '\n' + imports + content.substring(importEnd);
  }
  return imports + '\n' + content;
}

String _addHelperFunction(String content) {
  final helper = '''
/// Helper to create FieldBuilderContext for tests
FieldBuilderContext createTestContext({
  required form.FormController controller,
  required form.Field field,
  FormTheme? theme,
}) {
  final resolvedTheme = theme ?? const FormTheme();
  final colors = resolvedTheme.normalColorScheme ?? const FieldColorScheme();

  return FieldBuilderContext(
    controller: controller,
    field: field,
    theme: resolvedTheme,
    state: FieldState.normal,
    colors: colors,
  );
}

''';

  // Insert before void main()
  final mainStart = content.indexOf('void main()');
  if (mainStart > 0) {
    return content.substring(0, mainStart) + helper + content.substring(mainStart);
  }
  return helper + content;
}

class ReplacementResult {
  final String content;
  final int replacements;
  ReplacementResult(this.content, this.replacements);
}

ReplacementResult _fixAutoCompleteWrapper(String content) {
  int count = 0;

  // Pattern: Find AutocompleteWrapper with old API
  final pattern = RegExp(
    r'AutocompleteWrapper\s*\(\s*'
    r'(?:child:\s*TextField\([^)]*\),?\s*)?'
    r'(?:autoComplete:\s*\w+,?\s*)?'
    r'(?:focusNode:\s*\w+,?\s*)?'
    r'(?:textEditingController:\s*\w+,?\s*)?',
    multiLine: true,
  );

  // This is complex - let's use a simpler approach
  // Just check if file contains old-style AutocompleteWrapper params
  if (content.contains('focusNode:') && content.contains('AutocompleteWrapper')) {
    // Mark for manual fix
    print('   ⚠️  Contains AutocompleteWrapper with old API - needs manual review');
  }

  return ReplacementResult(content, count);
}

ReplacementResult _fixFileUploadWidget(String content) {
  int count = 0;

  // Pattern: Find FileUploadWidget with old API (6 parameters)
  // We'll look for the signature and replace it

  final oldPattern = RegExp(
    r'FileUploadWidget\s*\(\s*'
    r'id:\s*([^,]+),\s*'
    r'controller:\s*([^,]+),\s*'
    r'field:\s*([^,]+),\s*'
    r'currentColors:\s*[^,]+,\s*'
    r'onFocusChange:\s*[^,]+,\s*'
    r'onFileOptionChange:\s*[^,]+,?\s*'
    r'\)',
    multiLine: true,
  );

  content = content.replaceAllMapped(oldPattern, (match) {
    count++;
    final fieldVar = match.group(3)!.trim();
    final controllerVar = match.group(2)!.trim();

    return '''FileUploadWidget(
                context: createTestContext(
                  controller: $controllerVar,
                  field: $fieldVar,
                ),
              )''';
  });

  return ReplacementResult(content, count);
}

String _cleanupOldVariables(String content) {
  // Remove standalone focusNode and textController declarations that are no longer used
  // This is optional and can be done manually
  return content;
}
