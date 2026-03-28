require "src/entities/entities"
require "src/entities/enemy"
require "src/unique_entities/player"
require "src/unique_entities/mey"
require "src/misc/healthbar"
require "src/misc/deathscreen"
require "src/systems/gamelist"
require "src/systems/rooms"
require "src/systems/dungeon"

function love.load()
    state    = "menu"
    player   = Player.new(3, 400, nil, nil, ROOM_BOUNDS)
    dungeon = Dungeon.new()
    player.dungeon = dungeon
    gameList = GameList.new()
    gameList:addEntity(player)
    --local mey = Mey.new(600, 200)
    --mey.gameList = gameList
    --gameList:addEntity(mey)
end

function love.update(dt)
    if state == "menu" then
        updateMenu(dt)
    elseif state == "game" then
        if player.state == "dead" then
            DeathScreen:update(dt)
        else
            gameList:update(dt)
            dungeon:update(dt, gameList)
        end
    end
end

local function resetGame()
    player   = Player.new(3, 400, nil, nil, ROOM_BOUNDS)
    dungeon  = Dungeon.new()
    player.dungeon = dungeon
    gameList = GameList.new()
    gameList:addEntity(player)
    DeathScreen.selected = 1
end

function updateMenu(dt)
    if love.keyboard.isDown("return") then
        state = "game"
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if state == "game" and player.state == "dead" and key == "return" then
        local choice = DeathScreen:confirm()
        if choice == "restart" then
            resetGame()
        elseif choice == "menu" then
            resetGame()
            state = "menu"
        end
    end
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
        dungeon:draw()
        gameList:draw()
        drawHealthBar(player)
        if player.state == "dead" then
            DeathScreen:draw()
        end
    end
end
