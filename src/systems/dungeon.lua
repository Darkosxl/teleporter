require "src/systems/rooms"
Dungeon = setmetatable({}, {__index = Dungeon})
Dungeon.__index = Dungeon

local OPPOSITE = { top = "bottom", bottom = "top", left = "right", right = "left" }
local DIR_OFFSET = {
    top    = { 0, -1},
    bottom = { 0,  1},
    left   = {-1,  0},
    right  = { 1,  0},
}

function Dungeon:new()
    local self = setmetatable({}, Dungeon)
    self.grid = {}
    self.rooms = self:generateRooms()
    self.currentRoom = self.rooms[1]
    return self
end

function Dungeon:generateRooms()
    local rooms = {}
    local MAX_ROOMS = 8

    local function key(gx, gy) return gx .. "," .. gy end

    local function shuffle(t)
        for i = #t, 2, -1 do
            local j = math.random(i)
            t[i], t[j] = t[j], t[i]
        end
    end

    local function doorCount(room)
        local n = 0
        for _, _ in pairs(room.neighbours) do n = n + 1 end
        return n
    end

    -- create spawn room
    local spawn = Room.new({}, "spawn")
    spawn.depth = 1
    spawn.gx = 0
    spawn.gy = 0
    self.grid[key(0, 0)] = spawn
    table.insert(rooms, spawn)

    -- BFS queue: each entry is {room, gx, gy}
    local queue = { { spawn, 0, 0 } }
    local head = 1

    while head <= #queue and #rooms < MAX_ROOMS do
        local current, gx, gy = queue[head][1], queue[head][2], queue[head][3]
        head = head + 1

        local maxDoors = current.difficulty == "spawn" and 3 or 4
        -- random number of children this room tries to spawn (1 to available slots)
        local available = maxDoors - doorCount(current)
        if available <= 0 then goto nextRoom end
        local numChildren = math.random(available)

        local dirs = { "top", "bottom", "left", "right" }
        shuffle(dirs)

        local spawned = 0
        for _, dir in ipairs(dirs) do
            if spawned >= numChildren or #rooms >= MAX_ROOMS then break end
            if current.neighbours[dir] then goto skipDir end

            local off = DIR_OFFSET[dir]
            local nx, ny = gx + off[1], gy + off[2]
            if self.grid[key(nx, ny)] then goto skipDir end

            local diff = math.random() < 0.3 and "hard" or "normal"
            local child = Room.new({}, diff)
            child.depth = current.depth + 1
            child.gx = nx
            child.gy = ny
            self.grid[key(nx, ny)] = child
            table.insert(rooms, child)

            -- link both ways
            current.neighbours[dir] = child
            child.neighbours[OPPOSITE[dir]] = current

            table.insert(queue, { child, nx, ny })
            spawned = spawned + 1

            ::skipDir::
        end
        ::nextRoom::
    end

    -- post-BFS: optionally connect adjacent rooms that aren't linked (creates loops)
    for _, room in ipairs(rooms) do
        local maxDoors = room.difficulty == "spawn" and 3 or 4
        local dirs = { "top", "bottom", "left", "right" }
        shuffle(dirs)

        for _, dir in ipairs(dirs) do
            if doorCount(room) >= maxDoors then break end
            if room.neighbours[dir] then goto skip end

            local off = DIR_OFFSET[dir]
            local nx, ny = room.gx + off[1], room.gy + off[2]
            local neighbour = self.grid[key(nx, ny)]
            if neighbour and not neighbour.neighbours[OPPOSITE[dir]] then
                local neighbourMax = neighbour.difficulty == "spawn" and 3 or 4
                if doorCount(neighbour) < neighbourMax and math.random() < 0.4 then
                    room.neighbours[dir] = neighbour
                    neighbour.neighbours[OPPOSITE[dir]] = room
                end
            end
            ::skip::
        end
    end

    -- pick boss from rooms at depth >= 4, pick randomly among the 3 deepest
    local sorted = {}
    for i, r in ipairs(rooms) do sorted[i] = r end
    table.sort(sorted, function(a, b) return a.depth > b.depth end)
    -- filter to depth >= 4
    local candidates = {}
    for i = 1, math.min(3, #sorted) do
        if sorted[i].depth >= 4 then
            table.insert(candidates, sorted[i])
        end
    end
    -- fallback: if no room is deep enough, pick the deepest
    if #candidates == 0 then
        candidates = { sorted[1] }
    end
    local boss = candidates[math.random(#candidates)]
    boss.difficulty = "boss"

    -- boss room gets only one entrance: keep the parent link, remove the rest
    local kept = false
    for dir, neighbour in pairs(boss.neighbours) do
        if not kept then
            kept = true  -- keep the first door (parent connection)
        else
            -- remove this door and the neighbour's link back
            neighbour.neighbours[OPPOSITE[dir]] = nil
            boss.neighbours[dir] = nil
        end
    end

    return rooms
end

function Dungeon:passGate(x, y, w, h)
    local room = self.currentRoom
    if room.state ~= "cleared" then return nil, false end

    local cx = x + w / 2  -- entity center
    local cy = y + h / 2
    local gateLeft  = ROOM_W / 2 - ROOM_GATE_W / 2
    local gateRight = ROOM_W / 2 + ROOM_GATE_W / 2
    local gateTop   = ROOM_H / 2 - ROOM_GATE_W / 2
    local gateBot   = ROOM_H / 2 + ROOM_GATE_W / 2

    local dir = nil
    if y < 0 and cx > gateLeft and cx < gateRight then
        dir = "top"
    elseif y + h > ROOM_H and cx > gateLeft and cx < gateRight then
        dir = "bottom"
    elseif x < 0 and cy > gateTop and cy < gateBot then
        dir = "left"
    elseif x + w > ROOM_W and cy > gateTop and cy < gateBot then
        dir = "right"
    end

    if not dir or not room.neighbours[dir] then return nil, false end

    -- switch room
    self.currentRoom = room.neighbours[dir]

    -- reposition at opposite door entrance (just inside the wall)
    local newpos = { x = x, y = y }
    if dir == "top" then
        newpos.y = ROOM_H - ROOM_WALL_T - h
    elseif dir == "bottom" then
        newpos.y = ROOM_WALL_T
    elseif dir == "left" then
        newpos.x = ROOM_W - ROOM_WALL_T - w
    elseif dir == "right" then
        newpos.x = ROOM_WALL_T
    end

    return newpos, true
end

function Dungeon:update(dt, gameList)
    if self.currentRoom.state == "active" and not gameList:hasLivingEnemies() then
        self.currentRoom.state = "cleared"
    end
    self.currentRoom:update(dt)
end

function Dungeon:draw()
    if self.currentRoom then
        self.currentRoom:draw()
    end
end