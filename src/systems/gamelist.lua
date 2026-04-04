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

function GameList:spawnBullet(damage, speed, shape, direction, x, y, faction)
    local b = Bullet.new(damage, speed, shape, direction, x, y)
    b.faction = faction or "enemy"
    table.insert(self.bullets, b)
    return b
end

---------------------------------------------------------------------------
-- Spatial grid for bullet-on-bullet collision
---------------------------------------------------------------------------
local GRID_CELL = 40

local function buildBulletGrid(bullets)
    local grid = {}
    for i, b in ipairs(bullets) do
        if b.active and not b.controlled and b:canCollide() then
            local cx = math.floor(b.x / GRID_CELL)
            local cy = math.floor(b.y / GRID_CELL)
            local key = cx * 100000 + cy
            if not grid[key] then grid[key] = {} end
            table.insert(grid[key], i)
        end
    end
    return grid
end

---------------------------------------------------------------------------
-- Explosion: AOE damage to entities and destroy nearby bullets
---------------------------------------------------------------------------
local function triggerExplosion(bullet, gameList)
    local radius = bullet.radius * 3
    local damage = bullet.damage

    for _, entity in ipairs(gameList.entities) do
        if entity.state == "alive" then
            local ex = entity.x + (entity.w or 20)
            local ey = entity.y + (entity.h or 20)
            local dx = bullet.x - ex
            local dy = bullet.y - ey
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < radius then
                entity.hp = entity.hp - damage
            end
        end
    end

    for _, b in ipairs(gameList.bullets) do
        if b.active and b ~= bullet then
            local dx = bullet.x - b.x
            local dy = bullet.y - b.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < radius * 0.5 then
                b.active = false
            end
        end
    end

    bullet.active = false
end

---------------------------------------------------------------------------
-- Bullet-on-bullet collision
---------------------------------------------------------------------------
local function bulletOnBullet(self)
    local grid = buildBulletGrid(self.bullets)
    local merged = {}

    for key, cell in pairs(grid) do
        -- decode cell coords
        local cy = key % 100000
        local cx = (key - cy) / 100000

        -- gather indices from this cell + 8 neighbors
        local nearby = {}
        for dx = -1, 1 do
            for dy = -1, 1 do
                local nkey = (cx + dx) * 100000 + (cy + dy)
                if grid[nkey] then
                    for _, idx in ipairs(grid[nkey]) do
                        nearby[#nearby + 1] = idx
                    end
                end
            end
        end

        for ai = 1, #nearby do
            for bi = ai + 1, #nearby do
                local ii, ji = nearby[ai], nearby[bi]
                if ii == ji then goto next_pair end
                local a = self.bullets[ii]
                local b = self.bullets[ji]
                if not a.active or not b.active then goto next_pair end
                if merged[ii] or merged[ji] then goto next_pair end

                local same_faction = (a.faction == b.faction) and (a.faction ~= "neutral")

                if same_faction then
                    if innerCircleOverlap(a, b) then
                        a:merge(b)
                        merged[ji] = true
                        if a:shouldExplode() then
                            triggerExplosion(a, self)
                            merged[ii] = true
                        end
                    end
                else
                    if outerCircleOverlap(a, b) then
                        -- tug of war: one is stopped neutral, other is moving
                        local stopped, moving, si, mi = nil, nil, nil, nil
                        if a.faction == "neutral" and a.speed == 0 then
                            stopped, moving, si, mi = a, b, ii, ji
                        elseif b.faction == "neutral" and b.speed == 0 then
                            stopped, moving, si, mi = b, a, ji, ii
                        end

                        if stopped and moving then
                            stopped:merge(moving)
                            stopped.speed = moving.speed
                            stopped.direction = {x = moving.direction.x, y = moving.direction.y}
                            stopped.neutral_timer = nil
                            merged[mi] = true
                            if stopped:shouldExplode() then
                                triggerExplosion(stopped, self)
                                merged[si] = true
                            end
                        else
                            -- two moving bullets of different factions → neutral stop
                            a:merge(b)
                            a.faction = "neutral"
                            a.speed = 0
                            a.direction = {x = 0, y = 0}
                            a.neutral_timer = 10.0
                            merged[ji] = true
                            if a:shouldExplode() then
                                triggerExplosion(a, self)
                                merged[ii] = true
                            end
                        end
                    end
                end
                ::next_pair::
            end
        end
    end
end

---------------------------------------------------------------------------
-- Main update
---------------------------------------------------------------------------
function GameList:update(dt)
    for i, entity in ipairs(self.entities) do
        if entity.update then entity:update(dt) end
        entity:checkAlive()
    end

    -- Update player attack beam states
    if self.beamStates then
        for i = #self.beamStates, 1, -1 do
            local state = self.beamStates[i]
            local alive = state.fireFn(0, dt)  -- elapsed time not needed, just dt
            if not alive then
                table.remove(self.beamStates, i)
            end
        end
    end

    -- Update player controlled formations (pickaxe, axe spin)
    if self.controlledFormations then
        for i = #self.controlledFormations, 1, -1 do
            local state = self.controlledFormations[i]
            local t = state.getTime and state:getTime() or 0
            local alive = false
            for j, b in ipairs(state.bullets) do
                if b.active and state.fireFn then
                    local off = state.offsets[j]
                    local still_alive = state.fireFn(b, off, t, dt)
                    if still_alive then alive = true end
                end
            end
            state.timer = state.timer - dt
            if not alive or state.timer <= 0 then
                table.remove(self.controlledFormations, i)
            end
        end
    end

    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)

        if b:canCollide() then
            for _, entity in ipairs(self.entities) do
                if entity.state == "dead" then
                    goto continue
                elseif b.faction == "enemy" and entity.type ~= "player" then
                    -- enemy bullets cannot hit other enemies
                    goto continue
                elseif entity.type == "player" and entity.sweep_active then
                    local hit = aabb({ shape = b:getShape() }, { shape = entity:getSweepShape() })
                    if hit and b.deflect_cd <= 0 then
                        deflect(b, entity)
                        b.damage = b.damage * 2
                        b.speed = b.speed * 0.5
                        b:scale(2)
                        b.deflect_cd = 0.3
                        b.faction = "neutral"
                        break
                    end
                    local hit2 = b.x + b.radius > entity.x and b.x - b.radius < entity.x + entity.w
                              and b.y + b.radius > entity.y and b.y - b.radius < entity.y + entity.h
                    if hit2 then
                        entity.hp = entity.hp - b.damage
                        b.active  = false
                        break
                    end
                else
                    local hit = b.x + b.radius > entity.x and b.x - b.radius < entity.x + entity.w
                             and b.y + b.radius > entity.y and b.y - b.radius < entity.y + entity.h
                    if hit then
                        entity.hp = entity.hp - b.damage
                        b.active  = false
                        break
                    end
                end
                ::continue::
            end
        end

        if not b.active then
            table.remove(self.bullets, i)
        end
    end

    -- bullet-on-bullet collision (after entity collision, before next frame)
    bulletOnBullet(self)

    -- centralized explosion scan: catches merge_count bumped from any source (parry, merge, etc.)
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        if b.active and b:shouldExplode() then
            triggerExplosion(b, self)
        end
    end

    -- clean up bullets deactivated by merges/explosions
    for i = #self.bullets, 1, -1 do
        if not self.bullets[i].active then
            table.remove(self.bullets, i)
        end
    end
end

function GameList:hasLivingEnemies()
    for _, entity in ipairs(self.entities) do
        if entity.type ~= "player" and entity.state == "alive" then
            return true
        end
    end
    return false
end

function GameList:draw()
    for _, entity in ipairs(self.entities) do
        if entity.draw and entity.state == "alive" then entity:draw() end
    end
    for _, b in ipairs(self.bullets) do
        b:draw()
    end
end
