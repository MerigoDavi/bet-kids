Escolhi Flutter porque já tinha feito dois projetos menores com ele antes, e o próprio projeto do módulo também.

Para rodar o projeto, o único pré-requisito é ter o Flutter SDK instalado e um dispositivo ou emulador configurado:

```bash
flutter pub get
flutter run
```

O banco SQLite é criado automaticamente na primeira execução, então não tem nenhum script de migração para rodar. O Firebase é completamente opcional, já que o app funciona 100% offline, e se a configuração do Firebase falhar no `main.dart`, ele só imprime um log e segue em frente.

---

Agora para o que realmente importa, que é como esse negócio foi construído.

## Estrutura geral

Dividi o projeto em três camadas principais dentro de `lib/`:

- `core/` — constantes, tema e utilitários sem dependências de Flutter Widget
- `data/` — modelos, banco local, serviços externos
- `presentation/` — providers de estado, widgets e telas

Não é exatamente Clean Architecture, mas é próximo o suficiente para que cada camada saiba quem ela pode chamar sem criar dependência circular.

## Por onde comecei: os modelos

Comecei pelo `data/models/` para definir o que era um usuário e o que era um resultado de jogo antes de construir qualquer outra coisa.

O `UserProfile` ficou com `id`, `username`, `avatar` (que é um emoji), `coins`, `gamesPlayed`, `totalWon`, `bestWin` e `createdAt`. Coloquei o `coins` começando em 1000 como default para que qualquer jogador novo já tenha algo pra apostar. O `avatar` ser um emoji foi para não precisar lidar com upload de imagem nem com assets. O sistema de login só mostra uma grade de 12 emojis e o usuário escolhe um.

O `GameResult` guarda `userId`, `gameType` (que é um enum com os tipos de jogo), `bet`, `payout`, `won` e `playedAt`. A separação entre `bet` e `payout` em vez de guardar só o delta foi porque queria mostrar no histórico tanto o quanto apostou quanto o quanto recebeu de volta.

Para serialização/deserialização usei `toMap()` e `fromMap()` à mão. Pesquisei usar `json_serializable` mas achei que ia adicionar complexidade de geração de código para um modelo simples, então fiz na mão mesmo. Deu mais trabalho do que eu esperava porque o SQLite não tem tipo `DateTime`, então guardo como `millisecondsSinceEpoch` e converto nas duas pontas.

## Banco de dados local

Com os modelos definidos, fui para o `data/local/local_database.dart`. Usei o `sqflite`, que é o pacote padrão de SQLite para Flutter. A primeira coisa que tive que entender é que o `sqflite` não é uma ORM, então você escreve SQL na mão. Achei isso bom, na verdade, porque não precisei aprender a API de query de nenhuma biblioteca.

Criei duas tabelas:

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  avatar TEXT NOT NULL,
  coins INTEGER NOT NULL DEFAULT 1000,
  ...
)

CREATE TABLE game_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  ...
)
```

Coloquei a criação no `onCreate` do `openDatabase`, então a tabela existe na primeira vez que o app sobe, sem precisar de nenhum comando extra. O método `initialize()` é chamado no `main.dart` antes do `runApp`, então quando qualquer tela tenta acessar o banco, ele já está pronto.

Um problema que tive: o `getLeaderboard` precisava retornar os usuários ordenados por moedas, mas a versão online vem do Firestore e a offline vem do SQLite. No `UserProvider`, o `loadLeaderboard` tenta o Firestore primeiro e cai pro SQLite se a lista vier vazia. Não é ideal porque "lista vazia" e "sem conexão" são coisas diferentes, mas funcionou para o escopo da ponderada bem o suficiente.

## Gerenciamento de estado

Escolhi o `provider` porque é o mais recomendado na documentação oficial do Flutter para projetos do tamanho desse. Fiquei um tempo olhando para Riverpod e BLoC mas resolvi não aprender dois frameworks novos ao mesmo tempo.

Criei dois providers: `AuthProvider` e `UserProvider`. O `AuthProvider` cuida de login com Firebase Auth, e o `UserProvider` carrega e persiste o perfil do usuário e o histórico de jogos. Os dois são registrados no `MultiProvider` no `main.dart` e disponíveis para qualquer widget na árvore.

O `UserProvider` tem uma propriedade que tomou mais tempo do que deveria, o `_multiplicadorGlobal`. No começo eu tinha esse estado de multiplicador na tela da roleta e tive que mover para o provider quando percebi que o Cara ou Coroa também precisava dele.

## O `main.dart` e o `app.dart`

O `main.dart` é bem enxuto, trava a orientação em portrait, inicializa o banco e as notificações, tenta subir o Firebase num bloco try/catch, e chama `runApp`.

O `app.dart` é onde ficou uma das partes mais discutíveis do projeto: o loop de notificações de reengajamento. O `BetKidsApp` implementa `WidgetsBindingObserver` para escutar o ciclo de vida do app. Quando o app vai para segundo plano (`paused` ou `detached`), um `Timer` de 5 segundos começa, e depois dispara uma notificação repetida a cada 2 segundos via `Timer.periodic`. Quando o app volta ao primeiro plano, os timers são cancelados. O comentário no código diz "inferno das notificações" e isso resume bem.

## As telas

### LoginScreen

Bem simples, um campo de texto para o nome, uma grade de emojis para o avatar, e um botão. O `AuthProvider.signIn()` cria uma conta anônima no Firebase Auth e retorna o `uid`, que vira o ID do usuário no banco. Se não tiver Firebase, o `signIn()` gera um UUID local. Depois de criar o usuário, navega para a `HomeScreen` com `pushReplacementNamed` para que o botão de voltar não leve de volta ao login.

### HomeScreen

A home é uma grade 2x3 de cards de jogos. Cada card tem uma cor, um emoji e uma rota. Coloquei a lista de jogos como uma constante de records (a feature de records do Dart 3.0 que eu tinha medo de usar mas acabou sendo bem legível):

```dart
const _jogos = [
  (emoji: '🎡', nome: 'Roleta', desc: 'Agite o celular!', rota: AppRoutes.roulette, cor: AppColors.colorRoulette),
  ...
];
```

A home também tem dois comportamentos automáticos: a recompensa diária e o detector de inatividade do "Tio Sorte". A recompensa diária usa `addDailyReward()` que é chamado num `Future.delayed` de 500ms no `initState` para dar tempo da tela renderizar antes de abrir o dialog. O detector de inatividade roda a cada 15 segundos e verifica se o usuário ficou mais de 45 segundos sem apostar, se sim, o Tio Sorte aparece.

### RouletteScreen — o hardware começou aqui

A roleta foi a tela que mais tempo levou, principalmente por causa do acelerômetro. A ideia é que você agita o celular para girar a roda, e a intensidade do agite determina quantas voltas a roda dá e por quanto tempo ela gira.

Criei um `ShakeDetector` separado em `core/utils/shake_detector.dart` para encapsular a lógica de detecção. Ele escuta o `accelerometerEventStream` do `sensors_plus`, calcula a magnitude do vetor `(x, y, z)` e dispara o callback `onShake` quando a magnitude passa de 25.0 m/s² com um cooldown de 1200ms para não disparar múltiplas vezes num único agite.

O callback recebe uma `intensidade` normalizada entre 0 e 1, calculada em relação ao máximo testado de 55 m/s². Essa intensidade é usada na `RouletteScreen` com uma curva quadrática:

```dart
final voltas = (2 + (intensidade * intensidade * 14)).round();
final duracao = (1200 + (intensidade * intensidade * 7800)).round();
```

A curva quadrática foi na tentativa e erro: com curva linear a diferença entre agite fraco e forte era imperceptível visualmente, mas com quadrática um agite mole gira 2 voltas em 1.2s e um agite forte gira 16 voltas em 9s, o que é bem mais satisfatório.

O `AnimationController` da roda recebe uma rotação alvo calculada antes de o giro começar, então o resultado já está determinado quando a animação inicia — ela só chega até ele de forma animada. O segmento vencedor é um `Random().nextInt()` sobre os segmentos da roda.

### MamadeiraScreen — acelerômetro de tilt

O Suco Tang foi a funcionalidade mais estranha de implementar.

Usei o `AccelerometerEvent.y` para medir a inclinação. Em repouso com o celular em pé, `y ≈ 9.8` (gravidade total no eixo Y). Quando você deita o celular para frente, `y ≈ 0`. Então calculei o tilt como:

```dart
final t = ((9.8 - e.y) / 9.8).clamp(0.0, 1.0);
```

Tem um detalhe importante, o copo só esvazia e nunca enche sozinho. Se você virou o celular até 0.6 e voltou para o normal, o nível fica em 0.6. Para reiniciar, tem um botão "Reencher copo" que zera o `_tiltMax`, limitado a 3 reenchimentos. Sem isso, qualquer movimento acidental do celular ia desfazer o progresso, o que seria frustrante.

O visual do copo é um widget personalizado `_CopoSuco` com um `CustomClipper` para fazer o formato de trapézio (mais largo no topo, mais estreito na base). O nível do líquido é um `AnimatedContainer` com `height = _altura * nivelLiquido` e duração de 80ms, o que deixa a animação fluida sem atrasar.

A tabela de multiplicadores fica em `_tiers`:

| Tilt mínimo | Multiplicador |
|-------------|---------------|
| 0.0         | 1x (sem risco)|
| 0.2         | 1.5x          |
| 0.4         | 2x            |
| 0.65        | 3x            |
| 0.85        | 5x            |

Quando o multiplicador está ativo, todos os jogos mostram um banner laranja no topo avisando. O multiplicador é consumido após o primeiro jogo via `resetMultiplicador()` no provider.

### CoinFlipScreen — física real com o acelerômetro

O Cara ou Coroa foi a tela tecnicamente mais divertida. Em vez de apertar um botão para jogar a moeda, você literalmente joga o celular para cima. O acelerômetro detecta quando o celular foi arremessado, a moeda começa a girar na tela, e para quando o celular volta para a mão com magnitude estável.

O fluxo é dividido em 4 estados (`_Estado`):
1. `apostando` — escolhe cara ou coroa e o valor
2. `lancando` — esperando o arremesso (magnitude > 20 m/s²)
3. `girando` — a moeda está "no ar" (esperando o celular parar)
4. `resultado` — mostra o resultado com haptic feedback

A detecção de "celular pegou de volta" foi a parte mais difícil. Não dava para usar só "magnitude caiu", porque na queda o celular também tem aceleração. Testei alguns limiares e defini uma "faixa de repouso" entre 7.5 e 12.0 m/s², que é o range de magnitude quando o celular está parado na mão. Mas mesmo assim era disparado rápido demais, então adicionei `_duracaoParadoNecessaria` de 180ms, então o celular precisa estar na faixa por pelo menos 180ms seguidos e o giro precisa ter durado pelo menos 600ms antes de parar. Um timeout de 5 segundos garante que nunca fica travado esperando o celular.

### CigarroScreen — microfone

A tela do cigarro usa o microfone para detectar quando você "traga". O pacote `record` da pub.dev fornece um stream de amplitude via `onAmplitudeChanged`. Testei vários limiares e cheguei em `-24.0 dBFS` como o ponto que diferencia sopro/assopro normal de ruído ambiente.

Quando a amplitude passa do limiar, `_tragar()` é chamado, o cigarro acende (animação de brasa laranja com glow), espera 1 segundo, depois `_soprarBolhas()` adiciona 10 bolhas ao estado com posições, tamanhos e durações aleatórias. As bolhas são widgets `_Bolha` que usam `TweenAnimationBuilder` para subir e desaparecer com uma deriva lateral usando `sin(t * pi * 3)` para o movimento ondulante.

O arquivo de gravação é salvo em um arquivo temporário (necessário pela API do `record`) e deletado no `dispose()` da tela. Se o usuário negar permissão de microfone, mostra uma mensagem com botão para tentar novamente que chama `_iniciarMicrofone()` de novo.

O cigarro visualmente é um widget `_Cigarro` desenhado com `Column` de `Container`s: a brasa no topo (que alterna cor e glow via `AnimatedContainer`), uma pontinha cinza, o corpo branco com gradiente e a marca "MARLBORO KIDS" em `RotatedBox`, e o filtro marrom na base. Passei um tempo maior do que devia desenhando esse cigarro.

## O "Tio Sorte" — IA local on-device

Esse foi o item mais difícil do projeto. O `AiCasinoHostService` usa `flutter_gemma` para rodar o modelo Gemma 3 270M localmente no dispositivo. O modelo é baixado do Hugging Face na primeira execução (exige aceitar a licença e gerar um token), passado via `--dart-define=HUGGINGFACE_TOKEN=hf_xxx` no build.

```dart
const _personagem =
    'Você é "Tio Sorte", o anfitrião caricato e dublê de vilão de um cassino fictício...'
    'Use propositalmente táticas óbvias de manipulação (urgência falsa, "quase ganhou", "só mais uma"),'
    'como uma sátira escancarada de um vilão de desenho animado — nunca sutil, sempre caricato.';
```

O serviço tem um sistema de fallback com frases prontas para cada situação (`perdeu`, `vaiApostar`, `inatividade`, `sequencia`) porque: a) o modelo pode não estar carregado na hora do evento, b) o dispositivo pode não ter memória suficiente, c) o token pode não estar configurado. Com o fallback, a feature nunca trava esperando o modelo.

Tem também um timeout de 6 segundos na chamada de inferência. Se o modelo demorar mais do que isso pra responder, cai pro fallback. O modelo é carregado em background na primeira vez que o serviço é chamado, então chama `garantirModeloCarregado()` sem `await` para começar o download, e usa o fallback enquanto espera.

O popup do Tio Sorte (`AiHostPopup`) aparece em 4 situações:
- Depois de perder (Cara ou Coroa e Roleta)
- Antes de confirmar uma aposta pequena no Cara ou Coroa (com 50% de chance — Random().nextBool())
- Quando o usuário fica 45 segundos inativo na HomeScreen
- A cada 5 jogos consecutivos (sequência de apostas)

## Notificações

O `NotificationService` usa `flutter_local_notifications` e está integrado com o ciclo de vida do app pelo `WidgetsBindingObserver` no `app.dart`. Existem 4 tipos:

- **Vitória** — disparada imediatamente pelo `UserProvider.recordGameResult()` quando `won == true`
- **Recompensa diária** — disparada no `addDailyReward()` sempre que o app abre
- **Conquista** — disponível no serviço, não implementei trigger ainda
- **Reengajamento** — a notificação "A roleta está esperando!" que dispara repetidamente quando o app vai para segundo plano

A notificação de reengajamento tem um `payload` com a rota `/roulette`. Quando o usuário toca nela, o `_onNotificationTap` usa o `navigatorKey.currentState?.pushNamed(route)` para navegar direto para a roleta, mesmo que o app tenha sido fechado e reaberto.

Para isso funcionar o `MaterialApp` precisa do `navigatorKey: NotificationService.navigatorKey`, que é um `GlobalKey<NavigatorState>` estático. Isso era necessário porque o callback de toque na notificação não tem `BuildContext` disponível.

## Firebase — opcional mas funcionando

O `FirestoreService` salva usuários e resultados na nuvem quando o Firebase está configurado. Todos os métodos do serviço silenciam erros internamente, então se o Firestore não estiver disponível, o `UserProvider` continua funcionando só com o SQLite local.

O `loadLeaderboard` tenta o Firestore primeiro (leaderboard global) e cai pro SQLite local se vier vazio. Com Firebase configurado, todos jogadores aparecem no ranking de todos.

Para configurar o Firebase:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Isso gera um `lib/firebase_options.dart` novo com suas credenciais. O arquivo commitado no repo tem credenciais de exemplo que só funcionam no ambiente de desenvolvimento.

## Tela de Perfil e Leaderboard

A `ProfileScreen` mostra: saldo de moedas, total de jogos, total ganho, melhor vitória, e o histórico das últimas 20 partidas. O histórico é carregado pelo `UserProvider.loadHistory()` no `initState` da tela.

A `LeaderboardScreen` mostra um pódio com os top 3 (usando tamanhos diferentes de cards para 1º, 2º e 3º lugar) e uma lista dos demais. O provider é o `UserProvider.leaderboard` populado por `loadLeaderboard()`.

Tem um botão de compartilhar no perfil e na roleta que usa `share_plus`. O `ShareService.shareWin()` monta uma mensagem formatada com o nome do usuário, o jogo e a quantidade de moedas, e abre o sheet de compartilhamento nativo.

## Tema e cores

Todas as cores ficam em `AppColors`. O tema base é dark navy (`#0D1B2A`), o accent principal é ouro (`#F4C542`). Nunca usei `Theme.of(context).colorScheme` nem nada assim, referenciei as constantes do `AppColors` direto em cada widget. Não é o mais "correto" do Flutter, mas foi mais rápido e nunca errei uma cor por usar o token errado do tema.

A fonte é `Nunito` via `google_fonts` em quase tudo, com `Ultra` para títulos dramáticos (o nome do cigarro ficou particularmente bom com `Ultra`).

## Como rodar

```bash
# Dependências
flutter pub get

# Modo offline (sem Firebase)
flutter run

# Com modelo de IA (precisa de token do HuggingFace)
flutter run --dart-define=HUGGINGFACE_TOKEN=hf_SeuTokenAqui
```

O banco `bet_kids.db` é criado automaticamente em `getDatabasesPath()` (que fica em um diretório interno do app no dispositivo) na primeira execução.
