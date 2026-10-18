import 'package:latlong2/latlong.dart';

import '../../shared/models/poste.dart';

/// Parâmetros geográficos de Itaguari, GO (rede fixa do mock — PRD §3).
abstract final class MapaGeo {
  /// Centro aproximado da cidade, entre os postes do seed.
  static const LatLng centroItaguari = LatLng(-15.920801, -49.606172);

  static const double zoomInicial = 15.2;
  static const double zoomMin = 12;
  static const double zoomMax = 18.5;

  /// OpenStreetMap padrão: gratuito, sem API key. User-Agent identificando o
  /// app conforme a política de uso do OSM.
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> tileSubdominios = ['a', 'b', 'c'];
  static const String tileUserAgent = 'br.gov.itaguari.smartcity_app';
  static const String atribuicao = '© OpenStreetMap contributors';
}

extension PosteLatLng on PosteResumo {
  LatLng get posicao => LatLng(latitude, longitude);
}
