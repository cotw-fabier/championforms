## Flutter accessibility (A11Y) standards

- **Color Contrast**: Ensure text has minimum 4.5:1 contrast ratio against background; 3:1 for large text (WCAG 2.1)
- **Semantic Labels**: Use `Semantics` widget to provide clear, descriptive labels for interactive elements and images
- **Screen Reader Testing**: Regularly test with TalkBack (Android) and VoiceOver (iOS) to ensure usable experience
- **Dynamic Text Scaling**: Design UI to remain usable when users increase system font size; test with large text
- **Touch Targets**: Ensure interactive elements are at least 48x48 dp for adequate touch target size
- **Focus Order**: Verify logical tab/focus order for keyboard navigation; use `FocusNode` to control focus when needed
- **Semantic Buttons**: Use semantic button widgets (`ElevatedButton`, `TextButton`) instead of generic `GestureDetector` when possible
- **Alternative Text**: Provide meaningful `semanticsLabel` for images, icons, and decorative elements
- **Form Labels**: Associate labels with form fields; use `InputDecoration.labelText` for proper screen reader support
- **Error Announcements**: Use `Semantics` with `liveRegion: true` to announce important errors or status changes
- **Avoid Color-Only Information**: Don't rely solely on color to convey information; use text labels or icons too
- **Reduced Motion**: Respect user's reduce motion preference; provide option to disable animations
- **Keyboard Navigation**: Ensure all interactive features are accessible via keyboard for users who can't use touch
- **Contrast Themes**: Support both light and dark themes with proper contrast in each mode
- **Exclude Decorative Elements**: Use `excludeSemantics: true` for purely decorative elements to reduce screen reader noise
