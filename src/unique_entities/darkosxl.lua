Darkosxl = setmetatable({}, {__index = Enemy})
Darkosxl.__index = Darkosxl

local function bulletShape()
    local verts = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        verts[i] = {x = math.cos(a) * 9, y = math.sin(a) * 9}
    end
    return verts
end

-- Axe pixel grid (15x15) — handle bottom-left, head top-right
local AXE_PIXELS = {
    {1,1}, {2,1},
    {1,2}, {2,2}, {3,2},
    {2,3}, {3,3}, {4,3},
    {4,4}, {5,4}, {6,4}, {10,4}, {11,4},
    {4,5}, {5,5}, {6,5}, {10,5}, {11,5}, {12,5},
    {5,6}, {6,6}, {7,6}, {8,6}, {9,6}, {10,6}, {11,6}, {12,6}, {13,6},
    {6,7}, {7,7}, {8,7}, {9,7}, {10,7}, {11,7}, {12,7}, {13,7}, {14,7},
    {7,8}, {8,8}, {9,8}, {10,8}, {11,8}, {12,8}, {13,8}, {14,8}, {15,8},
    {8,9}, {9,9}, {10,9}, {11,9}, {12,9}, {13,9}, {14,9}, {15,9},
    {5,10}, {6,10}, {7,10}, {8,10}, {9,10}, {10,10}, {11,10}, {12,10}, {13,10}, {14,10}, {15,10},
    {5,11}, {6,11}, {7,11}, {8,11}, {9,11}, {10,11}, {11,11}, {12,11},
    {6,12}, {7,12}, {8,12}, {9,12}, {10,12}, {11,12},
    {7,13}, {8,13}, {9,13}, {10,13},
    {8,14}, {9,14}, {10,14},
    {9,15}, {10,15},
}

function Darkosxl.new(x, y)
    local size = 50
    local shape = {
        {x = 0, y = 0}, {x = size, y = 0},
        {x = size, y = size}, {x = 0, y = size},
    }
    local self = setmetatable(Entity.new(200, 100, shape, nil), Darkosxl)
    self.x = x
    self.y = y
    self.w = size
    self.h = size
    self.type = "enemy"
    self.attack_timer = 3
    self.gameList = nil
    -- rosepetals state
    self.rose_bullets = nil
    self.rose_offsets = nil
    self.rose_angle   = 0
    self.rose_timer   = 0
    self.rose_active  = false
    return self
end

function Darkosxl:getShape()
    return {
        {x = self.x, y = self.y},
        {x = self.x + self.w, y = self.y},
        {x = self.x + self.w, y = self.y + self.h},
        {x = self.x, y = self.y + self.h},
    }
end

function Darkosxl:update(dt)
    local half = self.w / 2

    -- rosepetals sweep
    if self.rose_active then
        self.rose_timer = self.rose_timer - dt
        self.rose_angle = self.rose_angle + (2 * math.pi / 1.0) * dt

        local cx, cy = self.x + half, self.y + half
        local cos_a = math.cos(self.rose_angle)
        local sin_a = math.sin(self.rose_angle)
        local elapsed = 1.0 - self.rose_timer
        local scale = 1 + (elapsed / 1.0) * 1.5

        if self.rose_timer <= 0 then
            for i, b in ipairs(self.rose_bullets) do
                if b.active then
                    local off = self.rose_offsets[i]
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
            self.rose_active = false
            self.rose_bullets = nil
            self.rose_offsets = nil
        else
            for i, b in ipairs(self.rose_bullets) do
                if b.active then
                    local off = self.rose_offsets[i]
                    local rx = off.x * cos_a - off.y * sin_a
                    local ry = off.x * sin_a + off.y * cos_a
                    b.x = cx + rx * scale
                    b.y = cy + ry * scale
                end
            end
        end
        return
    end

    self.attack_timer = self.attack_timer - dt
    if self.attack_timer <= 0 then
        self.attack_timer = 3
        if self.gameList then
            local cx, cy = self.x + half, self.y + half
            self:rosepetals(cx, cy)
        end
    end
end

function Darkosxl:rosepetals(cx, cy)
    local cellSize = 12
    local pivotX, pivotY = 1, 1

    self.rose_bullets = {}
    self.rose_offsets = {}
    self.rose_angle = 0
    self.rose_timer = 1.0
    self.rose_active = true

    -- 8 axes evenly spaced (every 45°), full density
    local numAxes = 8
    for a = 0, numAxes - 1 do
        local rot = (2 * math.pi / numAxes) * a
        local cos_r = math.cos(rot)
        local sin_r = math.sin(rot)
        for _, px in ipairs(AXE_PIXELS) do
            local rawx = (px[1] - pivotX) * cellSize
            local rawy = (px[2] - pivotY) * cellSize
            local ox = rawx * cos_r - rawy * sin_r
            local oy = rawx * sin_r + rawy * cos_r

            local bx = cx + ox
            local by = cy + oy
            self.gameList:spawnBullet(1, 0, bulletShape(), {x = 0, y = 0}, bx, by)
            local bullets = self.gameList.bullets
            local b = bullets[#bullets]
            b.controlled = true
            b.timer = 0.2

            table.insert(self.rose_bullets, b)
            table.insert(self.rose_offsets, { x = ox, y = oy })
        end
    end
end

function Darkosxl:draw()
    love.graphics.setColor(0.6, 0.1, 0.6)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end
