# Initial Spec Idea

## User's Initial Description
The goal is to dramatically simplify the custom field creation API in ChampionForms while maintaining all necessary hooks for validation, state management, focus handling, and callbacks. The current API requires ~120-150 lines of boilerplate code per custom field. The new API should reduce this to ~30-50 lines while providing both high-level convenience helpers and low-level flexibility.

Key improvements to implement:
1. FieldBuilderContext class - bundles 6 builder parameters into one context object with convenience methods
2. StatefulFieldWidget base class - handles controller integration boilerplate automatically
3. Simplified registration API - FormFieldRegistry.register() with inline converter support
4. Converter mixins - TextFieldConverters, MultiselectFieldConverters, etc. to eliminate boilerplate
5. Unified builder signatures between registry and fieldBuilder property
6. Comprehensive documentation and examples

The user has confirmed they want:
- Priority: Simpler registration API
- Breaking changes are acceptable
- Keep both builder approaches (registry + fieldBuilder)
- Both high-level helpers and low-level flexibility

## Metadata
- Date Created: 2025-11-13
- Spec Name: simplify-custom-field-api
- Spec Path: agent-os/specs/2025-11-13-simplify-custom-field-api
