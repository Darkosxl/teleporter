
function love.load()
    x, y   = 400, 300
    vx, vy = 0, 0
    shield_cd = 5
    shield_timer = 0
    state = "menu"
end


function love.update(dt)
    if state == "menu" then
        updateMenu(dt)
    elseif state == "game" then
        updateGame(dt)
    end
end
function updateMenu(dt)
    if love.keyboard.isDown("return") then
        state = "game"
    end
end

function teleporter_shield(r, g, b)
    shield_cd = 5
    love.graphics.setLineWidth(3)
    love.graphics.setColor(r, g, b)
    love.graphics.circle("line", x + 20, y + 20, 36)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

function updateGame(dt)
    shield_cd = math.max(0, shield_cd - dt)
    shield_timer = math.max(0, shield_timer - dt)
    if love.keyboard.isDown("space") and shield_cd <=0 then
        shield_timer = 1
        shield_cd = 5
    end
    local speed = 400
    if love.keyboard.isDown("d") then vx = vx + speed * dt end
    if love.keyboard.isDown("a") then vx = vx - speed * dt end
    if love.keyboard.isDown("s") then vy = vy + speed * dt end
    if love.keyboard.isDown("w") then vy = vy - speed * dt end

    vx = vx * 0.85
    vy = vy * 0.85
    x  = x + vx
    y  = y + vy

    local W, H = love.graphics.getDimensions()
    x = math.max(0, math.min(x, W - 40))
    y = math.max(0, math.min(y, H - 40))
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        
    end
    if button == 2 then
        x, y = mx, my
    end
end


function love.draw()
    if state == "menu" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("MAIN MENU", 350, 250)
        love.graphics.print("Press ENTER to start", 310, 290)
    elseif state == "game" then    
        love.graphics.setColor(0.2, 0.8, 0.4)
        love.graphics.rectangle("fill", x, y, 40, 40)
        if shield_timer > 0 then
            teleporter_shield(1,1,1)
        end
    end
end