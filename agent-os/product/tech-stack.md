# ChampionForms Tech Stack

This document outlines all technical choices and dependencies used in the ChampionForms package.

## Core Platform

### Language & Framework
- **Dart** (>=3.0.5 <4.0.0): Primary language with null safety, pattern matching, and modern language features
- **Flutter** (>=1.17.0): Cross-platform UI framework for rendering form components across mobile, web, and desktop

## Package Architecture

### Package Type
- **Flutter Package**: Reusable library published to pub.dev, consumed by Flutter applications
- **Distribution**: Published as `championforms` on pub.dev package registry

### Dependencies

#### Core Dependencies
- **flutter (SDK)**: Flutter framework and widgets for UI rendering
- **email_validator** (^3.0.0): Email address validation utility for DefaultValidators
- **super_clipboard** (^0.9.1): Clipboard operations for copy/paste functionality
- **super_drag_and_drop** (^0.9.1): Native drag-and-drop support for file uploads
- **collection** (^1.19.0): Extended collection utilities for Dart
- **uuid** (^4.5.1): UUID generation for unique field identifiers
- **file_picker** (^10.3.2): Native file picker dialog integration for file upload fields
- **cross_file** (^0.3.4+2): Cross-platform file abstraction
- **mime** (^2.0.0): MIME type detection and validation for file uploads

#### Development Dependencies
- **flutter_test (SDK)**: Flutter testing framework for widget and unit tests
- **flutter_lints** (^5.0.0): Official Flutter linting rules for code quality
- **custom_lint** (^0.6.8): Custom linting rules and analysis

## Application Integration (Consumer Apps)

When ChampionForms is integrated into applications, those apps typically use:

### State Management
- **Riverpod** (code generation): Recommended state management for dependency injection and async data (per tech-stack.md standards)
- **Note**: ChampionForms itself is state-management agnostic via ChampionFormController

### Routing
- **auto_route**: Declarative navigation for multi-page forms and deep linking (per tech-stack.md standards)

### Backend Integration
- **Serverpod**: Dart-based backend framework for type-safe form submission APIs (per tech-stack.md standards)
- **PostgreSQL**: Database for storing form submissions via Serverpod ORM

## Development Tools

### Code Quality
- **analysis_options.yaml**: Custom lint rules configuration
- **flutter_lints**: Standard Flutter code analysis rules
- **custom_lint**: Project-specific linting rules

### Testing Framework
- **flutter_test**: Widget testing and unit testing
- **integration_test**: End-to-end testing for form workflows
- **package:test**: Dart testing utilities

### Build System
- **build_runner**: Code generation for serialization and model generation (when integrated with Serverpod)
- **Flutter build system**: Native compilation toolchain

### Documentation
- **dartdoc**: API documentation generation
- **README.md**: Package documentation with usage examples
- **CHANGELOG.md**: Version history and migration notes

## Platform-Specific Integrations

### iOS
- **Info.plist**: Permissions configuration for file_picker (photo library, camera access)
- **Xcode**: Native iOS build toolchain

### Android
- **AndroidManifest.xml**: Permissions configuration for file_picker (storage, camera)
- **Gradle**: Native Android build system

### macOS
- **Entitlements files**: Sandbox permissions for file_picker
- **Xcode**: Native macOS build toolchain

### Web
- **Flutter Web**: HTML/CSS/JS compilation target
- **MIME type handling**: Browser-based file type detection

## Design System

### Material Design
- **Material 3**: Modern Material Design components and theming
- **ColorScheme.fromSeed()**: Dynamic color generation for consistent theming
- **ThemeData**: Material theme configuration integration

### Custom Theming
- **FormTheme**: ChampionForms custom theme system
- **FieldColorScheme**: Field-level color customization for different states
- **Pre-built themes**: softBlueColorTheme, redAccentFormTheme, iconicColorTheme

## File Upload Stack

### File Selection
- **file_picker**: Native file dialog integration
- **cross_file**: Platform-agnostic file representation

### Drag & Drop
- **super_drag_and_drop**: Native drag-and-drop support
- **super_clipboard**: Clipboard integration for file operations

### File Validation
- **mime**: MIME type detection
- **Custom validators**: DefaultValidators for file type and size validation

## Validation Architecture

### Core Validation
- **FormBuilderValidator**: Pattern-based validator definition
- **DefaultValidators**: Built-in validation library (email, numeric, length, file types)
- **Custom validators**: User-defined validation functions

### Email Validation
- **email_validator**: RFC-compliant email address validation

## State Management (Internal)

### Controller Pattern
- **ChampionFormController**: Centralized form state management
- **TextEditingController**: Flutter's text input controller (managed internally)
- **ChangeNotifier**: State notification system for reactive updates
- **ValueNotifier**: Lightweight state for focus and validation

## Testing Strategy

### Unit Tests
- **package:test**: Pure Dart logic testing
- **Validator testing**: FormBuilderValidator and DefaultValidators tests

### Widget Tests
- **flutter_test**: Widget rendering and interaction testing
- **Controller testing**: ChampionFormController behavior verification

### Integration Tests
- **integration_test**: End-to-end form workflows
- **Platform testing**: File upload, autocomplete, validation flows

## Distribution & Versioning

### Package Registry
- **pub.dev**: Official Dart/Flutter package repository
- **Semantic versioning**: MAJOR.MINOR.PATCH version scheme

### Version Control
- **Git**: Source control
- **GitHub**: Repository hosting at github.com/cotw-fabier/championforms/

### Release Process
- **CHANGELOG.md**: Version history documentation
- **pub publish**: Package publishing workflow
- **GitHub releases**: Tagged releases with notes

## Logging & Debugging

### Development Logging
- **dart:developer log()**: Structured logging for debugging
- **Flutter DevTools**: Widget inspector and performance profiling
- **print statements**: Simple console output during development

## Future Considerations

Technologies under consideration for future releases:

- **Firebase Storage**: Cloud file storage integration for uploads
- **AWS S3**: Enterprise file storage option
- **Image manipulation libraries**: For file upload preprocessing
- **Animation packages**: Enhanced form transitions and effects
- **Accessibility testing tools**: Automated a11y validation
