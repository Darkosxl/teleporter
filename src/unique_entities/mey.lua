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
    self.attack_timer = self.attack_timer - dt
    if self.attack_timer <= 0 then
        self.attack_timer = 2
        if self.gameList then
            spear(self.x + 15, self.y + 15, player.x + 20, player.y + 20, self.gameList)
        end
    end
end

function Mey:draw()
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, 30, 30)
end

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

function pickaxe()
end

function scythe()
end

function axes()
end
