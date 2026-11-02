# Guia de estudo — entenda o percurso dos dados

Este guia explica a implementação da Atividade 1. Comece pelo fluxo dos dados, depois leia o código em partes. Você não precisa decorar a interface inteira para entender as responsabilidades.

## 1. O que acontece ao tocar em Iniciar coleta?

1. A tela impede um segundo início se estiver ocupada ou coletando.
2. O serviço verifica o GPS, solicita a permissão de localização e verifica a autorização para notificações.
3. O serviço fornece um Stream<Position>.
4. A tela usa asyncMap para transformar cada posição em uma gravação assíncrona.
5. _salvar registra a Future da gravação; _gravar cria um Localizacao.
6. O repositório transforma o objeto em mapa e insere na tabela.
7. A tela informa que a localização foi salva.

Fluxo: posição do GPS → objeto Localizacao → repositório → SQLite. Na consulta: SQLite → mapas → objetos Localizacao → widgets.

## 2. Variáveis e tipos

```dart
final double latitude;
final DateTime instante;
bool _ativa = false;
StreamSubscription<void>? _assinatura;
```

- double: número com casas decimais.
- DateTime: representa data/hora; não usamos texto para fazer toda a lógica da aplicação.
- bool: verdadeiro ou falso.
- final: recebe valor uma vez. Não significa que qualquer objeto referenciado seja imutável; aqui os campos do modelo são finais.
- ?: pode conter null. Não existir assinatura antes do início é um estado válido.
- _: nome privado à biblioteca Dart. Não é apenas uma convenção visual.
- required: o chamador precisa fornecer o argumento nomeado.
- const: objeto constante quando todos os argumentos e o construtor permitem.

Use nomes com significado: latitude, precisao, repositorio. Evite a, b, x para dados do domínio. Os nomes dos membros usam lowerCamelCase e os tipos usam UpperCamelCase.

## 3. O modelo Localizacao

Representa um registro, não a tela ou a conexão. id é opcional porque o SQLite gera o identificador ao inserir.

```dart
Localizacao(
  latitude: posicao.latitude,
  longitude: posicao.longitude,
  precisao: posicao.accuracy,
  instante: posicao.timestamp,
);
```

`toMap()` converte objeto em mapa para gravar. `Localizacao.fromMap()` faz o caminho contrário. É um factory constructor: devolve uma instância construída com os dados do banco. O cast para num seguido de toDouble aceita tanto números inteiros quanto decimais recebidos do SQLite.

## 4. Future, async e await

```dart
Future<void> inserir(Localizacao localizacao) async {
  final conexao = await banco.conexao;
  await conexao.insert('localizacoes', localizacao.toMap());
}
```

Future representa um resultado que estará disponível depois. Future<void> indica conclusão sem valor útil de retorno. async permite usar await. await aguarda aquela etapa sem bloquear o processamento normal da interface.

Não diga que await cria uma thread: ele organiza a espera assíncrona.

## 5. Stream e assinatura

Future: uma conclusão. Stream: sequência de eventos ao longo do tempo. GPS contínuo combina com Stream.

```dart
_assinatura = widget.servico.posicoes()
    .asyncMap(_salvar)
    .listen((_) {}, onError: (Object erro) { /* tratar */ });
```

asyncMap aguarda a Future devolvida por _salvar antes de processar o próximo evento. Um simples listen((posicao) async { ... }) não oferece, por si só, essa garantia de sequência. A StreamSubscription permite cancelar a recepção com cancel().

A Future _gravacao permite esperar a gravação em andamento ao parar; assim um novo início não sobrepõe aquela gravação. A operação de parar não desfaz uma inserção que já começou.

## 6. Coesão e acoplamento

Coesão: os elementos de uma classe trabalham para um propósito claro. ServicoLocalizacao trata GPS e permissões. RepositorioLocalizacoes trata operações de persistência. ItemLocalizacao apresenta um registro.

Acoplamento: quanto uma parte depende de outra. A tela recebe repositório e serviço no construtor e não escreve SQL. Isso reduz dependências globais e detalhes de armazenamento na interface. Ainda existem dependências entre classes: baixo acoplamento não significa ausência de dependência.

Não foi criada uma interface para cada classe: isso aumentaria o código sem necessidade para esta atividade. Uma interface faria sentido se precisássemos trocar implementações com frequência.

## 7. StatefulWidget, StatelessWidget e setState

- StatelessWidget: apresenta dados recebidos, como ItemLocalizacao.
- StatefulWidget: possui estado que muda, como _ativa, _ocupada e a lista de registros.
- setState: informa que o estado mudou e solicita reconstrução da interface.
- initState: inicialização do State; carrega dados uma vez ao abrir a tela.
- dispose: libera os recursos possuídos pelo componente.

Após await, a tela pode já ter sido fechada:

```dart
final registros = await widget.repositorio.consultar();
if (!mounted) return;
setState(() => _registros = registros);
```

mounted informa se o State ainda está associado à árvore. Não coloque uma função async dentro de setState.

## 8. Navegação e continuidade

Navigator.push abre outra rota sem remover a tela inicial. Por isso sua assinatura continua existindo enquanto histórico ou mapa estão abertos. Navigator.pop volta. Se trocássemos a tela inicial por pushReplacement, precisaríamos rever quem é responsável pela coleta.

Minimizar não equivale a dispose. No Android, o foreground service configurado pelo plugin mantém notificação e permite continuar a localização. Se o processo for encerrado, o estado Dart pode desaparecer; não implementamos reinício automático.

## 9. Banco e SQL

```sql
CREATE TABLE localizacoes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  precisao REAL NOT NULL,
  instante TEXT NOT NULL
)
```

INTEGER: inteiro. REAL: número real. TEXT: texto. NOT NULL: obrigatório. Chave primária identifica cada linha. AUTOINCREMENT faz o SQLite gerar ids crescentes.

`query(..., orderBy: 'instante DESC, id DESC', limit: 100)` consulta os últimos registros. DESC significa ordem decrescente. LIMIT limita o resultado, não o total armazenado.

`delete('localizacoes')` sem WHERE apaga todas as linhas; não usa DROP TABLE e não remove o arquivo.

BancoLocalizacoes compartilha uma Future<Database>: duas chamadas simultâneas aguardam a mesma abertura. Se falhar, ela é descartada; uma consulta futura pode tentar novamente.

## 10. UTC e apresentação

```dart
instante.toUtc().toIso8601String();
localizacao.instante.toLocal();
localizacao.latitude.toStringAsFixed(6);
localizacao.precisao.toStringAsFixed(1);
```

UTC padroniza o armazenamento. toLocal converte para o fuso do aparelho. toStringAsFixed formata para exibição e retorna String; não modifica a precisão do número armazenado. Precisão em metros é a estimativa de incerteza do GPS, não o número de casas decimais.

## 11. Erros

try executa a operação; catch trata a falha; finally executa a limpeza do estado, com ou sem erro. rethrow repassa o erro original para uma camada que possa informar ao usuário. O serviço não precisa conhecer SnackBar: ele lança a falha e a apresentação decide a mensagem.

## 12. Mapa

TileLayer fornece imagens de ruas. MarkerLayer mostra os marcadores. LatLng representa uma coordenada. MapController controla a câmera. CameraFit.coordinates calcula o enquadramento, com limite de zoom para um único ponto ou coordenadas iguais.

O mapa recebe objetos tipados, não resultados brutos do SQLite. A primeira localização consultada é a mais recente; ela aparece vermelha. O cache armazena imagens do mapa, não substitui a tabela de localizações.

## 13. Questões para treinar no papel

1. Desenhe o percurso da posição até o SQLite e o caminho de volta até o histórico.
2. Escreva uma classe Localizacao e explique o id opcional.
3. Escreva os métodos inserir, consultar com limite 100 e limpar.
4. Explique a diferença entre Future e Stream com exemplos deste projeto.
5. Explique por que cancelamos a assinatura e liberamos o MapController.
6. Mostre onde existem alta coesão e redução do acoplamento.
7. Por que converter UTC para horário local somente na apresentação?
8. Por que não usar Timer.periodic no lugar do stream?
9. Por que verificar mounted após uma operação assíncrona?
10. Por que LIMIT 100 não exclui os registros antigos?
11. O que acontece com a coleta ao abrir o mapa? E ao encerrar o processo?
12. Por que asyncMap é usado em vez de apenas listen com callback async?

Leia primeiro modelo e repositório, depois serviço e coleta, e por último histórico/mapa. Para cada método, tente dizer em uma frase o que recebe, o que faz e o que devolve.
