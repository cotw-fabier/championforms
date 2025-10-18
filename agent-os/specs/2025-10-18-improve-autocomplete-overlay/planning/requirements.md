# Spec Requirements: Improve Autocomplete Overlay

## Initial Description
I want to improve the auto-complete overlay behavior. Right now its functional, but I would like to have you rewrite it so it uses the correct flutter material widgets for building and displaying the overlay. It needs to be smart about judging how much space it has and determining if it should build above or below the field we're working with, and it also needs to be accessible where a user can press tab or down arrow and be able to immediately start scrolling through the items available in the dropdown. The overlay also needs to honor our theme colors. Finally, the overlay should be modular because I would like to begin to apply it to other fields, so we should separate it out from the text edit widget and instead make it a widget we can wrap another field with in order to bring auto-complete to other fields at a later time.

## Requirements Discussion

### First Round Questions

**Q1: Current Implementation Location**
**Question:** Where is the current autocomplete implementation located, and should I analyze it to understand the existing behavior before refactoring?
**Answer:** The autocomplete is available in `/Users/fabier/Documents/code/championforms/lib/widgets_internal/field_widgets/textfieldwidget.dart` currently. They need to break it out into its own widget. Maybe listen through the controller where you can get access to the textfield controller or get just listen to the raw value.

**Q2: Selection Behavior**
**Question:** When a user selects an autocomplete option, should it trigger a callback that by default updates the field value, or should it always require custom handling?
**Answer:** It should trigger a callback which by default updates the field. But it can be overridden by the user.

**Q3: Screen Reader Announcements**
**Question:** For accessibility, should we implement screen reader announcements for the number of results available and when the selected option changes as the user navigates?
**Answer:** That sounds great. The user is not an accessibility expert so if we think this is standard practice then they are on board for it.

**Q4: Overlay Dismiss Behavior**
**Question:** Should the overlay dismiss when the user taps outside, presses escape, or when the field loses focus?
**Answer:** Yes to all the above (tap outside, escape key, field loses focus).

### Existing Code to Reference

**Similar Features Identified:**
- Feature: Current Autocomplete Implementation - Path: `/Users/fabier/Documents/code/championforms/lib/widgets_internal/field_widgets/textfieldwidget.dart`
- Key implementation details to preserve:
  - Uses `OverlayEntry` with `CompositedTransformFollower` and `LayerLink` (lines 64, 327-411)
  - Space calculation logic (lines 339-353) determines above/below positioning
  - Focus management with per-item focus nodes (lines 76, 361-364, 394)
  - Debounce logic with `debounceWait` parameter (lines 60-61, 208-214)
  - `championCallback` function handles selection (lines 306-317)
  - Uses `FieldColorScheme` for colors (lines 380-381)
  - Keyboard navigation with Tab and Escape keys (lines 112-118)
  - `_autoCompleteOptions` list management (lines 58, 216-227)

### Follow-up Questions
None required - all information gathered from initial answers and code analysis.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
No visual assets to analyze.

## Requirements Summary

### Functional Requirements

**Core Functionality:**
- Extract autocomplete overlay into a standalone, reusable widget that can wrap any field type
- Implement intelligent positioning logic that calculates available space and renders above or below the field accordingly
- Support keyboard navigation (Tab/Down Arrow to enter overlay, Arrow keys to navigate, Enter to select, Escape to dismiss)
- Support mouse interaction (click to select, click outside to dismiss)
- Trigger default callback on selection that updates the field value, with ability for users to override this behavior
- Dismiss overlay on: tap outside, Escape key, field losing focus
- Maintain existing debounce functionality for async option updates
- Preserve existing AutoCompleteOption model integration

**Accessibility:**
- Implement screen reader announcements for:
  - Number of results available when overlay appears
  - Currently focused option as user navigates
  - Selected option when user makes a selection
- Ensure proper ARIA/semantic labeling for overlay and list items
- Maintain keyboard-only navigation support
- Follow WCAG 2.1 AA guidelines as per product roadmap priorities

**Theming:**
- Honor FieldColorScheme for surface background and text colors
- Use Material 3 design patterns as per tech stack standards
- Integrate with existing FormTheme hierarchy (global -> form -> field)
- Support Material elevation and shadow styling

**Architecture:**
- Create wrapper widget pattern that can be applied to any field type
- Expose controller interface for accessing field values (TextEditingController access or raw value listening)
- Maintain separation of concerns between overlay logic and field-specific behavior
- Preserve existing AutoCompleteBuilder integration with updateOptions callback
- Support both sync (initialOptions) and async (updateOptions) option sources

### Reusability Opportunities

**Patterns to Extract from Current Implementation:**
- Overlay positioning calculation logic (lines 339-353 of textfieldwidget.dart)
- LayerLink and CompositedTransformFollower pattern for overlay attachment
- Per-item focus node management for keyboard navigation
- Debounce timer pattern for async updates
- championCallback selection handler pattern

**Components That May Exist:**
- FieldColorScheme theming system (already exists, referenced in textfieldwidget.dart)
- FormTheme hierarchy (already exists per product mission)
- AutoCompleteOption and AutoCompleteBuilder models (already exist)
- FormResults API for value access (already exists)

**Similar Features to Model After:**
- File upload field with drag-and-drop overlay for overlay positioning patterns
- Focus management patterns from ChampionFormController
- Theme integration patterns from existing field widgets (ChampionTextField, ChampionOptionSelect, etc.)

### Scope Boundaries

**In Scope:**
- Refactor autocomplete overlay into standalone reusable widget
- Implement Material 3-compliant overlay rendering
- Add intelligent above/below positioning based on available space
- Implement comprehensive keyboard navigation (Tab, Arrow keys, Enter, Escape)
- Add screen reader announcements for accessibility
- Integrate with FieldColorScheme theming system
- Create wrapper pattern for applying to any field type
- Maintain existing debounce and async option update functionality
- Support default selection callback with override capability
- Implement dismiss-on-outside-tap, dismiss-on-escape, dismiss-on-blur behaviors

**Out of Scope:**
- Applying autocomplete to other field types (future enhancement - this spec focuses on creating the reusable widget)
- Creating new AutoCompleteOption models or changing existing data structures
- Modifying ChampionFormController architecture
- Implementing autocomplete for fields other than text (will be possible after this refactor, but not included in initial implementation)
- Advanced features like multi-select autocomplete or grouped options
- Search highlighting or fuzzy matching (preserve existing string matching logic)

### Technical Considerations

**Integration Points:**
- Must integrate with existing ChampionFormController for value updates
- Must work with existing AutoCompleteBuilder and AutoCompleteOption models
- Must respect existing FormTheme and FieldColorScheme theming system
- Must preserve existing debounce timing configuration
- Should use Material 3 widgets (per tech stack standards)

**Existing System Constraints:**
- Flutter SDK (>=1.17.0) as minimum version
- Dart (>=3.0.5 <4.0.0) with null safety
- Must maintain backward compatibility with existing textfieldwidget.dart behavior
- Must not break existing autocomplete functionality in ChampionTextField

**Technology Preferences:**
- Use Material 3 widgets for overlay rendering
- Follow Flutter best practices for overlay management
- Implement using StatefulWidget pattern consistent with existing codebase
- Use FocusNode and FocusTraversalGroup for keyboard navigation (already in use)
- Leverage CompositedTransformFollower and LayerLink for positioning (already in use)

**Similar Code Patterns to Follow:**
- Widget composition pattern from existing field widgets
- Controller listener pattern from ChampionFormController integration
- Focus management from textfieldwidget.dart (lines 107-189)
- Overlay lifecycle management from textfieldwidget.dart (lines 262-294, 420-428)
- Theme integration from FormFieldWrapperDesignWidget and field builders

**Accessibility Standards:**
- Must comply with WCAG 2.1 AA standards (per roadmap priority #2)
- Implement proper semantic labels and screen reader support
- Ensure keyboard navigation meets accessibility best practices
- Follow Flutter accessibility guidelines from standards documentation

**Code Organization:**
- Create new widget file in `lib/widgets_internal/` directory (consistent with existing structure)
- Export through appropriate barrel files
- Document public API with comprehensive dartdoc comments
- Include usage examples in documentation
