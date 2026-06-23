# 🎰 BetKids — Cassino Infantil Educacional

Aplicativo mobile Flutter com tema de cassino para crianças, desenvolvido como projeto acadêmico.

> ⚠️ **Nota:** Este app é exclusivamente para fins educacionais e não envolve dinheiro real.

---

## 🎮 Jogos e Funcionalidades

| Jogo | Descrição | Destaque |
|------|-----------|----------|
| 🎡 Roleta | Roda colorida com 12 segmentos | **Acelerômetro** — agite o celular para girar |
| 🃏 Blackjack | Jogo de cartas clássico | Hit, Stand, Double Down |
| 🎰 Caça-Níqueis | 3 rolos com símbolos emoji | Jackpot até 50x |
| 🧠 Trivia Quiz | Perguntas de múltipla escolha | Integração com API externa (Open Trivia DB) |

### Outras telas
- 🏠 **Home** — grade de jogos com saldo de moedas
- 👤 **Perfil** — estatísticas, conquistas e histórico
- 🏆 **Ranking** — leaderboard com pódio dos top 3
- 🔐 **Login** — cadastro com avatar emoji e nome

---

## 📋 Checklist de Requisitos

- [x] **Implementação mobile** — Flutter (Android + iOS)
- [x] **Múltiplas telas** — 9 telas com navegação funcional
- [x] **Backend** — Firebase Firestore (opcional) + SQLite local (sempre funcional)
- [x] **Banco de dados** — SQLite local via `sqflite` + Firestore (cloud)
- [x] **API externa** — [Open Trivia Database](https://opentdb.com/) (sem chave)
- [x] **Notificações** — locais (vitória, recompensa diária, conquista) via `flutter_local_notifications`
- [x] **Compartilhamento** — via `share_plus` (resultado de vitória, perfil, posição no ranking)
- [x] **Hardware** — Acelerômetro via `sensors_plus` (roleta acionada por shake)
- [x] **Interface colorida** — tema dark com gradientes, animações e confetes

---

## 🛠 Tecnologias

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Flutter 3.x / Dart |
| Estado | Provider (ChangeNotifier) |
| Backend | Firebase Auth + Firestore |
| DB Local | SQLite (sqflite) + SharedPreferences |
| API | Open Trivia Database (opentdb.com) |
| Hardware | sensors_plus (acelerômetro) |
| Notificações | flutter_local_notifications + firebase_messaging |
| Compartilhamento | share_plus |
| Animações | flutter_animate + confetti |
| Tipografia | Google Fonts (Nunito) |

---

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK >= 3.0.0 instalado
- Android Studio / Xcode configurado
- Dispositivo físico ou emulador

### Passos

```bash
# 1. Clonar repositório
git clone <repo-url>
cd bet_kids

# 2. Instalar dependências
flutter pub get

# 3. Rodar (modo offline — funciona sem Firebase)
flutter run

# 4. [Opcional] Configurar Firebase
dart pub global activate flutterfire_cli
flutterfire configure
# Isso substituirá lib/firebase_options.dart com sua configuração real
```

### Modo Offline vs Online

O app funciona **completamente** sem Firebase:
- Dados persistidos localmente em SQLite
- Leaderboard local
- Notificações locais funcionando

Com Firebase configurado:
- Sincronização na nuvem
- Leaderboard global
- Push notifications via FCM

---

## 🏗 Arquitetura

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + rotas
├── core/
│   ├── constants/               # Cores e rotas
│   ├── theme/                   # ThemeData
│   └── utils/
│       ├── card_deck.dart       # Lógica de baralho
│       └── shake_detector.dart  # Detecção de agitação (acelerômetro)
├── data/
│   ├── models/                  # UserProfile, GameResult, TriviaQuestion
│   ├── services/                # Auth, Firestore, Trivia API, Notifications, Share
│   └── local/                   # SQLite database helper
└── presentation/
    ├── providers/               # AuthProvider, UserProvider (ChangeNotifier)
    ├── widgets/                 # Componentes reutilizáveis
    └── screens/                 # 9 telas do app
```

---

## 🎯 Fluxo Principal

```
SplashScreen
    ↓ (usuário novo)
LoginScreen → escolhe avatar + nome
    ↓
HomeScreen → grade com os 4 jogos + perfil + ranking
    ↓               ↓               ↓           ↓
RouletteScreen  BlackjackScreen  SlotMachine  TriviaScreen
(shake!)        (cartas)         (rolos)      (API + timer)
    ↓
ProfileScreen → histórico + conquistas + compartilhar
    ↓
LeaderboardScreen → pódio + ranking geral
```

---

## 📱 Hardware Utilizado

**Acelerômetro** — O jogo da Roleta usa `sensors_plus` para detectar quando o usuário agita o celular. O threshold de 15 m/s² detecta um movimento de shake e aciona o giro automático da roda.

```dart
accelerometerEventStream().listen((event) {
  final magnitude = sqrt(event.x² + event.y² + event.z²);
  if (magnitude > 15.0) spinRoulette(); // Shake detectado!
});
```

---

## 👥 Equipe

Projeto acadêmico — Inteli

---

## 📄 Licença

Uso educacional apenas. Não para distribuição pública.
