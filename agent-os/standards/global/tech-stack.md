## Flutter + Serverpod tech stack standards

- **Flutter Framework**: Use Flutter for cross-platform mobile, web, and desktop application development
- **Serverpod Backend**: Use Serverpod as the Dart-based backend framework for type-safe client-server communication
- **Dart Language**: Leverage Dart's null safety, pattern matching, records, and async features throughout stack
- **Code Generation**: Use `build_runner` for code generation; Serverpod models, serialization, and Riverpod providers
- **State Management**: Use Riverpod (code generation) for app state management, dependency injection, and async data
- **Routing**: Use `auto_route` package for declarative navigation, deep linking, and web support
- **Forms**: Use ChampionForms package for declarative form building with validation, theming, and centralized state management
- **File Uploads**: Leverage ChampionForms file upload fields with `file_picker`, `super_drag_and_drop` for user file selection
- **Database**: Use PostgreSQL with Serverpod's ORM for type-safe database operations and migrations
- **Serialization**: Leverage Serverpod's automatic serialization for type-safe communication between client and server
- **API Protocol**: Use Serverpod's protocol for RPC-style endpoints and streaming; WebSockets for real-time features
- **Authentication**: Use Serverpod's built-in authentication module or implement custom auth with proper session management
- **Logging**: Use `dart:developer` `log()` on client; Serverpod's logging on server for structured, filterable logs
- **Testing**: Use `package:test` for unit tests, `flutter_test` for widget tests, `integration_test` for E2E tests
- **Linting**: Use `flutter_lints` package with customized rules in `analysis_options.yaml`
- **API Documentation**: Generate API docs with `dartdoc`; Serverpod generates OpenAPI specs automatically
- **Theming**: Use Material 3 with `ColorScheme.fromSeed()` for consistent, accessible theming across platforms
