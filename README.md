# Minhas localizações

Aplicativo Flutter para Android desenvolvido na Atividade 1 da disciplina de Programação para Dispositivos Móveis I.

**Integrante:** Bruna Rodrigues Gomes  
**Professor:** Arley

## Objetivo

Coletar continuamente a localização do aparelho, armazenar as posições em um banco SQLite e permitir sua consulta em uma lista e em um mapa interativo.

## Funcionalidades

- Iniciar e interromper a coleta de localização.
- Verificar a disponibilidade do serviço de localização e solicitar permissões.
- Manter a coleta durante a navegação entre telas e ao minimizar o aplicativo.
- Exibir uma notificação enquanto a coleta estiver ativa.
- Armazenar as posições localmente em SQLite.
- Consultar as últimas 100 localizações, da mais recente para a mais antiga.
- Exibir data e hora locais, latitude, longitude e precisão estimada.
- Limpar todo o histórico mediante confirmação.
- Apresentar as localizações em um mapa com ruas e marcadores.
- Destacar o registro mais recente em vermelho.
- Atualizar os registros e reenquadrar os pontos no mapa.
- Utilizar ícone próprio.

A coleta solicita alta precisão e intervalo de 20 segundos. O intervalo efetivo depende do sistema operacional e da disponibilidade de localização.

## Tecnologias

- Dart e Flutter.
- `geolocator`: localização e stream de posições.
- `permission_handler`: permissão de notificações.
- `sqflite`: banco SQLite.
- `path` e `path_provider`: caminhos e armazenamento privado.
- `flutter_map` e `latlong2`: mapa e coordenadas.
- `url_launcher`: abertura do link de atribuição do mapa.

As dependências estão declaradas no `pubspec.yaml`, e as versões resolvidas estão registradas no `pubspec.lock`.

## Execução

### Requisitos

- Flutter SDK instalado.
- Android SDK e ferramentas de compilação configurados.
- Celular Android com depuração USB habilitada ou emulador Android compatível.
- Internet para obter as dependências e carregar novas imagens do mapa.

### Instalação e execução

Clone o repositório:

```sh
git clone https://github.com/brunagomess26/coleta-localizacoes-flutter.git
cd coleta-localizacoes-flutter
```

Instale as dependências:

```sh
flutter pub get
```

Confira o ambiente e os dispositivos disponíveis:

```sh
flutter doctor
flutter devices
```

Execute o aplicativo:

```sh
flutter run
```

Para selecionar um dispositivo específico:

```sh
flutter run -d ID_DO_DISPOSITIVO
```

### Análise estática

```sh
flutter analyze
```

## Utilização

### Coleta

Na tela inicial, selecione **Iniciar coleta** e conceda as permissões solicitadas. A localização do aparelho deve estar habilitada.

Durante a coleta, o botão de início fica desabilitado e o botão **Parar coleta** fica disponível. A notificação informa que a coleta está ativa.

A coleta continua durante a navegação para o histórico e o mapa. Para encerrá-la, selecione **Parar coleta**.

### Histórico

A tela apresenta as últimas 100 localizações salvas, com:

- Data e hora locais.
- Latitude e longitude com seis casas decimais.
- Precisão estimada em metros, com uma casa decimal.

O botão de atualização recarrega a lista. A lixeira permite excluir todo o histórico após confirmação.

Quando a limpeza é realizada durante a coleta, novos registros continuam sendo salvos.

### Mapa

O mapa apresenta as últimas 100 posições salvas.

- Marcadores azuis: registros anteriores.
- Marcador vermelho: registro mais recente.
- Toque no marcador: detalhes da localização.
- Botão de mira: reenquadramento de todos os pontos.
- Botão de atualização: nova consulta aos registros.

As cores representam a ordem dos registros, não sua precisão. Pontos com coordenadas iguais ou próximas podem ficar sobrepostos.

## Organização do projeto

O código está organizado em `lib/features/localizacoes`, com separação entre modelo, persistência, serviços e apresentação.

| Arquivo ou diretório | Responsabilidade |
|---|---|
| `lib/main.dart` | Inicialização do Flutter |
| `lib/app.dart` | Configuração do aplicativo e criação das dependências |
| `models/localizacao.dart` | Representação tipada dos registros e conversão para persistência |
| `data/database/banco_localizacoes.dart` | Abertura do banco e criação da tabela |
| `data/repositories/repositorio_localizacoes.dart` | Inserção, consulta e exclusão dos registros |
| `services/servico_localizacao.dart` | GPS, permissões e stream de posições |
| `services/cache_mapa.dart` | Preparação do cache privado do mapa |
| `presentation/screens/` | Telas, estados e coordenação das operações |
| `presentation/widgets/` | Componentes de apresentação reutilizáveis |

As telas não executam SQL diretamente. A apresentação utiliza objetos `Localizacao`, e as dependências são recebidas por construtor.

A coleta utiliza stream de localização. O processamento com `asyncMap` aguarda a gravação de uma posição antes de processar a seguinte.

## Banco de dados

**Arquivo:** `localizacoes.db`  
**Tabela:** `localizacoes`

| Coluna | Tipo | Restrição |
|---|---|---|
| `id` | INTEGER | Chave primária com autoincremento |
| `latitude` | REAL | Obrigatória |
| `longitude` | REAL | Obrigatória |
| `precisao` | REAL | Obrigatória; valor em metros |
| `instante` | TEXT | Obrigatória; UTC em formato ISO 8601 |

Os registros permanecem no armazenamento privado do aplicativo após seu fechamento.

O instante é armazenado em UTC e convertido para o horário local na apresentação.

O limite de 100 registros aplica-se somente às consultas. Os registros antigos não são excluídos automaticamente.

A limpeza remove todas as linhas, preservando a tabela e o arquivo do banco.

## Mapa e cache

O aplicativo utiliza imagens do OpenStreetMap e apresenta a atribuição **© OpenStreetMap contributors**, com acesso à página de direitos autorais.

O cache de imagens utiliza uma pasta privada do aplicativo, com limite configurado de aproximadamente 100 MB e validade determinada pelos cabeçalhos HTTP do provedor.

Não há download em massa ou modo offline completo. O carregamento de novas imagens depende de conexão com a internet.

- [Atribuição do OpenStreetMap](https://www.openstreetmap.org/copyright)
- [Política de uso das imagens do mapa](https://operations.osmfoundation.org/policies/tiles/)

## Ícone

O ícone próprio está disponível em `assets/icons/localizacoes.png`, acompanhado da fonte vetorial `localizacoes.svg`.

O projeto inclui versões Android para diferentes densidades, ícone adaptativo e ícone da notificação.

## Validação

O aplicativo foi compilado e executado em um **Motorola Moto g9 play com Android 11 — API 30**, conectado por USB.

A análise estática foi concluída com:

```text
No issues found!
```

Nos testes manuais realizados, foram verificados:

- Início e parada da coleta.
- Estado dos botões conforme a coleta.
- Gravação e consulta das posições.
- Continuidade da coleta durante a navegação e em segundo plano.
- Notificação de coleta ativa.
- Persistência após fechar e reabrir o aplicativo.
- Atualização, cancelamento e confirmação da limpeza do histórico.
- Limpeza durante a coleta.
- Apresentação do histórico vazio.
- Formatação dos dados.
- Exibição dos marcadores e destaque do registro mais recente.
- Detalhes dos marcadores, atualização e reenquadramento do mapa.
- Tratamento de GPS desativado e permissão negada.
- Exibição do ícone próprio.

## Limitações

- Implementação configurada para Android.
- Intervalo e precisão sujeitos às condições do serviço de localização.
- Atualização manual do histórico e do mapa.
- Ausência de reinício automático da coleta após encerramento do processo ou reinicialização do aparelho.
- Dependência de internet para carregar imagens do mapa ainda não disponíveis no cache.

## Referências

- [Geolocator](https://pub.dev/packages/geolocator)
- [Permission Handler](https://pub.dev/packages/permission_handler)
- [Flutter Map](https://pub.dev/documentation/flutter_map/latest/)
- [Persistência com SQLite no Flutter](https://docs.flutter.dev/cookbook/persistence/sqlite)
