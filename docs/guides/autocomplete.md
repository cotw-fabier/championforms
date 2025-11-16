# Autocomplete Guide

Complete guide to adding autocomplete suggestions to TextField.

## Table of Contents
- [Overview](#overview)
- [Quick Start](#quick-start)
- [AutoCompleteBuilder API](#autocompletebuilder-api)
- [CompleteOption API](#completeoption-api)
- [Patterns and Use Cases](#patterns-and-use-cases)
- [Async Data Fetching](#async-data-fetching)
- [Debouncing](#debouncing)
- [Customization](#customization)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Related Documentation](#related-documentation)

## Overview

Autocomplete adds intelligent dropdown suggestions to TextField fields, helping users:
- Complete input faster with suggestions
- Reduce typos by selecting from valid options
- Discover available values without memorization

### When to Use It

Use autocomplete when you have:
- A predefined set of common values (emails, countries, product names)
- Dynamic data from an API (user search, product catalog)
- Large option lists that would be unwieldy as dropdowns
- Partial matching needs (search-as-you-type)

### TextField-Only Feature

Autocomplete is currently only available on `form.TextField`. It is not supported on `form.OptionSelect` or other field types.

## Quick Start

### Basic Autocomplete

Simple example with static options:

```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email Address',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: 'user@example.com'),
      form.CompleteOption(value: 'admin@example.com'),
      form.CompleteOption(value: 'support@example.com'),
    ],
  ),
)
```

This creates a dropdown that shows all three options when the user starts typing in the field.

### With Client-Side Filtering

Filter options based on user input:

```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email Address',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: 'test1@example.com'),
      form.CompleteOption(value: 'test2@example.com'),
      form.CompleteOption(value: 'another@domain.net'),
    ],
    updateOptions: (searchValue) async {
      return [
        form.CompleteOption(value: 'test1@example.com'),
        form.CompleteOption(value: 'test2@example.com'),
        form.CompleteOption(value: 'another@domain.net'),
      ].where((opt) =>
        opt.value.toLowerCase().contains(searchValue.toLowerCase())
      ).toList();
    },
  ),
)
```

## AutoCompleteBuilder API

### Constructor

```dart
AutoCompleteBuilder({
  AutoCompleteType type = AutoCompleteType.dropdown,
  List<CompleteOption> initialOptions = const [],
  Future<List<CompleteOption>> Function(String)? updateOptions,
  Duration debounceDuration = const Duration(seconds: 1),
  Duration debounceWait = const Duration(milliseconds: 100),
  Widget Function(CompleteOption, String Function(CompleteOption))? optionBuilder,
  int dropdownBoxMargin = 8,
  int? maxHeight,
  int? minHeight,
  int? percentageHeight,
})
```

### Properties

#### type
- **Type:** `AutoCompleteType`
- **Default:** `AutoCompleteType.dropdown`
- **Purpose:** Display style for autocomplete suggestions
- **Options:**
  - `AutoCompleteType.dropdown` - Shows suggestions in dropdown below field (only option currently)
  - `AutoCompleteType.none` - Disables autocomplete (useful for debugging)

```dart
autoComplete: form.AutoCompleteBuilder(
  type: AutoCompleteType.dropdown, // Default
  initialOptions: [...],
)
```

#### initialOptions
- **Type:** `List<CompleteOption>`
- **Default:** `[]`
- **Purpose:** Starting list of autocomplete suggestions
- **Use for:** Static options, cached data, initial dataset

```dart
autoComplete: form.AutoCompleteBuilder(
  initialOptions: [
    form.CompleteOption(value: 'Apple'),
    form.CompleteOption(value: 'Banana'),
    form.CompleteOption(value: 'Cherry'),
  ],
)
```

**Note:** If you don't provide `updateOptions`, only `initialOptions` will be shown (unfiltered).

#### updateOptions
- **Type:** `Future<List<CompleteOption>> Function(String)?`
- **Default:** `null`
- **Purpose:** Async callback to fetch/filter options based on user input
- **Parameter:** Current input value as String
- **Returns:** `Future<List<CompleteOption>>`

```dart
autoComplete: form.AutoCompleteBuilder(
  updateOptions: (searchValue) async {
    // Filter, fetch from API, or compute options
    return filteredOptions;
  },
)
```

**When called:**
- Triggered when field value changes
- Controlled by `debounceWait` (prevents excessive calls)
- Not called if field is empty

#### debounceDuration
- **Type:** `Duration`
- **Default:** `Duration(seconds: 1)`
- **Purpose:** Timer for subsequent `updateOptions` calls (after first call)
- **Use for:** Rate limiting repeated API calls

```dart
autoComplete: form.AutoCompleteBuilder(
  debounceDuration: const Duration(seconds: 1),
  updateOptions: (searchValue) async { ... },
)
```

**How it works:**
- First call uses `debounceWait` (fast, default 100ms)
- Subsequent calls use `debounceDuration` (slower, default 1000ms)
- Prevents excessive API calls while typing

#### debounceWait
- **Type:** `Duration`
- **Default:** `Duration(milliseconds: 100)`
- **Purpose:** Initial delay before first `updateOptions` call
- **Use for:** Providing fast initial response

```dart
autoComplete: form.AutoCompleteBuilder(
  debounceWait: const Duration(milliseconds: 250),
  updateOptions: (searchValue) async { ... },
)
```

**Recommended values:**
- 100-200ms: Very responsive, local filtering
- 250-500ms: Balanced, API calls (most common)
- 700-1000ms: Conservative, expensive operations

#### optionBuilder
- **Type:** `Widget Function(CompleteOption, String Function(CompleteOption))?`
- **Default:** `null` (uses default ListTile builder)
- **Purpose:** Custom widget builder for each autocomplete option
- **Parameters:**
  - `CompleteOption option` - The option to render
  - `String Function(CompleteOption) championCallback` - Callback to trigger selection
- **Use for:** Custom option layouts, icons, styling

```dart
autoComplete: form.AutoCompleteBuilder(
  optionBuilder: (option, championCallback) {
    return InkWell(
      onTap: () => championCallback(option),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.email),
            SizedBox(width: 8),
            Text(option.title),
          ],
        ),
      ),
    );
  },
)
```

**Important:** Always call `championCallback(option)` when option is selected.

#### dropdownBoxMargin
- **Type:** `int`
- **Default:** `8`
- **Purpose:** Spacing (in pixels) between field and dropdown overlay

```dart
autoComplete: form.AutoCompleteBuilder(
  dropdownBoxMargin: 12, // More spacing
)
```

#### minHeight
- **Type:** `int?`
- **Default:** `null` (uses 100 internally)
- **Purpose:** Minimum height of dropdown overlay in pixels
- **Use for:** Ensuring dropdown is tall enough to see options

```dart
autoComplete: form.AutoCompleteBuilder(
  minHeight: 150,
)
```

**Behavior:**
- If space below field is less than `minHeight`, dropdown appears above field
- Ensures dropdown is always usable

#### maxHeight
- **Type:** `int?`
- **Default:** `null` (uses 300 internally)
- **Purpose:** Maximum height of dropdown overlay in pixels
- **Use for:** Preventing dropdown from being too tall

```dart
autoComplete: form.AutoCompleteBuilder(
  maxHeight: 400,
)
```

**Behavior:**
- Dropdown will not exceed this height
- Becomes scrollable if options exceed this height

#### percentageHeight
- **Type:** `int?`
- **Default:** `null`
- **Purpose:** Height of dropdown as percentage of available space
- **Use for:** Responsive sizing based on screen space

```dart
autoComplete: form.AutoCompleteBuilder(
  percentageHeight: 50, // 50% of available space
)
```

**Notes:**
- Overridden by `minHeight` if result is too small
- Overridden by `maxHeight` if result is too large
- If unset, dropdown shrinkwraps to content (respecting min/max)

## CompleteOption API

### Constructor

```dart
CompleteOption({
  String? title,
  required String value,
  bool isSet = false,
  Object? additionalData,
  Function(CompleteOption)? callback,
  Widget Function(CompleteOption, String Function(CompleteOption))? optionBuilder,
})
```

### Properties

#### value (required)
- **Type:** `String`
- **Purpose:** The text inserted into the field when option is selected
- **Use:** This is the actual data stored

```dart
form.CompleteOption(value: 'john.doe@example.com')
```

#### title
- **Type:** `String?`
- **Default:** Same as `value`
- **Purpose:** Custom display text in dropdown
- **Use for:** Showing formatted or friendly text

```dart
form.CompleteOption(
  value: 'john.doe@example.com',
  title: 'John Doe (john.doe@example.com)',
)
```

#### isSet
- **Type:** `bool`
- **Default:** `false`
- **Purpose:** Track custom state for this option
- **Use for:** Advanced use cases (e.g., marking favorites)

```dart
form.CompleteOption(
  value: 'favorite@example.com',
  isSet: true, // Could be used in custom optionBuilder
)
```

#### additionalData
- **Type:** `Object?`
- **Default:** `null`
- **Purpose:** Store arbitrary data with this option
- **Use for:** IDs, metadata, complex objects

```dart
form.CompleteOption(
  value: 'USA',
  additionalData: {
    'code': 'US',
    'dialCode': '+1',
    'population': 331000000,
  },
)
```

**Note:** You'll need to cast `additionalData` to the expected type when using it.

#### callback
- **Type:** `Function(CompleteOption)?`
- **Default:** `null`
- **Purpose:** Custom function called when option is selected
- **Use for:** Side effects, logging, analytics

```dart
form.CompleteOption(
  value: 'example@test.com',
  callback: (option) {
    print('User selected: ${option.value}');
    // Log to analytics, etc.
  },
)
```

#### optionBuilder
- **Type:** `Widget Function(CompleteOption, String Function(CompleteOption))?`
- **Default:** `null`
- **Purpose:** Custom builder for this specific option (overrides AutoCompleteBuilder's optionBuilder)
- **Use for:** Per-option custom rendering

```dart
form.CompleteOption(
  value: 'premium@example.com',
  optionBuilder: (option, championCallback) {
    return Container(
      color: Colors.gold,
      child: ListTile(
        title: Text(option.title),
        trailing: Icon(Icons.star),
        onTap: () => championCallback(option),
      ),
    );
  },
)
```

## Patterns and Use Cases

### Pattern 1: Static List

Fixed autocomplete options that never change.

```dart
form.TextField(
  id: 'fruit',
  textFieldTitle: 'Choose a Fruit',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: 'Apple'),
      form.CompleteOption(value: 'Banana'),
      form.CompleteOption(value: 'Cherry'),
      form.CompleteOption(value: 'Date'),
      form.CompleteOption(value: 'Fig'),
      form.CompleteOption(value: 'Grape'),
    ],
  ),
)
```

**When to use:**
- Predefined choices (fruits, countries, states)
- Small datasets (<50 items)
- No API required
- Options never change

**Pros:**
- Simple and fast
- No network calls
- Works offline

**Cons:**
- Shows ALL options (no filtering)
- Not searchable
- Not suitable for large lists

### Pattern 2: Client-Side Filtering

Filter `initialOptions` based on user input.

```dart
final allFruits = [
  form.CompleteOption(value: 'Apple'),
  form.CompleteOption(value: 'Banana'),
  form.CompleteOption(value: 'Cherry'),
  form.CompleteOption(value: 'Date'),
  form.CompleteOption(value: 'Fig'),
  form.CompleteOption(value: 'Grape'),
];

form.TextField(
  id: 'fruit',
  textFieldTitle: 'Search Fruits',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: allFruits,
    updateOptions: (searchValue) async {
      return allFruits
          .where((opt) => opt.value
              .toLowerCase()
              .contains(searchValue.toLowerCase()))
          .toList();
    },
  ),
)
```

**When to use:**
- Moderate datasets (<1000 items)
- Fast filtering needed
- Offline-first applications
- No server-side search

**Pros:**
- Fast and responsive
- Works offline
- No API calls
- Searchable

**Cons:**
- All data loaded into memory
- Not suitable for very large datasets
- No real-time updates from server

### Pattern 3: Server-Side Search

Fetch options from API based on user input.

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<form.CompleteOption>> searchUsers(String query) async {
  if (query.isEmpty) return [];

  final response = await http.get(
    Uri.parse('https://api.example.com/users?search=$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((user) => form.CompleteOption(
      value: user['email'],
      title: '${user['name']} (${user['email']})',
      additionalData: user['id'],
    )).toList();
  }

  return [];
}

// Usage
form.TextField(
  id: 'user_email',
  textFieldTitle: 'Search Users',
  autoComplete: form.AutoCompleteBuilder(
    updateOptions: searchUsers,
    debounceWait: const Duration(milliseconds: 500),
  ),
)
```

**When to use:**
- Large datasets
- Real-time data
- Complex search logic
- Database lookups

**Pros:**
- Handles massive datasets
- Real-time results
- Reduced memory usage
- Server-side filtering logic

**Cons:**
- Requires network connection
- Slower than client-side
- API call overhead
- Needs error handling

### Pattern 4: Hybrid (Initial + Dynamic)

Start with cached data, update from API for refinement.

```dart
final cachedEmails = [
  form.CompleteOption(value: 'recent1@example.com'),
  form.CompleteOption(value: 'recent2@example.com'),
  form.CompleteOption(value: 'recent3@example.com'),
];

form.TextField(
  id: 'email',
  textFieldTitle: 'Email',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: cachedEmails,
    updateOptions: (searchValue) async {
      // For short queries, filter cached results
      if (searchValue.length < 3) {
        return cachedEmails
            .where((opt) => opt.value
                .toLowerCase()
                .contains(searchValue.toLowerCase()))
            .toList();
      }

      // For longer queries, fetch from API
      final response = await http.get(
        Uri.parse('https://api.example.com/emails?q=$searchValue'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) =>
          form.CompleteOption(value: item['email'])
        ).toList();
      }

      return cachedEmails;
    },
    debounceWait: const Duration(milliseconds: 300),
  ),
)
```

**When to use:**
- Hybrid online/offline apps
- Progressive enhancement
- Recent items + search
- Performance optimization

**Pros:**
- Fast initial response
- Works offline (partially)
- Reduces API calls
- Better UX

**Cons:**
- More complex logic
- Potential stale data in cache
- Need to manage cache updates

## Async Data Fetching

### Making API Calls

Example of fetching autocomplete data from a REST API:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<form.CompleteOption>> searchProducts(String query) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/products?search=$query'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((product) => form.CompleteOption(
      value: product['name'],
      title: '${product['name']} - \$${product['price']}',
      additionalData: {
        'id': product['id'],
        'price': product['price'],
        'inStock': product['inStock'],
      },
    )).toList();
  }

  throw Exception('Failed to load products');
}

// Usage in TextField
form.TextField(
  id: 'product_search',
  textFieldTitle: 'Search Products',
  autoComplete: form.AutoCompleteBuilder(
    updateOptions: searchProducts,
    debounceWait: const Duration(milliseconds: 500),
  ),
)
```

### Error Handling

Always handle errors gracefully to prevent crashes:

```dart
updateOptions: (searchValue) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.example.com/search?q=$searchValue'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) =>
        form.CompleteOption(value: item['name'])
      ).toList();
    } else {
      // Non-200 response
      print('API error: ${response.statusCode}');
      return []; // Return empty list
    }
  } catch (e) {
    // Network error, timeout, parsing error, etc.
    print('Autocomplete error: $e');
    return []; // Return empty list on error
  }
}
```

**Best practices:**
- Always use try-catch
- Return empty list on error (not null)
- Log errors for debugging
- Consider showing error state in UI
- Handle network timeouts

### Timeout Handling

Prevent slow APIs from hanging:

```dart
updateOptions: (searchValue) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.example.com/search?q=$searchValue'),
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw TimeoutException('Request timeout');
      },
    );

    // Process response...
  } on TimeoutException {
    print('Search timed out');
    return [];
  } catch (e) {
    print('Error: $e');
    return [];
  }
}
```

### Loading States

Currently, there's no built-in loading indicator, but `updateOptions` runs async automatically. The overlay updates when results arrive.

To show a loading indicator, you could use a custom `optionBuilder`:

```dart
bool _isLoading = false;

form.TextField(
  id: 'search',
  autoComplete: form.AutoCompleteBuilder(
    updateOptions: (searchValue) async {
      setState(() => _isLoading = true);
      try {
        final results = await fetchResults(searchValue);
        return results;
      } finally {
        setState(() => _isLoading = false);
      }
    },
    // Note: Loading state would need to be managed externally
  ),
)
```

## Debouncing

### Why Debouncing?

Without debouncing, `updateOptions` would fire on every keystroke:
- User types "test" → 4 API calls (t, te, tes, test)
- Wastes bandwidth and server resources
- Slower user experience
- Expensive with rate-limited APIs

With debouncing:
- User types "test" → 1 API call (test)
- Waits until user pauses typing
- Much more efficient

### How Debouncing Works

ChampionForms uses a dual-timer approach:

1. **First keystroke:** Uses `debounceWait` (default 100ms)
   - Fast initial response
   - User sees results quickly

2. **Subsequent keystrokes:** Uses `debounceDuration` (default 1000ms)
   - Longer delay to reduce API calls
   - Timer resets on each keystroke

**Example timeline:**
```
User types: h → e → l → l → o
            ↓   ↓   ↓   ↓   ↓
Timers:    100ms (canceled by next keystroke)
                100ms (canceled)
                     100ms (canceled)
                          100ms (canceled)
                               1000ms → API call!
```

### Setting Debounce Duration

```dart
form.TextField(
  id: 'search',
  autoComplete: form.AutoCompleteBuilder(
    updateOptions: (searchValue) async {
      return await searchAPI(searchValue);
    },
    debounceWait: const Duration(milliseconds: 300),    // First call
    debounceDuration: const Duration(milliseconds: 800), // Subsequent calls
  ),
)
```

### Recommended Values

| Use Case | debounceWait | debounceDuration |
|----------|--------------|------------------|
| Local filtering | 100-200ms | 500ms |
| Standard API | 300-500ms | 1000ms |
| Expensive API | 500-700ms | 1500ms |
| Rate-limited API | 700-1000ms | 2000ms+ |

**Guidelines:**
- Lower values = more responsive, more API calls
- Higher values = less responsive, fewer API calls
- Balance user experience with resource usage

### Minimum Characters

You can require a minimum input length before triggering search:

```dart
updateOptions: (searchValue) async {
  if (searchValue.length < 3) {
    return []; // No suggestions until 3+ characters
  }

  return await fetchSuggestions(searchValue);
}
```

**Benefits:**
- Reduces API calls for short queries
- Prevents too many results
- Better for large datasets

## Customization

### Custom Display Text

Show different text in dropdown than what gets inserted:

```dart
form.CompleteOption(
  value: 'john.doe@company.com',
  title: 'John Doe (Engineering)',
)
```

**Result:**
- Dropdown shows: "John Doe (Engineering)"
- Field receives: "john.doe@company.com"

### Using Additional Data

Store metadata with options:

```dart
form.CompleteOption(
  value: 'United States',
  title: 'United States of America',
  additionalData: {
    'code': 'US',
    'dialCode': '+1',
    'population': 331000000,
    'flag': '🇺🇸',
  },
)
```

**Accessing in callback:**

```dart
form.CompleteOption(
  value: 'United States',
  additionalData: {'code': 'US'},
  callback: (option) {
    final data = option.additionalData as Map<String, dynamic>;
    print('Selected country code: ${data['code']}');
  },
)
```

### Custom Option Builder

Create fully custom option widgets:

```dart
form.TextField(
  id: 'user_search',
  autoComplete: form.AutoCompleteBuilder(
    updateOptions: (query) async => fetchUsers(query),
    optionBuilder: (option, championCallback) {
      final userData = option.additionalData as Map<String, dynamic>;

      return InkWell(
        onTap: () => championCallback(option),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(userData['avatarUrl']),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      option.value,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (userData['verified'] == true)
                const Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
          ),
        ),
      );
    },
  ),
)
```

**Important:** Always call `championCallback(option)` when option is selected.

### Dropdown Sizing

Control dropdown dimensions:

```dart
form.TextField(
  id: 'search',
  autoComplete: form.AutoCompleteBuilder(
    minHeight: 150,        // Minimum height
    maxHeight: 400,        // Maximum height
    percentageHeight: 60,  // 60% of available space
    dropdownBoxMargin: 12, // Spacing from field
  ),
)
```

**How it works:**
- Dropdown tries to fit `percentageHeight` of available space
- Never smaller than `minHeight`
- Never larger than `maxHeight`
- If field is near bottom and can't fit `minHeight`, dropdown appears above field

## Best Practices

### 1. Use Reasonable Debounce

Don't over-debounce (feels sluggish) or under-debounce (too many requests):

```dart
// Good: Balanced debounce
debounceWait: const Duration(milliseconds: 300),

// Bad: Too slow for user
debounceWait: const Duration(seconds: 3),

// Bad: Too fast, excessive API calls
debounceWait: const Duration(milliseconds: 10),
```

### 2. Limit Result Count

Return a reasonable number of options:

```dart
updateOptions: (searchValue) async {
  final allResults = await searchAPI(searchValue);
  return allResults.take(10).toList(); // Max 10 results
}
```

**Benefits:**
- Faster rendering
- Easier to scan
- Less overwhelming for users

### 3. Handle Empty Results

Provide feedback when no matches found:

```dart
updateOptions: (searchValue) async {
  final results = await search(searchValue);

  if (results.isEmpty) {
    return [
      form.CompleteOption(
        value: '',
        title: 'No results found for "$searchValue"',
      ),
    ];
  }

  return results;
}
```

### 4. Cache When Possible

Reduce API calls with caching:

```dart
final _cache = <String, List<form.CompleteOption>>{};

updateOptions: (searchValue) async {
  // Check cache first
  if (_cache.containsKey(searchValue)) {
    return _cache[searchValue]!;
  }

  // Fetch and cache
  final results = await fetchResults(searchValue);
  _cache[searchValue] = results;
  return results;
}
```

**Considerations:**
- Clear cache periodically to prevent stale data
- Implement cache expiration for real-time data
- Be mindful of memory usage

### 5. Case-Insensitive Matching

Always use case-insensitive filtering:

```dart
// Good
.where((opt) => opt.value.toLowerCase().contains(searchValue.toLowerCase()))

// Bad (case-sensitive)
.where((opt) => opt.value.contains(searchValue))
```

### 6. Sort Results by Relevance

Prioritize best matches:

```dart
updateOptions: (searchValue) async {
  final results = await fetchResults(searchValue);

  // Sort: starts-with matches first, then contains
  results.sort((a, b) {
    final aStarts = a.value.toLowerCase().startsWith(searchValue.toLowerCase());
    final bStarts = b.value.toLowerCase().startsWith(searchValue.toLowerCase());

    if (aStarts && !bStarts) return -1;
    if (!aStarts && bStarts) return 1;
    return a.value.compareTo(b.value);
  });

  return results;
}
```

### 7. Provide Visual Feedback

Use `title` to make options scannable:

```dart
// Good: Clear, scannable
form.CompleteOption(
  value: 'john.doe@company.com',
  title: 'John Doe - Engineering (john.doe@company.com)',
)

// Bad: Value only
form.CompleteOption(value: 'john.doe@company.com')
```

### 8. Validate Selected Values

Use validators to ensure valid selection:

```dart
form.TextField(
  id: 'email',
  autoComplete: form.AutoCompleteBuilder(...),
  validateLive: true,
  validators: [
    form.Validator(
      validator: (results) => form.Validators.isEmail(results),
      reason: 'Please enter a valid email address',
    ),
  ],
)
```

## Complete Examples

### Example 1: Email Domain Suggestions

Simple email autocomplete with common domains:

```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email Address',
  hintText: 'Enter your email',
  validateLive: true,
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: 'test1@example.com'),
      form.CompleteOption(value: 'test2@example.com'),
      form.CompleteOption(value: 'another@domain.net'),
      form.CompleteOption(value: 'admin@company.com'),
    ],
    updateOptions: (searchValue) async {
      await Future.delayed(const Duration(milliseconds: 300));

      return [
        form.CompleteOption(value: 'test1@example.com'),
        form.CompleteOption(value: 'test2@example.com'),
        form.CompleteOption(value: 'another@domain.net'),
        form.CompleteOption(value: 'admin@company.com'),
      ].where((opt) =>
        opt.value.toLowerCase().contains(searchValue.toLowerCase())
      ).toList();
    },
    debounceWait: const Duration(milliseconds: 250),
  ),
  validators: [
    form.Validator(
      validator: (results) => form.Validators.stringIsNotEmpty(results),
      reason: 'Email cannot be empty.',
    ),
    form.Validator(
      validator: (results) => form.Validators.isEmail(results),
      reason: 'Please enter a valid email address.',
    ),
  ],
)
```

### Example 2: Fruit Picker with Filtering

Client-side filtering of fruit options:

```dart
final allFruits = [
  form.CompleteOption(value: 'Apple'),
  form.CompleteOption(value: 'Banana'),
  form.CompleteOption(value: 'Cherry'),
  form.CompleteOption(value: 'Date'),
  form.CompleteOption(value: 'Fig'),
  form.CompleteOption(value: 'Grape'),
  form.CompleteOption(value: 'Kiwi'),
  form.CompleteOption(value: 'Lemon'),
  form.CompleteOption(value: 'Mango'),
  form.CompleteOption(value: 'Orange'),
];

form.TextField(
  id: 'favorite_fruit',
  textFieldTitle: 'Favorite Fruit',
  hintText: 'Start typing...',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: allFruits,
    updateOptions: (searchValue) async {
      return allFruits
          .where((opt) => opt.value
              .toLowerCase()
              .contains(searchValue.toLowerCase()))
          .toList();
    },
  ),
)
```

### Example 3: Country Selector with Metadata

Searchable country list with country codes:

```dart
final countries = [
  form.CompleteOption(
    value: 'United States',
    title: '🇺🇸 United States',
    additionalData: {'code': 'US', 'dialCode': '+1'},
  ),
  form.CompleteOption(
    value: 'United Kingdom',
    title: '🇬🇧 United Kingdom',
    additionalData: {'code': 'GB', 'dialCode': '+44'},
  ),
  form.CompleteOption(
    value: 'Canada',
    title: '🇨🇦 Canada',
    additionalData: {'code': 'CA', 'dialCode': '+1'},
  ),
  form.CompleteOption(
    value: 'Australia',
    title: '🇦🇺 Australia',
    additionalData: {'code': 'AU', 'dialCode': '+61'},
  ),
  form.CompleteOption(
    value: 'Germany',
    title: '🇩🇪 Germany',
    additionalData: {'code': 'DE', 'dialCode': '+49'},
  ),
];

form.TextField(
  id: 'country',
  textFieldTitle: 'Country',
  hintText: 'Search countries...',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: countries,
    updateOptions: (searchValue) async {
      final query = searchValue.toLowerCase();
      return countries.where((country) {
        final value = country.value.toLowerCase();
        final data = country.additionalData as Map<String, dynamic>;
        final code = data['code'].toString().toLowerCase();

        return value.contains(query) || code.contains(query);
      }).toList();
    },
    debounceWait: const Duration(milliseconds: 200),
  ),
  onChange: (results) {
    final country = results.grab('country').asString();
    print('Selected country: $country');
  },
)
```

### Example 4: User Search with API

Real-world API integration with error handling:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<form.CompleteOption>> searchUsers(String query) async {
  if (query.length < 2) {
    return []; // Require at least 2 characters
  }

  try {
    final response = await http.get(
      Uri.parse('https://api.example.com/users?search=$query&limit=10'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((user) => form.CompleteOption(
        value: user['email'],
        title: '${user['name']} (${user['email']})',
        additionalData: {
          'id': user['id'],
          'department': user['department'],
          'avatarUrl': user['avatarUrl'],
        },
        callback: (option) {
          print('Selected user: ${option.value}');
        },
      )).toList();
    } else {
      print('API returned status: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('User search error: $e');
    return [];
  }
}

// Usage
form.TextField(
  id: 'assignee',
  textFieldTitle: 'Assign To',
  hintText: 'Search by name or email...',
  autoComplete: form.AutoCompleteBuilder(
    updateOptions: searchUsers,
    debounceWait: const Duration(milliseconds: 500),
    debounceDuration: const Duration(seconds: 1),
    maxHeight: 300,
  ),
)
```

### Example 5: Tag Input Pattern

Autocomplete for adding tags (without using the autocomplete value directly):

```dart
class TagInputExample extends StatefulWidget {
  @override
  State<TagInputExample> createState() => _TagInputExampleState();
}

class _TagInputExampleState extends State<TagInputExample> {
  final controller = form.FormController();
  final List<String> selectedTags = [];

  final availableTags = [
    'Flutter', 'Dart', 'Mobile', 'Web', 'iOS', 'Android',
    'Backend', 'Frontend', 'API', 'Database', 'UI/UX',
  ];

  void addTag(String tag) {
    if (!selectedTags.contains(tag)) {
      setState(() {
        selectedTags.add(tag);
      });
      controller.updateFieldValue('tag_input', '');
    }
  }

  void removeTag(String tag) {
    setState(() {
      selectedTags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display selected tags
        Wrap(
          spacing: 8,
          children: selectedTags.map((tag) => Chip(
            label: Text(tag),
            onDeleted: () => removeTag(tag),
          )).toList(),
        ),

        const SizedBox(height: 12),

        // Tag input with autocomplete
        form.Form(
          controller: controller,
          fields: [
            form.TextField(
              id: 'tag_input',
              textFieldTitle: 'Add Tags',
              hintText: 'Type to search tags...',
              autoComplete: form.AutoCompleteBuilder(
                initialOptions: availableTags
                    .map((tag) => form.CompleteOption(
                          value: tag,
                          callback: (option) {
                            addTag(option.value);
                          },
                        ))
                    .toList(),
                updateOptions: (searchValue) async {
                  if (searchValue.isEmpty) return [];

                  return availableTags
                      .where((tag) => tag
                          .toLowerCase()
                          .contains(searchValue.toLowerCase()))
                      .where((tag) => !selectedTags.contains(tag))
                      .map((tag) => form.CompleteOption(
                            value: tag,
                            callback: (option) {
                              addTag(option.value);
                            },
                          ))
                      .toList();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

## Related Documentation

- [TextField API Reference](../api/fields.md#textfield) - Complete TextField documentation
- [Form Results Guide](../guides/form-results.md) - Accessing autocomplete values after submission
- [Validation Guide](../guides/validation.md) - Validating autocomplete fields
- [Custom Fields Guide](../guides/custom-fields.md) - Building custom autocomplete-enabled fields
- [Theming Guide](../guides/theming.md) - Styling autocomplete dropdowns
