Odachi                  = setmetatable({}, { __index = Enemy })
Odachi.__index          = Odachi

-- Tuning constants
local SIZE              = 70
local ODACHI_SPEED      = 150
local PARRY_RADIUS      = 130
local PARRY_COOLDOWN    = 0.3
local PARRY_BLAST_COUNT = 20
local SWING_RANGE       = 90
local SWING_COOLDOWN    = 1.0
local SWING_DAMAGE      = 2
local SKILL_COOLDOWN    = 7.0
local DASH_DURATION     = 0.7
local DASH_PEAK_SPEED   = 2500
local CLONE_LIFETIME    = 10.0
local CLONE_HP          = 225
local CROSS_TELEGRAPH   = 2.0
local CROSS_BULLET_GAP  = 30
local CROSS_LIFETIME    = 45.0
local BLAST_SPEED       = 900
local BLAST_SPAWN_RATE  = 0.04
local BLAST_DURATION    = 3.5
local BLAST_WIDTH_MIN   = 17
local BLAST_WIDTH_MAX   = 21
local BLAST_WIDTH_FLUX  = 2
local BLAST_BULLET_GAP  = 24
local BLAST_JITTER      = 10
local BLAST_SPEED_FLUX  = 200

local function bulletShape()
    local verts = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        verts[i] = { x = math.cos(a) * 9, y = math.sin(a) * 9 }
    end
    return verts
end

local function angleNormalize(a)
    return (a + math.pi) % (2 * math.pi) - math.pi
end

local function odachiDeflect(bullet, cx, cy)
    local nx = bullet.x - cx
    local ny = bullet.y - cy
    local len = math.sqrt(nx * nx + ny * ny)
    if len == 0 then return end
    nx, ny = nx / len, ny / len
    local dot = bullet.direction.x * nx + bullet.direction.y * ny
    bullet.direction.x = bullet.direction.x - 2 * dot * nx
    bullet.direction.y = bullet.direction.y - 2 * dot * ny
end

---------------------------------------------------------------------------
-- Constructor
---------------------------------------------------------------------------
function Odachi.new(x, y, is_clone)
    local hp = is_clone and CLONE_HP or 450
    local r = SIZE / 2
    local shape = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        shape[i] = { x = r + math.cos(a) * r, y = r + math.sin(a) * r }
    end
    local self             = setmetatable(Entity.new(hp, ODACHI_SPEED, shape, nil, ROOM_BOUNDS), Odachi)
    self.x                 = x
    self.y                 = y
    self.w                 = SIZE
    self.h                 = SIZE
    self.type              = "enemy"
    self.is_clone          = is_clone or false
    self.clone_timer       = is_clone and CLONE_LIFETIME or nil
    self.gameList          = nil
    -- parry
    self.parry_cd          = 0
    self.parry_count       = 0
    -- swing
    self.swing_cd          = 0
    self.swing_flash_timer = 0
    self.swing_flash_dir   = 0
    -- skill rotation
    self.skill_timer       = SKILL_COOLDOWN
    self.skill_weights     = { 1, 1, 1 }
    -- dash
    self.dash_active       = false
    self.dash_elapsed      = 0
    self.dash_dir          = { x = 0, y = 0 }
    -- cross
    self.cross_active      = false
    self.cross_timer       = 0
    -- clones
    self.clones            = {}
    -- blast wave (continuous stream)
    self.blast_active      = false
    self.blast_timer       = 0
    self.blast_spawn_cd    = 0
    return self
end

function Odachi:getShape()
    local r = SIZE / 2
    local cx, cy = self.x + r, self.y + r
    local verts = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        verts[i] = { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r }
    end
    return verts
end

---------------------------------------------------------------------------
-- Skill selection
---------------------------------------------------------------------------
local function pickSkill(self)
    local weights = self.skill_weights
    local function roll()
        local total = weights[1] + weights[2] + weights[3]
        local r = math.random() * total
        if r <= weights[1] then
            return 1
        elseif r <= weights[1] + weights[2] then
            return 2
        else
            return 3
        end
    end

    local choice = roll()
    if choice == 2 and (self.is_clone or self:clonesAlive()) then
        choice = roll()
        if choice == 2 then choice = 3 end
    end

    for i = 1, 3 do
        if i == choice then
            weights[i] = 1
        else
            weights[i] = weights[i] + 2
        end
    end
    return choice
end

function Odachi:clonesAlive()
    for _, c in ipairs(self.clones) do
        if c.state == "alive" then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Dash
---------------------------------------------------------------------------
function Odachi:startDash()
    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    local px, py = player.x + 20, player.y + 20
    local dx, dy = px - cx, py - cy
    local len = math.sqrt(dx * dx + dy * dy)
    if len == 0 then return end
    self.dash_dir     = { x = dx / len, y = dy / len }
    self.dash_active  = true
    self.dash_elapsed = 0
end

---------------------------------------------------------------------------
-- Clones
---------------------------------------------------------------------------
function Odachi:spawnClones()
    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    local px, py = player.x + 20, player.y + 20
    local dx, dy = px - cx, py - cy
    local len = math.sqrt(dx * dx + dy * dy)
    local perp = { x = 0, y = 0 }
    if len > 0 then perp = { x = -dy / len, y = dx / len } end

    for i = 1, 2 do
        local sign = (i == 1) and -1 or 1
        local clx = cx + perp.x * 100 * sign - SIZE / 2
        local cly = cy + perp.y * 100 * sign - SIZE / 2
        local clone = Odachi.new(clx, cly, true)
        clone.gameList = self.gameList
        self.gameList:addEntity(clone)
        table.insert(self.clones, clone)
    end
end

---------------------------------------------------------------------------
-- Cross: wall-to-wall + shape, no center gap
---------------------------------------------------------------------------
function Odachi:spawnCross()
    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    local W, H = love.graphics.getDimensions()

    local function crossBullet(bx, by)
        local b = self.gameList:spawnBullet(1, 0, bulletShape(), { x = 0, y = 0 }, bx, by, "enemy")
        b.neutral_timer = CROSS_LIFETIME
    end

    -- horizontal arm: 5 rows centered on cy
    for row = 0, 4 do
        local by = cy + (row - 2) * CROSS_BULLET_GAP
        local bx = 0
        while bx <= W do
            crossBullet(bx, by)
            bx = bx + CROSS_BULLET_GAP
        end
    end

    -- vertical arm: 5 columns centered on cx
    -- skip y values that land on a horizontal row to avoid double-spawning
    for col = 0, 4 do
        local bx = cx + (col - 2) * CROSS_BULLET_GAP
        local by = 0
        while by <= H do
            local in_h = false
            for row = 0, 4 do
                if math.abs(by - (cy + (row - 2) * CROSS_BULLET_GAP)) < CROSS_BULLET_GAP * 0.5 then
                    in_h = true; break
                end
            end
            if not in_h then crossBullet(bx, by) end
            by = by + CROSS_BULLET_GAP
        end
    end
end

---------------------------------------------------------------------------
-- Blast wave: kamehameha continuous stream, bullets converge on player
---------------------------------------------------------------------------
function Odachi:startBlast()
    self.blast_active   = true
    self.blast_timer    = BLAST_DURATION
    self.blast_spawn_cd = 0
end

function Odachi:updateBlast(dt)
    self.blast_timer = self.blast_timer - dt
    if self.blast_timer <= 0 then
        self.blast_active = false
        return
    end

    local cx, cy        = self.x + SIZE / 2, self.y + SIZE / 2
    local px, py        = player.x + 20, player.y + 20
    local base_angle    = math.atan2(py - cy, px - cx)
    local dirx, diry    = math.cos(base_angle), math.sin(base_angle)
    local perpx, perpy  = -diry, dirx

    self.blast_spawn_cd = self.blast_spawn_cd - dt
    while self.blast_spawn_cd <= 0 do
        self.blast_spawn_cd = self.blast_spawn_cd + BLAST_SPAWN_RATE
        local base_w = math.random(BLAST_WIDTH_MIN, BLAST_WIDTH_MAX)
        local w = math.max(2, base_w + math.random(-BLAST_WIDTH_FLUX, BLAST_WIDTH_FLUX))
        local half = (w - 1) / 2
        for col = 0, w - 1 do
            local offset     = (col - half) * BLAST_BULLET_GAP
            local lat_jitter = (math.random() * 2 - 1) * BLAST_JITTER
            local fwd_jitter = (math.random() * 2 - 1) * BLAST_JITTER * 0.5
            -- spawn position: perpendicular spread around Odachi center
            local bx         = cx + perpx * (offset + lat_jitter) + dirx * (20 + fwd_jitter)
            local by         = cy + perpy * (offset + lat_jitter) + diry * (20 + fwd_jitter)
            -- each bullet aims at current player pos from its spawn → natural convergence
            local ddx, ddy   = px - bx, py - by
            local dlen       = math.sqrt(ddx * ddx + ddy * ddy)
            if dlen > 0 then
                ddx, ddy = ddx / dlen, ddy / dlen
            else
                ddx, ddy = dirx, diry
            end
            local spd = BLAST_SPEED + (math.random() * 2 - 1) * BLAST_SPEED_FLUX
            local b = self.gameList:spawnBullet(1, spd, bulletShape(), { x = ddx, y = ddy }, bx, by, "enemy")
            b.timer = 0.2
        end
    end
end

---------------------------------------------------------------------------
-- Main update
---------------------------------------------------------------------------
function Odachi:update(dt)
    if self.state == "dead" then return end

    if self.is_clone and self.clone_timer then
        self.clone_timer = self.clone_timer - dt
        if self.clone_timer <= 0 then
            self.hp = 0; return
        end
    end

    self.swing_flash_timer = math.max(0, self.swing_flash_timer - dt)

    -- blast stream runs concurrently; movement paused while active
    if self.blast_active then self:updateBlast(dt) end

    -- cross telegraph: Odachi is planted
    if self.cross_active then
        self.cross_timer = self.cross_timer - dt
        if self.cross_timer <= 0 then
            self:spawnCross()
            self.cross_active = false
        end
    end

    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    local px, py = player.x + 20, player.y + 20

    -- movement (skipped during dash, cross telegraph, or blast)
    if self.dash_active then
        local t_norm = self.dash_elapsed / DASH_DURATION
        local spd = DASH_PEAK_SPEED * math.sin(t_norm * math.pi)
        self.x = self.x + self.dash_dir.x * spd * dt
        self.y = self.y + self.dash_dir.y * spd * dt
        self:clampToBounds()
        self.dash_elapsed = self.dash_elapsed + dt
        if self.dash_elapsed >= DASH_DURATION then self.dash_active = false end
    elseif not self.cross_active and not self.blast_active then
        local dx, dy = px - cx, py - cy
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 1 then
            self.x = self.x + (dx / dist) * ODACHI_SPEED * dt
            self.y = self.y + (dy / dist) * ODACHI_SPEED * dt
            self:clampToBounds()
        end
    end

    -- swing
    self.swing_cd = math.max(0, self.swing_cd - dt)
    if self.swing_cd <= 0 then
        local dx, dy = px - cx, py - cy
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < SWING_RANGE then
            player.hp              = player.hp - SWING_DAMAGE
            self.swing_cd          = SWING_COOLDOWN
            self.swing_flash_timer = 0.25
            self.swing_flash_dir   = math.atan2(dy, dx)
        end
    end

    -- parry: 180° arc facing player
    self.parry_cd = math.max(0, self.parry_cd - dt)
    if self.parry_cd <= 0 and self.gameList then
        local facing = math.atan2(py - cy, px - cx)
        for _, b in ipairs(self.gameList.bullets) do
            if b.active and b:canCollide() and b.deflect_cd <= 0 and not b.controlled then
                local bdx = b.x - cx
                local bdy = b.y - cy
                if math.sqrt(bdx * bdx + bdy * bdy) < PARRY_RADIUS then
                    local diff = angleNormalize(math.atan2(bdy, bdx) - facing)
                    if math.abs(diff) < math.pi / 2 then
                        odachiDeflect(b, cx, cy)
                        b.faction              = "neutral"
                        b.merge_count          = b.merge_count + 2
                        b.deflect_cd           = 0.3
                        self.parry_cd          = PARRY_COOLDOWN
                        self.swing_flash_timer = 0.15
                        self.swing_flash_dir   = facing
                        self.parry_count       = self.parry_count + 1
                        if self.parry_count >= PARRY_BLAST_COUNT then
                            self:startBlast()
                            self.parry_count = 0
                        end
                        break
                    end
                end
            end
        end
    end

    -- skill rotation
    self.skill_timer = self.skill_timer - dt
    if self.skill_timer <= 0 then
        self.skill_timer = SKILL_COOLDOWN
        if self.gameList then
            local choice = pickSkill(self)
            if choice == 1 then
                self:startDash()
            elseif choice == 2 then
                self:spawnClones()
            else
                self.cross_active = true
                self.cross_timer  = CROSS_TELEGRAPH
            end
        end
    end
end

---------------------------------------------------------------------------
-- Draw
---------------------------------------------------------------------------
function Odachi:draw()
    local cx, cy = self.x + SIZE / 2, self.y + SIZE / 2
    local r = SIZE / 2

    if self.is_clone then
        love.graphics.setColor(0.9, 0.1, 0.1, 0.45)
        love.graphics.circle("fill", cx, cy, r)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- swing flash: golden arc sector toward player
    if self.swing_flash_timer > 0 then
        local alpha = (self.swing_flash_timer / 0.25) * 0.6
        local a1 = self.swing_flash_dir - math.pi / 4
        local a2 = self.swing_flash_dir + math.pi / 4
        love.graphics.setColor(0.95, 0.78, 0.15, alpha)
        local segs = 10
        for k = 0, segs - 1 do
            local ang1 = a1 + (a2 - a1) * k / segs
            local ang2 = a1 + (a2 - a1) * (k + 1) / segs
            love.graphics.polygon("fill",
                cx, cy,
                cx + math.cos(ang1) * (SWING_RANGE - 8),
                cy + math.sin(ang1) * (SWING_RANGE - 8),
                cx + math.cos(ang2) * (SWING_RANGE - 8),
                cy + math.sin(ang2) * (SWING_RANGE - 8)
            )
        end
    end

    -- body
    love.graphics.setColor(0.05, 0.05, 0.05)
    love.graphics.circle("fill", cx, cy, r)

    -- horns
    love.graphics.setColor(0.08, 0.08, 0.08)
    love.graphics.polygon("fill", cx - 8, cy - 30, cx - 16, cy - 30, cx - 20, cy - 50, cx - 12, cy - 50)
    love.graphics.polygon("fill", cx + 8, cy - 30, cx + 16, cy - 30, cx + 20, cy - 50, cx + 12, cy - 50)

    -- cross telegraph: purple pulse growing toward spawn
    if self.cross_active then
        local prog = (CROSS_TELEGRAPH - self.cross_timer) / CROSS_TELEGRAPH
        love.graphics.setColor(0.5, 0.15, 0.85, prog * 0.6)
        love.graphics.circle("fill", cx, cy, r + prog * 25)
    end

    -- blast active: red glow while firing
    if self.blast_active then
        local pulse = 0.5 + 0.5 * math.sin(love.timer.getTime() * 14)
        love.graphics.setColor(1.0, 0.15, 0.1, 0.3 + pulse * 0.2)
        love.graphics.circle("fill", cx, cy, r + 12)
    end

    -- sword: sits 48px to the perpendicular-right of the facing direction
    local px_g   = player.x + 20
    local py_g   = player.y + 20
    local facing = math.atan2(py_g - cy, px_g - cx)
    local perpx  = -math.sin(facing)
    local perpy  = math.cos(facing)
    local sx     = cx + perpx * 48
    local sy     = cy + perpy * 48

    -- blade color: silver → gold based on parry charge
    local charge = self.parry_count / PARRY_BLAST_COUNT
    local br     = 0.72 + charge * 0.28
    local bg     = 0.72 + charge * 0.10
    local bb     = 0.78 - charge * 0.66

    love.graphics.push()
    love.graphics.translate(sx, sy)
    love.graphics.rotate(facing)
    -- after rotate(facing), local +x axis points toward player

    -- blade: points toward player (local +x direction)
    love.graphics.setColor(br, bg, bb)
    love.graphics.rectangle("fill", 4, -2, 24, 4)
    -- cross-guard: perpendicular bar
    love.graphics.setColor(br * 0.65, bg * 0.65, bb * 0.65)
    love.graphics.rectangle("fill", 0, -8, 4, 16)
    -- hilt
    love.graphics.setColor(0.35, 0.18, 0.08)
    love.graphics.rectangle("fill", -10, -2, 10, 4)
    -- pommel
    love.graphics.setColor(br * 0.8, bg * 0.7, bb * 0.5)
    love.graphics.circle("fill", -10, 0, 3)

    -- blade sparkle when charging up
    if charge > 0.3 then
        local t = love.timer.getTime()
        local intensity = (charge - 0.3) / 0.7
        love.graphics.setColor(1, 1, 0.85, intensity * (0.35 + 0.65 * math.abs(math.sin(t * 7))))
        for k = 1, 4 do
            local spark_x = 6 + k * 5 + math.sin(t * (3 + k * 2.3) + k) * 2
            local spark_y = math.cos(t * (4.5 + k * 1.7) + k * 2.1) * 2
            love.graphics.circle("fill", spark_x, spark_y, 1.5 * intensity)
        end
    end

    love.graphics.pop()

    love.graphics.setColor(1, 1, 1, 1)
end
