local bullet = {}
bullet.__index = bullet

activeBullets = {}

function bullet.new(damage, speed, shape, direction, x, y)
    local self = setmetatable({}, bullet)
    self.damage    = damage
    self.speed     = speed
    self.shape     = shape
    self.direction = direction  -- {x, y} normalized vector
    self.x         = x
    self.y         = y
    self.timer     = 0
    self.active    = true
    return self
end

function bullet:getShape()
    local result = {}
    for i, v in ipairs(self.shape) do
        result[i] = {x = v.x + self.x, y = v.y + self.y}
    end
    return result
end

function bullet:update(dt)
    self.timer = self.timer + dt
    self.x = self.x + self.direction.x * self.speed * dt
    self.y = self.y + self.direction.y * self.speed * dt

    local W, H = love.graphics.getDimensions()
    if self.x < 0 or self.x > W or self.y < 0 or self.y > H then
        self.active = false
    end
end

function bullet:canCollide()
    return self.timer >= 1
end





