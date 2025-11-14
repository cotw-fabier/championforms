# Pages Guide

Pages enable multi-step form workflows in ChampionForms, allowing you to organize fields into logical groups, validate incrementally, and build wizard-style user experiences while maintaining centralized state management.

## Table of Contents

- [What are Pages?](#what-are-pages)
- [How Pages are Established](#how-pages-are-established)
  - [Basic Page Definition](#basic-page-definition)
  - [Multiple Pages with One Controller](#multiple-pages-with-one-controller)
- [Page Management in FormController](#page-management-in-formcontroller)
  - [Automatic Registration](#automatic-registration)
  - [Manual Page Management](#manual-page-management)
- [Validation with Pages](#validation-with-pages)
  - [Per-Page Validation](#per-page-validation)
  - [Quick Validity Check](#quick-validity-check)
  - [Full Form Validation](#full-form-validation)
- [Navigation Between Pages](#navigation-between-pages)
  - [Basic Navigation Pattern](#basic-navigation-pattern)
  - [Advanced Navigation with State](#advanced-navigation-with-state)
- [Accessing Results by Page](#accessing-results-by-page)
  - [Single Page Results](#single-page-results)
  - [All Results at Once](#all-results-at-once)
  - [Mixed Access Patterns](#mixed-access-patterns)
- [Complete Examples](#complete-examples)
  - [Three-Step Registration Form](#three-step-registration-form)
  - [Conditional Multi-Page Form](#conditional-multi-page-form)
- [Best Practices](#best-practices)
- [FAQ](#faq)

---

## What are Pages?

Pages are **logical groupings of form fields** that enable multi-step form workflows. Unlike traditional single-page forms, pages allow you to:

- Break complex forms into manageable steps
- Validate incrementally as users progress
- Control navigation between form sections
- Access results per page or for the entire form
- Build wizard-style user experiences

**Key Characteristics:**

- **Optional:** Pages are not required; single-page forms work without them
- **Controller-Centric:** Pages are managed through the `FormController`
- **Implicit Definition:** No explicit page class; pages are identified by string names
- **Shared State:** All pages share the same controller, so values persist across navigation
- **Flexible Validation:** Validate per-page, cross-page, or entire form

**Common Use Cases:**

- User registration (personal info → address → confirmation)
- Checkout flows (cart → shipping → payment → review)
- Survey forms (demographics → questions → feedback)
- Application wizards (basic info → qualifications → documents → submit)
- Settings screens (profile → preferences → security → notifications)

---

## How Pages are Established

Pages are defined through the `pageName` parameter on the `Form` widget. There's no explicit page class or separate data structure.

### Basic Page Definition

```dart
import 'package:championforms/championforms.dart' as form;

class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  Widget build(BuildContext context) {
    return form.Form(
      controller: controller,
      pageName: 'personal-info',  // Identifies this page
      fields: [
        form.TextField(
          id: 'firstName',
          title: 'First Name',
        ),
        form.TextField(
          id: 'lastName',
          title: 'Last Name',
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

**Key Points:**

- The `pageName` is a unique string identifier for the page
- If `pageName` is omitted, fields are added to a "default" page
- Page names should be descriptive and unique (e.g., `'step-1'`, `'shipping-address'`, `'confirmation'`)

### Multiple Pages with One Controller

Multiple `Form` widgets can share the same controller and register fields to different pages:

```dart
class MultiPageForm extends StatefulWidget {
  @override
  State<MultiPageForm> createState() => _MultiPageFormState();
}

class _MultiPageFormState extends State<MultiPageForm> {
  late form.FormController controller;
  String currentPage = 'step-1';

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step 1: Personal Information
        if (currentPage == 'step-1')
          form.Form(
            controller: controller,
            pageName: 'step-1',
            fields: [
              form.TextField(id: 'name', title: 'Full Name'),
              form.TextField(id: 'email', title: 'Email'),
            ],
          ),

        // Step 2: Address
        if (currentPage == 'step-2')
          form.Form(
            controller: controller,
            pageName: 'step-2',
            fields: [
              form.TextField(id: 'street', title: 'Street'),
              form.TextField(id: 'city', title: 'City'),
            ],
          ),

        // Step 3: Confirmation
        if (currentPage == 'step-3')
          form.Form(
            controller: controller,
            pageName: 'step-3',
            fields: [
              form.CheckboxSelect(
                id: 'agree',
                title: 'I agree to the terms',
                options: [form.FieldOption(value: 'yes', label: 'Agree')],
              ),
            ],
          ),

        // Navigation buttons
        ElevatedButton(
          onPressed: () => _nextPage(),
          child: Text('Next'),
        ),
      ],
    );
  }

  void _nextPage() {
    // Validate current page before proceeding
    if (controller.validatePage(currentPage)) {
      setState(() {
        if (currentPage == 'step-1') currentPage = 'step-2';
        else if (currentPage == 'step-2') currentPage = 'step-3';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

**Important:** Field IDs must be unique across **all pages** when using the same controller.

---

## Page Management in FormController

The `FormController` maintains page organization through the `pageFields` property, a map that groups fields by page name.

### Automatic Registration

Pages are automatically registered when a `Form` widget is rendered. This happens in the widget's lifecycle:

```dart
// Internal implementation (for reference)
// When Form widget is built, it calls:
widget.controller.updatePageFields(widget.pageName!, allFieldDefs);
```

**What This Means:**

- You don't need to manually register pages
- Fields are automatically added to the page when the Form widget builds
- If you navigate away and back, fields are re-registered (idempotent)

### Manual Page Management

You can also manually manage pages using controller methods:

```dart
// Add fields to a page programmatically
controller.updatePageFields('custom-page', [
  form.TextField(id: 'field1', title: 'Field 1'),
  form.TextField(id: 'field2', title: 'Field 2'),
]);

// Get all fields for a specific page
List<form.Field> fields = controller.getPageFields('step-1');

// Access all pages
Map<String, List<form.Field>> allPages = controller.pageFields;

// Check if a page exists
bool pageExists = controller.pageFields.containsKey('step-2');

// Get all registered page names
List<String> pageNames = controller.pageFields.keys.toList();
```

**Controller Methods Reference:**

| Method | Purpose | Returns |
|--------|---------|---------|
| `updatePageFields(pageName, fields)` | Add/update fields for a page | `void` |
| `getPageFields(pageName)` | Retrieve all fields for a page | `List<Field>` |
| `validatePage(pageName)` | Validate all fields on a page | `bool` |
| `isPageValid(pageName)` | Check if page is valid (no re-validation) | `bool` |

---

## Validation with Pages

ChampionForms provides three levels of validation when working with pages.

### Per-Page Validation

Validate all fields on a specific page using `validatePage()`:

```dart
// Validate the current page
bool isValid = controller.validatePage('step-1');

if (isValid) {
  // All fields on step-1 passed validation
  navigateToNextPage();
} else {
  // Some fields have errors
  // Errors are automatically stored in controller.formErrors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Please fix errors before continuing')),
  );
}
```

**How It Works:**

1. Gets all fields registered to the specified page using `getPageFields(pageName)`
2. Runs all validators on each field
3. Stores errors in `controller.formErrors`
4. Returns `true` if no errors, `false` if any errors exist

**Error Handling:**

```dart
// If page doesn't exist, throws ArgumentError
try {
  controller.validatePage('nonexistent-page');
} catch (e) {
  print(e); // ArgumentError: Page "nonexistent-page" does not exist
}
```

**Source Reference:** `lib/controllers/form_controller.dart:1401-1419`

### Quick Validity Check

Check if a page is currently valid without re-running validators:

```dart
// Check validity based on existing errors
bool isValid = controller.isPageValid('step-1');

// Use case: Enable/disable navigation buttons
ElevatedButton(
  onPressed: controller.isPageValid('step-1') ? _nextPage : null,
  child: Text('Next'),
)
```

**Difference from `validatePage()`:**

- `validatePage()`: Re-runs all validators, updates errors, returns result
- `isPageValid()`: Checks existing errors only, no validation execution

**When to Use Each:**

- Use `validatePage()` when: User clicks "Next", before navigation, on blur
- Use `isPageValid()` when: Updating UI state, checking button enabled state

**Source Reference:** `lib/controllers/form_controller.dart:1444-1456`

### Full Form Validation

Validate all pages at once:

```dart
// Validate entire form (all pages)
bool allValid = controller.validateForm();

if (allValid) {
  final results = form.FormResults.getResults(controller: controller);
  _submitForm(results);
} else {
  // Show which pages have errors
  for (String pageName in controller.pageFields.keys) {
    if (!controller.isPageValid(pageName)) {
      print('Page $pageName has errors');
    }
  }
}
```

**Cross-Page Validation:**

You can validate relationships across pages:

```dart
// Validate individual pages first
bool page1Valid = controller.validatePage('step-1');
bool page2Valid = controller.validatePage('step-2');
bool page3Valid = controller.validatePage('step-3');

// Then check cross-page dependencies
final email1 = controller.getFieldValue<String>('step-1', 'email');
final email2 = controller.getFieldValue<String>('step-3', 'confirm_email');

if (email1 != email2) {
  // Add custom error
  controller.addError(
    form.FormBuilderError(
      fieldId: 'confirm_email',
      reason: 'Emails do not match',
    ),
  );
}
```

---

## Navigation Between Pages

ChampionForms provides the building blocks for navigation, but doesn't implement it directly. You control the navigation logic.

### Basic Navigation Pattern

```dart
class SimpleMultiPageForm extends StatefulWidget {
  @override
  State<SimpleMultiPageForm> createState() => _SimpleMultiPageFormState();
}

class _SimpleMultiPageFormState extends State<SimpleMultiPageForm> {
  late form.FormController controller;
  int currentPageIndex = 0;
  final List<String> pages = ['personal', 'address', 'confirmation'];

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  void _nextPage() {
    final currentPageName = pages[currentPageIndex];

    // Validate before moving forward
    if (!controller.validatePage(currentPageName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fix errors')),
      );
      return;
    }

    // Move to next page
    setState(() {
      if (currentPageIndex < pages.length - 1) {
        currentPageIndex++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (currentPageIndex > 0) {
        currentPageIndex--;
      }
    });
  }

  void _submitForm() {
    // Validate all pages
    bool allValid = true;
    for (final page in pages) {
      if (!controller.validatePage(page)) {
        allValid = false;
      }
    }

    if (allValid) {
      final results = form.FormResults.getResults(controller: controller);
      _handleSubmit(results);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fix all errors')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPageName = pages[currentPageIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${currentPageIndex + 1} of ${pages.length}'),
      ),
      body: Column(
        children: [
          // Page indicator
          LinearProgressIndicator(
            value: (currentPageIndex + 1) / pages.length,
          ),

          // Current page content
          Expanded(
            child: _buildPageContent(currentPageName),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentPageIndex > 0)
                  ElevatedButton(
                    onPressed: _previousPage,
                    child: Text('Previous'),
                  )
                else
                  SizedBox.shrink(),

                if (currentPageIndex < pages.length - 1)
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text('Next'),
                  )
                else
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: Text('Submit'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(String pageName) {
    if (pageName == 'personal') {
      return form.Form(
        controller: controller,
        pageName: 'personal',
        fields: [
          form.TextField(id: 'name', title: 'Full Name'),
          form.TextField(id: 'email', title: 'Email'),
        ],
      );
    } else if (pageName == 'address') {
      return form.Form(
        controller: controller,
        pageName: 'address',
        fields: [
          form.TextField(id: 'street', title: 'Street'),
          form.TextField(id: 'city', title: 'City'),
        ],
      );
    } else {
      return form.Form(
        controller: controller,
        pageName: 'confirmation',
        fields: [
          form.CheckboxSelect(
            id: 'agree',
            title: 'I agree',
            options: [form.FieldOption(value: 'yes', label: 'Yes')],
          ),
        ],
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### Advanced Navigation with State

Use navigation libraries like `go_router` for more complex flows:

```dart
// Define routes for each page
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/registration/step1',
      builder: (context, state) => RegistrationStep1Page(
        controller: state.extra as form.FormController,
      ),
    ),
    GoRoute(
      path: '/registration/step2',
      builder: (context, state) => RegistrationStep2Page(
        controller: state.extra as form.FormController,
      ),
    ),
  ],
);

// In your step pages
class RegistrationStep1Page extends StatelessWidget {
  final form.FormController controller;

  const RegistrationStep1Page({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: form.Form(
        controller: controller,
        pageName: 'step-1',
        fields: [...],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.validatePage('step-1')) {
            context.go('/registration/step2', extra: controller);
          }
        },
        child: Icon(Icons.arrow_forward),
      ),
    );
  }
}
```

---

## Accessing Results by Page

Pages provide flexible result access patterns.

### Single Page Results

Get results for a specific page only:

```dart
// Get results for step-1 only
final page1Results = form.FormResults.getResults(
  controller: controller,
  fields: controller.getPageFields('step-1'),
);

if (!page1Results.errorState) {
  // Process step-1 data
  final name = page1Results.grab('name').asString();
  final email = page1Results.grab('email').asString();

  print('Step 1 completed: $name, $email');
}
```

**Use Cases:**

- Preview data before final submission
- Save progress incrementally
- Send partial data to API
- Show confirmation summaries

### All Results at Once

Get results for all fields across all pages:

```dart
// Get all results (validates entire form by default)
final allResults = form.FormResults.getResults(
  controller: controller,
);

if (!allResults.errorState) {
  // All fields are valid
  final name = allResults.grab('name').asString();
  final street = allResults.grab('street').asString();
  final agree = allResults.grab('agree').asMultiselectList();

  _submitToAPI(allResults);
}
```

**Without Validation:**

```dart
// Get results without re-validating
final results = form.FormResults.getResults(
  controller: controller,
  checkForErrors: false,
);
```

### Mixed Access Patterns

Combine page-level and full-form access:

```dart
void _onPageComplete(String pageName) {
  // Validate current page
  if (!controller.validatePage(pageName)) {
    return;
  }

  // Get current page results for preview
  final pageResults = form.FormResults.getResults(
    controller: controller,
    fields: controller.getPageFields(pageName),
    checkForErrors: false, // Already validated above
  );

  // Show preview dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Page Summary'),
      content: Column(
        children: controller.getPageFields(pageName).map((field) {
          final value = pageResults.grab(field.id).asString();
          return Text('${field.id}: $value');
        }).toList(),
      ),
    ),
  );
}

void _onFinalSubmit() {
  // Get all results for final submission
  final allResults = form.FormResults.getResults(controller: controller);

  if (!allResults.errorState) {
    _submitToAPI(allResults);
  }
}
```

---

## Complete Examples

### Three-Step Registration Form

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class RegistrationWizard extends StatefulWidget {
  @override
  State<RegistrationWizard> createState() => _RegistrationWizardState();
}

class _RegistrationWizardState extends State<RegistrationWizard> {
  late form.FormController controller;
  int currentStep = 0;
  final steps = ['personal', 'address', 'confirmation'];

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  void _nextStep() {
    final currentPageName = steps[currentStep];

    if (!controller.validatePage(currentPageName)) {
      _showError('Please fix errors before continuing');
      return;
    }

    if (currentStep < steps.length - 1) {
      setState(() => currentStep++);
    } else {
      _submit();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    }
  }

  void _submit() {
    // Validate all pages
    final allValid = steps.every((page) => controller.validatePage(page));

    if (!allValid) {
      _showError('Please fix all errors');
      return;
    }

    final results = form.FormResults.getResults(controller: controller);

    if (!results.errorState) {
      _processRegistration(results);
    }
  }

  void _processRegistration(form.FormResults results) {
    // Extract all data
    final personalData = {
      'firstName': results.grab('firstName').asString(),
      'lastName': results.grab('lastName').asString(),
      'email': results.grab('email').asString(),
    };

    final addressData = {
      'street': results.grab('street').asString(),
      'city': results.grab('city').asString(),
      'state': results.grab('state').asString(),
      'zip': results.grab('zip').asString(),
    };

    final agreed = results.grab('terms').asMultiselectList().contains('yes');

    print('Registration complete:');
    print('Personal: $personalData');
    print('Address: $addressData');
    print('Agreed to terms: $agreed');

    // Submit to API
    // await api.register(personalData, addressData);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration - Step ${currentStep + 1}/${steps.length}'),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (currentStep + 1) / steps.length,
          ),

          // Step indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: index <= currentStep
                        ? Colors.blue
                        : Colors.grey[300],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= currentStep ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Current step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(steps[currentStep]),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  OutlinedButton(
                    onPressed: _previousStep,
                    child: Text('Previous'),
                  )
                else
                  SizedBox(width: 100),

                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(
                    currentStep < steps.length - 1 ? 'Next' : 'Submit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(String step) {
    switch (step) {
      case 'personal':
        return form.Form(
          controller: controller,
          pageName: 'personal',
          fields: [
            form.TextField(
              id: 'firstName',
              title: 'First Name',
              validators: [
                form.Validators.isEmpty('First name is required'),
              ],
              validateLive: true,
            ),
            form.TextField(
              id: 'lastName',
              title: 'Last Name',
              validators: [
                form.Validators.isEmpty('Last name is required'),
              ],
              validateLive: true,
            ),
            form.TextField(
              id: 'email',
              title: 'Email Address',
              validators: [
                form.Validators.isEmpty('Email is required'),
                form.Validators.isEmail('Invalid email format'),
              ],
              validateLive: true,
            ),
          ],
        );

      case 'address':
        return form.Form(
          controller: controller,
          pageName: 'address',
          fields: [
            form.TextField(
              id: 'street',
              title: 'Street Address',
              validators: [
                form.Validators.isEmpty('Street is required'),
              ],
            ),
            form.Row(
              columns: [
                form.Column(
                  fields: [
                    form.TextField(
                      id: 'city',
                      title: 'City',
                      validators: [
                        form.Validators.isEmpty('City is required'),
                      ],
                    ),
                  ],
                  columnFlex: 2,
                ),
                form.Column(
                  fields: [
                    form.TextField(
                      id: 'state',
                      title: 'State',
                      validators: [
                        form.Validators.isEmpty('State is required'),
                      ],
                    ),
                  ],
                  columnFlex: 1,
                ),
                form.Column(
                  fields: [
                    form.TextField(
                      id: 'zip',
                      title: 'ZIP',
                      validators: [
                        form.Validators.isEmpty('ZIP is required'),
                      ],
                    ),
                  ],
                  columnFlex: 1,
                ),
              ],
              collapse: true,
            ),
          ],
        );

      case 'confirmation':
        return form.Form(
          controller: controller,
          pageName: 'confirmation',
          fields: [
            form.CheckboxSelect(
              id: 'terms',
              title: 'Terms and Conditions',
              options: [
                form.FieldOption(
                  value: 'yes',
                  label: 'I agree to the terms and conditions',
                ),
              ],
              validators: [
                form.Validator(
                  validator: (results) {
                    final selected = results.asMultiselectList();
                    return selected.contains('yes');
                  },
                  reason: 'You must agree to continue',
                ),
              ],
            ),
          ],
        );

      default:
        return SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### Conditional Multi-Page Form

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class ConditionalWizard extends StatefulWidget {
  @override
  State<ConditionalWizard> createState() => _ConditionalWizardState();
}

class _ConditionalWizardState extends State<ConditionalWizard> {
  late form.FormController controller;
  List<String> pageSequence = ['type-selection'];

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  void _updatePageSequence() {
    // Dynamically build page sequence based on selections
    final accountType = controller.getFieldValue<List<String>>('accountType');

    pageSequence = ['type-selection'];

    if (accountType?.contains('business') ?? false) {
      pageSequence.addAll(['business-info', 'tax-info']);
    }

    if (accountType?.contains('personal') ?? false) {
      pageSequence.add('personal-info');
    }

    pageSequence.add('confirmation');
  }

  void _nextPage() {
    final currentIndex = pageSequence.indexOf(_currentPage());
    final currentPageName = pageSequence[currentIndex];

    if (!controller.validatePage(currentPageName)) {
      return;
    }

    // Update sequence before navigating
    _updatePageSequence();

    if (currentIndex < pageSequence.length - 1) {
      setState(() {});
    } else {
      _submit();
    }
  }

  String _currentPage() {
    // Logic to determine current page
    return pageSequence[0]; // Simplified
  }

  void _submit() {
    final results = form.FormResults.getResults(controller: controller);
    print('Conditional form submitted: ${results.fieldMap}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conditional Wizard')),
      body: Column(
        children: [
          Expanded(
            child: _buildCurrentPage(),
          ),
          ElevatedButton(
            onPressed: _nextPage,
            child: Text('Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    final page = _currentPage();

    if (page == 'type-selection') {
      return form.Form(
        controller: controller,
        pageName: 'type-selection',
        fields: [
          form.CheckboxSelect(
            id: 'accountType',
            title: 'Account Type',
            options: [
              form.FieldOption(value: 'personal', label: 'Personal'),
              form.FieldOption(value: 'business', label: 'Business'),
            ],
            onChange: (value) => setState(() => _updatePageSequence()),
          ),
        ],
      );
    }
    // Other pages...
    return SizedBox.shrink();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

---

## Best Practices

### Page Naming

**DO:**
```dart
// Use descriptive, kebab-case names
pageName: 'personal-information'
pageName: 'shipping-address'
pageName: 'payment-details'
pageName: 'order-confirmation'
```

**DON'T:**
```dart
// Avoid generic or ambiguous names
pageName: 'page1'
pageName: 'step'
pageName: 'form'
```

### Field ID Uniqueness

**DO:**
```dart
// Ensure field IDs are unique across all pages
// Step 1
form.TextField(id: 'personal_email', ...)

// Step 2
form.TextField(id: 'shipping_email', ...)
```

**DON'T:**
```dart
// Don't reuse field IDs across pages
// Step 1
form.TextField(id: 'email', ...)

// Step 2
form.TextField(id: 'email', ...) // CONFLICT!
```

### Validation Timing

**Per-Page Validation:**
```dart
// Validate before moving forward
void _nextPage() {
  if (controller.validatePage(currentPageName)) {
    // Move forward
  } else {
    // Show errors
  }
}
```

**Final Submission:**
```dart
// Validate all pages at final submission
void _submit() {
  final allValid = pageNames.every((page) =>
    controller.validatePage(page)
  );

  if (allValid) {
    final results = form.FormResults.getResults(controller: controller);
    _processSubmission(results);
  }
}
```

### State Persistence

**Consider persisting form state:**

```dart
import 'package:shared_preferences/shared_preferences.dart';

class PersistentFormState {
  static const String _keyPrefix = 'form_';

  static Future<void> savePageProgress(
    form.FormController controller,
    String pageName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final results = form.FormResults.getResults(
      controller: controller,
      fields: controller.getPageFields(pageName),
      checkForErrors: false,
    );

    for (final field in controller.getPageFields(pageName)) {
      final value = results.grab(field.id).asString();
      await prefs.setString('$_keyPrefix${field.id}', value);
    }
  }

  static Future<void> restoreProgress(
    form.FormController controller,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in prefs.getKeys()) {
      if (key.startsWith(_keyPrefix)) {
        final fieldId = key.substring(_keyPrefix.length);
        final value = prefs.getString(key);
        if (value != null) {
          controller.updateFieldValue(fieldId, value);
        }
      }
    }
  }
}

// Usage
await PersistentFormState.savePageProgress(controller, 'step-1');
await PersistentFormState.restoreProgress(controller);
```

### Error Display

**Show page-specific errors:**

```dart
Widget _buildPageErrors(String pageName) {
  final pageFieldIds = controller
      .getPageFields(pageName)
      .map((f) => f.id)
      .toSet();

  final pageErrors = controller.formErrors
      .where((error) => pageFieldIds.contains(error.fieldId))
      .toList();

  if (pageErrors.isEmpty) return SizedBox.shrink();

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Errors on this page:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...pageErrors.map((error) => Text('• ${error.reason}')),
      ],
    ),
  );
}
```

### Progress Tracking

**Visual progress indicators:**

```dart
class PageProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> pageNames;

  const PageProgress({
    required this.currentStep,
    required this.totalSteps,
    required this.pageNames,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
        ),
        SizedBox(height: 8),
        Text(
          '${pageNames[currentStep]} (${currentStep + 1}/$totalSteps)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
```

---

## FAQ

### Q: Can I use pages without the `Form` widget?

**A:** Technically yes, you can manually call `controller.updatePageFields()`, but the `Form` widget handles automatic registration and field rendering, so it's the recommended approach.

### Q: What happens if I don't specify a `pageName`?

**A:** Fields are added to a "default" page. This is fine for single-page forms, but for multi-step forms, always specify unique page names.

### Q: Can I validate multiple pages at once?

**A:** Yes, call `validatePage()` for each page:

```dart
final page1Valid = controller.validatePage('step-1');
final page2Valid = controller.validatePage('step-2');
final bothValid = page1Valid && page2Valid;
```

Or use `validateForm()` to validate all pages.

### Q: How do I clear errors for a specific page?

**A:** Iterate through page fields and clear individually:

```dart
final pageFields = controller.getPageFields('step-1');
for (final field in pageFields) {
  controller.clearErrors(field.id);
}
```

### Q: Can I have conditional pages (show/hide based on selections)?

**A:** Yes! Dynamically build your page sequence based on form values (see [Conditional Multi-Page Form](#conditional-multi-page-form) example).

### Q: Do field values persist when navigating between pages?

**A:** Yes! All pages share the same `FormController`, so values are preserved across navigation. This is a key benefit of the centralized state management approach.

### Q: Can I skip a page?

**A:** Yes, navigation is entirely under your control. You can jump to any page:

```dart
setState(() {
  currentPage = 'step-3'; // Skip from step-1 to step-3
});
```

### Q: How do I know which page a field belongs to?

**A:** Check `controller.pageFields`:

```dart
String? findPageForField(String fieldId) {
  for (final entry in controller.pageFields.entries) {
    if (entry.value.any((field) => field.id == fieldId)) {
      return entry.key;
    }
  }
  return null;
}

final page = findPageForField('email'); // Returns page name
```

### Q: Can I have the same field on multiple pages?

**A:** No. Field IDs must be unique across the entire form/controller. If you need similar fields on different pages, use unique IDs like `step1_email` and `step2_email`.

### Q: How do I implement a "Save Progress" feature?

**A:** Get page results and save to persistent storage:

```dart
Future<void> saveProgress(String pageName) async {
  final results = form.FormResults.getResults(
    controller: controller,
    fields: controller.getPageFields(pageName),
    checkForErrors: false,
  );

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('saved_page', pageName);

  for (final field in controller.getPageFields(pageName)) {
    final value = results.grab(field.id).asString();
    await prefs.setString('field_${field.id}', value);
  }
}
```

### Q: Can I use PageView with ChampionForms pages?

**A:** Yes! Use `PageView` for swipe navigation:

```dart
PageView.builder(
  controller: _pageController,
  itemCount: pages.length,
  onPageChanged: (index) {
    // Validate before allowing page change
    if (!controller.validatePage(pages[_currentIndex])) {
      _pageController.jumpToPage(_currentIndex);
    } else {
      setState(() => _currentIndex = index);
    }
  },
  itemBuilder: (context, index) {
    return _buildPage(pages[index]);
  },
)
```

### Q: How do I handle back button navigation?

**A:** Override `WillPopScope` to validate before allowing navigation away:

```dart
WillPopScope(
  onWillPop: () async {
    if (currentPageIndex > 0) {
      _previousPage();
      return false; // Prevent default back
    }

    // Ask for confirmation before leaving form
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit form?'),
        content: Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Exit'),
          ),
        ],
      ),
    ) ?? false;
  },
  child: _buildCurrentPage(),
)
```

---

## Next Steps

- **Try the Examples**: Run the complete examples above in your project
- **Build a Multi-Step Form**: Start with a simple 2-3 page registration flow
- **Explore Validation**: Experiment with per-page and cross-page validation
- **Add Persistence**: Implement save/restore functionality for better UX
- **Combine with Navigation**: Integrate with `go_router` or other navigation packages

---

**Related Documentation:**

- [Main README](../../README.md) - Getting started guide
- [Compound Fields Guide](compound-fields.md) - Reusable composite fields
- [Form Controller](../../lib/controllers/form_controller.dart) - Controller source code
- [Form Widget](../../lib/widgets_external/form.dart) - Form widget source code
