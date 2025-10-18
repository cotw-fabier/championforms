## Flutter & Dart coding style best practices

- **Effective Dart Guidelines**: Follow the official Effective Dart guidelines for style, documentation, usage, and design
- **Naming Conventions**: Use `PascalCase` for classes/enums, `camelCase` for variables/functions/members, and `snake_case` for file names
- **Line Length**: Keep lines to 80 characters or fewer; configure formatter to enforce this limit
- **Concise and Declarative**: Write concise, modern, technical Dart code; prefer functional and declarative patterns over imperative
- **Small, Focused Functions**: Keep functions short and single-purpose, striving for less than 20 lines per function
- **Meaningful Names**: Use descriptive names that reveal intent; avoid abbreviations except in universally understood contexts
- **Arrow Functions**: Use arrow syntax (`=>`) for simple one-line functions
- **Null Safety**: Write soundly null-safe code; avoid using `!` (null assertion) unless value is guaranteed non-null
- **Pattern Matching**: Leverage Dart's pattern matching features to simplify code and improve readability
- **Exhaustive Switch**: Prefer exhaustive `switch` statements/expressions which don't require `break` statements
- **Remove Dead Code**: Delete unused code, commented-out blocks, and unused imports immediately
- **DRY Principle**: Extract common logic into reusable functions or classes to avoid duplication
- **Const Constructors**: Use `const` constructors for immutable widgets and objects whenever possible to reduce rebuilds
- **Automated Formatting**: Use `dart format` to ensure consistent code formatting across the codebase
