Mey = setmetatable({}, {__index = Enemy})
Mey.__index = Mey

local function bulletShape()
    local verts = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        verts[i] = {x = math.cos(a) * 9, y = math.sin(a) * 9}
    end
    return verts
end

function Mey.new(x, y)
    local size = 30
    local shape = {
        {x = 0, y = 0}, {x = size, y = 0},
        {x = size, y = size}, {x = 0, y = size},
    }
    local self = setmetatable(Entity.new(50, 100, shape, nil), Mey)
    self.x = x
    self.y = y
    self.type = "enemy"
    self.attack_timer = 2
    self.gameList = nil
    -- pickaxe sweep state
    self.pickaxe_bullets = nil   -- table of bullet refs during sweep
    self.pickaxe_offsets = nil   -- {angle, radius} per bullet (polar offsets from mey)
    self.pickaxe_angle   = 0    -- current rotation of the whole formation
    self.pickaxe_timer   = 0    -- countdown for sweep duration
    self.pickaxe_active  = false
    return self
end

function Mey:getShape()
    return {
        {x = self.x, y = self.y},
        {x = self.x + 30, y = self.y},
        {x = self.x + 30, y = self.y + 30},
        {x = self.x, y = self.y + 30},
    }
end

function Mey:update(dt)
    -- update pickaxe sweep if active
    if self.pickaxe_active then
        self.pickaxe_timer = self.pickaxe_timer - dt
        self.pickaxe_angle = self.pickaxe_angle + (math.pi / 0.8) * dt

        local cx, cy = self.x + 15, self.y + 15
        local cos_a = math.cos(self.pickaxe_angle)
        local sin_a = math.sin(self.pickaxe_angle)

        if self.pickaxe_timer <= 0 then
            -- release: give each bullet an outward direction and uncontrol it
            for i, b in ipairs(self.pickaxe_bullets) do
                if b.active then
                    local off = self.pickaxe_offsets[i]
                    local rx = off.x * cos_a - off.y * sin_a
                    local ry = off.x * sin_a + off.y * cos_a
                    local len = math.sqrt(rx * rx + ry * ry)
                    if len > 0 then
                        b.direction = { x = rx / len, y = ry / len }
                    else
                        b.direction = { x = 0, y = -1 }
                    end
                    b.speed = 1800
                    b.controlled = false
                end
            end
            self.pickaxe_active = false
            self.pickaxe_bullets = nil
            self.pickaxe_offsets = nil
        else
            -- sweep: rotate cartesian offsets and position bullets
            for i, b in ipairs(self.pickaxe_bullets) do
                if b.active then
                    local off = self.pickaxe_offsets[i]
                    local rx = off.x * cos_a - off.y * sin_a
                    local ry = off.x * sin_a + off.y * cos_a
                    b.x = cx + rx
                    b.y = cy + ry
                end
            end
        end
        return  -- don't attack while sweeping
    end

    self.attack_timer = self.attack_timer - dt
    if self.attack_timer <= 0 then
        self.attack_timer = 2
        if self.gameList then
            local cx, cy = self.x + 15, self.y + 15
            local tx, ty = player.x + 20, player.y + 20
            if math.random() < 0.5 then
                spear(cx, cy, tx, ty, self.gameList)
            else
                self:pickaxeAttack(cx, cy, tx, ty)
            end
        end
    end
end

function Mey:draw()
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, 30, 30)
end

-- Mey TODOs:
-- TODO: movement — reposition between attacks (move → attack → move cycle)
-- TODO: random attack selection — pick from spear/pickaxe/scythe/axes each cycle
-- TODO: spawn as duo — two Meys per room, independent rotations
-- TODO: enemy bullets cannot hit each other — needs gamelist change
-- TODO: Mey death — remove from gamelist when hp <= 0
--
-- Global TODOs (playtest blockers):
-- TODO: wall collision — player walks through walls freely
-- TODO: room transitions — gates exist visually but don't transport player
-- TODO: room clearing logic — detect all enemies dead, open gates
-- TODO: bullet-on-bullet collision — stopped bullets, charge, explosion system
-- TODO: upgrade selection UI — pick 1 of 3 after room clear
-- TODO: permadeath / run reset — dying returns to main menu, resets state
-- TODO: teleport-onto-bullet collision — teleporting onto a bullet counts as a hit
-- TODO: entity-on-entity collision
-- TODO: at least 1 boss for area 1

-- Weapon patterns

function spear(x, y, target_x, target_y, gameList)
    local dx = target_x - x
    local dy = target_y - y
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return end
    local dirx, diry = dx / len, dy / len
    local perpx, perpy = -diry, dirx

    local gap    = 36
    local speed  = 2400
    local damage = 1

    local function spawn(along, perp)
        local bx = x + dirx * (along * gap) + perpx * (perp * gap)
        local by = y + diry * (along * gap) + perpy * (perp * gap)
        gameList:spawnBullet(damage, speed, bulletShape(), {x = dirx, y = diry}, bx, by)
    end

    -- Pyramid (tip points forward toward target)
    spawn(4, 0)
    spawn(3, -0.5)   spawn(3, 0.5)
    spawn(2, -1)      spawn(2, 0)       spawn(2, 1)
    spawn(1, -2)      spawn(1, 2)
    spawn(0, -1)      spawn(0, 0)       spawn(0, 1)

    -- Shaft: double line of 7 behind the pyramid
    for i = 1, 7 do
        spawn(-i, -0.5)
        spawn(-i,  0.5)
    end
end

-- Minecraft diamond pickaxe pixel grid (14x14, centered at 7.5,7.5)
-- Every non-empty cell from the reference image becomes a bullet
local PICKAXE_PIXELS = {
    -- row 1: head top edge
    {5,1}, {6,1}, {7,1}, {8,1},
    -- row 2: head upper
    {4,2}, {5,2}, {6,2}, {7,2}, {8,2}, {9,2}, {10,2}, {11,2},
    -- row 3: head middle
    {4,3}, {5,3}, {6,3}, {7,3}, {8,3}, {9,3}, {10,3}, {11,3},
    -- row 4: head lower + right extension
    {5,4}, {6,4}, {7,4}, {8,4}, {9,4}, {10,4}, {11,4}, {12,4}, {13,4},
    -- row 5: handle start + right piece
    {8,5}, {9,5}, {10,5}, {11,5}, {12,5}, {13,5},
    -- row 6
    {7,6}, {8,6}, {9,6}, {11,6}, {12,6}, {13,6},
    -- row 7
    {6,7}, {7,7}, {8,7}, {11,7}, {12,7}, {13,7},
    -- row 8
    {5,8}, {6,8}, {7,8}, {11,8}, {12,8}, {13,8},
    -- row 9
    {4,9}, {5,9}, {6,9}, {11,9}, {12,9}, {13,9},
    -- row 10
    {3,10}, {4,10}, {5,10}, {12,10},
    -- row 11
    {2,11}, {3,11}, {4,11},
    -- row 12
    {1,12}, {2,12}, {3,12},
    -- row 13
    {1,13}, {2,13},
    -- row 14
    {1,14},
}

function Mey:pickaxeAttack(cx, cy, tx, ty)
    local baseAngle = math.atan2(ty - cy, tx - cx) - math.pi / 2
    local cellSize = 18  -- pixels per grid cell
    local centerX, centerY = 1, 24  -- pivot far past handle, large sweep radius

    self.pickaxe_bullets = {}
    self.pickaxe_offsets = {}
    self.pickaxe_angle = baseAngle
    self.pickaxe_timer = 0.8
    self.pickaxe_active = true

    -- spawn four pickaxes: one per quadrant (0°, 90°, 180°, 270° offsets)
    local rotations = {0, math.pi / 2, math.pi, 3 * math.pi / 2}
    for _, rot in ipairs(rotations) do
        local cos_r = math.cos(rot)
        local sin_r = math.sin(rot)
        for _, px in ipairs(PICKAXE_PIXELS) do
            local rawx = (px[1] - centerX) * cellSize
            local rawy = (px[2] - centerY) * cellSize
            local ox = rawx * cos_r - rawy * sin_r
            local oy = rawx * sin_r + rawy * cos_r

            local rx = ox * math.cos(baseAngle) - oy * math.sin(baseAngle)
            local ry = ox * math.sin(baseAngle) + oy * math.cos(baseAngle)

            local bx = cx + rx
            local by = cy + ry
            self.gameList:spawnBullet(1, 0, bulletShape(), {x = 0, y = 0}, bx, by)
            local bullets = self.gameList.bullets
            local b = bullets[#bullets]
            b.controlled = true
            b.timer = 0.2

            table.insert(self.pickaxe_bullets, b)
            table.insert(self.pickaxe_offsets, { x = ox, y = oy })
        end
    end
end

-- TODO: scythe — curved line of bullets across entire screen, unavoidable without teleport
function scythe()
end

-- TODO: axes — multiple small circular bullet formations that orbit and spin, area denial
function axes()
end
