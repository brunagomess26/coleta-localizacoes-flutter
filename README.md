# Minhas localizações — Atividade 1

Integrante: Bruna Rodrigues Gomes.
Plataforma escolhida: **Android**. Não é uma entrega configurada para iOS ou Web.

Aplicativo Flutter didático para coletar coordenadas por stream, persistir no SQLite e consultar histórico/mapa. Sem backend, Timer.periodic, workmanager, Provider, BLoC ou camadas artificiais. As classes concretas são recebidas por construtor: reduz dependências globais sem acrescentar interfaces desnecessárias.

## Situação da validação

Fontes e configurações foram revisados, mas **não foram compilados ou executados**: o ambiente de preparação não possui Flutter, Android SDK ou dispositivo. Não foi possível executar `dart format`, `flutter analyze` ou validar o GPS em segundo plano. Execute os comandos abaixo e os testes manuais antes de entregar. Não apresente este pacote como uma versão já testada.

## Preparar e executar

É necessário um computador com Flutter SDK, Android SDK (normalmente instalado pelo Android Studio), Python 3 e um Android físico com depuração USB ou emulador com Google APIs. VS Code é uma opção de editor. DartPad não executa esta atividade completa.

1. Extraia o ZIP e abra o terminal na pasta `localizacoes_estudo`.
2. Confira a instalação: `flutter doctor`.
3. Execute `python preparar_projeto.py` (Linux: `python3 preparar_projeto.py`). O script cria `projeto_android` com os arquivos nativos oficiais do Flutter e copia estes fontes/configurações sobre a base. Ele não altera uma pasta `projeto_android` já existente.
4. Entre em `projeto_android`.
5. Execute:

```sh
flutter pub get
dart format lib
flutter analyze
flutter devices
flutter run
```

Use Flutter estável recente. O geolocator requer compileSdk de pelo menos 35; confira `android/app/build.gradle.kts` gerado pelo Flutter. Se o padrão do SDK instalado for menor, defina `compileSdk = 35` (ou maior) e instale a plataforma correspondente no Android SDK Manager. Use minSdk de pelo menos 21. Dependências possuem limites de versão no pubspec; após resolver e testar, versione também o `pubspec.lock` gerado.

O wrapper Gradle, MainActivity, temas e demais arquivos nativos são gerados por `flutter create`, não foram reconstruídos manualmente neste pacote. O Manifest entregue substitui o gerado para adicionar permissões e o ícone próprio. Faça os ajustes de código dentro de `projeto_android` depois da preparação.

## Uso

- Autorize notificações quando solicitado; se estiverem bloqueadas, habilite-as nas configurações do aplicativo. A coleta só inicia com o aviso autorizado.
- Ative o GPS e inicie a coleta com o aplicativo aberto. Autorize localização precisa, se desejar a melhor precisão disponível.
- O AndroidSettings pede alta precisão e intervalo de 20 segundos; não garante uma posição exatamente nesse intervalo.
- O geolocator mantém um serviço em primeiro plano com notificação e wake lock. Sua declaração de serviço é mesclada pelo manifest do plugin.
- A permissão enquanto em uso atende ao serviço iniciado com a tela visível. Não iniciamos o serviço em background e não pedimos acesso permanente desnecessário.
- Ao abrir histórico ou mapa, Navigator.push mantém a tela de coleta montada. Ao minimizar, o serviço de localização mantém a coleta conforme as condições do Android; valide no aparelho, incluindo tela apagada. Não se exige sobrevivência ao encerramento do processo, reinicialização ou parada forçada pelo usuário.
- Pare pelo botão Parar coleta. Uma gravação já iniciada pode terminar antes de a parada ser concluída.
- Atualize o histórico e o mapa pelos botões do topo. Os registros não são atualizados automaticamente nessas telas.
- No mapa, toque nos marcadores para detalhes. Vermelho indica o registro mais recente, pintado por cima dos demais. O botão de mira reenquadra os pontos, inclusive quando todos têm a mesma coordenada.

## Banco

`localizacoes.db`, tabela `localizacoes`, com id INTEGER PRIMARY KEY AUTOINCREMENT, latitude/longitude/precisao REAL NOT NULL e instante TEXT NOT NULL. O instante é salvo em UTC ISO 8601 e convertido com toLocal() para exibição.

A consulta usa LIMIT 100, com ordenação por instante e id decrescentes. O limite não remove registros. A limpeza usa DELETE sem WHERE, preservando banco e tabela. A conexão e uma abertura ainda em andamento são compartilhadas; abertura com falha é descartada para permitir nova tentativa.

## Organização

- `main.dart`: inicialização.
- `app.dart`: MaterialApp e criação das dependências compartilhadas.
- `models/localizacao.dart`: dados tipados e conversão para persistência.
- `data/database`: conexão e criação do SQLite.
- `data/repositories`: inserir, consultar e limpar.
- `services/servico_localizacao.dart`: GPS, permissão, stream e configurações.
- `services/cache_mapa.dart`: pasta privada e cache HTTP do mapa.
- `presentation/screens`: estado das telas, assinatura e navegação.
- `presentation/widgets`: apresentação reutilizável do registro e mapa.

## Mapa, atribuição e cache

Usa tiles de ruas do OpenStreetMap: https://tile.openstreetmap.org/{z}/{x}/{y}.png. A atribuição visível tem link para https://www.openstreetmap.org/copyright. O identificador do aplicativo é br.com.bruna.localizacoes, usado no User-Agent. Para publicar ou distribuir amplamente, atualize o identificador e forneça uma identificação de contato/projeto verificável segundo a política do provedor.

O cache nativo do flutter_map recebe uma pasta privada preparada antes do mapa. Respeita cabeçalhos HTTP sem sobrescrever validade, limitado a aproximadamente 100 MB. Não há download em massa, pré-carregamento para uso offline ou promessa de funcionamento offline. Só imagens já armazenadas e utilizáveis poderão aparecer sem rede. Regras: https://operations.osmfoundation.org/policies/tiles/.

## Ícone

Imagem original em `assets/icons/localizacoes.png`, acompanhada da fonte vetorial SVG editável. Inclui versões por densidade, foreground adaptativo, fundo e ícone monocromático da notificação. O Manifest aponta para `@mipmap/ic_localizacoes`. Verifique na tela inicial e lista de aplicativos após instalar; se necessário reinstale para limpar cache do launcher.

## Validação manual antes de entregar

1. Sem GPS: iniciar deve orientar a ativação.
2. Negar permissão e bloquear novas solicitações: conferir mensagens e botão de configurações.
3. Autorizar e iniciar: confirmar notificação, estado dos botões e registros; tocar repetidamente não deve criar outras assinaturas.
4. Navegar para histórico/mapa e minimizar por alguns minutos: voltar, atualizar e confirmar novos instantes. Repetir com tela apagada no aparelho de destino.
5. Parar: após concluir a parada, esperar e atualizar; não devem surgir novas posições da coleta parada.
6. Fechar e reabrir: histórico deve persistir.
7. Em uma base de teste com mais de 100 registros: mostrar apenas os últimos 100, sem apagar os antigos; a limpeza deve remover todos. Não envie a base ao repositório.
8. Cancelar a limpeza deve preservar dados. Confirmar deve mostrar sucesso e atualizar. Durante coleta, novos dados podem surgir após a exclusão.
9. Conferir 6 casas nas coordenadas, 1 na precisão e horário local.
10. No mapa: ruas, atribuição clicável, pontos, mais recente vermelho, toque, zoom, pan, atualização e reenquadramento. Conferir histórico vazio e erro de rede.
11. Conferir ícone instalado, `dart format lib` e `flutter analyze` sem problemas.

## Repositório e entrega

Envie o conteúdo de `projeto_android` ao GitHub e mantenha o nome da integrante neste README. O roteiro de estudo pode acompanhar o projeto. Não envie banco com coordenadas pessoais, build/, .dart_tool/ ou android/local.properties. A entrega no Teams e o envio ao professor devem ser feitos por você.

## Referências das APIs

- https://pub.dev/packages/geolocator
- https://pub.dev/packages/permission_handler/versions/12.0.3
- https://pub.dev/documentation/flutter_map/latest/
- https://docs.flutter.dev/cookbook/persistence/sqlite
