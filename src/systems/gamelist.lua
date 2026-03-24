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
                if entity.type == "player" and entity.sweep_active then
                    local hit = aabb({ shape = b:getShape() }, { shape = entity:getSweepShape() })
                    if hit and b.deflect_cd <= 0 then
                        deflect(b, entity)
                        b.damage = b.damage * 2
                        b.speed = b.speed * 0.5
                        b:scale(2)
                        b.deflect_cd = 0.3
                        break
                    end
                    local hit2 = aabb({ shape = b:getShape() }, { shape = entity:getShape() })
                    if hit2 then
                        entity.hp = entity.hp - b.damage
                        b.active  = false
                        break
                    end
                else
                    local hit = aabb({shape = b:getShape()}, {shape = entity:getShape()})
                    if hit then
                        entity.hp = entity.hp - b.damage
                        b.active  = false
                        break
                    end
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
