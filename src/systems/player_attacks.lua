PlayerAttacks = {}
PlayerAttacks.__index = PlayerAttacks

---------------------------------------------------------------------------
-- Shared helpers (same as enemy files)
---------------------------------------------------------------------------
local function circleShape(r, segments)
    local verts = {}
    for i = 1, segments do
        local a = (2 * math.pi / segments) * (i - 1)
        verts[i] = {x = math.cos(a) * r, y = math.sin(a) * r}
    end
    return verts
end

---------------------------------------------------------------------------
-- Attack definitions
-- Each entry: { enemy, key, name, desc, cooldown, fire }
-- fire(player, gameList) — fires toward mouse cursor
---------------------------------------------------------------------------
local ATTACKS = {

    -- ============================================================
    -- MEY ATTACKS
    -- ============================================================
    {
        enemy = "mey",
        key   = "mey_spear",
        name  = "SPEAR",
        desc  = "Hurl a razor spear toward cursor",
        cooldown = 2.0,
        color = {0.85, 0.2, 0.2},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local dx, dy = mx - cx, my - cy
            local len = math.sqrt(dx * dx + dy * dy)
            if len == 0 then return end
            local dirx, diry = dx / len, dy / len
            local perpx, perpy = -diry, dirx
            local gap   = 36
            local speed = 2400
            local function spawn(along, perp)
                local bx = cx + dirx * (along * gap) + perpx * (perp * gap)
                local by = cy + diry * (along * gap) + perpy * (perp * gap)
                local b = gameList:spawnBullet(1, speed, circleShape(4, 8), {x = dirx, y = diry}, bx, by, "player")
                b.timer = 0.2
            end
            -- pyramid tip
            spawn(4, 0)
            spawn(3, -0.5)  spawn(3, 0.5)
            spawn(2, -1)    spawn(2, 0)    spawn(2, 1)
            spawn(1, -2)    spawn(1, 2)
            spawn(0, -1)    spawn(0, 0)    spawn(0, 1)
            -- shaft
            for i = 1, 7 do
                spawn(-i, -0.5)
                spawn(-i,  0.5)
            end
        end,
    },

    {
        enemy = "mey",
        key   = "mey_pickaxe",
        name  = "PICKAXE",
        desc  = "Spin four pickaxes in an arc",
        cooldown = 2.5,
        color = {0.85, 0.2, 0.2},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local baseAngle = math.atan2(my - cy, mx - cx) - math.pi / 2
            local cellSize = 18
            local centerX, centerY = 1, 24
            local PICKAXE_PIXELS = {
                {5,1},{6,1},{7,1},{8,1},
                {4,2},{5,2},{6,2},{7,2},{8,2},{9,2},{10,2},{11,2},
                {4,3},{5,3},{6,3},{7,3},{8,3},{9,3},{10,3},{11,3},
                {5,4},{6,4},{7,4},{8,4},{9,4},{10,4},{11,4},{12,4},{13,4},
                {8,5},{9,5},{10,5},{11,5},{12,5},{13,5},
                {7,6},{8,6},{9,6},{11,6},{12,6},{13,6},
                {6,7},{7,7},{8,7},{11,7},{12,7},{13,7},
                {5,8},{6,8},{7,8},{11,8},{12,8},{13,8},
                {4,9},{5,9},{6,9},{11,9},{12,9},{13,9},
                {3,10},{4,10},{5,10},{12,10},
                {2,11},{3,11},{4,11},
                {1,12},{2,12},{3,12},
                {1,13},{2,13},
                {1,14},
            }
            local bullets = {}
            local offsets = {}
            local rotations = {0, math.pi / 2, math.pi, 3 * math.pi / 2}
            for _, rot in ipairs(rotations) do
                local cos_r, sin_r = math.cos(rot), math.sin(rot)
                for _, px in ipairs(PICKAXE_PIXELS) do
                    local rawx = (px[1] - centerX) * cellSize
                    local rawy = (px[2] - centerY) * cellSize
                    local ox = rawx * cos_r - rawy * sin_r
                    local oy = rawx * sin_r + rawy * cos_r
                    local rx = ox * math.cos(baseAngle) - oy * math.sin(baseAngle)
                    local ry = ox * math.sin(baseAngle) + oy * math.cos(baseAngle)
                    table.insert(bullets, {ox = rx, oy = ry})
                    table.insert(offsets, {ox = rx, oy = ry})
                end
            end
            -- controlled formation that fans out
            local state = {
                active   = true,
                bullets  = {},
                offsets  = offsets,
                angle    = 0,
                timer    = 0.8,
                speed    = 1800,
                cx       = cx,
                cy       = cy,
            }
            for i, off in ipairs(offsets) do
                local bx = cx + off.ox
                local by = cy + off.oy
                local b = gameList:spawnBullet(1, 0, circleShape(4, 8), {x = 0, y = 0}, bx, by, "player")
                b.controlled = true
                b.timer = 0.2
                table.insert(state.bullets, b)
            end
            -- store on gameList for the controlled-formation update system
            if not gameList.controlledFormations then gameList.controlledFormations = {} end
            state.fireFn = function(b, off, t, dt)
                -- rotate offsets then apply baseAngle spin
                local cos_a = math.cos(t / 0.8 * math.pi * 2)
                local sin_a = math.sin(t / 0.8 * math.pi * 2)
                local rx = off.ox * cos_a - off.oy * sin_a
                local ry = off.ox * sin_a + off.oy * cos_a
                b.x = state.cx + rx
                b.y = state.cy + ry
                if t >= 0.8 then
                    local dx, dy = b.x - state.cx, b.y - state.cy
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then b.direction = {x = dx / len, y = dy / len} end
                    b.speed = state.speed
                    b.controlled = false
                    return false  -- done managing
                end
                return true  -- keep managing
            end
            state.getTime = function() return state.timer end
            table.insert(gameList.controlledFormations, state)
        end,
    },

    {
        enemy = "mey",
        key   = "mey_axe",
        name  = "SPINNING AXE",
        desc  = "Unleash six spinning axes",
        cooldown = 3.0,
        color = {0.85, 0.2, 0.2},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local AXE_PIXELS = {
                {1,1},{2,1},
                {1,2},{2,2},{3,2},
                {2,3},{3,3},{4,3},
                {4,4},{5,4},{6,4},{10,4},{11,4},
                {4,5},{5,5},{6,5},{10,5},{11,5},{12,5},
                {5,6},{6,6},{7,6},{8,6},{9,6},{10,6},{11,6},{12,6},{13,6},
                {6,7},{7,7},{8,7},{9,7},{10,7},{11,7},{12,7},{13,7},{14,7},
                {7,8},{8,8},{9,8},{10,8},{11,8},{12,8},{13,8},{14,8},{15,8},
                {8,9},{9,9},{10,9},{11,9},{12,9},{13,9},{14,9},{15,9},
                {5,10},{6,10},{7,10},{8,10},{9,10},{10,10},{11,10},{12,10},{13,10},{14,10},{15,10},
                {5,11},{6,11},{7,11},{8,11},{9,11},{10,11},{11,11},{12,11},
                {6,12},{7,12},{8,12},{9,12},{10,12},{11,12},
                {7,13},{8,13},{9,13},{10,13},
                {8,14},{9,14},{10,14},
                {9,15},{10,15},
            }
            local cellSize = 12
            local pivotX, pivotY = 1, 1
            local bullets, offsets = {}, {}
            local numAxes = 6
            for a = 0, numAxes - 1 do
                local rot = (2 * math.pi / numAxes) * a
                local cos_r, sin_r = math.cos(rot), math.sin(rot)
                local count = 0
                for _, px in ipairs(AXE_PIXELS) do
                    count = count + 1
                    if count % 2 == 0 then goto skip end
                    local rawx = (px[1] - pivotX) * cellSize
                    local rawy = (px[2] - pivotY) * cellSize
                    local ox = rawx * cos_r - rawy * sin_r
                    local oy = rawx * sin_r + rawy * cos_r
                    table.insert(offsets, {ox = ox, oy = oy})
                    ::skip::
                end
            end
            local state = {
                active = true,
                bullets = {},
                offsets = offsets,
                angle   = 0,
                timer   = 1.0,
                speed   = 1800,
                cx      = cx,
                cy      = cy,
            }
            for _, off in ipairs(offsets) do
                local bx = cx + off.ox
                local by = cy + off.oy
                local b = gameList:spawnBullet(1, 0, circleShape(4, 8), {x = 0, y = 0}, bx, by, "player")
                b.controlled = true
                b.timer = 0.2
                table.insert(state.bullets, b)
            end
            if not gameList.controlledFormations then gameList.controlledFormations = {} end
            state.fireFn = function(b, off, t, dt)
                state.angle = state.angle + (2 * math.pi / 1.0) * dt
                local cos_a = math.cos(state.angle)
                local sin_a = math.sin(state.angle)
                local elapsed = 1.0 - state.timer
                local scale = 1 + (elapsed / 1.0) * 1.5
                local rx = off.ox * cos_a - off.oy * sin_a
                local ry = off.ox * sin_a + off.oy * cos_a
                b.x = state.cx + rx * scale
                b.y = state.cy + ry * scale
                if state.timer <= 0 then
                    local dx, dy = b.x - state.cx, b.y - state.cy
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then b.direction = {x = dx / len, y = dy / len} end
                    b.speed = state.speed
                    b.controlled = false
                    return false
                end
                return true
            end
            table.insert(gameList.controlledFormations, state)
        end,
    },

    -- ============================================================
    -- SITAR ATTACKS
    -- ============================================================
    {
        enemy = "sitar",
        key   = "sitar_single_beam",
        name  = "SINGULAR BEAM",
        desc  = "Fire a wide tracking beam",
        cooldown = 3.5,
        color = {0.2, 0.6, 0.9},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local angle = math.atan2(my - cy, mx - cx)
            local BEAM_SPEED    = 1200
            local BEAM_BULLET_GAP = 24
            local BEAM_SPAWN_RATE = 0.04
            local BEAM_WIDTH_MIN  = 17
            local BEAM_WIDTH_MAX  = 21
            local BEAM_WIDTH_FLUX = 2
            local BEAM_JITTER     = 10
            local BEAM_SPEED_FLUX = 200
            local width = math.random(BEAM_WIDTH_MIN, BEAM_WIDTH_MAX)
            local state = {
                active    = true,
                angle     = angle,
                width     = width,
                spawn_cd  = 0,
                duration  = 3.0,
                cx        = cx,
                cy        = cy,
            }
            state.fireFn = function(t, dt)
                state.duration = state.duration - dt
                if state.duration <= 0 then return false end
                -- slowly track player
                local mx2, my2 = love.mouse.getPosition()
                local target = math.atan2(my2 - state.cy, mx2 - state.cx)
                local diff = (target - state.angle + math.pi) % (2 * math.pi) - math.pi
                local max_rot = 0.4 * dt
                if math.abs(diff) < max_rot then
                    state.angle = target
                else
                    state.angle = state.angle + max_rot * (diff > 0 and 1 or -1)
                end
                state.spawn_cd = state.spawn_cd - dt
                while state.spawn_cd <= 0 do
                    state.spawn_cd = state.spawn_cd + BEAM_SPAWN_RATE
                    local dirx, diry = math.cos(state.angle), math.sin(state.angle)
                    local perpx, perpy = -diry, dirx
                    local w = state.width + math.random(-BEAM_WIDTH_FLUX, BEAM_WIDTH_FLUX)
                    w = math.max(2, w)
                    local half = (w - 1) / 2
                    for col = 0, w - 1 do
                        local offset = (col - half) * BEAM_BULLET_GAP
                        local lat_j = (math.random() * 2 - 1) * BEAM_JITTER
                        local fwd_j = (math.random() * 2 - 1) * BEAM_JITTER * 0.5
                        local bx = state.cx + perpx * (offset + lat_j) + dirx * fwd_j
                        local by = state.cy + perpy * (offset + lat_j) + diry * fwd_j
                        local spd = BEAM_SPEED + (math.random() * 2 - 1) * BEAM_SPEED_FLUX
                        local b = gameList:spawnBullet(1, spd, circleShape(4, 8), {x = dirx, y = diry}, bx, by, "player")
                        b.timer = 0.2
                    end
                end
                return true
            end
            if not gameList.beamStates then gameList.beamStates = {} end
            table.insert(gameList.beamStates, state)
        end,
    },

    {
        enemy = "sitar",
        key   = "sitar_triple_beam",
        name  = "TRIPLE BEAM",
        desc  = "Three tracking beams at 120°",
        cooldown = 5.0,
        color = {0.2, 0.6, 0.9},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local base = math.atan2(my - cy, mx - cx)
            local BEAM_SPEED    = 1200
            local BEAM_BULLET_GAP = 24
            local BEAM_SPAWN_RATE = 0.04
            local BEAM_WIDTH_MIN  = 6
            local BEAM_WIDTH_MAX  = 10
            local BEAM_WIDTH_FLUX = 2
            local BEAM_JITTER     = 10
            local BEAM_SPEED_FLUX = 200
            local beams = {}
            for i = 0, 2 do
                local angle = base + i * (2 * math.pi / 3)
                local width = math.random(BEAM_WIDTH_MIN, BEAM_WIDTH_MAX)
                local state = {
                    active   = true,
                    angle    = angle,
                    width    = width,
                    spawn_cd = 0,
                    duration = 3.0,
                    cx       = cx,
                    cy       = cy,
                }
                state.fireFn = function(t, dt)
                    state.duration = state.duration - dt
                    if state.duration <= 0 then return false end
                    local mx2, my2 = love.mouse.getPosition()
                    local target = math.atan2(my2 - state.cy, mx2 - state.cx)
                    local diff = (target - state.angle + math.pi) % (2 * math.pi) - math.pi
                    local max_rot = 0.4 * dt
                    if math.abs(diff) < max_rot then
                        state.angle = target
                    else
                        state.angle = state.angle + max_rot * (diff > 0 and 1 or -1)
                    end
                    state.spawn_cd = state.spawn_cd - dt
                    while state.spawn_cd <= 0 do
                        state.spawn_cd = state.spawn_cd + BEAM_SPAWN_RATE
                        local dirx, diry = math.cos(state.angle), math.sin(state.angle)
                        local perpx, perpy = -diry, dirx
                        local w = state.width + math.random(-BEAM_WIDTH_FLUX, BEAM_WIDTH_FLUX)
                        w = math.max(2, w)
                        local half = (w - 1) / 2
                        for col = 0, w - 1 do
                            local offset = (col - half) * BEAM_BULLET_GAP
                            local lat_j = (math.random() * 2 - 1) * BEAM_JITTER
                            local fwd_j = (math.random() * 2 - 1) * BEAM_JITTER * 0.5
                            local bx = state.cx + perpx * (offset + lat_j) + dirx * fwd_j
                            local by = state.cy + perpy * (offset + lat_j) + diry * fwd_j
                            local spd = BEAM_SPEED + (math.random() * 2 - 1) * BEAM_SPEED_FLUX
                            local b = gameList:spawnBullet(1, spd, circleShape(4, 8), {x = dirx, y = diry}, bx, by, "player")
                            b.timer = 0.2
                        end
                    end
                    return true
                end
                table.insert(beams, state)
            end
            if not gameList.beamStates then gameList.beamStates = {} end
            for _, b in ipairs(beams) do table.insert(gameList.beamStates, b) end
        end,
    },

    {
        enemy = "sitar",
        key   = "sitar_orbit",
        name  = "ORBIT STORM",
        desc  = "Fire an orbiting comet formation",
        cooldown = 4.0,
        color = {0.2, 0.6, 0.9},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local ORBIT_RADIUS    = 120
            local ORBIT_SPIN_SPEED = 3.0
            local ORBIT_DURATION  = 1.5
            local ORBIT_CURVE_STR = 1.2
            local ORBIT_RELEASE_SPD = 500
            local ORBIT_BEAM_MIN  = 6
            local ORBIT_BEAM_MAX  = 13
            local ORBIT_TRACK_STR = 2.5
            local count = math.random(6, 9)
            local beam_gap = (2 * math.pi / count)
            local bullets, datas = {}, {}
            for i = 1, count do
                local base_angle = beam_gap * (i - 1)
                local beam_len = math.random(ORBIT_BEAM_MIN, ORBIT_BEAM_MAX)
                local curve_sign = (i % 2 == 0) and 1 or -1
                local angle_step = beam_gap * 0.55 / beam_len
                for j = 1, beam_len do
                    local a = base_angle - (j - 1) * angle_step * math.sign(ORBIT_SPIN_SPEED)
                    local bx = cx + math.cos(a) * ORBIT_RADIUS
                    local by = cy + math.sin(a) * ORBIT_RADIUS
                    local b = gameList:spawnBullet(1, 0, circleShape(4, 8), {x = 0, y = 0}, bx, by, "player")
                    b.controlled = true
                    b.timer = 0.2
                    table.insert(bullets, b)
                    table.insert(datas, {angle = a, curve_sign = curve_sign, heading = 0})
                end
            end
            local orbitState = {
                phase  = "orbit",
                timer  = ORBIT_DURATION,
                bullets = bullets,
                datas  = datas,
                radius = ORBIT_RADIUS,
                spin   = ORBIT_SPIN_SPEED,
                cx     = cx,
                cy     = cy,
            }
            orbitState.fireFn = function(dt)
                if orbitState.phase == "orbit" then
                    orbitState.timer = orbitState.timer - dt
                    for i, b in ipairs(orbitState.bullets) do
                        if b.active then
                            local d = orbitState.datas[i]
                            d.angle = d.angle + orbitState.spin * dt
                            b.x = orbitState.cx + math.cos(d.angle) * orbitState.radius
                            b.y = orbitState.cy + math.sin(d.angle) * orbitState.radius
                        end
                    end
                    if orbitState.timer <= 0 then
                        local mx2, my2 = love.mouse.getPosition()
                        for i, b in ipairs(orbitState.bullets) do
                            if b.active then
                                local d = orbitState.datas[i]
                                local tx = -math.sin(d.angle) * math.sign(orbitState.spin)
                                local ty =  math.cos(d.angle) * math.sign(orbitState.spin)
                                local dx = mx2 - b.x
                                local dy = my2 - b.y
                                local len = math.sqrt(dx * dx + dy * dy)
                                if len > 0 then dx, dy = dx / len, dy / len end
                                local hx = dx + tx * ORBIT_CURVE_STR
                                local hy = dy + ty * ORBIT_CURVE_STR
                                d.heading = math.atan2(hy, hx)
                            end
                        end
                        orbitState.phase = "release"
                        orbitState.timer = 4.0
                    end
                else
                    orbitState.timer = orbitState.timer - dt
                    local mx2, my2 = love.mouse.getPosition()
                    local any_alive = false
                    for i, b in ipairs(orbitState.bullets) do
                        if b.active then
                            any_alive = true
                            local d = orbitState.datas[i]
                            local desired = math.atan2(my2 - b.y, mx2 - b.x)
                            local diff = (desired - d.heading + math.pi) % (2 * math.pi) - math.pi
                            local max_turn = ORBIT_TRACK_STR * dt
                            if math.abs(diff) < max_turn then
                                d.heading = desired
                            else
                                d.heading = d.heading + max_turn * (diff > 0 and 1 or -1)
                            end
                            b.x = b.x + math.cos(d.heading) * ORBIT_RELEASE_SPD * dt
                            b.y = b.y + math.sin(d.heading) * ORBIT_RELEASE_SPD * dt
                            if b.x < -50 or b.x > 2000 or b.y < -50 or b.y > 1500 then
                                b.active = false
                            end
                        end
                    end
                    if not any_alive or orbitState.timer <= 0 then
                        for _, b in ipairs(orbitState.bullets) do b.active = false end
                        return false
                    end
                end
                return true
            end
            if not gameList.controlledFormations then gameList.controlledFormations = {} end
            table.insert(gameList.controlledFormations, orbitState)
        end,
    },

    -- ============================================================
    -- ODACHI ATTACKS
    -- ============================================================
    {
        enemy = "odachi",
        key   = "odachi_parry",
        name  = "PARRY",
        desc  = "Reflect bullets in front of you for 0.5s",
        cooldown = 6.0,
        color = {0.4, 0.7, 0.3},
        fire = function(player, gameList)
            -- Same as player sweep: deflect all enemy bullets in a 120° arc toward mouse
            player.parry_active  = true
            player.parry_timer   = 0.5
            local mx, my = love.mouse.getPosition()
            player.parry_angle = math.atan2(my - (player.y + 20), mx - (player.x + 20))
        end,
    },

    {
        enemy = "odachi",
        key   = "odachi_cross_blast",
        name  = "CROSS BLAST",
        desc  = "Fire a wide cross beam of bullets",
        cooldown = 4.0,
        color = {0.4, 0.7, 0.3},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local base = math.atan2(my - cy, mx - cx)
            local BEAM_SPEED    = 1200
            local BEAM_BULLET_GAP = 30
            local BEAM_SPAWN_RATE = 0.04
            local BEAM_WIDTH_MIN  = 17
            local BEAM_WIDTH_MAX  = 21
            local BEAM_WIDTH_FLUX = 2
            local BEAM_JITTER     = 10
            local BEAM_SPEED_FLUX = 200
            local width = math.random(BEAM_WIDTH_MIN, BEAM_WIDTH_MAX)
            local state = {
                active   = true,
                angles   = {base, base + math.pi / 2, base + math.pi, base + 3 * math.pi / 2},
                width    = width,
                spawn_cd = 0,
                duration = 2.5,
                cx       = cx,
                cy       = cy,
            }
            state.fireFn = function(t, dt)
                state.duration = state.duration - dt
                if state.duration <= 0 then return false end
                state.spawn_cd = state.spawn_cd - dt
                while state.spawn_cd <= 0 do
                    state.spawn_cd = state.spawn_cd + BEAM_SPAWN_RATE
                    for _, angle in ipairs(state.angles) do
                        local dirx, diry = math.cos(angle), math.sin(angle)
                        local perpx, perpy = -diry, dirx
                        local w = state.width + math.random(-BEAM_WIDTH_FLUX, BEAM_WIDTH_FLUX)
                        w = math.max(2, w)
                        local half = (w - 1) / 2
                        for col = 0, w - 1 do
                            local offset = (col - half) * BEAM_BULLET_GAP
                            local lat_j = (math.random() * 2 - 1) * BEAM_JITTER
                            local fwd_j = (math.random() * 2 - 1) * BEAM_JITTER * 0.5
                            local bx = state.cx + perpx * (offset + lat_j) + dirx * fwd_j
                            local by = state.cy + perpy * (offset + lat_j) + diry * fwd_j
                            local spd = BEAM_SPEED + (math.random() * 2 - 1) * BEAM_SPEED_FLUX
                            local b = gameList:spawnBullet(1, spd, circleShape(4, 8), {x = dirx, y = diry}, bx, by, "player")
                            b.timer = 0.2
                        end
                    end
                end
                return true
            end
            if not gameList.beamStates then gameList.beamStates = {} end
            table.insert(gameList.beamStates, state)
        end,
    },

    {
        enemy = "odachi",
        key   = "odachi_dash",
        name  = "DASH SLASH",
        desc  = "Dash toward cursor and release a blade wave",
        cooldown = 3.0,
        color = {0.4, 0.7, 0.3},
        fire = function(player, gameList)
            local mx, my = love.mouse.getPosition()
            local dx = mx - (player.x + 20)
            local dy = my - (player.y + 20)
            local len = math.sqrt(dx * dx + dy * dy)
            if len == 0 then return end
            dx, dy = dx / len, dy / len
            -- dash
            player.vx = dx * 1200
            player.vy = dy * 1200
            -- release blade wave perpendicular to dash direction
            local perp = math.atan2(dx, -dy)  -- perpendicular angle
            local perpdx, perpdy = math.cos(perp), math.sin(perp)
            local GAP = 36
            local SPEED = 1600
            for col = -3, 3 do
                local ox = perpdx * col * GAP
                local oy = perpdy * col * GAP
                local bx = player.x + 20 + ox
                local by = player.y + 20 + oy
                local b = gameList:spawnBullet(2, SPEED, circleShape(5, 8), {x = dx, y = dy}, bx, by, "player")
                b.timer = 0.2
            end
        end,
    },

    -- ============================================================
    -- BOSS ATTACKS (greater upgrades)
    -- ============================================================
    {
        enemy = "boss",
        key   = "boss_rosette",
        name  = "ROSETTE",
        desc  = "Fire a spreading rosette of bullet petals",
        cooldown = 5.0,
        color = {0.7, 0.3, 0.9},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local base = math.atan2(my - cy, mx - cx)
            local count = 12
            local layers = 3
            local SPEED = 800
            local layerGap = 48
            for layer = 0, layers - 1 do
                local layerDelay = layer * 0.15
                for i = 0, count - 1 do
                    local angle = base + (2 * math.pi / count) * i
                    local bx = cx + math.cos(angle) * (layer * layerGap)
                    local by = cy + math.sin(angle) * (layer * layerGap)
                    local b = gameList:spawnBullet(2, SPEED, circleShape(5, 8), {x = math.cos(angle), y = math.sin(angle)}, bx, by, "player")
                    b.timer = 0.2
                end
            end
        end,
    },

    {
        enemy = "boss",
        key   = "boss_devour",
        name  = "DEVOUR",
        desc  = "Fire homing void orbs that seek enemies",
        cooldown = 6.0,
        color = {0.7, 0.3, 0.9},
        fire = function(player, gameList)
            local cx, cy = player.x + 20, player.y + 20
            local mx, my = love.mouse.getPosition()
            local angle = math.atan2(my - cy, mx - cx)
            local count = 5
            for i = 1, count do
                local spread = (i - (count + 1) / 2) * 0.15
                local a = angle + spread
                local bx = cx + math.cos(a) * 30
                local by = cy + math.sin(a) * 30
                local b = gameList:spawnBullet(3, 400, circleShape(6, 8), {x = math.cos(a), y = math.sin(a)}, bx, by, "player")
                b.timer = 0.2
                b.homing = true
                b.homing_strength = 3.0
            end
        end,
    },
}

---------------------------------------------------------------------------
-- Pool helpers
---------------------------------------------------------------------------
function PlayerAttacks.poolFor(enemy)
    local out = {}
    for _, a in ipairs(ATTACKS) do
        if a.enemy == enemy then table.insert(out, a) end
    end
    return out
end

function PlayerAttacks.byKey(key)
    for _, a in ipairs(ATTACKS) do
        if a.key == key then return a end
    end
end

-- Default key bindings in order of slot assignment
local SLOT_KEYS = {"q", "r", "f", "lshift", "rshift", "tab", "ralt", "lctrl", "rctrl"}

function PlayerAttacks.nextSlotKey(owned)
    for _, k in ipairs(SLOT_KEYS) do
        local taken = false
        for _, entry in ipairs(owned) do
            if entry.key == k then taken = true; break end
        end
        if not taken then return k end
    end
    return nil  -- no slots left
end

return PlayerAttacks
