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

    local function key(gx, gy) return gx .. "," .. gy end

    local function dfs(gx, gy, parent_dir, depth)
        if self.grid[key(gx, gy)] then return end
        if #rooms >= 10 then return end

        local diff
        if depth == 1 then
            diff = "spawn"
        else
            diff = math.random() < 0.3 and "hard" or "normal"
        end

        local room = Room.new({}, diff)
        room.depth = depth
        self.grid[key(gx, gy)] = room
        table.insert(rooms, room)

        -- link back to parent
        if parent_dir then
            room.neighbours[parent_dir] = self.grid[key(
                gx - DIR_OFFSET[parent_dir][1],
                gy - DIR_OFFSET[parent_dir][2]
            )]
        end

        -- shuffle directions and recurse into random neighbors
        local dirs = {"top", "bottom", "left", "right"}
        for i = #dirs, 2, -1 do
            local j = math.random(i)
            dirs[i], dirs[j] = dirs[j], dirs[i]
        end

        for _, dir in ipairs(dirs) do
            local off = DIR_OFFSET[dir]
            local nx, ny = gx + off[1], gy + off[2]
            if not self.grid[key(nx, ny)] and #rooms < 10 and math.random() < 0.6 then
                room.neighbours[dir] = true  -- placeholder, filled after recurse
                dfs(nx, ny, OPPOSITE[dir], depth + 1)
                -- link to the newly created room
                room.neighbours[dir] = self.grid[key(nx, ny)]
            end
        end
    end
    dfs(0, 0, nil, 1)

    -- pick boss from the 3 deepest rooms
    local sorted = {}
    for i, r in ipairs(rooms) do sorted[i] = r end
    table.sort(sorted, function(a, b) return a.depth > b.depth end)
    local candidates = math.min(3, #sorted)
    sorted[math.random(candidates)].difficulty = "boss"

    return rooms
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