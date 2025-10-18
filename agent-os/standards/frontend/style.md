## Flutter theming and styling standards

- **Material 3**: Use Material 3 design system with `useMaterial3: true` in `ThemeData` for modern, consistent UI
- **ColorScheme.fromSeed**: Generate harmonious color palettes from single seed color for light and dark themes
- **Centralized Theme**: Define centralized `ThemeData` object in `MaterialApp` for consistent application-wide styling
- **Light and Dark Themes**: Implement both light and dark theme support using `theme` and `darkTheme` properties
- **Theme Access**: Use `Theme.of(context)` to access theme properties; never hardcode colors or text styles. In widgets pull the `Theme.of(context)` into a local variable and then use that for future theme calls. `final theme = Theme.of(context);` and then `final primaryColor = theme.colorScheme.primaryColor`
- **Text Theme**: Use `Theme.of(context).textTheme` for all text styling (displayLarge, titleLarge, bodyMedium, etc.)
- **Component Themes**: Customize component appearance using specific theme properties (appBarTheme, elevatedButtonTheme, cardTheme)
- **Google Fonts**: Use `google_fonts` package for custom fonts; define `TextTheme` for consistent typography
- **Custom Theme Extensions**: Use `ThemeExtension<T>` for custom design tokens not covered by standard `ThemeData`
- **Color Contrast**: Ensure text meets WCAG 2.1 contrast ratios (4.5:1 for normal text, 3:1 for large text)
- **60-30-10 Rule**: Apply 60% primary color, 30% secondary color, 10% accent color for balanced color schemes
- **Responsive Text**: Use relative text sizing that adapts to user's system font size preferences
- **WidgetStateProperty**: Use `WidgetStateProperty.resolveWith` for state-dependent styling (pressed, hovered, disabled)
- **Shadow and Elevation**: Use consistent elevation values; Material 3 handles shadows automatically based on elevation
- **Icons**: Use Material Icons from `Icons` class; use `ImageIcon` for custom icons from assets
