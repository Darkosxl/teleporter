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
    self.x = self.x + self.direction.x * self.speed * dt
    self.y = self.y + self.direction.y * self.speed * dt

    local W, H = love.graphics.getDimensions()
    if self.x < 0 or self.x > W or self.y < 0 or self.y > H then
        self.active = false
    end
end

function Bullet:canCollide()
    return self.timer >= 0.2
end

function Bullet:draw()
    love.graphics.setColor(1, 1, 1)
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
end
