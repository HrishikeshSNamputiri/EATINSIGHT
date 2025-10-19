String _normalize(String value) => value.toLowerCase().trim();

List<String> tokenize(String raw) {
  final normalized = _normalize(raw);
  if (normalized.isEmpty) return const <String>[];
  final parts = normalized.split(RegExp(r'\s+')).where((element) => element.isNotEmpty).toSet().toList();
  parts.sort();
  return parts;
}

bool containsAllTokens({
  required String haystackName,
  required String haystackBrand,
  required List<String> tokens,
}) {
  if (tokens.isEmpty) return true;
  final name = _normalize(haystackName);
  final brand = _normalize(haystackBrand);
  for (final token in tokens) {
    if (!(name.contains(token) || brand.contains(token))) {
      return false;
    }
  }
  return true;
}
