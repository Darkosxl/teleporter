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
