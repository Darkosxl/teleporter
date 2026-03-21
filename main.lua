
function love.load()
    x, y   = 400, 300
    vx, vy = 0, 0
end


function love.update(dt)
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
        x, y = mx, my
    end
end

function love.draw()
    love.graphics.setColor(0.2, 0.8, 0.4)
    love.graphics.rectangle("fill", x, y, 40, 40)
end