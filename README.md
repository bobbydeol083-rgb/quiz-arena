# QuizArena

A modern, animated, gamified quiz battle app — Flutter (GetX) + MERN backend.

Your uploaded UI kit was used as **flow reference only** (home → discover → quiz → leaderboard → profile).
The visual design is new: dark-first "midnight arena" theme, violet→cyan gradients, glassmorphism,
and motion everywhere.

## What's inside

| Folder | What | Status |
|---|---|---|
| `app/` | Flutter app (`quiz_arena`, `com.dork.quizarena`), GetX state management | 91 Dart files, ~10.4k lines, 5 test files |
| `server/` | MERN backend: Express + Mongoose + Socket.io | 44 JS files, **43/43 tests green** |

## Game modes (app)

- **Solo Quiz** — category + difficulty, 10 questions
- **Blitz** — 60 seconds, as many as you can
- **Marathon** — endless, 3 lives, ramping difficulty
- **Daily Challenge** — one deterministic set per day, streak tracking
- **Duel** — realtime 1v1 over Socket.io (random matchmaking or invite)
- **Party Room** — create a room code, friends join, host starts

**Nearby play:** the Nearby tab requests location, posts it to the backend, and lists
online players by distance with one-tap duel invites (MongoDB `$near` geospatial query).

**Gamification:** XP + 8 levels (Bronze → Legend), daily streaks, coins, unlockable badges,
animated results (count-up score, XP bar, confetti, podium).

**Offline-first:** a bundled 126-question bank (`assets/questions.json`) keeps every solo
mode playable with zero backend; an "Offline demo" chip shows when the API is unreachable.

## Run the backend

```bash
cd server
cp .env.example .env   # set MONGO_URI + JWT secrets
npm install
npm run seed           # 6 categories + 120 questions (idempotent)
npm run dev            # http://localhost:5000
npm test               # 43 tests
```

Full REST + socket contract tables are in `server/README.md`.

## Run the app

```bash
cd app
flutter pub get
flutter analyze && flutter test   # first gate on your machine (no Flutter SDK on the build VM)
flutter run
```

Point the app at your backend in `lib/app/core/values/app_config.dart`
(`apiBase` — override supported; defaults: Android emulator → `10.0.2.2:5000`,
everything else → `localhost:5000`). Socket.io uses the same host.

## Integration notes (verified by cross-checking both codebases)

- The server is the single source of truth for grading: `answerIndex` is stripped from
  every client-facing payload (REST + socket). Online reveals are intentionally neutral.
- Realtime games: the server grades on `game:end`, persists `GameResult`s and applies
  XP/coins/badges/streak per player; the app builds the results screen from the
  `game:end` payload and never double-submits via REST.
- `game:answer` and `POST /quiz/submit` accept `selectedIndex: -1` (timed out/skipped).
- `startedAt` accepts epoch-ms or ISO-8601 (what the app sends).
- `room:leave` (or disconnect) mid-game ends it immediately as `forfeit` instead of
  stalling on the server timer.
- Server `streak` shape is `{count, lastPlayedAt}` — the app parses both shapes.
- Party flow uses the server's real events: `room:created {code}` → `room:update {roomId, players[]}`.
