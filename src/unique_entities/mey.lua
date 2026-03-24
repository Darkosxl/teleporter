Enemy1 = setmetatable({}, {__index = Enemy})
Enemy1.__index = Enemy1

local function ai(self)
    local min_y, max_y = math.huge, -math.huge
    for _, v in ipairs(self.shape) do
        min_y = math.min(min_y, v.y)
        max_y = math.max(max_y, v.y)
    end
    local step        = max_y - min_y

    local left        = self.playground.lowerx
    local right       = self.playground.upperx
    local bottom      = self.playground.uppery

    local path        = {}
    local current_y   = self.y
    local going_right = true

    while current_y <= bottom do
        local target_x = going_right and right or left
        table.insert(path, { x = target_x, y = current_y })
        current_y = current_y + step
        table.insert(path, { x = target_x, y = current_y })
        going_right = not going_right
    end

    for i = #path - 1, 1, -1 do
        table.insert(path, path[i])
    end

    return path
end

function Enemy1.new(x, y, hp, speed, shape, image, playground)
    local self = setmetatable(Entity.new(hp, speed, shape, image), Enemy1)
    self.x = x
    self.y = y
    self.playground = playground
    self.path = ai(self)
    return self
end

function mobilizeEnemy1(spawn_playground, num_of_enemies)
    local lowerx = math.min(spawn_playground[1][1], spawn_playground[2][1])
    local lowery = math.min(spawn_playground[1][2], spawn_playground[2][2])
    local upperx = math.max(spawn_playground[1][1], spawn_playground[2][1])
    local uppery = math.max(spawn_playground[1][2], spawn_playground[2][2])
    local enemies = {}
    for i = 1, num_of_enemies do
        local x, y = math.random(lowerx, upperx), math.random(lowery, uppery)
        local enemy1hp = 50
        local enemy1speed = 10 -- assuming the map is 1900x1080
        local enemy1shape = { { x = x, y = y }, { x = x + 15, y = y }, { x = x, y = y - 15 }, { x = x + 15, y = y - 15 } }
        local playground = { lowerx = lowerx, lowery = lowery, upperx = upperx, uppery = uppery }
        local enemy1 = Enemy1.new(x, y, enemy1hp, enemy1speed, enemy1shape, nil, playground)
        table.insert(enemies, enemy1)
    end
    return enemies
end

local function bulletShape()
    local verts = {}
    for i = 1, 8 do
        local a = (2 * math.pi / 8) * (i - 1)
        verts[i] = {x = math.cos(a) * 3, y = math.sin(a) * 3}
    end
    return verts
end

function spear(x, y, target_x, target_y, gameList)
    local dx = target_x - x
    local dy = target_y - y
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return end
    local dirx, diry = dx / len, dy / len
    local perpx, perpy = -diry, dirx

    local gap    = 12
    local speed  = 1200
    local damage = 1
    local dir    = {x = dirx, y = diry}

    local function spawn(along, perp)
        local bx = x + dirx * (along * gap) + perpx * (perp * gap)
        local by = y + diry * (along * gap) + perpy * (perp * gap)
        gameList:spawnBullet(damage, speed, bulletShape(), {x = dirx, y = diry}, bx, by)
    end

    -- Pyramid (tip points forward toward target)
    -- Row 4 (tip):    1 bullet
    spawn(4, 0)
    -- Row 3:          2 bullets
    spawn(3, -0.5)   spawn(3, 0.5)
    -- Row 2:          3 bullets (full)
    spawn(2, -1)      spawn(2, 0)       spawn(2, 1)
    -- Row 1:          leftmost + rightmost only (skeleton of 5-wide)
    spawn(1, -2)      spawn(1, 2)
    -- Row 0 (base):   central 3 only (skeleton of 7-wide)
    spawn(0, -1)      spawn(0, 0)       spawn(0, 1)

    -- Shaft: double line of 7 behind the pyramid
    for i = 1, 7 do
        spawn(-i, -0.5)
        spawn(-i,  0.5)
    end
end

function pickaxe()
    local bullets = {}
    
    return bullets
end

function scythe()
    local bullets = {}
    
    return bullets
end

function axes()
    local bullets = {}
    
    return bullets
end