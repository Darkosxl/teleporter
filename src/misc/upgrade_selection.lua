UpgradeSelection = {}
UpgradeSelection.__index = UpgradeSelection

local CELL = 5
local CARD_W = 240
local CARD_H = 320
local CARD_GRID_W = CARD_W / CELL
local CARD_GRID_H = CARD_H / CELL
local SPAWN_DURATION = 0.8
local PARTICLE_SPEED = 2200

local ENEMY_COLORS = {
    mey    = {0.85, 0.2, 0.2},
    sitar  = {0.2, 0.6, 0.9},
    odachi = {0.4, 0.7, 0.3},
    boss   = {0.7, 0.3, 0.9},
}

function UpgradeSelection.new(roomEnemyType)
    local self = setmetatable({}, UpgradeSelection)
    self.state     = "spawning"
    self.timer     = 0
    self.selected  = nil
    self.cards     = {}
    self.particles = {}
    self.upgrades  = {}  -- the 3 upgrades chosen

    -- Get attack pool from PlayerAttacks
    local PlayerAttacks = require "src/systems.player_attacks"
    local attackPool = PlayerAttacks.poolFor(roomEnemyType)

    -- Pick 3 random attacks
    local pool = {}
    for i = 1, #attackPool do pool[i] = i end
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    for i = 1, math.min(3, #pool) do
        local attack = attackPool[pool[i]]
        -- Wrap as upgrade with isAttack flag
        self.upgrades[i] = {
            isAttack = true,
            key      = attack.key,
            name     = attack.name,
            desc     = attack.desc,
            enemy    = attack.enemy,
            color    = attack.color,
            cooldown = attack.cooldown,
            apply    = attack.fire,  -- fire function doubles as apply
            fire     = attack.fire,  -- convenience
        }
    end

    -- Arrange cards
    local W, H = love.graphics.getDimensions()
    local gap = 60
    local totalW = #self.upgrades * CARD_W + (#self.upgrades - 1) * gap
    local startX = W / 2 - totalW / 2

    for i, upg in ipairs(self.upgrades) do
        local card = {
            upgrade = upg,
            x = startX + (i - 1) * (CARD_W + gap),
            y = H / 2 - CARD_H / 2,
        }
        self.cards[i] = card

        -- Spawn particles: one per cell, flying from random offscreen positions
        for gy = 0, CARD_GRID_H - 1 do
            for gx = 0, CARD_GRID_W - 1 do
                local targetX = card.x + gx * CELL + CELL / 2
                local targetY = card.y + gy * CELL + CELL / 2
                local angle = math.random() * 2 * math.pi
                local dist  = 400 + math.random() * 600
                local sx    = W / 2 + math.cos(angle) * dist
                local sy    = H / 2 + math.sin(angle) * dist
                -- Wave delay: center of card first, edges last
                local dx    = gx - CARD_GRID_W / 2
                local dy    = gy - CARD_GRID_H / 2
                local delay = math.sqrt(dx * dx + dy * dy) / (CARD_GRID_W / 2) * 0.35
                table.insert(self.particles, {
                    tx     = targetX,
                    ty     = targetY,
                    x      = sx,
                    y      = sy,
                    delay  = delay,
                    elapsed = -math.random() * 0.15,
                    color  = ENEMY_COLORS[upg.enemy] or {1, 1, 1},
                    alive  = false,
                })
            end
        end
    end

    return self
end

function UpgradeSelection:update(dt)
    self.timer = self.timer + dt

    if self.state ~= "spawning" then return end

    local allDone = true
    for _, p in ipairs(self.particles) do
        p.elapsed = p.elapsed + dt
        if p.elapsed < p.delay then
            allDone = false
        elseif p.elapsed < p.delay + SPAWN_DURATION then
            allDone = false
            local t = (p.elapsed - p.delay) / SPAWN_DURATION
            t = 1 - (1 - t) ^ 3
            local dx = p.tx - p.x
            local dy = p.ty - p.y
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 1 then
                local spd = PARTICLE_SPEED * (1 - t)
                p.x = p.x + (dx / len) * spd * dt
                p.y = p.y + (dy / len) * spd * dt
            end
            if t > 0.92 then
                p.x, p.y = p.tx, p.ty
            end
            p.alive = true
        else
            p.x, p.y = p.tx, p.ty
            p.alive = true
        end
    end

    if allDone and self.timer > SPAWN_DURATION + 0.15 then
        self.state = "active"
    end
end

function UpgradeSelection:mousemoved(mx, my)
    if self.state ~= "active" then return end
    self.selected = nil
    for i, card in ipairs(self.cards) do
        if mx >= card.x and mx <= card.x + CARD_W and
           my >= card.y and my <= card.y + CARD_H then
            self.selected = i
            return
        end
    end
end

function UpgradeSelection:mousepressed(mx, my, button)
    if button ~= 1 then return nil end
    if self.state ~= "active" then return nil end
    self:mousemoved(mx, my)
    if self.selected then
        return self.cards[self.selected].upgrade
    end
    return nil
end

function UpgradeSelection:keypressed(key)
    if self.state ~= "active" then return nil end
    if key == "1" then self.selected = self.selected ~= 1 and 1 or self.selected
    elseif key == "2" then self.selected = self.selected ~= 2 and 2 or self.selected
    elseif key == "3" then self.selected = self.selected ~= 3 and 3 or self.selected
    elseif key == "return" or key == " " then
        if self.selected then
            return self.cards[self.selected].upgrade
        end
    end
    return nil
end

function UpgradeSelection:draw()
    local W, H = love.graphics.getDimensions()

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, W, H)

    love.graphics.setFont(fontTitle)
    love.graphics.setColor(1, 0.9, 0.2)
    local title = "CHOOSE YOUR UPGRADE"
    love.graphics.print(title, W / 2 - fontTitle:getWidth(title) / 2, H * 0.1)

    -- Particles (card pixels flying in)
    for _, p in ipairs(self.particles) do
        if p.alive then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], 0.9)
            love.graphics.rectangle("fill", p.x - CELL / 2, p.y - CELL / 2, CELL, CELL)
        end
    end

    -- Card overlays (name, desc, key hint, cooldown)
    if self.state == "active" then
        for i, card in ipairs(self.cards) do
            local upg = card.upgrade
            local cx  = card.x + CARD_W / 2
            local col = ENEMY_COLORS[upg.enemy] or {1, 1, 1}

            if i == self.selected then
                love.graphics.setColor(col[1], col[2], col[3], 0.25)
                love.graphics.rectangle("fill", card.x - 5, card.y - 5, CARD_W + 10, CARD_H + 10)
                love.graphics.setColor(1, 1, 1)
                love.graphics.setLineWidth(2)
                love.graphics.rectangle("line", card.x - 5, card.y - 5, CARD_W + 10, CARD_H + 10)
                love.graphics.setLineWidth(1)
            end

            -- Enemy label
            love.graphics.setFont(fontMenu)
            love.graphics.setColor(col[1], col[2], col[3])
            local elabel = string.upper(upg.enemy)
            love.graphics.print(elabel, cx - fontMenu:getWidth(elabel) / 2, card.y + 16)

            -- Separator
            love.graphics.setColor(col[1], col[2], col[3], 0.4)
            love.graphics.rectangle("fill", card.x + 20, card.y + 55, CARD_W - 40, 2)
            love.graphics.setColor(1, 1, 1)

            -- Upgrade name
            love.graphics.setFont(fontMenu)
            love.graphics.setColor(1, 1, 1)
            local nw = fontMenu:getWidth(upg.name)
            love.graphics.print(upg.name, cx - nw / 2, card.y + 80)

            -- Cooldown
            love.graphics.setColor(0.5, 0.5, 0.6)
            local cdlabel = string.format("%.1fs CD", upg.cooldown or 0)
            love.graphics.print(cdlabel, cx - fontMenu:getWidth(cdlabel) / 2, card.y + 120)

            -- Description with word-wrap
            love.graphics.setColor(0.72, 0.72, 0.78)
            local words = {}
            for w in upg.desc:gmatch("%S+") do table.insert(words, w) end
            local line, lines = "", {}
            for _, w in ipairs(words) do
                local test = line == "" and w or line .. " " .. w
                if fontMenu:getWidth(test) > CARD_W - 20 then
                    table.insert(lines, line)
                    line = w
                else
                    line = test
                end
            end
            if line ~= "" then table.insert(lines, line) end
            local ly = card.y + 165
            for _, l in ipairs(lines) do
                love.graphics.print(l, cx - fontMenu:getWidth(l) / 2, ly)
                ly = ly + 30
            end

            -- Key hint (the slot key this would be assigned)
            love.graphics.setColor(0.45, 0.45, 0.5)
            local hint = "[" .. i .. "]"
            love.graphics.print(hint, cx - fontMenu:getWidth(hint) / 2, card.y + CARD_H - 40)
        end
    end

    love.graphics.setColor(1, 1, 1)
end
