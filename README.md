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
| Shield | Space | 1-second deflect bubble, 5-second cooldown |

### Teleport
Zero cooldown. The player can blink anywhere on screen instantly. Primary mobility and escape tool. Bullets fired by the player have a 1-second grace period before they can collide — you cannot shoot yourself on spawn. **Teleporting onto an existing bullet counts as getting hit** — teleport is already so powerful that this tradeoff is necessary.

### Shield (Deflect)
Activating the shield while a bullet hits it reflects the bullet back. Works on both enemy bullets and your own. Window is short (1 second). Cooldown is long (5 seconds). High risk, high reward — catching a dense volley and sending it back is the intended power fantasy moment.

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
| Shield visual | Done |
| Shield deflection (reflect bullets) | Not implemented |
| Teleport-onto-bullet collision | Not implemented |
| SAT collision detection | Done |
| Health bar (3 dashes) | Done |
| Bullet system | Done |
| Enemy1 AI (path generation) | Done |
| Enemy path-following movement | Not implemented |
| Enemy fire patterns | Not implemented |
| Room layout (walls + gates) | Not started |
| Room difficulty coloring | Not started |
| Room / level system | Not started |
| Upgrades | Not started |
| Bosses | Not started |
