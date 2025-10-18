# Specification: Autocomplete Overlay Widget

## Goal
Extract and modernize the autocomplete overlay functionality from TextFieldWidget into a standalone, reusable wrapper widget that uses proper Flutter Material 3 widgets, provides smart positioning, comprehensive accessibility, and can be applied to multiple field types.

## User Stories
- As a developer, I want a reusable autocomplete overlay widget so that I can apply autocomplete to any field type without duplicating code
- As a keyboard user, I want to navigate autocomplete options with Tab and arrow keys so that I can select options without using a mouse
- As a screen reader user, I want to hear announcements about available options and my current selection so that I can effectively use autocomplete
- As a user on a small screen, I want the autocomplete overlay to position itself intelligently so that it's always visible and doesn't get cut off
- As a developer, I want the overlay to respect my theme colors so that it matches my application's design

## Core Requirements

### Functional Requirements
- Extract overlay logic from `textfieldwidget.dart` (lines 64, 76, 262-411) into standalone widget
- Support wrapping any field type via controller pattern (TextEditingController or value listening)
- Calculate available vertical space and position overlay above or below field accordingly
- Support keyboard navigation: Tab/Down Arrow to enter, Arrow keys to navigate, Enter to select, Escape to dismiss
- Support mouse interaction: click to select, click outside to dismiss
- Trigger callback on selection with default behavior that updates field value (overridable by user)
- Dismiss overlay on tap outside, Escape key, or field blur/focus loss
- Maintain dual debounce approach: fast initial run (100ms), slower subsequent runs (1000ms)
- Preserve existing AutoCompleteOption and AutoCompleteBuilder integration
- Account for safe areas (MediaQuery padding) in positioning calculations

### Non-Functional Requirements
- Performance: Overlay positioning must calculate within one frame (16ms) to prevent visual jank
- Accessibility: WCAG 2.1 AA compliance with proper screen reader support
- Maintainability: Clear separation between overlay logic and field-specific behavior
- Reusability: Widget must work with any field type that provides a controller or value
- Compatibility: Must not break existing ChampionTextField autocomplete functionality

## Visual Design
No mockups provided. Widget follows Material 3 design patterns with elevated surface appearance.

### Key UI Elements
- Elevated Material surface with shadow (elevation: 4.0)
- ListView of options (using ListView.builder for performance)
- Focus highlight on currently selected option
- Reverse list order when positioned above field
- Honor FieldColorScheme for surface colors and text

### Responsive Considerations
- Account for MediaQuery safe areas (top and bottom padding)
- Calculate available space dynamically based on field position
- Respect min/max height constraints from AutoCompleteBuilder
- Adjust positioning when keyboard appears on mobile devices

## Reusable Components

### Existing Code to Leverage
- **Overlay positioning logic**: Lines 339-353 of textfieldwidget.dart (space calculation, above/below decision)
- **LayerLink pattern**: Lines 64, 435, 369-378 (attaching overlay to field position)
- **CompositedTransformFollower**: Lines 369-378 (following field position during scrolling)
- **Focus management pattern**: Lines 76, 107-189, 361-364, 394 (per-item focus nodes, keyboard navigation)
- **Debounce timer pattern**: Lines 60-61, 208-214 (dual timing for async updates)
- **championCallback selection handler**: Lines 306-317 (default field update with override support)
- **FieldColorScheme theming**: Lines 23-24, 380-381 (surface background and text colors)
- **AutoCompleteOption model**: Already exists at `/Users/fabier/Documents/code/championforms/lib/models/autocomplete/autocomplete_option_class.dart`
- **AutoCompleteBuilder model**: Already exists at `/Users/fabier/Documents/code/championforms/lib/models/autocomplete/autocomplete_class.dart`
- **FocusTraversalGroup pattern**: Line 383-384 (keyboard traversal policy for list)

### New Components Required
- **ChampionAutocompleteWrapper**: Standalone wrapper widget that can wrap any field type
  - Why new: Current implementation is tightly coupled to TextFieldWidget; need generic wrapper
- **AutocompleteOverlayController**: Controller to manage overlay state and lifecycle
  - Why new: Need clean interface for managing overlay independently of field widget
- **Semantic announcer utility**: Helper for screen reader announcements
  - Why new: Current implementation lacks accessibility announcements; need dedicated utility

## Technical Approach

### Architecture
- Create `ChampionAutocompleteWrapper` as StatefulWidget in `/Users/fabier/Documents/code/championforms/lib/widgets_internal/autocomplete_overlay_widget.dart`
- Widget accepts a child (any field widget), AutoCompleteBuilder configuration, and optional callbacks
- Use generic value listener pattern to support both TextEditingController and other value sources
- Maintain LayerLink + CompositedTransformFollower pattern for robust overlay positioning
- Create per-item FocusNode list for keyboard navigation (dispose on rebuild)
- Use GestureDetector with HitTestBehavior.translucent to detect outside taps

### Database
No database changes required.

### API
Widget Parameters:
- `child`: Widget (required) - The field widget to wrap
- `autoComplete`: AutoCompleteBuilder (required) - Configuration for autocomplete behavior
- `colorScheme`: FieldColorScheme? (optional) - Theme colors for overlay
- `onOptionSelected`: Function(AutoCompleteOption)? (optional) - Override default selection behavior
- `valueNotifier`: ValueNotifier\<String\>? (optional) - For non-TextEditingController fields
- `textEditingController`: TextEditingController? (optional) - For text field integration
- `focusNode`: FocusNode (required) - Field's focus node for blur detection

Selection Flow:
1. User selects option via click or Enter key
2. Widget calls `onOptionSelected` if provided, otherwise updates controller/notifier
3. Widget removes overlay and returns focus to field

Positioning Logic:
1. Get field RenderBox size and global offset
2. Calculate screen height minus safe areas
3. Calculate space below field (screen height - field bottom - dropdown margin)
4. If space below < minHeight, position above; otherwise position below
5. Calculate overlay height as min(available space, maxHeight)

### Frontend
- Use Material widget for overlay surface (not Card or Container)
- Use ListView.builder for options list (better performance than Column + map)
- Wrap each option in Focus widget with individual FocusNode
- Use ListTile for default option rendering (matches Material 3 patterns)
- Use Semantics widget with liveRegion for announcements
- Use ReadingOrderTraversalPolicy for logical keyboard navigation
- Implement onKey handler in Focus widgets for Enter key selection

### Testing
- Unit tests for positioning calculation logic (above/below decision)
- Unit tests for debounce timer behavior
- Widget tests for keyboard navigation (Tab, arrows, Enter, Escape)
- Widget tests for mouse interaction (click option, click outside)
- Widget tests for focus management and blur detection
- Integration tests for TextEditingController integration
- Accessibility tests for screen reader announcements (Semantics tree validation)
- Visual regression tests for overlay appearance and positioning

## Out of Scope
- Implementing autocomplete for fields other than ChampionTextField (architecture supports it, but implementation is future work)
- Creating new AutoCompleteOption or AutoCompleteBuilder models (use existing)
- Modifying ChampionFormController architecture
- Advanced features: multi-select autocomplete, grouped options, search highlighting
- Fuzzy matching or custom filtering logic (preserve existing string matching)
- Mobile keyboard avoidance logic beyond basic safe area handling
- Custom scrollbar styling for overlay list
- Loading states or skeleton screens for async option updates
- Error states for failed option updates

## Success Criteria
- Autocomplete overlay successfully extracted into standalone widget file
- ChampionTextField uses new wrapper widget with identical functionality to current implementation
- Overlay positions above field when space below is insufficient (tested with field at bottom of screen)
- Tab key moves focus from field to first option; arrow keys navigate; Enter selects; Escape dismisses
- Screen reader announces "X options available" when overlay appears and current option on focus change
- Overlay honors FieldColorScheme surfaceBackground and surfaceText colors
- Clicking outside overlay dismisses it; field blur dismisses overlay after 200ms delay
- Debounce timers work as expected: 100ms for first run, 1000ms (or custom) for subsequent runs
- No visual regressions in existing ChampionTextField autocomplete behavior
- Widget can theoretically wrap any field type (demonstrated with at least one alternative field beyond TextField)
