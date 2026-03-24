# Teleporter — Game Design Document

## Overview

- **Genre**: Bullet hell / action
- **Engine**: LÖVE 2D
- **Core fantasy**: You are the threat. Enemies swarm and fill the screen with bullets. You teleport through the chaos and throw their own bullets back at them.

The player is deliberately overpowered. The challenge is not surviving attrition — it is staying in control and stylish when things get dense. Getting hit is punishing precisely because it should not happen.

---

## Core Mechanics

| Action | Input | Description |
|---|---|---|
| Move | WASD | Acceleration-based with friction |
| Teleport | RMB | Instant blink to cursor, velocity zeroed on arrival, no cooldown |
| Shoot | LMB | Fire bullet toward cursor |
| Sweep | Space | Directional blade sweep toward cursor, 0.3s window, 5s cooldown |

### Teleport
Zero cooldown. The player can blink anywhere on screen instantly. Primary mobility and escape tool. Bullets fired by the player have a 1-second grace period before they can collide — you cannot shoot yourself on spawn. **Teleporting onto an existing bullet counts as getting hit** — teleport is already so powerful that this tradeoff is necessary.

### Sweep (Parry)
A directional blade sweep toward the cursor. Covers a 120-degree arc in front of the player. Bullets caught in the sweep are reflected back the way they came at double damage. The remaining 240 degrees are wide open — you are fully vulnerable from behind while sweeping.

Window is tight (0.3 seconds). Cooldown is long (5 seconds). Inspired by Sekiro's parry — it is an active, committal action, not a passive shield. You read the bullet pattern, aim the sweep, and time it. Get it right and a volley becomes a weapon. Miss and you wasted your cooldown.

Visual: a crescent-moon arc that flows in from one edge (0.12s), holds full shape (0.06s), then fades out from the same edge (0.12s).

---

## Player

- **HP**: 3 (displayed as 3 dashes above the player)
- Each hit removes one dash; at zero the run ends
- No healing mid-run
- Base stats are fixed; power comes from room-clear upgrades

---

## Enemies

3 enemy types for v1. Each type has:
- A **movement pattern** (AI returns an array of waypoints the enemy follows)
- A **fire pattern** (set of direction vectors, rotated per instance so no two enemies fire identically)
- 3 bullet types across the enemy roster (TBD — one per enemy type or mixed)

All enemies are present in the room when the player enters — no wave spawning.

### Enemy 1 (implemented)
- Serpentine sweep: traverses the room in horizontal strips, then retraces the full path in reverse
- No bullets yet

Each world introduces at least one new enemy type.

---

## Bosses

- One boss at the end of each world
- Unique bullet pattern, phase transitions (TBD)
- Defeating the boss unlocks the next world

---

## Level Structure

- **Room-based**, linear chain per world
- ~5 rooms per world, 2 worlds for v1
- Each room: clear all enemies → pick one upgrade → proceed to next room
- Room difficulty escalates in enemy count and type mix
- **Win condition**: clear the final boss of world 2

### Room Layout
Rooms have thick walls with gates (Binding of Isaac style). Gate positions: top, left, right in most cases. Wall color indicates room difficulty:

| Color | Difficulty |
|---|---|
| Gray | Normal |
| Bronze | Hard |
| Red | Boss |

---

## Progression

- After each room clear, choose one upgrade from a small selection (upgrades TBD)
- No cross-run persistence — pure arcade, single attempt
- Dying returns to the main menu; start over from the beginning

---

## Win / Loss

- **Loss**: HP reaches zero → game over → main menu
- **Win**: Clear the final boss of world 2

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

---

## Implementation Status

| Feature | Status |
|---|---|
| Player movement / teleport / shoot | Done |
| Sweep visual (crescent arc) | Done |
| Sweep deflection (reflect bullets) | Done |
| Teleport-onto-bullet collision | Not implemented |
| SAT collision detection | Done |
| Health bar (3 dashes) | Done |
| Bullet system | Done |
| Enemy1 AI (path generation) | Done |
| Enemy path-following movement | Not implemented |
| Enemy fire patterns | Not implemented |
| Room layout (walls + gates + torii) | Done |
| Room difficulty coloring | Done |
| Wall collision (block movement) | Not implemented |
| Room / level system | Not started |
| Upgrades | Not started |
| Bosses | Not started |

---

## Dev Notes

- `aabb` in collision.lua is SAT, not AABB — misnamed
- `mobilizeEnemy1()` exists but is never called; enemies don't spawn or move yet — no `update()` on Enemy1
- Sweep cooldown (`shield_cd`) is defined in `Player.new` but the decrement/check logic in `update` may be using stale names — verify
- Sweep collision hitbox is a pie-slice polygon (`getSweepShape`), not the crescent visual — intentionally simpler
- Wall collision is not implemented — player walks through walls freely
- Healthbar is hardcoded to 3 dashes regardless of `max_hp`
- Bullets collide with all entities including the player after the 1s grace period — no team/owner tracking
