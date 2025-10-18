## Dart documentation and commenting standards

- **Dartdoc Style**: Write `dartdoc`-style comments using `///` for all public APIs to enable documentation generation
- **Single-Sentence Summary**: Start doc comments with a concise, user-centric summary sentence ending with a period
- **Separate Summary**: Add a blank line after the first sentence to create a distinct summary paragraph
- **Comment Wisely**: Explain *why* code is written a certain way, not *what* it does; the code itself should be self-explanatory
- **No Useless Documentation**: Avoid documentation that only restates what's obvious from the code's name or signature
- **Document for Users**: Write with the reader in mind; answer questions someone using the API would have
- **Avoid Redundancy**: Don't document both getter and setter; documentation tools treat them as a single field
- **Consistent Terminology**: Use consistent terms and phrasing throughout documentation
- **Code Samples**: Include code examples in doc comments to illustrate usage of complex APIs
- **Parameters and Returns**: Use prose to describe what functions expect, return, and what exceptions they might throw
- **Before Annotations**: Place doc comments before metadata annotations (e.g., `@override`, `@deprecated`)
- **Library-Level Comments**: Consider adding library-level doc comments to provide overview of purpose and usage
- **Markdown Sparingly**: Use markdown for formatting but avoid excessive styling; never use HTML
- **Backticks for Code**: Enclose code references in backticks; use triple backticks with language for code blocks
