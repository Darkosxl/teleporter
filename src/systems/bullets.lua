Bullet = {}
Bullet.__index = Bullet


function Bullet.new(damage, speed, shape, direction, x, y)
    local self = setmetatable({}, Bullet)
    self.damage    = damage
    self.speed     = speed
    self.shape     = shape
    self.direction = direction  -- {x, y} normalized vector
    self.x         = x
    self.y         = y
    self.timer     = 0
    self.active    = true
    self.type      = "bullet"
    self.deflect_cd = 0
    self.controlled = false  -- when true, owner overrides position, skip normal movement
    self.faction     = "enemy"   -- "player", "enemy", "neutral"
    self.merge_count = 0
    self.neutral_timer = nil     -- countdown for stopped neutral bullets (10s)

    -- cache radius from shape vertices
    local maxR = 0
    for _, v in ipairs(self.shape) do
        local d = math.sqrt(v.x * v.x + v.y * v.y)
        if d > maxR then maxR = d end
    end
    self.radius = maxR

    return self
end

function Bullet:getShape()
    local result = {}
    for i, v in ipairs(self.shape) do
        result[i] = {x = v.x + self.x, y = v.y + self.y}
    end
    return result
end

function Bullet:update(dt)
    self.deflect_cd = math.max(0, self.deflect_cd - dt)
    self.timer = self.timer + dt

    if self.neutral_timer then
        self.neutral_timer = self.neutral_timer - dt
        if self.neutral_timer <= 0 then
            self.active = false
            return
        end
    end

    if not self.controlled then
        self.x = self.x + self.direction.x * self.speed * dt
        self.y = self.y + self.direction.y * self.speed * dt

        if self.speed > 0 then
            local W, H = love.graphics.getDimensions()
            if self.x < -50 or self.x > W + 50 or self.y < -50 or self.y > H + 50 then
                self.active = false
            end
        end
    end
end

function Bullet:canCollide()
    return self.timer >= 0.5
end

local FACTION_COLORS = {
    player  = {0.4, 1.0, 0.5},
    enemy   = {1.0, 0.4, 0.4},
    neutral = {1.0, 0.9, 0.3},
}

function Bullet:draw()
    local c = FACTION_COLORS[self.faction] or {1, 1, 1}
    love.graphics.setColor(c[1], c[2], c[3])
    local verts = {}
    for _, v in ipairs(self.shape) do
        table.insert(verts, v.x + self.x)
        table.insert(verts, v.y + self.y)
    end
    love.graphics.polygon("fill", verts)
end

function Bullet:scale(size)
    for _, v in ipairs(self.shape) do
        v.x = v.x * size
        v.y = v.y * size
    end
    self.radius = self.radius * size
end

function Bullet:merge(other)
    self.damage = self.damage + other.damage
    self.merge_count = self.merge_count + other.merge_count + 1
    self:scale(1.15)
    other.active = false
end

function Bullet:shouldExplode()
    return self.merge_count >= 10
end
