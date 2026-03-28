Menu = {}
Menu.selected = 1

function Menu:getOptions()
    if hasActiveGame then
        return { "New Game", "Continue", "Exit" }
    else
        return { "New Game", "Exit" }
    end
end

function Menu:getOptionY(i)
    local _, H = love.graphics.getDimensions()
    return H / 3 + 60 + i * 50
end

function Menu:mousemoved(mx, my)
    local W = love.graphics.getDimensions()
    local options = self:getOptions()
    local th = fontMenu:getHeight()

    for i, text in ipairs(options) do
        local ow = fontMenu:getWidth(text)
        local ox = W / 2 - ow / 2
        local oy = self:getOptionY(i)
        if mx >= ox and mx <= ox + ow and my >= oy and my <= oy + th then
            self.selected = i
            return
        end
    end
end

function Menu:mousepressed(mx, my, button)
    if button ~= 1 then return nil end
    local W = love.graphics.getDimensions()
    local options = self:getOptions()
    local th = fontMenu:getHeight()

    for i, text in ipairs(options) do
        local ow = fontMenu:getWidth(text)
        local ox = W / 2 - ow / 2
        local oy = self:getOptionY(i)
        if mx >= ox and mx <= ox + ow and my >= oy and my <= oy + th then
            self.selected = i
            return self:confirm()
        end
    end
    return nil
end

function Menu:confirm()
    local options = self:getOptions()
    local pick = options[self.selected]
    if pick == "New Game" then
        return "newgame"
    elseif pick == "Continue" then
        return "continue"
    elseif pick == "Exit" then
        return "exit"
    end
end

function Menu:keypressed(key)
    local options = self:getOptions()

    if key == "w" or key == "up" then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #options end
    elseif key == "s" or key == "down" then
        self.selected = self.selected + 1
        if self.selected > #options then self.selected = 1 end
    elseif key == "return" then
        return self:confirm()
    end
    return nil
end

function Menu:draw()
    local W, H = love.graphics.getDimensions()

    -- background
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", 0, 0, W, H)

    -- title
    love.graphics.setFont(fontTitle)
    love.graphics.setColor(0.9, 0.95, 1)
    local title = "TELEPORTER"
    local tw = fontTitle:getWidth(title)
    love.graphics.print(title, W / 2 - tw / 2, H / 3 - 50)

    -- options
    love.graphics.setFont(fontMenu)
    local options = self:getOptions()
    for i, text in ipairs(options) do
        if i == self.selected then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(0.4, 0.4, 0.45)
        end
        local ow = fontMenu:getWidth(text)
        love.graphics.print(text, W / 2 - ow / 2, self:getOptionY(i))
    end

    love.graphics.setColor(1, 1, 1)
end
