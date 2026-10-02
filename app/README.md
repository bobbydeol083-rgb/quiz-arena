# QuizArena 🏆

A modern, heavily animated, gamified quiz battle app — **Flutter (GetX)** frontend
+ **MERN** backend contract. Dark-first "midnight arena" design: deep space
blues, electric violet → cyan gradients, glassmorphism cards, and motion
everywhere.

> The flat purple mockups in `quiz_app_ui/` were used as **flow reference only**.
> QuizArena is a full redesign — new theme, new motion language, new game modes.

## Features

### Game modes (all playable)
| Mode | Description |
|---|---|
| 🎯 Solo Quiz | Pick category + difficulty, 10 questions |
| ⚡ Blitz | 60 seconds, as many questions as you can |
| 🏃 Marathon | Endless, 3 lives, difficulty ramps easy → hard |
| 📅 Daily Challenge | One deterministic set per day, streak tracking |
| ⚔️ Duel (online 1v1) | Realtime via Socket.io — random matchmaking or invite a nearby friend; live scores, winner screen |
| 🎉 Party Room | Create a room, share the code, host starts the game |

### Gamification
- **XP + levels** (`LevelConfig`): 16 levels, Bronze → Silver → Gold → Platinum → Diamond tiers
- **Coins**, **daily streaks**, **10 unlockable badges** (`BadgeService` rules: First Blood, On Fire, Unstoppable, Speed Demon, Perfectionist, Marathoner, Duelist, Scholar, Explorer, Committed)
- Achievements shelf on the profile, animated XP bar with level-up celebration

### Nearby play
Nearby tab requests location (graceful permission-denied flow), posts it to
`POST /api/players/location`, lists `GET /api/players/nearby` with distance,
and sends realtime duel invites over the socket.

### Offline-first
If the backend is unreachable the app **never crashes**: it falls back to the
bundled 126-question bank (`assets/questions.json`), grades locally, persists
the profile/progress/badges on-device, and shows an **"Offline demo"** chip.
Duel / matchmaking / party features show a friendly "Offline" notice.

## Project structure

```
lib/
  main.dart                        # GetStorage init, theme observer, GetMaterialApp
  app/
    routes/                        # Routes constants, AppPages (GetPage table)
    bindings/                      # InitialBinding (providers → services → repos)
    core/
      theme/                       # AppColors / AppGradients / AppTheme (dark + light)
      values/                      # AppConfig (API base URL), spacing, strings
      utils/                       # LevelConfig, BadgeService, QuizEngine, ThemeController, formatters
      widgets/                     # Shared animated kit (see below)
    data/
      models/                      # AppUser, Question, QuizCategory, QuizSubmitResult, Badge, ...
      providers/                   # ApiService, SocketService, LocalQuestionBank
      repositories/                # Auth, Quiz, Leaderboard, Social, Progress
    modules/<feature>/            # splash, onboarding, auth, home, categories,
                                   # discover, quiz, results, leaderboard, profile,
                                   # nearby, duel, modes, settings
      controllers/ views/ bindings/ (widgets/ where needed)
assets/questions.json              # 126 bundled questions (6 categories × 3 difficulties)
test/                              # unit + controller tests
android/                           # Android scaffolding (applicationId com.dork.quizarena)
```

### Shared animated widget kit (`core/widgets`)
`ArenaBackground` (ambient glows), `ArenaScaffold` (bottom nav with **sliding
active pill** + center Play FAB), `GlassCard`, `GradientButton` (press-down
spring), `GhostButton`, `OfflineChip`, `FadeSlideIn` (staggered entrances),
`CountUpText`, `StreakFlame` (spring pop on streak change), `PulsingDot`,
`XpProgressBar` (animated sweep), `TimerRing` (countdown arc), `ArenaAvatar`,
`EmptyState`, `ShimmerCard`/`ShimmerList`.

### Motion highlights
- Animated splash (logo scale/fade + staggered tagline) and onboarding pages
- Custom page transition on **every** route (fade + scale + slight slide)
- Quiz play: countdown ring, per-question slide-in, option tap morph
  (green pulse / red shake / violet "locked in"), streak flame pop
- Results: count-up score, XP sweep, level-up banner, confetti, badge reveals
- Leaderboard podium rise, animated scope tabs, staggered rank rows
- Hero animation from category card → quiz screen

## Setup & run

```bash
flutter pub get
flutter run
```

### Backend URL
Resolution order:
1. Settings screen → Backend → API base URL (persisted, takes effect immediately)
2. `--dart-define=API_BASE=https://my-server/api`
3. Platform default: `http://10.0.2.2:5000/api` on Android emulator,
   `http://localhost:5000/api` elsewhere

The Socket.io client connects to the same host without the `/api` suffix.

### Build APK
```bash
flutter build apk --debug
```

### Tests
```bash
flutter test
```
Covers: `LevelConfig` xp/level math, `BadgeService` unlock rules,
`QuizEngine` scoring/grading, `QuizController` game flow (offline fakes),
`ApiService` URL building.

## API contract (implemented exactly)

| Method | Path |
|---|---|
| POST | `/api/auth/register` `{username,email,password}` → `{token, refreshToken, user}` |
| POST | `/api/auth/login` `{email,password}` → same |
| POST | `/api/auth/refresh` `{refreshToken}` → `{token}` |
| GET | `/api/auth/me` → `{user}` |
| GET | `/api/categories` → `[{id,name,icon,color,quizCount}]` |
| GET | `/api/questions?category=&difficulty=&count=10` → `[{id,category,difficulty,question,options[4],explanation}]` (no `answerIndex` — server grades) |
| POST | `/api/quiz/submit` `{mode,category,difficulty,answers:[{questionId,selectedIndex,timeMs}],startedAt}` → `{score,correct,total,xpEarned,coinsEarned,newBadges[],levelUp,streak}` |
| GET | `/api/leaderboard?scope=weekly\|alltime&limit=50` → `{entries:[{rank,user{id,username,avatar},points}], me:{rank,points}}` |
| GET | `/api/users/:id` → `{user, stats, badges[]}` |
| POST | `/api/players/location` `{lng,lat}` → `{ok}` |
| GET | `/api/players/nearby?maxDistance=5000&limit=20` → `[{id,username,avatar,xp,level,distanceM,online}]` |
| POST | `/api/rooms` `{mode,category}` → `{code}` |

**Socket.io** (namespace `/`, token via auth handshake + `authenticate` event):

Client → server: `matchmaking:join {category}`, `matchmaking:leave`,
`duel:invite {toUserId,category}`, `duel:accept {inviteId}`,
`duel:decline {inviteId}`, `room:create {mode,category}`, `room:join {code}`,
`room:leave`, `game:answer {questionId,selectedIndex}`

Server → client: `match:found {roomId,opponent}`,
`duel:invited {inviteId,from,category}`, `duel:accepted {roomId}`,
`game:start {roomId,questions}`, `game:score {scores}`,
`game:end {winner,scores}`

### Notes for the backend build
- `room:start` (emitted by the party host) is a **small proposed extension**
  — the backend should start the game on it and emit `game:start`
  (see the code comment in `party_controller.dart`).
- Online questions carry no `answerIndex`, so the client shows a neutral
  violet "Locked in ✓" reveal instead of green/red; the full color reveal
  appears in offline mode. If the backend ever returns per-question
  correctness (e.g. in `game:score` or the submit response), the UI will pick
  it up with no client changes beyond reading it.
- `GET /api/questions` has no daily variant — the daily set is deterministic
  client-side (seeded by date) and graded via the normal submit endpoint.

## Screenshots
_TODO: add screenshots / screen recording here._

## Tech
Flutter stable · Dart 3 · **GetX** (controllers, bindings, named routes) ·
`http` · `socket_io_client` · `geolocator` · `get_storage` · `google_fonts` ·
`flutter_animate` · `confetti` · `shimmer` · `percent_indicator`
