Room = setmetatable({}, {__index = Room})
Room.__index = Room

ROOM_W, ROOM_H    = 1900, 1200
ROOM_WALL_T       = math.floor(ROOM_H * 0.08)  -- ~96px
ROOM_GATE_W       = 140
local W, H        = ROOM_W, ROOM_H
local WALL_T      = ROOM_WALL_T
local GATE_W      = ROOM_GATE_W
local FRAME_T     = 10
local BAR_T       = 4
local BAR_COUNT_V = 5   -- vertical bars
local BAR_COUNT_H = 4   -- horizontal bars

ROOM_BOUNDS = { WALL_T, W - WALL_T, WALL_T, H - WALL_T }

local FLOOR = { 0.16, 0.13, 0.12 }

local WALL_COLOR = {
    spawn  = { 0.08, 0.18, 0.22 },
    normal = { 0.42, 0.42, 0.42 },
    hard   = { 0.52, 0.30, 0.07 },
    boss   = { 0.07, 0.07, 0.07 },
}
local WALL_FACE = {
    spawn  = { 0.12, 0.25, 0.28 },
    normal = { 0.55, 0.55, 0.55 },
    hard   = { 0.65, 0.40, 0.12 },
    boss   = { 0.13, 0.13, 0.13 },
}
local DOOR_FRAME = {
    spawn  = { 0.06, 0.14, 0.18 },
    normal = { 0.30, 0.30, 0.30 },
    hard   = { 0.40, 0.22, 0.05 },
    boss   = { 0.06, 0.06, 0.06 },
}
local DOOR_BAR = {
    spawn  = { 0.05, 0.12, 0.14 },
    normal = { 0.22, 0.22, 0.22 },
    hard   = { 0.32, 0.18, 0.04 },
    boss   = { 0.10, 0.10, 0.10 },
}

local function drawDoor(cx, cy, direction, diff, openAmount)
    local fc = DOOR_FRAME[diff]
    local bc = DOOR_BAR[diff]

    if direction == "top" or direction == "bottom" then
        local y0 = direction == "top" and 0 or (H - WALL_T)
        local gx = cx - GATE_W / 2
        -- cut opening
        love.graphics.setColor(FLOOR)
        love.graphics.rectangle("fill", gx, y0, GATE_W, WALL_T)
        -- frame (top, bottom, left, right edges of opening)
        love.graphics.setColor(fc)
        love.graphics.rectangle("fill", gx, y0, GATE_W, FRAME_T)
        love.graphics.rectangle("fill", gx, y0 + WALL_T - FRAME_T, GATE_W, FRAME_T)
        love.graphics.rectangle("fill", gx, y0, FRAME_T, WALL_T)
        love.graphics.rectangle("fill", gx + GATE_W - FRAME_T, y0, FRAME_T, WALL_T)
        -- grid bars (lift up when open)
        love.graphics.setColor(bc)
        local innerW = GATE_W - 2 * FRAME_T
        local innerH = WALL_T - 2 * FRAME_T
        local ix = gx + FRAME_T
        local iy = y0 + FRAME_T
        local barOffset = openAmount * innerH * (2/3) * (direction == "top" and -1 or 1)
        for i = 1, BAR_COUNT_V do
            local bx = ix + (innerW / (BAR_COUNT_V + 1)) * i - BAR_T / 2
            love.graphics.rectangle("fill", bx, iy + barOffset, BAR_T, innerH)
        end
        for i = 1, BAR_COUNT_H do
            local by = iy + (innerH / (BAR_COUNT_H + 1)) * i - BAR_T / 2
            love.graphics.rectangle("fill", ix, by + barOffset, innerW, BAR_T)
        end

    elseif direction == "left" or direction == "right" then
        local x0 = direction == "left" and 0 or (W - WALL_T)
        local gy = cy - GATE_W / 2
        -- cut opening
        love.graphics.setColor(FLOOR)
        love.graphics.rectangle("fill", x0, gy, WALL_T, GATE_W)
        -- frame
        love.graphics.setColor(fc)
        love.graphics.rectangle("fill", x0, gy, WALL_T, FRAME_T)
        love.graphics.rectangle("fill", x0, gy + GATE_W - FRAME_T, WALL_T, FRAME_T)
        love.graphics.rectangle("fill", x0, gy, FRAME_T, GATE_W)
        love.graphics.rectangle("fill", x0 + WALL_T - FRAME_T, gy, FRAME_T, GATE_W)
        -- grid bars (slide sideways when open)
        love.graphics.setColor(bc)
        local innerW = WALL_T - 2 * FRAME_T
        local innerH = GATE_W - 2 * FRAME_T
        local ix = x0 + FRAME_T
        local iy = gy + FRAME_T
        local barOffset = openAmount * innerW * (2/3) * (direction == "left" and -1 or 1)
        for i = 1, BAR_COUNT_V do
            local bx = ix + (innerW / (BAR_COUNT_V + 1)) * i - BAR_T / 2
            love.graphics.rectangle("fill", bx + barOffset, iy, BAR_T, innerH)
        end
        for i = 1, BAR_COUNT_H do
            local by = iy + (innerH / (BAR_COUNT_H + 1)) * i - BAR_T / 2
            love.graphics.rectangle("fill", ix + barOffset, by, innerW, BAR_T)
        end
    end
end

local function enemySpawned(self, difficulty)
    local enemies = {}
    return enemies
end

-- door alcove rects: {x, y, w, h} for each direction
local DOOR_ALCOVES = {
    top    = { W/2 - GATE_W/2 + FRAME_T, 0,          GATE_W - 2*FRAME_T, WALL_T },
    bottom = { W/2 - GATE_W/2 + FRAME_T, H - WALL_T, GATE_W - 2*FRAME_T, WALL_T },
    left   = { 0,          H/2 - GATE_W/2 + FRAME_T, WALL_T, GATE_W - 2*FRAME_T },
    right  = { W - WALL_T, H/2 - GATE_W/2 + FRAME_T, WALL_T, GATE_W - 2*FRAME_T },
}

-- thin barrier line position (blocks transition during combat)
-- for top/bottom: a horizontal line; for left/right: a vertical line
local BARRIER_T = FRAME_T
local DOOR_BARRIERS = {
    top    = { W/2 - GATE_W/2 + FRAME_T, FRAME_T,              GATE_W - 2*FRAME_T, BARRIER_T },
    bottom = { W/2 - GATE_W/2 + FRAME_T, H - FRAME_T - BARRIER_T, GATE_W - 2*FRAME_T, BARRIER_T },
    left   = { FRAME_T,              H/2 - GATE_W/2 + FRAME_T, BARRIER_T, GATE_W - 2*FRAME_T },
    right  = { W - FRAME_T - BARRIER_T, H/2 - GATE_W/2 + FRAME_T, BARRIER_T, GATE_W - 2*FRAME_T },
}

local function rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

function Room.new(neighbours, difficulty)
    local self = setmetatable({}, Room)
    self.neighbours = neighbours or {}
    self.difficulty = difficulty or "spawn" -- spawn, normal, hard, boss
    self.enemies    = enemySpawned(self, difficulty)
    self.upgrade    = {}
    self.state      = "active"  -- "active" or "cleared"
    self.doorOpen   = 0        -- 0 = closed, 1 = fully open
    return self
end

function Room:isWalkable(x, y, w, h)
    -- inside main room is always walkable
    if x >= WALL_T and x + w <= W - WALL_T and y >= WALL_T and y + h <= H - WALL_T then
        return true
    end

    -- check if entity is in a door alcove
    for dir, alcove in pairs(DOOR_ALCOVES) do
        if self.neighbours[dir] and rectsOverlap(x, y, w, h, alcove[1], alcove[2], alcove[3], alcove[4]) then
            -- door exists, check barrier
            if self.state == "active" then
                local bar = DOOR_BARRIERS[dir]
                if rectsOverlap(x, y, w, h, bar[1], bar[2], bar[3], bar[4]) then
                    return false  -- blocked by barrier during combat
                end
            end
            return true  -- in alcove, no barrier (or cleared)
        end
    end

    return false  -- in a wall, no door here
end

function Room:update(dt)
    if self.state == "cleared" and self.doorOpen < 1 then
        self.doorOpen = math.min(1, self.doorOpen + dt * 2) -- opens over 0.5s
    end
end

function Room:draw()
    local wc = WALL_COLOR[self.difficulty]
    local wf = WALL_FACE[self.difficulty]

    -- floor
    love.graphics.setColor(FLOOR)
    love.graphics.rectangle("fill", WALL_T, WALL_T, W - 2 * WALL_T, H - 2 * WALL_T)

    -- walls
    love.graphics.setColor(wc)
    love.graphics.rectangle("fill", 0,          0,          W,      WALL_T)
    love.graphics.rectangle("fill", 0,          H - WALL_T, W,      WALL_T)
    love.graphics.rectangle("fill", 0,          0,          WALL_T, H)
    love.graphics.rectangle("fill", W - WALL_T, 0,          WALL_T, H)

    -- 2.5D depth faces
    love.graphics.setColor(wf)
    love.graphics.rectangle("fill", WALL_T,          WALL_T - WALL_T * 0.18, W - 2 * WALL_T, WALL_T * 0.18)
    love.graphics.rectangle("fill", WALL_T - WALL_T * 0.12, WALL_T,          WALL_T * 0.12,  H - 2 * WALL_T)

    -- prison doors for each open direction
    local gates = { top = {W/2, 0}, left = {0, H/2}, right = {W, H/2}, bottom = {W/2, H} }
    for dir, pos in pairs(gates) do
        if self.neighbours[dir] then
            drawDoor(pos[1], pos[2], dir, self.difficulty, self.doorOpen)
        end
    end

    love.graphics.setColor(1, 1, 1)
end
