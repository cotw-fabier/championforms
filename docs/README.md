# ChampionForms Documentation

Welcome to the ChampionForms documentation! This directory contains comprehensive guides and references for building forms with ChampionForms.

## Table of Contents

### Getting Started
- [Main README](../README.md) - Quick start, installation, and basic usage
- [CHANGELOG](../CHANGELOG.md) - Version history and release notes

### Custom Fields (v0.6.0+)
- [Custom Field Cookbook](custom-fields/custom-field-cookbook.md) - Practical examples for creating custom fields
- [FieldBuilderContext API Reference](custom-fields/field-builder-context.md) - Complete API documentation for the context class
- [StatefulFieldWidget Guide](custom-fields/stateful-field-widget.md) - Building custom fields with the base class
- [Converters Guide](custom-fields/converters.md) - Type conversion mixins for field values

### Migration Guides
- [Migration Guide: v0.3.x → v0.4.0](migrations/MIGRATION-0.4.0.md) - Upgrading to namespace-based API
- [Migration Guide: v0.5.x → v0.6.0](migrations/MIGRATION-0.6.0.md) - Upgrading to simplified custom field API

### API Reference
- [Form Controller](api/form-controller.md) - State management and controller methods (Coming Soon)
- [Field Types](api/field-types.md) - Built-in field types and their properties (Coming Soon)
- [Validation](api/validation.md) - Validation system and built-in validators (Coming Soon)

### Theming
- [Theming Guide](themes/theming-guide.md) - Customizing form appearance (Coming Soon)
- [Custom Themes](themes/custom-themes.md) - Creating and applying themes (Coming Soon)

## Quick Links

### For New Users
1. Start with the [Main README](../README.md) for installation and basic usage
2. Review [Field Types](api/field-types.md) to understand available widgets (Coming Soon)
3. Explore [Custom Field Cookbook](custom-fields/custom-field-cookbook.md) for advanced use cases

### For v0.5.x Users Upgrading to v0.6.0
1. **Read First:** [Migration Guide: v0.5.x → v0.6.0](migrations/MIGRATION-0.6.0.md)
2. Review [Custom Field Cookbook](custom-fields/custom-field-cookbook.md) for updated examples
3. Reference [FieldBuilderContext API](custom-fields/field-builder-context.md) for new API

### For Custom Field Developers
1. [Custom Field Cookbook](custom-fields/custom-field-cookbook.md) - Start here with practical examples
2. [StatefulFieldWidget Guide](custom-fields/stateful-field-widget.md) - Learn the base class pattern
3. [FieldBuilderContext API Reference](custom-fields/field-builder-context.md) - Deep dive into the context API
4. [Converters Guide](custom-fields/converters.md) - Type conversion patterns

## What's New in v0.6.0

ChampionForms v0.6.0 dramatically simplifies custom field creation by reducing boilerplate from **120-150 lines to 30-50 lines** (60-70% reduction).

### New Features
- **FieldBuilderContext**: Bundles 6 parameters into one clean context object
- **StatefulFieldWidget**: Abstract base class with automatic lifecycle management
- **Converter Mixins**: Reusable type conversion logic
- **Simplified FormFieldRegistry**: Static registration methods

### Breaking Changes
⚠️ **This is a breaking change release** for custom field implementations. Built-in fields (TextField, OptionSelect, etc.) continue to work without changes, but if you've created custom fields, you'll need to migrate them.

See the [v0.6.0 Migration Guide](migrations/MIGRATION-0.6.0.md) for details.

## Contributing

Contributions are welcome! If you find errors in the documentation or have suggestions for improvements, please open an issue or pull request on [GitHub](https://github.com/fabier/championforms).

## License

ChampionForms is released under the MIT License. See [LICENSE](../LICENSE) for details.
