Entity = {}
Entity.__index = Entity

function Entity.new(hp, speed, shape, image)
    local self = setmetatable({}, Entity)
    self.hp    = hp
    self.speed = speed
    self.shape = shape
    self.image = image or nil
    return self
end
