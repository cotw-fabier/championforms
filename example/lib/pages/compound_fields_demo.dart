import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/default_fields/name_field.dart';
import 'package:championforms/default_fields/address_field.dart';
import 'package:flutter/material.dart';

/// Demonstration page for compound field functionality
///
/// This page demonstrates:
/// - NameField with includeMiddleName toggle
/// - AddressField with includeStreet2 and includeCountry toggles
/// - Results retrieval with asCompound() and individual sub-field access
/// - Custom theme application to compound fields
class CompoundFieldsDemo extends StatefulWidget {
  const CompoundFieldsDemo({super.key});

  @override
  State<CompoundFieldsDemo> createState() => _CompoundFieldsDemoState();
}

class _CompoundFieldsDemoState extends State<CompoundFieldsDemo> {
  late form.FormController controller;
  bool includeMiddleName = true;
  bool includeStreet2 = true;
  bool includeCountry = false;
  String resultsText = '';

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _showResults() {
    final results = form.FormResults.getResults(
      controller: controller,
      checkForErrors: true,
    );

    final buffer = StringBuffer();
    buffer.writeln('=== Form Results ===\n');

    if (results.errorState) {
      buffer.writeln('VALIDATION ERRORS:');
      for (final error in results.formErrors) {
        buffer.writeln('  - ${error.fieldId}: ${error.reason}');
      }
      buffer.writeln('');
    } else {
      buffer.writeln('All validations passed!\n');
    }

    // Name field results
    buffer.writeln('--- Name Field ---');
    buffer.writeln(
        'Full Name (joined): ${results.grab('customer_name').asCompound(delimiter: ' ')}');
    buffer.writeln(
        'First Name: ${results.grab('customer_name_firstname').asString()}');
    if (includeMiddleName) {
      buffer.writeln(
          'Middle Name: ${results.grab('customer_name_middlename').asString()}');
    }
    buffer.writeln(
        'Last Name: ${results.grab('customer_name_lastname').asString()}');
    buffer.writeln('');

    // Address field results
    buffer.writeln('--- Address Field ---');
    buffer.writeln(
        'Full Address (joined): ${results.grab('shipping_address').asCompound(delimiter: ', ')}');
    buffer.writeln(
        'Street: ${results.grab('shipping_address_street').asString()}');
    if (includeStreet2) {
      buffer.writeln(
          'Street 2: ${results.grab('shipping_address_street2').asString()}');
    }
    buffer.writeln('City: ${results.grab('shipping_address_city').asString()}');
    buffer
        .writeln('State: ${results.grab('shipping_address_state').asString()}');
    buffer.writeln('ZIP: ${results.grab('shipping_address_zip').asString()}');
    if (includeCountry) {
      buffer.writeln(
          'Country: ${results.grab('shipping_address_country').asString()}');
    }

    setState(() {
      resultsText = buffer.toString();
    });

    // Show results in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Form Results'),
        content: SingleChildScrollView(
          child: SelectableText(
            resultsText,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rebuildForm() {
    setState(() {
      // Dispose old controller and create new one
      controller.dispose();
      controller = form.FormController();
    });
  }

  List<form.Field> _buildFields() {
    return [
      // Header text
      form.TextField(
        id: 'header_text',
        title: 'Compound Fields Demo',
        description:
            'This form demonstrates NameField and AddressField compound fields with dynamic configuration.',
        disabled: true,
        hideField: false,
      ),

      // Name Field
      NameField(
        id: 'customer_name',
        title: 'Customer Name',
        description: includeMiddleName
            ? 'First, middle, and last name'
            : 'First and last name only',
        includeMiddleName: includeMiddleName,
        rollUpErrors: true, // Enable error display below the compound field
        validators: [
          // Validate at compound field level (will apply to all sub-fields conceptually)
          form.Validator(
            validator: (results) {
              final firstName =
                  results.grab('customer_name_firstname').asString();
              final lastName =
                  results.grab('customer_name_lastname').asString();
              return firstName.isNotEmpty && lastName.isNotEmpty;
            },
            reason: 'First and last name are required',
          ),
        ],
      ),

      // Address Field
      AddressField(
        id: 'shipping_address',
        title: 'Shipping Address',
        description: _buildAddressDescription(),
        includeStreet2: includeStreet2,
        includeCountry: includeCountry,
        rollUpErrors: true, // Enable error display below the compound field
        validators: [
          form.Validator(
            validator: (results) {
              final street = results.grab('shipping_address_street').asString();
              final city = results.grab('shipping_address_city').asString();
              final state = results.grab('shipping_address_state').asString();
              final zip = results.grab('shipping_address_zip').asString();
              return street.isNotEmpty &&
                  city.isNotEmpty &&
                  state.isNotEmpty &&
                  zip.isNotEmpty;
            },
            reason: 'Street, city, state, and ZIP are required',
          ),
        ],
      ),
    ];
  }

  String _buildAddressDescription() {
    final parts = <String>[];
    parts.add('Street address');
    if (includeStreet2) parts.add('apt/suite');
    parts.add('city, state, ZIP');
    if (includeCountry) parts.add('country');
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compound Fields Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration panel
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Field Configuration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NameField Options:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    CheckboxListTile(
                      title: const Text('Include Middle Name'),
                      value: includeMiddleName,
                      onChanged: (value) {
                        setState(() {
                          includeMiddleName = value ?? true;
                        });
                        // _rebuildForm();
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AddressField Options:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    CheckboxListTile(
                      title: const Text('Include Street 2 (Apt/Suite)'),
                      value: includeStreet2,
                      onChanged: (value) {
                        setState(() {
                          includeStreet2 = value ?? true;
                        });
                        // _rebuildForm();
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Include Country'),
                      value: includeCountry,
                      onChanged: (value) {
                        setState(() {
                          includeCountry = value ?? false;
                        });
                        // _rebuildForm();
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toggle options above to rebuild the form with different field configurations.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // The actual form
            form.Form(
              controller: controller,
              fields: _buildFields(),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showResults,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Show Results'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Clear all field values
                      for (final field in controller.activeFields) {
                        controller.updateFieldValue(field.id, '');
                      }
                      controller.clearAllErrors();
                      setState(() {
                        resultsText = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Form'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Information card
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'About Compound Fields',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Compound fields are composite fields made up of multiple sub-fields. '
                      'Each sub-field behaves as an independent field in the FormController.\n\n'
                      'Key features:\n'
                      '• Automatic ID prefixing (e.g., customer_name_firstname)\n'
                      '• Access combined values with asCompound()\n'
                      '• Access individual sub-field values normally\n'
                      '• Theme and disabled state propagation\n'
                      '• Custom layouts via registration',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Try:\n'
                      '1. Fill out the form fields\n'
                      '2. Click "Show Results" to see compound and individual values\n'
                      '3. Toggle configuration options to rebuild the form dynamically',
                      style:
                          TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
