## Flutter development conventions

- **SOLID Principles**: Apply SOLID principles throughout the codebase for maintainable, extensible architecture
- **Composition over Inheritance**: Favor composition for building complex widgets and business logic
- **Immutability**: Prefer immutable data structures; widgets (especially `StatelessWidget`) should always be immutable
- **Separation of Concerns**: Separate UI (widgets) from business logic (services, repositories, notifiers)
- **Layered Architecture**: Organize code into logical layers - Presentation (widgets), Domain (business logic), Data (models, repositories), Core (utilities)
- **Feature-Based Organization**: For larger projects, organize by feature with each having presentation/domain/data subfolders
- **Standard Project Structure**: Follow Flutter conventions with `lib/` containing source code and `lib/main.dart` as entry point
- **Package Management**: Use `flutter pub add` for dependencies, `flutter pub add dev:` for dev dependencies
- **Dependency Injection**: Use manual constructor dependency injection to make dependencies explicit and testable
- **API Documentation**: Add documentation comments (`///`) to all public APIs including classes, methods, and top-level functions
- **Changelog Maintenance**: Keep a changelog to track significant changes and improvements
- **Version Control**: Use clear commit messages, feature branches, and meaningful pull requests with descriptions
- **Environment Configuration**: Use environment variables for configuration; never commit secrets or API keys
- **Code Generation**: Run `dart run build_runner build --delete-conflicting-outputs` after modifying files requiring code generation
