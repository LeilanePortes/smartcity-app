// Coerções defensivas para o parsing dos payloads da API.
// A API é um mock e os números vêm arredondados, mas mantemos o parsing
// tolerante a `int` vs `double` e a campos ausentes.

typedef Json = Map<String, dynamic>;

double asDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int asInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Datas ISO 8601 em UTC (API.md). Mantemos em UTC; a UI converte com `toLocal()`.
DateTime asDate(dynamic v) => DateTime.parse(v as String).toUtc();

DateTime? asDateOrNull(dynamic v) {
  if (v == null || v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v)?.toUtc();
}

List<Json> asList(dynamic v) =>
    (v as List? ?? const []).cast<Json>();

/// Lista de números (ex.: ondas `[5, 25, 50, 100]`); itens inválidos são ignorados.
List<int> asListaInt(dynamic v) => v is List
    ? [for (final x in v) if (x is num) x.toInt()]
    : const [];

/// Lista de strings (ex.: códigos de postes); itens não-string são ignorados.
List<String> asListaString(dynamic v) =>
    v is List ? v.whereType<String>().toList() : const [];
