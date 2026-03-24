# Teleporter — Game Design Document

## Overview

- **Genre**: Bullet hell / action
- **Engine**: LÖVE 2D
- **Core fantasy**: You are the threat. Enemies swarm and fill the screen with bullets. You teleport through the chaos and throw their own bullets back at them.

The player is deliberately overpowered. The challenge is not surviving attrition — it is staying in control and stylish when things get dense. Getting hit is punishing precisely because it should not happen.

---

## Core Loop

1. Enter a room — enemies are already there, no wave spawning
2. Survive and kill all enemies — dodge, teleport, shoot, sweep, prime bullet-bombs
3. All enemies dead → gates open, pick 1 upgrade from a random set of 3 (Hades-style)
4. Move to the next room, repeat
5. Room 5 of each area is a boss — harder fight, greater upgrade on kill
6. Clear all areas → win. Die anywhere → permadeath, back to start, lose everything

A single run is short and intense. The player accumulates upgrades across rooms within a run but loses everything on death.

---

## Core Mechanics

| Action | Input | Description |
|---|---|---|
| Move | WASD | Acceleration-based with friction |
| Teleport | RMB | Instant blink to cursor, velocity zeroed on arrival, no cooldown |
| Shoot | LMB | Fire bullet toward cursor |
| Sweep | Space | Directional blade sweep toward cursor, 0.3s window, 5s cooldown |

### Teleport
Zero cooldown. The player can blink anywhere on screen instantly. Primary mobility and escape tool. Bullets fired by the player have a 0.2-second grace period before they can collide — you cannot shoot yourself on spawn. **Teleporting onto an existing bullet counts as getting hit** — teleport is already so powerful that this tradeoff is necessary.

### Sweep (Parry)
A directional blade sweep toward the cursor. Covers a 120-degree arc in front of the player. Bullets caught in the sweep are reflected back the way they came at double damage and double size, half speed. The remaining 240 degrees are wide open — you are fully vulnerable from behind while sweeping.

Window is tight (0.3 seconds). Cooldown is long (5 seconds). Inspired by Sekiro's parry — it is an active, committal action, not a passive shield. You read the bullet pattern, aim the sweep, and time it. Get it right and a volley becomes a weapon. Miss and you wasted your cooldown.

Deflected bullets have a 0.3s cooldown before they can be deflected again or damage the player who deflected them. Bullets can be deflected multiple times (beach volleyball style) — each deflection doubles damage and size again.

Visual: a crescent-moon arc that flows in from one edge (0.12s), holds full shape (0.06s), then fades out from the same edge (0.12s).

### Bullet Collision

When a player bullet and an enemy bullet collide, both **stop in place** and become neutral hazards.

- Stopped bullets track cumulative damage received (charge)
- Any bullet (player or enemy) hitting a stopped bullet adds to its charge
- When charge reaches **5× the stopped bullet's base damage** → explosion
  - AOE damage = stopped bullet's damage / 3
  - Hurts **both** enemies and the player — positioning matters
- Stopped bullets despawn after **5 seconds** if not detonated
- Stopped bullets can be **swept** only when near explosion threshold (≥4× damage) — you can't sweep every stopped bullet for free, you have to invest damage first then launch the primed bomb

This creates a secondary layer: the arena fills with potential bombs. The player chooses whether to invest shots into priming them, avoid them, or sweep a charged one into a group of enemies.

---

## Difficulty Design

Difficulty is not about bullet volume — it is about forcing bad decisions under pressure. Core pressure types:

| Pressure | Description |
|---|---|
| Panic teleport | Dense screen → player blinks to first open spot without checking what's about to fill it |
| Wasted sweep | Reflex sweep on a minor threat → 5s cooldown when the real volley arrives |
| Tunnel vision | Focused on one enemy's pattern → another charges up from the blind 240° |
| Greed for damage | Player stops dodging to line up a shot → eats a bullet they should have seen |
| Overcommit position | Player camps a safe corner → patterns close in, no exit |
| Wrong sweep target | Two volleys arrive at once → player sweeps the easy one, dangerous one hits |

Each enemy type should be designed to trigger 3 of these pressure types. With 6 pressure types choosing 3, there are 20 unique combinations — more than enough for all areas.

---

## Player

- **HP**: 3 (displayed as 3 dashes above the player)
- Each hit removes one dash; at zero the run ends
- No healing mid-run
- Base stats are fixed; power comes from room-clear upgrades

---

## Enemies

Each enemy type has:
- A **movement pattern** (AI returns an array of waypoints the enemy follows)
- A **fire pattern** (set of direction vectors, rotated per instance so no two enemies fire identically)
- A **pressure profile** — which 3 of the 6 pressure types it is designed to trigger

Few enemies per room, but each one is individually dangerous. The challenge is reading overlapping patterns, not surviving a swarm.

All enemies are present in the room when the player enters — no wave spawning.

### Enemy 1 (implemented)
- Serpentine sweep: traverses the room in horizontal strips, then retraces the full path in reverse
- No bullets yet
- Pressure profile: TBD

### Mey (Duo)
- Always spawns as a pair — two independent entities, same skill set, own rotations
- Cycles through 4 weapon attacks randomly: spear (fast line), pickaxe (wide arc), scythe (screen-wide curve), spinning axes (orbiting formations)
- Moves between attacks
- Pressure profile: overcommit position, panic teleport, tunnel vision
- **Enemy bullets cannot hit each other**
- See `src/unique_entities/enemy_types.md` for full details

Each area introduces at least one new enemy type.

---

## Bosses

- Room 5 of each area is a boss room
- One boss per area with unique bullet patterns and phase transitions (TBD)
- Defeating the boss grants a **greater upgrade** (stronger than normal room upgrades)
- Defeating the boss unlocks the next area

---

## Level Structure

- **Room-based**, linear chain per area
- **5 rooms per area**: 4 combat rooms + 1 boss room
- **2 areas for v1** (10 rooms total per run)
- Each room: clear all enemies → gates open → pick one upgrade → proceed
- Room difficulty escalates in enemy count and type mix
- **Win condition**: clear the final boss of area 2

### Room Layout
Rooms have thick walls with gates (Binding of Isaac style). Gate positions: top, left, right in most cases. Wall color indicates room difficulty:

| Color | Difficulty |
|---|---|
| Gray | Normal |
| Bronze | Hard |
| Dark/Black | Boss |

---

## Progression

- After each room clear, choose one upgrade from a random set of 3 (Hades-style)
- Boss kills grant a greater upgrade
- No cross-run persistence — pure arcade, single attempt
- Dying returns to the main menu; start over from the beginning
- Upgrades TBD

---

## Win / Loss

- **Loss**: HP reaches zero → game over → main menu → start fresh
- **Win**: Clear the final boss of area 2

---

## Visual Style

- Target: minimal and geometric — shapes readable at high speed
- Currently placeholder (colored rectangles and circles)
- Enemy death: instant removal
- Assets in `/assets/` (unused)

---

## Audio

- TBD

---

## v2 Backlog

Features explicitly deferred:

- Style meter / ranking system (DMC-style)
- Enemy death animations
- Hit feedback (invincibility frames, screen shake)
- Leaderboard
- Controller support
- Area 3+

---

## Implementation Status

| Feature | Status |
|---|---|
| Player movement / teleport / shoot | Done |
| Sweep visual (crescent arc) | Done |
| Sweep deflection (reflect + 2x damage + 2x size + 0.5x speed) | Done |
| Sweep deflect cooldown (0.3s, allows re-deflection) | Done |
| Teleport-onto-bullet collision | Not implemented |
| SAT collision detection | Done |
| Health bar (3 dashes) | Done |
| Bullet system (with shape-based draw + scale) | Done |
| Bullet-on-bullet collision (stopped bullets, charge, explosion) | Not implemented |
| Enemy1 AI (path generation) | Done |
| Enemy path-following movement | Not implemented |
| Enemy fire patterns | Not implemented |
| Room layout (walls + gates + torii) | Done |
| Room difficulty coloring | Done |
| Wall collision (block movement) | Not implemented |
| Room transitions / gate logic | Not started |
| Upgrade selection (pick 1 of 3) | Not started |
| Boss fights | Not started |
| Permadeath / run reset | Not started |
| Entity-on-entity collision | Not implemented |

---

## Playtest Blockers (must implement before first full run)

1. **Enemy movement** — Enemy1 has a path but no `update()`. Nothing moves.
2. **Enemy fire patterns** — without bullets from enemies, there's nothing to dodge or sweep.
3. **Enemy spawning** — `mobilizeEnemy1()` is never called. Rooms are empty.
4. **Wall collision** — player walks through walls freely.
5. **Room transitions** — gates exist visually but don't transport the player to the next room.
6. **Room clearing logic** — detect when all enemies are dead, open gates.
7. **Bullet-on-bullet collision** — the stopped bullet / charge / explosion system.
8. **Upgrade selection UI** — pick 1 of 3 after room clear (even placeholder upgrades).
9. **Permadeath / run reset** — dying should return to main menu and reset state.
10. **At least 1 boss** — area 1 boss needed to test the full 5-room loop.

Without these, individual mechanics work but there's no game loop to test.

---

## Dev Notes

- `aabb` in collision.lua is SAT, not AABB — misnamed
- `mobilizeEnemy1()` exists but is never called; enemies don't spawn or move yet — no `update()` on Enemy1
- Sweep cooldown names are now consistent (`sweep_cd`, `sweep_timer`, `sweep_active`)
- Sweep collision hitbox is a pie-slice polygon (`getSweepShape`), not the crescent visual — intentionally simpler
- Wall collision is not implemented — player walks through walls freely
- Healthbar is hardcoded to 3 dashes regardless of `max_hp`
- Bullets collide with all entities including the player after 0.2s grace period — no team/owner tracking yet
