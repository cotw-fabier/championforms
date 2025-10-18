## Flutter responsive design standards

- **LayoutBuilder**: Use `LayoutBuilder` to make layout decisions based on available space constraints
- **MediaQuery**: Use `MediaQuery.of(context)` to access screen size, orientation, padding, and system preferences
- **Responsive Breakpoints**: Define consistent breakpoints (e.g., mobile < 600dp, tablet < 900dp, desktop >= 900dp)
- **Flexible Layouts**: Use `Expanded` and `Flexible` widgets in `Row`/`Column` to create flexible, overflow-safe layouts
- **Wrap Widget**: Use `Wrap` for content that should flow to next line instead of overflowing in `Row` or `Column`
- **Adaptive Widgets**: Use different widget trees for different screen sizes, not just different padding/spacing
- **SafeArea**: Wrap content in `SafeArea` to avoid system UI intrusions (notches, status bars, navigation bars)
- **Platform Conventions**: Respect platform-specific UI conventions using `Platform.isIOS`, `Platform.isAndroid`, etc.
- **Orientation Support**: Handle both portrait and landscape orientations; test UI in both modes
- **FittedBox**: Use `FittedBox` to scale or fit child widget within parent while maintaining aspect ratio
- **AspectRatio**: Use `AspectRatio` widget to maintain consistent aspect ratios across different screen sizes
- **SingleChildScrollView**: Use for content that might overflow on smaller screens but has intrinsic size
- **Minimum Sizing**: Test UI on smallest supported screen size; ensure content doesn't overflow or become unusable
- **Desktop Considerations**: For desktop, use wider layouts, multi-column designs, and mouse/keyboard interactions
- **Web Considerations**: For web, ensure horizontal scrolling is avoided; use responsive max-width containers
