String unescapeString(String input) {
  return input
      .replaceAll(r'\n\n', '\n')
      .replaceAll(r'\t', '')
      .replaceAll(r'\', '');
}
