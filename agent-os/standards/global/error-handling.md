## Flutter error handling best practices

- **User-Friendly Messages**: Display clear, actionable error messages to users without exposing technical details or stack traces
- **Fail Fast and Explicitly**: Validate input and check preconditions early; throw clear exceptions rather than allowing invalid state
- **Custom Exceptions**: Create custom exception types for domain-specific errors rather than using generic `Exception`
- **Try-Catch Blocks**: Use `try-catch` for handling exceptions; catch specific exception types when appropriate
- **Async Error Handling**: Properly handle errors in `async`/`await` code with try-catch; handle `Future` errors with `.catchError()`
- **Stream Error Handling**: Handle stream errors using `.handleError()` or error callbacks in `StreamBuilder`
- **Graceful Degradation**: Design UI to degrade gracefully when services fail; show fallback content instead of breaking
- **Centralized Error Handling**: Handle errors at appropriate boundaries (repositories, services) rather than scattering try-catch everywhere
- **Error Logging**: Use `dart:developer` `log()` function with error and stackTrace parameters for structured error logging
- **Clean Up Resources**: Always clean up resources (streams, controllers, subscriptions) in `dispose()` methods
- **ErrorWidget**: Customize Flutter's `ErrorWidget.builder` to show user-friendly error screens instead of red error screens
- **Retry Strategies**: Implement exponential backoff for transient failures in network calls and external services
