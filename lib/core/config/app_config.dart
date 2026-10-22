/// Configuração de ambiente do app.
///
/// O endereço do servidor pode ser sobrescrito em build/run com:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
/// (só o servidor, sem `/api/v1` — o app acrescenta a versão da API).
///
/// Emulador Android usa `10.0.2.2` para alcançar o `localhost` da máquina host.
abstract final class AppConfig {
  /// Servidor do backend (sem caminho). Raiz do Socket.IO e de `GET /`.
  static const String servidorUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Prefixo das rotas REST versionadas (RF-APP-01).
  static const String apiVersao = '/api/v1';

  /// Base de todas as rotas REST: servidor + versão, ex.:
  /// `http://localhost:3000/api/v1`. É o único lugar que monta essa URL.
  static String get apiBaseUrl => '${_semBarraFinal(servidorUrl)}$apiVersao';

  /// Socket.IO fica na raiz do servidor (sem `/api/v1`), namespace abaixo.
  static String get realtimeUrl => _semBarraFinal(servidorUrl);
  static const String realtimeNamespace = '/tempo-real';

  /// Tarifa de referência B4a (PRD §6). O backend também devolve em `GET /kpis`.
  static const double tarifaKwh = 0.58;

  static const Duration httpConnectTimeout = Duration(seconds: 8);
  static const Duration httpReceiveTimeout = Duration(seconds: 15);

  static String _semBarraFinal(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;
}
