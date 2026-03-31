Sitar = setmetatable({}, {__index = Enemy})
Sitar.__index = Sitar

-- Tuning constants
local BEAM_SPEED        = 1200   -- bullet travel speed in beams
local BEAM_BULLET_GAP   = 24     -- spacing between bullets across beam width
local BEAM_SPAWN_RATE   = 0.04   -- seconds between each row of bullets in beam
local BEAM_TRACK_SPEED  = 0.4    -- radians/sec rotation toward player (sidesteppable)
local BEAM_JITTER       = 10     -- max lateral pixel offset per bullet (ragged edges)
local BEAM_WIDTH_FLUX   = 2      -- +/- bullets per row (width pulses each row)
local BEAM_SPEED_FLUX   = 200    -- +/- speed variation per bullet

local SINGLE_WIDTH_MIN  = 17
local SINGLE_WIDTH_MAX  = 21
local TRI_WIDTH_MIN     = 6
local TRI_WIDTH_MAX     = 10

local BEAM_DURATION_MIN = 3.0
local BEAM_DURATION_MAX = 5.0

local ORBIT_COUNT_MIN   = 6
local ORBIT_COUNT_MAX   = 9
local ORBIT_BEAM_MIN    = 6      -- bullets per small beam
local ORBIT_BEAM_MAX    = 13
local ORBIT_RADIUS      = 120    -- orbit distance from sitar center
local ORBIT_SPIN_SPEED  = 3.0    -- radians/sec while orbiting
local ORBIT_DURATION    = 1.5    -- seconds orbiting before release
local ORBIT_CURVE_STR   = 1.2    -- lateral curve strength (steers perpendicular to target)
local ORBIT_RELEASE_SPD = 500    -- bullet speed after release
local ORBIT_TRACK_STR   = 2.5   -- how fast bullets steer toward player (rad/s)

local ATTACK_COOLDOWN   = 1.5    -- seconds between attacks

local SIZE = 90  -- 3x mey's 30

local function bulletShape()
    local verts = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        verts[i] = {x = math.cos(a) * 9, y = math.sin(a) * 9}
    end
    return verts
end

function Sitar.new(x, y)
    local shape = {
        {x = 0, y = 0}, {x = SIZE, y = 0},
        {x = SIZE, y = SIZE}, {x = 0, y = SIZE},
    }
    local self = setmetatable(Entity.new(300, 0, shape, nil), Sitar)
    self.x = x
    self.y = y
    self.w = SIZE
    self.h = SIZE
    self.type = "enemy"
    self.gameList = nil

    self.attack_timer = ATTACK_COOLDOWN
    self.last_attack = nil       -- 1, 2, or 3
    self.attack_weights = {1, 1, 1}  -- priority weights, increase for unused attacks

    -- beam state (shared by attack 1 and 2)
    self.beam_active = false
    self.beam_timer = 0          -- remaining duration
    self.beam_spawn_cd = 0       -- cooldown until next row spawns
    self.beam_angles = {}        -- current angle of each beam
    self.beam_widths = {}        -- bullet count per beam
    self.beam_count = 0

    -- orbit state (attack 3)
    self.orbit_active = false
    self.orbit_timer = 0
    self.orbit_phase = "orbit"   -- "orbit" or "release"
    self.orbit_bullets = nil
    self.orbit_data = nil        -- per-bullet: angle, radius, beam_index, curve_dir
    return self
end

function Sitar:getShape()
    return {
        {x = self.x, y = self.y},
        {x = self.x + SIZE, y = self.y},
        {x = self.x + SIZE, y = self.y + SIZE},
        {x = self.x, y = self.y + SIZE},
    }
end

---------------------------------------------------------------------------
-- Attack selection: weighted random, prioritise attacks not recently used
---------------------------------------------------------------------------
local function pickAttack(self)
    local total = 0
    for i = 1, 3 do total = total + self.attack_weights[i] end
    local r = math.random() * total
    local acc = 0
    for i = 1, 3 do
        acc = acc + self.attack_weights[i]
        if r <= acc then
            -- boost weights of attacks NOT picked, reset picked one
            for j = 1, 3 do
                if j == i then
                    self.attack_weights[j] = 1
                else
                    self.attack_weights[j] = self.attack_weights[j] + 2
                end
            end
            self.last_attack = i
            return i
        end
    end
    return 3
end

---------------------------------------------------------------------------
-- Helper: angle from sitar center to player
---------------------------------------------------------------------------
local function angleToPlayer(self)
    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    local px, py = player.x + 20, player.y + 20
    return math.atan2(py - cy, px - cx)
end

---------------------------------------------------------------------------
-- Attack 1: single wide kamehameha beam (7-9 bullets wide)
---------------------------------------------------------------------------
function Sitar:singleBeam()
    local width = math.random(SINGLE_WIDTH_MIN, SINGLE_WIDTH_MAX)
    local duration = BEAM_DURATION_MIN + math.random() * (BEAM_DURATION_MAX - BEAM_DURATION_MIN)
    self.beam_active = true
    self.beam_timer = duration
    self.beam_spawn_cd = 0
    self.beam_count = 1
    self.beam_angles = { angleToPlayer(self) }
    self.beam_widths = { width }
end

---------------------------------------------------------------------------
-- Attack 2: triple kamehameha beams (3-5 wide, 120 degrees apart)
---------------------------------------------------------------------------
function Sitar:tripleBeam()
    local base = angleToPlayer(self)
    local duration = BEAM_DURATION_MIN + math.random() * (BEAM_DURATION_MAX - BEAM_DURATION_MIN)
    self.beam_active = true
    self.beam_timer = duration
    self.beam_spawn_cd = 0
    self.beam_count = 3
    self.beam_angles = {}
    self.beam_widths = {}
    for i = 0, 2 do
        self.beam_angles[i + 1] = base + i * (2 * math.pi / 3)
        self.beam_widths[i + 1] = math.random(TRI_WIDTH_MIN, TRI_WIDTH_MAX)
    end
end

---------------------------------------------------------------------------
-- Beam update: spawns rows of bullets, slowly tracks toward player
---------------------------------------------------------------------------
function Sitar:updateBeams(dt)
    self.beam_timer = self.beam_timer - dt
    if self.beam_timer <= 0 then
        self.beam_active = false
        return
    end

    -- slowly rotate each beam toward the player
    local target = angleToPlayer(self)
    for i = 1, self.beam_count do
        local diff = target - self.beam_angles[i]
        -- normalize to [-pi, pi]
        diff = (diff + math.pi) % (2 * math.pi) - math.pi
        local max_rot = BEAM_TRACK_SPEED * dt
        if math.abs(diff) < max_rot then
            self.beam_angles[i] = target
        else
            self.beam_angles[i] = self.beam_angles[i] + max_rot * (diff > 0 and 1 or -1)
        end
    end

    -- spawn bullet rows on cooldown
    self.beam_spawn_cd = self.beam_spawn_cd - dt
    while self.beam_spawn_cd <= 0 do
        self.beam_spawn_cd = self.beam_spawn_cd + BEAM_SPAWN_RATE
        local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
        for i = 1, self.beam_count do
            local angle = self.beam_angles[i]
            local dirx, diry = math.cos(angle), math.sin(angle)
            local perpx, perpy = -diry, dirx
            -- fluctuate width each row for that energy-pulsing look
            local base_w = self.beam_widths[i]
            local w = base_w + math.random(-BEAM_WIDTH_FLUX, BEAM_WIDTH_FLUX)
            w = math.max(2, w)
            local half = (w - 1) / 2
            for col = 0, w - 1 do
                local offset = (col - half) * BEAM_BULLET_GAP
                -- jitter: random lateral + forward offset per bullet
                local lat_jitter = (math.random() * 2 - 1) * BEAM_JITTER
                local fwd_jitter = (math.random() * 2 - 1) * BEAM_JITTER * 0.5
                local bx = cx + perpx * (offset + lat_jitter) + dirx * fwd_jitter
                local by = cy + perpy * (offset + lat_jitter) + diry * fwd_jitter
                local spd = BEAM_SPEED + (math.random() * 2 - 1) * BEAM_SPEED_FLUX
                local b = self.gameList:spawnBullet(1, spd, bulletShape(), {x = dirx, y = diry}, bx, by, "enemy")
                b.timer = 0.2
            end
        end
    end
end

---------------------------------------------------------------------------
-- Attack 3: orbiting small beams that release in a curve toward player
---------------------------------------------------------------------------
function Sitar:orbitAttack()
    local count = math.random(ORBIT_COUNT_MIN, ORBIT_COUNT_MAX)
    self.orbit_active = true
    self.orbit_phase = "orbit"
    self.orbit_timer = ORBIT_DURATION
    self.orbit_bullets = {}
    self.orbit_data = {}

    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    -- angular gap between beams; each beam fills ~60% of that gap tangentially
    local beam_gap = (2 * math.pi / count)
    for i = 1, count do
        local base_angle = beam_gap * (i - 1)
        local beam_len = math.random(ORBIT_BEAM_MIN, ORBIT_BEAM_MAX)
        local curve_sign = (i % 2 == 0) and 1 or -1
        -- step each bullet along the arc (tangential) so the beam hugs the orbit circle
        local angle_step = beam_gap * 0.55 / beam_len
        for j = 1, beam_len do
            -- leading bullet at base_angle, trailing bullets behind in the direction of spin
            local a = base_angle - (j - 1) * angle_step * math.sign(ORBIT_SPIN_SPEED)
            local bx = cx + math.cos(a) * ORBIT_RADIUS
            local by = cy + math.sin(a) * ORBIT_RADIUS
            local b = self.gameList:spawnBullet(1, 0, bulletShape(), {x = 0, y = 0}, bx, by, "enemy")
            b.controlled = true
            b.timer = 0.2

            table.insert(self.orbit_bullets, b)
            table.insert(self.orbit_data, {
                angle      = a,            -- individual angle on the orbit circle
                curve_sign = curve_sign,
                heading    = 0,            -- filled in on release
            })
        end
    end
end

function Sitar:updateOrbit(dt)
    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2

    if self.orbit_phase == "orbit" then
        self.orbit_timer = self.orbit_timer - dt
        -- spin each bullet individually along the orbit circle
        for i, b in ipairs(self.orbit_bullets) do
            if b.active then
                local d = self.orbit_data[i]
                d.angle = d.angle + ORBIT_SPIN_SPEED * dt
                b.x = cx + math.cos(d.angle) * ORBIT_RADIUS
                b.y = cy + math.sin(d.angle) * ORBIT_RADIUS
            end
        end

        if self.orbit_timer <= 0 then
            -- release: each bullet's heading is computed from its current arc position
            -- trailing bullets are still pointing where the leader just came from,
            -- so the spread fans out along the natural curve of the orbit
            local px, py = player.x + 20, player.y + 20
            for i, b in ipairs(self.orbit_bullets) do
                if b.active then
                    local d = self.orbit_data[i]
                    -- tangent of the orbit at this bullet's angle (direction of spin)
                    local tx = -math.sin(d.angle) * math.sign(ORBIT_SPIN_SPEED)
                    local ty =  math.cos(d.angle) * math.sign(ORBIT_SPIN_SPEED)
                    -- blend: mix tangent direction with aim-at-player based on curve strength
                    local dx = px - b.x
                    local dy = py - b.y
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then dx, dy = dx / len, dy / len end
                    local blend = ORBIT_CURVE_STR  -- 0 = pure aim, higher = more tangent curve
                    local hx = dx + tx * blend
                    local hy = dy + ty * blend
                    d.heading = math.atan2(hy, hx)
                end
            end
            self.orbit_phase = "release"
            self.orbit_timer = 4.0
        end
    elseif self.orbit_phase == "release" then
        self.orbit_timer = self.orbit_timer - dt
        local px, py = player.x + 20, player.y + 20
        local any_alive = false
        for i, b in ipairs(self.orbit_bullets) do
            if b.active then
                any_alive = true
                local d = self.orbit_data[i]
                -- steer heading toward player each frame
                local desired = math.atan2(py - b.y, px - b.x)
                local diff = (desired - d.heading + math.pi) % (2 * math.pi) - math.pi
                local max_turn = ORBIT_TRACK_STR * dt
                if math.abs(diff) < max_turn then
                    d.heading = desired
                else
                    d.heading = d.heading + max_turn * (diff > 0 and 1 or -1)
                end
                b.x = b.x + math.cos(d.heading) * ORBIT_RELEASE_SPD * dt
                b.y = b.y + math.sin(d.heading) * ORBIT_RELEASE_SPD * dt
                local W, H = love.graphics.getDimensions()
                if b.x < -50 or b.x > W + 50 or b.y < -50 or b.y > H + 50 then
                    b.active = false
                end
            end
        end
        if not any_alive or self.orbit_timer <= 0 then
            for _, b in ipairs(self.orbit_bullets) do
                if b.active then b.active = false end
            end
            self.orbit_active = false
            self.orbit_bullets = nil
            self.orbit_data = nil
        end
    end
end

---------------------------------------------------------------------------
-- Main update
---------------------------------------------------------------------------
function Sitar:update(dt)
    if self.beam_active then self:updateBeams(dt) end
    if self.orbit_active then self:updateOrbit(dt) end

    self.attack_timer = self.attack_timer - dt
    if self.attack_timer <= 0 then
        self.attack_timer = ATTACK_COOLDOWN
        if self.gameList then
            local choice = pickAttack(self)
            if choice == 1 then
                self:singleBeam()
            elseif choice == 2 then
                self:tripleBeam()
            else
                self:orbitAttack()
            end
        end
    end
end

function Sitar:draw()
    love.graphics.setColor(0.2, 0.6, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, SIZE, SIZE)
end
