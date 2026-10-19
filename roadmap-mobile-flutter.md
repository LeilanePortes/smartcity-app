# Roadmap — App Mobile (Flutter)

Iluminação Pública Inteligente · Prefeitura de Itaguari, GO

Trilha independente, iniciada somente após o marco de conclusão da trilha de backend. Consome a API já documentada e com dados mockados. Baseado no PRD do sistema e no design aprovado das 3 telas.

## Fase 1 · Setup e design system

- [ ] Setup do projeto Flutter e organização por feature (mapa, detalhe do poste, KPIs).
- [ ] Cliente HTTP para consumo da API do backend (dio ou http).
- [ ] Gerenciamento de estado (Provider, Riverpod ou Bloc).
- [ ] Implementação dos tokens do design system: cores herdadas do BRUT, tipografia IBM Plex Sans / IBM Plex Mono, radius 0, sem sombra.
- [ ] Componentes base reutilizáveis: cards, badges de status, seletor de período (segmented control), botões.

## Fase 2 · Tela Mapa da cidade

- [ ] Integração `flutter_map` com tiles OpenStreetMap.
- [ ] Marcadores por poste, coloridos conforme status retornado por `GET /postes`.
- [ ] Camada de heatmap de luminosidade (plugin ou overlay customizado).
- [ ] Busca por rua/bairro e filtros por status.
- [ ] Bottom sheet com resumo do poste selecionado e CTA para o detalhe.

## Fase 3 · Tela Detalhe do poste

- [ ] Cabeçalho com código, endereço, coordenadas e badge de status.
- [ ] Consumo em tempo real e barra de luminosidade com marcação do piso (50%).
- [ ] Texto contextual dinâmico (evento de veículo detectado ou aviso de telemetria ausente).
- [ ] Histórico de consumo com seletor Hoje / Semana / Mês, consumindo `GET /postes/:id/telemetria`.
- [ ] Log de eventos do sensor 360°, consumindo `GET /postes/:id/eventos`.
- [ ] Ações "Agendar manutenção" (`PATCH /postes/:id/status`) e "Ver no mapa".

## Fase 4 · Dashboard de KPIs

- [ ] Seletor de período Dia / Semana / Mês / Ano.
- [ ] Cards de consumo total e custo total, com variação percentual frente ao período anterior.
- [ ] Gráfico comparativo do período atual frente ao anterior.
- [ ] Ranking dos 5 postes de maior consumo.
- [ ] Distribuição de postes por status em barra empilhada.

## Fase 5 · Tempo real no app

- [ ] Conexão ao WebSocket do backend para atualização ao vivo de consumo e luminosidade.
- [ ] Reatividade no mapa (marcadores) e na tela de detalhe (indicador "AO VIVO").

## Fase 6 · Integração entre telas e fechamento

- [ ] Sincronização entre seleção no mapa e tela de detalhe.
- [ ] Revisão de consistência visual entre as três telas (cards, badges, seletor de período).
- [ ] Testes de navegação ponta a ponta com dados mockados do backend.
- [ ] Build final para apresentação da atividade.

## Fase 7 · Arquitetura em camadas

- [ ] Tela "Arquitetura" consumindo `GET /arquitetura` (edge → fog → nuvem).
- [ ] Indicador de no ar / fora do ar por camada, com API e broker MQTT da nuvem separados.
- [ ] Redução de banda no fog em destaque: entrada × saída (mensagens e KB), porcentagens e horário da janela.
- [ ] Gateways do fog por bairro (postes online / total) e buffer de mensagens.
- [ ] Alertas recentes do fog com acesso ao detalhe do poste.
- [ ] Aviso de modo de reserva (`modo: "interno"`) e consulta periódica (12 s) enquanto a aba estiver aberta.

## Fase 8 · OTA com grupo canário

- [ ] Seção "OTA · Grupo canário" na aba Arquitetura consumindo `GET /ota`.
- [ ] Versões de firmware em campo (barra empilhada + chips).
- [ ] Implantação por versão do catálogo (`POST /ota/implantacoes`) e reversão da frota (`POST /ota/reverter`), com confirmação e mensagens de erro 400/409 da API.
- [ ] Implantação atual: status, ondas 5% → 25% → 50% → 100%, contadores de aparelhos e próxima avaliação.
- [ ] Canário × controle: consumo normalizado e razão frente ao limite dos critérios.
- [ ] Histórico de decisões dos portões e falhas de instalação.
- [ ] Consulta a cada 5 s com implantação em andamento e a cada 15 s parada, só com a aba aberta.

## Marco de conclusão

A trilha mobile é considerada completa quando as três telas estão navegáveis, consumindo os dados reais da API mockada do backend (não mais dados estáticos locais), com atualização em tempo real funcional e consistência visual validada contra o design aprovado.
