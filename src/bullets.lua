local bullet = {}
bullet.__index = bullet

function bullet.new(damage, speed, size, shape)
    local self = setmetatable({}, bullet)
    self.damage = damage
    self.size = size
    self.speed = speed
    return self
end

