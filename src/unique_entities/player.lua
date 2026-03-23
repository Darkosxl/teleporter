Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(hp, speed, shape, image)
    local self = setmetatable(Entity.new(hp, speed, shape, image), Player)
    self.max_hp = hp
    return self
end

