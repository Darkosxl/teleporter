Room = setmetatable({}, {__index = Room})
Room.__index = Room

local W, H        = 1900, 1200
local WALL_T      = math.floor(H * 0.08)  -- ~96px
local GATE_W      = 140
local POST_W      = 14
local BEAM_EXTEND = 20
local BEAM_H      = 11
local NUKI_H      = 8
local NUKI_GAP    = 22

local FLOOR = { 0.16, 0.13, 0.12 }

local WALL_COLOR = {
    normal = { 0.42, 0.42, 0.42 },
    hard   = { 0.52, 0.30, 0.07 },
    boss   = { 0.07, 0.07, 0.07 },
}
local WALL_FACE = {
    normal = { 0.55, 0.55, 0.55 },
    hard   = { 0.65, 0.40, 0.12 },
    boss   = { 0.13, 0.13, 0.13 },
}
local TORII_COLOR = {
    normal = { 0.82, 0.10, 0.07 },
    hard   = { 0.82, 0.10, 0.07 },
    boss   = { 0.04, 0.04, 0.04 },
}
local TORII_DETAIL = {
    normal = { 0.82, 0.10, 0.07 },
    hard   = { 0.82, 0.10, 0.07 },
    boss   = { 0.86, 0.86, 0.86 },
}

local function drawTorii(cx, cy, direction, diff)
    local tc = TORII_COLOR[diff]
    local td = TORII_DETAIL[diff]

    if direction == "top" or direction == "bottom" then
        local y0 = direction == "top" and 0 or (H - WALL_T)
        -- cut opening
        love.graphics.setColor(FLOOR)
        love.graphics.rectangle("fill", cx - GATE_W / 2, y0, GATE_W, WALL_T)
        -- pillars
        love.graphics.setColor(tc)
        love.graphics.rectangle("fill", cx - GATE_W / 2,            y0, POST_W, WALL_T)
        love.graphics.rectangle("fill", cx + GATE_W / 2 - POST_W,   y0, POST_W, WALL_T)
        -- kasagi (top beam, extends past pillars)
        local beam_y = direction == "top"
            and (WALL_T - BEAM_H - NUKI_GAP - NUKI_H - 4)
            or  (H - WALL_T + 4)
        love.graphics.setColor(td)
        love.graphics.rectangle("fill", cx - GATE_W / 2 - BEAM_EXTEND, beam_y, GATE_W + BEAM_EXTEND * 2, BEAM_H)
        -- nuki (second beam, flush with pillars)
        local nuki_y = direction == "top"
            and (WALL_T - NUKI_H - 4)
            or  (H - WALL_T + BEAM_H + 8)
        love.graphics.rectangle("fill", cx - GATE_W / 2, nuki_y, GATE_W, NUKI_H)

    elseif direction == "left" or direction == "right" then
        local x0 = direction == "left" and 0 or (W - WALL_T)
        -- cut opening
        love.graphics.setColor(FLOOR)
        love.graphics.rectangle("fill", x0, cy - GATE_W / 2, WALL_T, GATE_W)
        -- pillars (run along top and bottom of opening)
        love.graphics.setColor(tc)
        love.graphics.rectangle("fill", x0, cy - GATE_W / 2,           WALL_T, POST_W)
        love.graphics.rectangle("fill", x0, cy + GATE_W / 2 - POST_W,  WALL_T, POST_W)
        -- kasagi
        local beam_x = direction == "left"
            and (WALL_T - BEAM_H - NUKI_GAP - NUKI_H - 4)
            or  (W - WALL_T + 4)
        love.graphics.setColor(td)
        love.graphics.rectangle("fill", beam_x, cy - GATE_W / 2 - BEAM_EXTEND, BEAM_H, GATE_W + BEAM_EXTEND * 2)
        -- nuki
        local nuki_x = direction == "left"
            and (WALL_T - NUKI_H - 4)
            or  (W - WALL_T + BEAM_H + 8)
        love.graphics.rectangle("fill", nuki_x, cy - GATE_W / 2, NUKI_H, GATE_W)
    end
end

local function enemySpawned(self, difficulty)
    local enemies = {}
    return enemies
end

function Room.new(neighbours, difficulty)
    local self = setmetatable({}, Room)
    self.neighbours = neighbours or {}
    self.difficulty = difficulty or "normal"
    self.enemies    = enemySpawned(self, difficulty)
    self.upgrade    = {}
    return self
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

    -- torii gates for each open direction
    local gates = { top = {W/2, 0}, left = {0, H/2}, right = {W, H/2}, bottom = {W/2, H} }
    for dir, pos in pairs(gates) do
        if self.neighbours[dir] then
            drawTorii(pos[1], pos[2], dir, self.difficulty)
        end
    end

    love.graphics.setColor(1, 1, 1)
end
