Enemy = setmetatable({}, {__index = Entity})
Enemy.__index = Enemy

function Enemy.new(hp, speed, shape, image)
    local self = setmetatable(Entity.new(hp, speed, shape, image), Enemy)
    return self
end

function Enemy:ai(dt)
    -- must return an array of {x, y} points to follow as a path
    -- e.g. return {{x=100, y=200}, {x=300, y=400}}
    error("Enemy:ai() not implemented")
end
