require "systems/bullets"

local BulletList = {}
BulletList.__index = BulletList

function BulletList.new()
    local self = setmetatable({}, BulletList)
    self.activeBullets = {}
    return self
end

function BulletList:spawnBullet(damage, speed, shape, direction, x, y)
    table.insert(self.activeBullets, bullet.new(damage, speed, shape, direction, x, y))
end

function BulletList:update(dt, targets)
    for i = #self.activeBullets, 1, -1 do
        local b = self.activeBullets[i]
        b:update(dt)

        if b:canCollide() then
            for _, target in ipairs(targets) do
                local hit, _ = aabb({shape = b:getShape()}, {shape = target:getShape()})
                if hit then
                    target.hp = target.hp - b.damage
                    b.active  = false
                    break
                end
            end
        end

        if not b.active then
            table.remove(self.activeBullets, i)
        end
    end
end