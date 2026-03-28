# Teleporter — Ship by Sunday

## Phase 1: Playable Loop
The game needs to feel like a game. Kill things, move on, die, restart.

- [x] Wall collision — `Room:isWalkable()` with door alcoves + barriers
- [x] Enemy death — `Entity:checkAlive()` sets state to "dead", GameList skips dead entities
- [x] Room clearing logic — Dungeon checks `GameList:hasLivingEnemies()`, sets room cleared, doors open
- [x] Room transitions — `Dungeon:passGate()` detects player at door edge, switches room, repositions
- [x] Permadeath / run reset — death screen overlay, restart or main menu, full state reset
- [ ] Spawn enemies per room (room config: which enemies, how many, positions)
- [x] Dungeon generation — BFS random rooms, random difficulty, boss placed in deepest branch (1 entrance only)
- [ ] 2 areas (10 rooms total per run)
- [ ] Win state — clear area 2 boss, show victory screen

## Phase 2: Enemies
4 normal enemies, 2 bosses. Enemies interleave with loop work so rooms aren't empty.

### Normal Enemies
- [ ] **Mey** — finish remaining weapons (pickaxe, scythe, spinning axes), movement, random attack selection, spawn as duo, enemy bullets can't hit each other
- [ ] **Enemy 2** — design TBD (user defines)
- [ ] **Enemy 3** — design TBD (user defines)
- [ ] **Enemy 4** — design TBD (user defines)

### Bosses
- [ ] **Area 1 Boss** — design TBD
- [ ] **Area 2 Boss** — design TBD

### Enemy Infrastructure
- [ ] Enemy bullets cannot hit each other (gamelist change)
- [ ] Entity-on-entity collision
- [ ] Beefed-up variants of normal enemies for area 2 (more hp, faster, extra patterns)

## Phase 3: Upgrades
Pick 1 of 3 after each room clear. Boss rooms give a greater upgrade.

- [ ] Upgrade selection UI (show 3 choices, player picks 1)
- [ ] Upgrade pool: ~6 unique abilities (40%)
- [ ] Upgrade pool: ~9 stat boosts (60%) that combo with uniques
- [ ] Greater upgrades for boss kills (stronger version or exclusive pool)
- [ ] Upgrade definitions — TBD, user designs

## Phase 4: Bullet Collision System
Stopped bullets, charge, explosion — secondary combat layer.

- [ ] Bullet-on-bullet collision (player bullet + enemy bullet = both stop)
- [ ] Stopped bullets track charge (cumulative damage received)
- [ ] Explosion at 5x base damage threshold (AOE = damage/3, hurts everyone)
- [ ] Stopped bullets despawn after 5 seconds
- [ ] Sweep can deflect stopped bullets at >= 4x charge

## Phase 5: Polish
Only if time allows. Not blocking Sunday ship.

- [ ] Teleport-onto-bullet collision (blink onto a bullet = get hit)
- [ ] Hit feedback (invincibility frames, screen flash)
- [ ] Better enemy spawn placement per room
- [ ] Difficulty scaling across rooms (enemy count, mix, stats)
- [x] Main menu (New Game / Continue / Exit, C&C font, mouse hover + keyboard)
- [x] Death screen (Game Over overlay, Start Again / Main Menu, mouse hover + keyboard)
