# QuizArena Server

Production-grade MERN backend for **QuizArena**, a gamified multiplayer quiz game.
Express 4 + Mongoose 8 + Socket.io 4, JWT access/refresh auth, and a single
gamification engine shared by the REST and realtime paths.

## Quick start

```bash
cd server
cp .env.example .env      # then set JWT_SECRET + MONGO_URI
npm install
npm run seed              # 6 categories + 120 questions (idempotent)
npm start                 # or: npm run dev (watch mode)
```

Health check: `GET http://localhost:5000/health`

## Scripts

| Script        | What it does                                        |
|---------------|-----------------------------------------------------|
| `npm start`   | Start the server (REST + Socket.io)                 |
| `npm run dev` | Start with `node --watch`                           |
| `npm run seed`| Idempotent seed of categories + 120 questions       |
| `npm test`    | Jest + Supertest + mongodb-memory-server (all green) |

## REST API

Base path: `/api`. Errors always look like `{ "error": { "code": "...", "message": "..." } }`.

Auth uses `Authorization: Bearer <accessToken>`.

| Method | Endpoint                        | Auth | Description |
|--------|---------------------------------|------|-------------|
| POST   | `/auth/register`                | –    | `{username,email,password}` → 201 `{token, refreshToken, user}` |
| POST   | `/auth/login`                   | –    | `{email,password}` → 200 `{token, refreshToken, user}` |
| POST   | `/auth/refresh`                 | –    | `{refreshToken}` → 200 `{token, refreshToken}` (rotated) |
| POST   | `/auth/logout`                  | ✅   | `{refreshToken?}` → 200 `{ok:true}` (revokes session) |
| GET    | `/auth/me`                      | ✅   | 200 `{user}` (full profile incl. stats) |
| GET    | `/categories`                   | –    | 200 `[{id,name,icon,color,description,quizCount}]` |
| GET    | `/questions?category=&difficulty=&count=10` | – | 200 `[{id,category,difficulty,question,options[4],explanation}]` — **never includes `answerIndex`** |
| POST   | `/quiz/submit`                  | ✅   | `{mode,category?,difficulty,answers:[{questionId,selectedIndex,timeMs}],startedAt}` (`selectedIndex: -1` = timed out; `startedAt` accepts epoch-ms or ISO-8601) → 200 `{score,correct,total,xpEarned,coinsEarned,newBadges[],levelUp,level,tier,streak,avgTimeMs}` |
| GET    | `/leaderboard?scope=weekly\|alltime&limit=50` | optional | 200 `{scope,entries:[{rank,user:{id,username,avatar},points}],me:{rank,points}}` |
| GET    | `/users/:id`                    | –    | 200 `{user:{id,username,avatar,xp,level,tier,coins,streak,badges,online,lastSeen},stats}` |
| POST   | `/players/location`             | ✅   | `{lng,lat}` → 200 `{ok:true}` |
| GET    | `/players/nearby?maxDistance=5000&limit=20` | ✅ | 200 `[{id,username,avatar,xp,level,online,distanceM}]` (excludes self, `$near` sorted) |
| POST   | `/rooms`                        | ✅   | `{mode,category?}` → 201 `{code,roomId}` |
| GET    | `/rooms/:code`                  | ✅   | 200 `{room}` |
| POST   | `/rooms/:code/join`             | ✅   | 200 `{room}` |

`user` shape (register/login): `{id,username,email,avatar,xp,level,tier,coins,streak:{count,lastPlayedAt},badges,online,lastSeen,stats}`.

### Gamification

`src/utils/gamification.js` is the single source of truth (unit-tested), used by
both `POST /api/quiz/submit` and the Socket.io game flow:

- **Levels** — XP thresholds `[0,100,250,500,1000,1800,3000,5000]` → levels 1–8,
  tiers Bronze → Legend.
- **XP** — `(correct×10 + streakBonus + speedBonus) × difficultyMultiplier`
  (`easy 1 / medium 1.5 / hard 2`); streakBonus = `min(streak,10)×2`;
  speedBonus = `+2` per correct answer under 5s.
- **Score** — `correct×100 + timeBonus` (up to +50 per correct answer, decaying over 10s).
- **Coins** — `correct×2 + 5` (perfect) `+ 10` (duel win).
- **Streak** — same calendar day keeps it, yesterday increments, older resets.
- **Badges** — `first_blood`, `sharpshooter` (≥8/10), `perfectionist` (10/10),
  `speed_demon` (avg <5s), `streak_3`, `streak_7`, `marathoner` (marathon ≥15),
  `duelist` (duel win), `scholar` (100 correct all-time).

Grading is always server-side: the client never sees `answerIndex`, and
`/quiz/submit` re-loads questions from MongoDB before scoring.

## Socket.io events

Connect, then emit `authenticate {token}`. Unauthenticated sockets receive only
`error {code,message}` events.

| Direction | Event | Payload → Response |
|-----------|-------|--------------------|
| → | `authenticate` | `{token}` → ack `{ok,user}` + `authenticated` |
| → | `matchmaking:join` | `{category}` → `matchmaking:queued`, then `match:found {roomId, opponent}`, then `game:start {roomId,mode,questions[],questionCount,timePerQuestionMs}` |
| → | `matchmaking:leave` | → `matchmaking:left` |
| → | `duel:invite` | `{toUserId, category}` → target gets `duel:invited {inviteId, from, category}` (60s expiry) |
| → | `duel:accept` | `{inviteId}` → inviter gets `duel:accepted {roomId}`, room gets `game:start` |
| → | `duel:decline` | `{inviteId}` → inviter gets `duel:declined` |
| → | `room:create` | `{mode, category}` → ack `{code}` + `room:created` |
| → | `room:join` | `{code}` → room gets `room:update {roomId, players[]}` |
| → | `room:start` | (host only) → room gets `game:start` |
| → | `room:leave` | leaves the room + any live game; if the game drops to ≤1 player it ends immediately with reason `forfeit` (remaining player wins) |\n| → | `game:answer` | `{questionId, selectedIndex}` (`-1` = timed out/skipped: counted as answered, never correct) → ack `{correct}`; room gets `game:score {scores[]}` |
| ← | `game:end` | `{roomId, reason, winner, scores[], rewards[]}` (rewards carry xp/coins/badges/levelUp per player) |
| ← | `player:left` | `{userId}` when a player disconnects mid-game |
| ← | `error` | `{code, message}` |

Questions sent over the socket are sanitized (no `answerIndex`).

## Seed

```bash
npm run seed
```

Upserts 6 categories (Science, Sports, History, Technology, Geography,
Entertainment) and 120 real questions (20/category, mixed difficulties) by
unique key — safe to re-run. Requires `MONGO_URI` to be reachable.

## Tests

```bash
npm test
```

Jest + Supertest + `mongodb-memory-server` (no external MongoDB needed):

- `tests/auth.test.js` — register/login/me/refresh rotation/logout
- `tests/gamification.test.js` — XP/level/streak/grading/badge unit tests
- `tests/quiz.test.js` — submit grading + XP math + `answerIndex` never leaks
- `tests/nearby.test.js` — `$near` geo query, self-exclusion, distance filter
- `tests/leaderboard.test.js` — weekly vs alltime scopes
- `tests/socket.test.js` — matchmaking → game:start → answers → game:end, duel invite flow

## Production notes

- **Secrets**: set a strong `JWT_SECRET` (startup refuses the dev default in production).
- **CORS**: restrict `CLIENT_URL` and the Socket.io `cors.origin` in `src/server.js`.
- **Rate limiting**: `/api/auth/*` is limited to 100 req / 15 min per IP.
- **Scaling sockets**: matchmaking queues, invites and live games are in-memory
  per process. For multiple instances, add the Socket.io Redis adapter and move
  game state to Redis.
- **Rooms** auto-expire via a 24h TTL index on `createdAt`.
- **Indexes**: `User.location` (2dsphere), unique `username`/`email`,
  `Question(category,difficulty)`, `GameResult.createdAt` for weekly boards.
- No `console.*` in `src/` — everything logs through `src/utils/logger.js`.
