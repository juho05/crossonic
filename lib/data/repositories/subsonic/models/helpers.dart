String? emptyToNull(String? str) {
  if (str == null) return null;
  if (str.isEmpty) return null;
  return str;
}
