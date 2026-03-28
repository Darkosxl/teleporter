DeathScreen = {}
DeathScreen.selected = 1  -- 1 = Start Again, 2 = Main Menu

function DeathScreen:update(dt)
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        self.selected = 1
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        self.selected = 2
    end
end

function DeathScreen:confirm()
    if self.selected == 1 then
        return "restart"
    else
        return "menu"
    end
end

function DeathScreen:draw()
    local W, H = love.graphics.getDimensions()

    -- semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- GAME OVER
    local font = love.graphics.getFont()
    love.graphics.setColor(0.9, 0.15, 0.15)
    local title = "GAME OVER"
    local tw = font:getWidth(title)
    love.graphics.print(title, W / 2 - tw / 2, H / 2 - 60)

    -- options
    local options = { "Start Again", "Main Menu" }
    for i, text in ipairs(options) do
        if i == self.selected then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
        end
        local ow = font:getWidth(text)
        love.graphics.print(text, W / 2 - ow / 2, H / 2 + i * 30)
    end

    love.graphics.setColor(1, 1, 1)
end
