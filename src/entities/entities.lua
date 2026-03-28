Entity = {}
Entity.__index = Entity

function Entity.new(hp, speed, shape, image, allowed_bounds)
    local self = setmetatable({}, Entity)
    self.hp    = hp
    self.speed = speed
    self.shape = shape
    self.image = image or nil
    self.type = "entity"
    self.state = "alive"
    self.w = 40
    self.h = 40
    self.allowed_bounds = allowed_bounds or {0, 0, 0, 0} --lower x, upper x, lower y, upper y
    return self
end

function Entity:clampToBounds()
    local b = self.allowed_bounds
    self.x = math.max(b[1], math.min(self.x, b[2] - self.w))
    self.y = math.max(b[3], math.min(self.y, b[4] - self.h))
end

function Entity:checkAlive()
    if self.hp <= 0 then
        self.state = "dead"
    end
end