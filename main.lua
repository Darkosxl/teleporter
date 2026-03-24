require "src/entities/entities"
require "src/entities/enemy"
require "src/unique_entities/player"
require "src/unique_entities/mey"
require "src/misc/healthbar"
require "src/systems/gamelist"
require "src/systems/rooms"

function love.load()
    state    = "menu"
    player   = Player.new(3, 400, nil, nil)
    room = Room.new({ top = true, left = true, right = true }, "boss")
    gameList = GameList.new()
    gameList:addEntity(player)
    local mey = Mey.new(600, 200)
    mey.gameList = gameList
    gameList:addEntity(mey)
end

function love.update(dt)
    if state == "menu" then
        updateMenu(dt)
    elseif state == "game" then
        gameList:update(dt)
    end
end

function updateMenu(dt)
    if love.keyboard.isDown("return") then
        state = "game"
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
end

function love.mousepressed(mx, my, button)
    if button == 1 then
        player:shoot(mx, my, gameList)
    end
    if button == 2 then
        player:teleport(mx, my)
    end
end

function love.draw()
    if state == "menu" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("MAIN MENU", 350, 250)
        love.graphics.print("Press ENTER to start", 310, 290)
    elseif state == "game" then
        room:draw()
        gameList:draw()
        drawHealthBar(player)
    end
end
