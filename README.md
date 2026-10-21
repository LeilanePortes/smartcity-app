# Iluminação Pública Inteligente — App Mobile

App Flutter da atividade acadêmica de IoT / Smart Cities — Prefeitura de
Itaguari, GO. Consome a API mockada do `smartcity-backend` (REST + WebSocket).

## Telas

| Tela | O que faz |
|---|---|
| **Mapa da cidade** | `flutter_map` + OpenStreetMap, marcadores por status, heatmap de luminosidade, busca por rua/bairro, filtro por status, bottom sheet do poste. |
| **Detalhe do poste** | Cabeçalho + badge, consumo ao vivo, barra de luminosidade (piso 50%), texto contextual, histórico com gráfico (Hoje/Semana/Mês), log do sensor 360°, ações de manutenção e "ver no mapa". |
| **Dashboard de KPIs** | Seletor Dia/Semana/Mês/Ano, consumo e custo com variação, gráfico atual × anterior, ranking top 5, distribuição por status. |
| **Arquitetura** | Fluxo edge → fog → nuvem com indicador de no ar / fora do ar (API e broker MQTT separados), redução de banda no fog (entrada × saída), gateways por bairro com buffer e alertas recentes do fog. Consulta `GET /arquitetura` a cada 12 s enquanto a aba está aberta. |
| **Arquitetura · OTA** | Seção "OTA · Grupo canário": versões de firmware em campo, implantação por versão do catálogo (com confirmação) e reversão da frota, ondas 5% → 25% → 50% → 100%, contadores de aparelhos, canário × controle com a razão de consumo frente ao limite, decisões dos portões e falhas. Consulta `GET /ota` a cada 5 s com implantação em andamento e a cada 15 s parada. |

Atualização em tempo real via Socket.IO: marcadores do mapa e a tela de detalhe
reagem ao simulador do backend; selo "AO VIVO" indica o estado da conexão.

## Stack

- **Estado:** `flutter_riverpod`
- **HTTP:** `dio` (fachada `SmartcityApi`, um método por endpoint)
- **Mapa:** `flutter_map` + `latlong2`
- **Gráficos:** `fl_chart`
- **Tempo real:** `socket_io_client`
- **Design system BRUT:** IBM Plex Sans / Mono (`google_fonts`), radius 0, sem sombra

Organização por feature em `lib/features/` (`mapa`, `detalhe_poste`, `kpis`,
`arquitetura`, `shell`, `design_system`); base compartilhada em `lib/core/` e `lib/shared/`.

## Rodando

Suba o backend primeiro (`smartcity-backend`, porta 3000), depois:

```bash
flutter pub get
flutter run
```

O app consome a **API v1**: as rotas REST ficam em `/api/v1` (ex.:
`http://localhost:3000/api/v1/postes`) e as listagens respondem paginadas
(`{ itens, pagina, tamanho, total, totalPaginas }`). O Socket.IO
(`/tempo-real`) continua na raiz do servidor.

O endereço do servidor é configurável por `--dart-define`. Informe **só o
servidor**, sem `/api/v1` — o app acrescenta a versão sozinho
(`AppConfig.apiBaseUrl`):

```bash
# Emulador Android (localhost do host = 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Dispositivo físico na mesma rede
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:3000
```

Sem o backend no ar, o app abre normalmente: as telas mostram estado de
carregamento/erro e o selo fica "OFFLINE".

## Verificação

```bash
flutter analyze
flutter test
```

## Build da apresentação

```bash
flutter build web --release            # build/web
flutter build apk --release            # build/app/outputs/flutter-apk/app-release.apk
```
