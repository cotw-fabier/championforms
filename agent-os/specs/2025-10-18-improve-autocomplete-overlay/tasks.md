# Task Breakdown: Autocomplete Overlay Widget

## Overview
Total Tasks: 28 sub-tasks across 5 task groups
Assigned roles: ui-designer, testing-engineer

## Task List

### Phase 1: Widget Structure and Core Extraction

#### Task Group 1: Create Standalone Widget Structure
**Assigned implementer:** ui-designer
**Dependencies:** None

- [x] 1.0 Extract autocomplete overlay into standalone reusable widget
  - [x] 1.1 Write 2-8 focused tests for core widget structure
    - Test widget instantiation with required parameters
    - Test widget builds without errors when wrapped around TextField
    - Test LayerLink connection between wrapper and overlay
    - Limit to critical structure tests only
  - [x] 1.2 Create ChampionAutocompleteWrapper StatefulWidget
    - Create new file: `/Users/fabier/Documents/code/championforms/lib/widgets_internal/autocomplete_overlay_widget.dart`
    - Define widget parameters:
      - `child`: Widget (required) - The field widget to wrap
      - `autoComplete`: AutoCompleteBuilder (required) - Configuration
      - `colorScheme`: FieldColorScheme? (optional) - Theme colors
      - `onOptionSelected`: Function(AutoCompleteOption)? (optional) - Selection callback
      - `textEditingController`: TextEditingController? (optional) - For text fields
      - `valueNotifier`: ValueNotifier<String>? (optional) - For other field types
      - `focusNode`: FocusNode (required) - Field's focus node
    - Use immutable final fields with named parameters
    - Include Key? key parameter and pass to super
  - [x] 1.3 Set up State class with core state variables
    - Create _ChampionAutocompleteWrapperState class
    - Declare LayerLink for overlay positioning
    - Declare OverlayEntry? for overlay lifecycle
    - Declare List<AutoCompleteOption> for options tracking
    - Declare List<FocusNode> for per-item focus nodes
    - Declare ScrollController for overlay list
    - Declare Timer? for debounce functionality
    - Declare bool flags: _autoCompleteAvailable, _updatedFromAutoComplete
  - [x] 1.4 Implement build method with CompositedTransformTarget
    - Return CompositedTransformTarget wrapping widget.child
    - Connect LayerLink to target
    - Follow pattern from textfieldwidget.dart lines 435-437
  - [x] 1.5 Ensure widget structure tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify widget instantiates correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- Widget file created at correct location
- Widget accepts all required and optional parameters
- CompositedTransformTarget wraps child correctly
- LayerLink properly initialized

### Phase 2: Overlay Positioning and Display Logic

#### Task Group 2: Implement Smart Overlay Positioning
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 1

- [x] 2.0 Implement intelligent overlay positioning
  - [x] 2.1 Write 2-8 focused tests for positioning logic
    - Test space calculation returns correct values
    - Test overlay positions below when sufficient space
    - Test overlay positions above when insufficient space below
    - Test overlay height respects min/max constraints
    - Limit to critical positioning scenarios only
  - [x] 2.2 Create _createOverlayEntry method
    - Extract from textfieldwidget.dart lines 327-411
    - Return OverlayEntry with Positioned + CompositedTransformFollower
    - Use Material widget for overlay surface (elevation: 4.0)
    - Apply colorScheme?.surfaceBackground and surfaceText colors
    - Set showWhenUnlinked: false on CompositedTransformFollower
  - [x] 2.3 Implement space calculation logic
    - Get RenderBox size and global offset from context
    - Calculate screen height using MediaQuery (minus safe area padding)
    - Calculate spaceBelow: screenHeight - fieldBottom - dropdownMargin
    - Get minHeight and maxHeight from AutoCompleteBuilder
    - Determine goUp boolean: spaceBelow < minHeight
    - Calculate final height: min(availableSpace, maxHeight)
    - Follow pattern from textfieldwidget.dart lines 339-353
  - [x] 2.4 Implement dynamic overlay offset calculation
    - If goUp: offset = -height - dropdownMargin
    - If goDown: offset = fieldHeight + dropdownMargin
    - Set width to match field width from RenderBox size
    - Set height to calculated value from 2.3
  - [x] 2.5 Account for MediaQuery safe areas
    - Use MediaQuery.of(context).padding.top
    - Use MediaQuery.of(context).padding.bottom
    - Subtract from total screen height in calculations
  - [x] 2.6 Ensure positioning tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify above/below positioning logic works
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- Overlay positions below field when space available
- Overlay positions above field when space below insufficient
- Overlay height respects min/max constraints
- Safe areas properly accounted for in calculations
- Material widget used with proper elevation and colors

### Phase 3: Keyboard Navigation and Focus Management

#### Task Group 3: Implement Keyboard Navigation and Accessibility
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 2

- [x] 3.0 Implement keyboard navigation and accessibility features
  - [x] 3.1 Write 2-8 focused tests for keyboard and accessibility
    - Test Tab key moves focus to first option
    - Test Arrow Down navigates to next option
    - Test Arrow Up navigates to previous option
    - Test Enter key selects focused option
    - Test Escape key dismisses overlay
    - Test Semantics widget announces option count
    - Limit to critical keyboard/a11y workflows only
  - [x] 3.2 Create per-item FocusNode list management
    - Generate List<FocusNode> in _createOverlayEntry
    - Create one FocusNode per autocomplete option
    - Dispose all nodes in _disposeAutoCompleteItemFocusNodes method
    - Clear list after disposal
    - Follow pattern from textfieldwidget.dart lines 298-303, 362-364
  - [x] 3.3 Build ListView with Focus widgets for each item
    - Use ListView.builder for performance
    - Set reverse: goUp for proper order when above field
    - Wrap each ListTile in Focus widget with dedicated FocusNode
    - Implement onKey handler for Enter key selection
    - Apply focus highlight: tileColor based on hasFocus
    - Follow pattern from textfieldwidget.dart lines 385-404
  - [x] 3.4 Implement FocusTraversalGroup with ReadingOrderTraversalPolicy
    - Wrap ListView in FocusTraversalGroup
    - Set policy: ReadingOrderTraversalPolicy()
    - Ensures logical tab order through options
    - Follow pattern from textfieldwidget.dart lines 383-384
  - [x] 3.5 Add Semantics widget for screen reader announcements
    - Wrap overlay content in Semantics widget
    - Set liveRegion: true for dynamic announcements
    - Set label: "X options available" where X is option count
    - Add semanticsLabel to each ListTile for current option
    - Follow accessibility standards from accessibility.md
  - [x] 3.6 Implement focus listeners for navigation announcements
    - Add focus listener to each FocusNode
    - On focus change, announce current option to screen reader
    - Use Semantics with liveRegion for announcements
    - Clean up listeners on disposal
  - [x] 3.7 Ensure keyboard and accessibility tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify Tab, Arrow, Enter, Escape keys work
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- Tab key moves focus from field to first option
- Arrow keys navigate between options with visual highlight
- Enter key selects currently focused option
- Escape key dismisses overlay and returns focus to field
- Screen reader announces option count when overlay appears
- Screen reader announces current option on focus change
- FocusTraversalGroup ensures logical keyboard navigation

### Phase 4: Selection, Debounce, and Integration Logic

#### Task Group 4: Implement Selection Callbacks and Debounce Logic
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 3

- [x] 4.0 Implement selection handling and debounce functionality
  - [x] 4.1 Write 2-8 focused tests for selection and debounce
    - Test default selection callback updates controller
    - Test custom onOptionSelected callback overrides default
    - Test first debounce runs at 100ms
    - Test subsequent debounces run at configured interval (default 1000ms)
    - Test overlay dismisses after selection
    - Limit to critical selection/debounce workflows only
  - [x] 4.2 Implement championCallback selection handler
    - Extract pattern from textfieldwidget.dart lines 306-317
    - If widget.onOptionSelected provided, call it and return
    - Otherwise, update textEditingController or valueNotifier with option.value
    - Call option.callback if provided
    - Call _removeOverlay(keepAway: true)
    - Set _updatedFromAutoComplete = true
  - [x] 4.3 Implement dual debounce timer logic
    - Track first run with boolean flag
    - On first value change: schedule callback with 100ms delay
    - On subsequent changes: schedule callback with autoComplete.debounceWait delay (default 1000ms)
    - Cancel existing timer before scheduling new one
    - Follow pattern from textfieldwidget.dart lines 208-214
  - [x] 4.4 Implement _scheduleUpdateOptions method
    - Accept current field value as parameter
    - Call autoComplete.updateOptions callback if provided
    - Update _autoCompleteOptions list with results
    - Call _showOrRemoveOverlay to refresh display
    - Use dual debounce timing from 4.3
  - [x] 4.5 Implement _showOrRemoveOverlay method
    - Check conditions: focusNode.hasFocus, autoComplete.type == dropdown, text not empty, options not empty
    - If conditions met: remove existing overlay, create new overlay, insert into Overlay
    - If conditions not met: remove overlay, clear options list
    - Use WidgetsBinding.instance.addPostFrameCallback for safety
    - Follow pattern from textfieldwidget.dart lines 262-278
  - [x] 4.6 Implement _removeOverlay method
    - Accept optional keepAway and requestFocus parameters
    - If requestFocus: call focusNode.requestFocus and set cursor to end
    - Remove overlay entry if exists
    - Set _autoCompleteAvailable = false
    - Dispose autocomplete item focus nodes
    - Follow pattern from textfieldwidget.dart lines 280-295
  - [x] 4.7 Ensure selection and debounce tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify default and custom callbacks work
    - Verify debounce timing is correct
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- Default selection callback updates field value correctly
- Custom onOptionSelected callback overrides default behavior
- First debounce runs at 100ms, subsequent at configured interval
- Overlay dismisses after selection
- Focus returns to field after selection with cursor at end
- Option.callback invoked when provided

### Phase 5: Testing and Integration Validation

#### Task Group 5: Integration Testing and Validation
**Assigned implementer:** testing-engineer
**Dependencies:** Task Groups 1-4

- [x] 5.0 Review existing tests and validate integration
  - [x] 5.1 Review tests from Task Groups 1-4
    - Review the 2-8 tests written by ui-designer in Task 1.1 (structure)
    - Review the 2-8 tests written by ui-designer in Task 2.1 (positioning)
    - Review the 2-8 tests written by ui-designer in Task 3.1 (keyboard/a11y)
    - Review the 2-8 tests written by ui-designer in Task 4.1 (selection/debounce)
    - Total existing tests: approximately 8-32 tests
  - [x] 5.2 Analyze test coverage gaps for autocomplete overlay feature
    - Identify critical integration workflows lacking coverage
    - Focus on end-to-end autocomplete workflows
    - Check overlay lifecycle (show, navigate, select, dismiss)
    - Check integration with TextEditingController
    - Do NOT assess entire application test coverage
  - [x] 5.3 Write up to 10 additional strategic tests maximum
    - Integration test: full autocomplete workflow (type, show overlay, navigate, select)
    - Integration test: overlay dismiss on tap outside
    - Integration test: overlay dismiss on field blur
    - Integration test: overlay updates when value changes
    - Widget test: accessibility tree validation for Semantics
    - Widget test: theming with custom FieldColorScheme
    - Widget test: overlay repositions when field scrolls
    - Visual regression test: overlay appearance (optional golden test)
    - Do NOT write exhaustive edge case tests
    - Skip performance tests unless business-critical
  - [x] 5.4 Update textfieldwidget.dart to use new wrapper (integration validation)
    - Import ChampionAutocompleteWrapper
    - Remove autocomplete-related code from TextFieldWidget (lines 58, 60-61, 64, 67, 73-76, 208-411, 420-428)
    - Wrap TextField in CompositedTransformTarget with ChampionAutocompleteWrapper
    - Pass required parameters: child, autoComplete, colorScheme, focusNode, textEditingController
    - Verify existing ChampionTextField autocomplete behavior unchanged
    - This is validation, not new feature - ensures no regressions
  - [x] 5.5 Run feature-specific tests only
    - Run tests from 1.1, 2.1, 3.1, 4.1, and 5.3
    - Expected total: approximately 18-42 tests maximum
    - Verify all critical workflows pass
    - Do NOT run entire application test suite
  - [x] 5.6 Manual accessibility validation
    - Test with screen reader (TalkBack on Android or VoiceOver on iOS)
    - Verify announcements: option count, current option, selection
    - Verify keyboard-only navigation works completely
    - Verify focus order is logical
    - Verify touch targets are at least 48x48 dp
    - Document any accessibility issues found

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 18-42 tests total)
- No more than 10 additional tests added by testing-engineer
- TextFieldWidget successfully refactored to use wrapper
- No visual or functional regressions in existing autocomplete
- Full keyboard navigation workflow verified
- Screen reader announcements verified manually
- Overlay positioning above/below verified at screen edges
- Theming with FieldColorScheme verified
- Overlay dismisses correctly on all trigger conditions

## Execution Order

Recommended implementation sequence:
1. Widget Structure and Core Extraction (Task Group 1)
2. Overlay Positioning and Display Logic (Task Group 2)
3. Keyboard Navigation and Accessibility (Task Group 3)
4. Selection, Debounce, and Integration Logic (Task Group 4)
5. Integration Testing and Validation (Task Group 5)

## Implementation Notes

### Key Patterns to Preserve
- **LayerLink + CompositedTransformFollower**: Maintains overlay position during scrolling
- **Per-item FocusNode management**: Enables keyboard navigation with visual feedback
- **Dual debounce timing**: Fast first run (100ms), slower subsequent (1000ms or custom)
- **championCallback pattern**: Default behavior with override support
- **FocusTraversalGroup**: Logical keyboard navigation through options
- **Material widget**: Proper Material 3 elevation and theming

### Technical Constraints
- Widget must work with any field type via controller/notifier pattern
- Must maintain backward compatibility with existing ChampionTextField
- Must follow Material 3 design patterns (per tech-stack.md)
- Must use ListView.builder for performance (per components.md)
- Must meet WCAG 2.1 AA accessibility standards (per accessibility.md)
- Must follow focused testing approach (per test-writing.md)

### Reusability Design
- Widget designed as wrapper that can be applied to any field type
- Support both TextEditingController (for text fields) and ValueNotifier (for other types)
- Clear separation between overlay logic and field-specific behavior
- Exposes clean API for customization (callbacks, theming, configuration)

### Accessibility Requirements
- Screen reader announces option count when overlay appears
- Screen reader announces current option as focus changes
- Screen reader announces selected option on selection
- Proper Semantics widgets with liveRegion for announcements
- Keyboard-only navigation fully supported (Tab, Arrow keys, Enter, Escape)
- Focus highlights visible for keyboard users
- Touch targets at least 48x48 dp (WCAG requirement)

### Testing Philosophy
- Each task group (1-4) writes 2-8 focused tests for their specific area
- testing-engineer adds maximum 10 strategic integration tests
- Total expected: 18-42 tests for this feature
- Focus on critical workflows, not exhaustive coverage
- Each task group verifies ONLY their new tests, not entire suite
- Final validation (5.5) runs all feature-specific tests together
