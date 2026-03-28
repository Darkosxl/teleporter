# Teleporter — Ship by Sunday

## Phase 1: Playable Loop
The game needs to feel like a game. Kill things, move on, die, restart.

- [x] Wall collision — entity bounds clamping via `Entity:clampToBounds()`
- [ ] Enemy death — remove from gamelist when hp <= 0
- [ ] Room clearing logic — detect all enemies dead, open gates
- [ ] Room transitions — gates transport player to next room
- [ ] Permadeath / run reset — dying returns to main menu, resets all state
- [ ] Spawn enemies per room (room config: which enemies, how many, positions)
- [ ] 5-room area structure (rooms 1-4 normal, room 5 boss)
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
- [ ] Menu improvements (run stats, death screen)
