function love.load()
    message = "Hello, LOVE"
    img = love.graphics.newImage("assets/mc.png")
end

function love.update(dt)

end

function love.draw()
    love.graphics.print(message, 100, 100)
    love.graphics.draw(img, 100, 200, 0, 0.2, 0.2)
end