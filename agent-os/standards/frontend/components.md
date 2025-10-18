## Flutter widget composition standards

- **Widgets are UI**: Everything in Flutter is a widget; compose complex UIs from smaller, reusable widgets
- **Single Responsibility**: Each widget should have one clear purpose and render one coherent piece of UI
- **Stateless by Default**: Prefer `StatelessWidget` unless the widget needs to manage internal state
- **Immutability**: Widgets (especially `StatelessWidget`) must be immutable; use `final` for all fields
- **Composition over Inheritance**: Build complex widgets by composing smaller widgets rather than extending existing ones
- **Private Widget Classes**: Extract UI sections into small private `Widget` classes instead of helper methods returning widgets
- **Small Build Methods**: Break down large `build()` methods into smaller, reusable private widget classes
- **Const Constructors**: Always use `const` constructors for widgets that don't depend on runtime data
- **Const in Build**: Use `const` keyword when instantiating widgets in `build()` methods to reduce rebuilds
- **Clear Widget Interface**: Define explicit, well-typed parameters with required/optional distinction and defaults
- **Minimal Parameters**: Keep parameter count manageable; if widget needs many parameters, consider composition or splitting
- **Named Parameters**: Use named parameters for widget constructors to improve readability and flexibility
- **Key Parameter**: Include a `Key? key` parameter and pass it to `super(key: key)` for all custom widgets
- **Reusability**: Design widgets to be reusable across different contexts with configurable parameters
- **Build Performance**: Avoid expensive operations (network calls, complex calculations) directly in `build()` methods
- **ListView Performance**: Use `ListView.builder` or `SliverList` for long lists to create lazy-loaded, performant lists
