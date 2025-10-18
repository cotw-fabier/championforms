## Input validation standards for Flutter

- **Client-Side Validation**: Implement immediate feedback validation in Flutter UI using `Form` and `TextFormField` validators
- **Server-Side Validation**: Always validate on Serverpod backend; never trust client-side validation alone
- **Clear Validation Messages**: Provide specific, actionable validation messages that tell users how to fix issues
- **Real-Time Feedback**: Use `autovalidateMode` appropriately (e.g., `AutovalidateMode.onUserInteraction`) for better UX
- **Required Fields**: Clearly mark required fields in UI and validate they are not empty or null
- **Type Validation**: Validate data types match expectations (e.g., email format, phone numbers, URLs)
- **Range Validation**: Check numeric inputs are within acceptable ranges; validate string lengths
- **Pattern Matching**: Use regex patterns for format validation (email, phone, postal codes) but keep them maintainable
- **Sanitize Inputs**: Sanitize user input to prevent injection attacks before sending to backend
- **Form State Management**: Use Flutter's `Form` widget with `GlobalKey<FormState>` for coordinated validation
- **Disable Submit on Invalid**: Disable form submission buttons when form is invalid to prevent unnecessary API calls
- **Input Formatters**: Use `TextInputFormatter` to restrict/format input as user types (e.g., phone numbers, currency)
- **Consistent Validation Logic**: Share validation rules between frontend and backend using generated code where possible
