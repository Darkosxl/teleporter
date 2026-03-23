require "src/systems/bullets"
require "src/systems/collision"
GameList = {}
GameList.__index = GameList

function GameList.new()
    local self = setmetatable({}, GameList)
    self.entities = {}
    self.bullets  = {}
    return self
end

function GameList:addEntity(entity)
    table.insert(self.entities, entity)
end

function GameList:spawnBullet(damage, speed, shape, direction, x, y)
    table.insert(self.bullets, Bullet.new(damage, speed, shape, direction, x, y))
end

function GameList:update(dt)
    for _, entity in ipairs(self.entities) do
        if entity.update then entity:update(dt) end
    end

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)

        if b:canCollide() then
            for _, entity in ipairs(self.entities) do
                local hit, _ = aabb({shape = b:getShape()}, {shape = entity:getShape()})
                if hit then
                    entity.hp = entity.hp - b.damage
                    b.active  = false
                    break
                end
            end
        end

        if not b.active then
            table.remove(self.bullets, i)
        end
    end
end

function GameList:draw()
    for _, entity in ipairs(self.entities) do
        if entity.draw then entity:draw() end
    end
    for _, b in ipairs(self.bullets) do
        b:draw()
    end
end
