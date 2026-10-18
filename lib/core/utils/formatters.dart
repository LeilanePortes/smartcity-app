import 'package:intl/intl.dart';

/// Formatadores pt-BR para números, moeda, energia e datas.
abstract final class Fmt {
  static final NumberFormat _int = NumberFormat.decimalPattern('pt_BR');
  static final NumberFormat _reais = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  static String inteiro(num v) => _int.format(v);

  static String moeda(num v) => _reais.format(v);

  /// Valor em reais sem o símbolo (para exibir "R$" separado do número).
  static String reais(num v) => _decimal(v, 2);

  /// Número decimal pt-BR sem unidade (ex.: ranking em kWh, coluna sem sufixo).
  static String decimal(num v, {int casas = 1}) => _decimal(v, casas);

  static String _decimal(num v, int casas) =>
      NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: casas)
          .format(v);

  /// kW com 3 casas (consumo instantâneo).
  static String kw(num v) => '${_decimal(v, 3)} kW';

  /// kWh com 1 casa (agregados).
  static String kwh(num v) => '${_decimal(v, 1)} kWh';

  /// Percentual com sinal explícito (variações).
  static String percentualVariacao(num? v) {
    if (v == null) return '—';
    final s = _decimal(v.abs(), 1);
    if (v > 0) return '+$s%';
    if (v < 0) return '−$s%';
    return '0%';
  }

  static String percentual(num v, {int casas = 0}) => '${_decimal(v, casas)}%';

  static String coordenadas(double lat, double lng) =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

  static final DateFormat _hora = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _dataHora = DateFormat("dd/MM 'às' HH:mm", 'pt_BR');
  static final DateFormat _dataCurta = DateFormat('dd/MM', 'pt_BR');

  static String hora(DateTime d) => _hora.format(d.toLocal());
  static String dataHora(DateTime d) => _dataHora.format(d.toLocal());
  static String dataCurta(DateTime d) => _dataCurta.format(d.toLocal());

  /// "há 3 min", "há 2 h", "há 4 d" — para última leitura válida.
  static String desde(DateTime d) {
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inSeconds < 60) return 'agora há pouco';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }
}
