# Enemy Types

## Mey (Duo)

Two independent entities spawned together. Same skill set, each picks their own rotation and positioning. They do NOT mirror each other — both act independently with random attack selection.

### Behavior
- **State loop**: move → attack → move → attack → ...
- **Attack selection**: random pick from weapon set each cycle
- **Movement**: repositions between attacks (pattern TBD)

### Weapons (bullet patterns)

| Weapon | Description |
|---|---|
| Spear | Singular line of bullets fired at high speed — fast, narrow, punishes standing still |
| Pickaxe | Massive sweeping arc of bullets — wide coverage, forces movement |
| Scythe | Curved line of bullets that travels across the entire screen — unavoidable without teleport |
| Spinning Axes | Multiple small circular formations of bullets that orbit and spin — area denial, lingering hazard |

### Rules
- Enemy bullets **cannot hit each other** (no friendly fire between enemy bullets)
- Each Mey entity is individually dangerous — two of them create overlapping patterns that force bad decisions
- Pressure profile: **overcommit position** (spinning axes deny safe zones), **panic teleport** (scythe/pickaxe force reactive blinks), **tunnel vision** (each weapon demands attention — while you're reading one Mey's spear, the other is winding up a pickaxe)

### Stats (TBD)
- HP: ?
- Speed: ?
- Attack cooldown between weapons: ?
- Size/shape: ?
