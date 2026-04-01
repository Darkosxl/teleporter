require "src/systems/rooms"
require "src/entities/enemy"
require "src/unique_entities/player"
require "src/misc/healthbar"
require "src/misc/deathscreen"
require "src/misc/menu"
require "src/misc/upgrade_selection"
require "src/systems/gamelist"
require "src/systems/dungeon"

local function resetGame()
    player   = Player.new(3, 400, nil, nil, ROOM_BOUNDS)
    dungeon  = Dungeon.new()
    player.dungeon = dungeon
    gameList = GameList.new()
    gameList:addEntity(player)
    player.gameList = gameList
    dungeon:mobilizeRoom(gameList)
    upgradeSelection = nil
    hasActiveGame = true
    DeathScreen.selected = 1
end

function love.load()
    state    = "menu"
    fontTitle  = love.graphics.newFont("assets/C&C Red Alert [INET].ttf", 72)
    fontMenu   = love.graphics.newFont("assets/C&C Red Alert [INET].ttf", 36)
    hasActiveGame = false
end

function love.update(dt)
    if state == "game" and player.state ~= "dead" then
        if upgradeSelection then
            upgradeSelection:update(dt)
        else
            gameList:update(dt)
            dungeon:update(dt, gameList)
            if dungeon.currentRoom.state == "cleared" and not upgradeSelection then
                local etype = dungeon.currentRoom.enemyType
                if etype then
                    upgradeSelection = UpgradeSelection.new(etype)
                end
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    if state == "menu" then
        local action = Menu:keypressed(key)
        if action == "newgame" then
            resetGame()
            state = "game"
        elseif action == "continue" then
            state = "game"
        elseif action == "exit" then
            love.event.quit()
        end

    elseif state == "game" and player.state == "dead" then
        local action = DeathScreen:keypressed(key)
        if action == "restart" then
            resetGame()
        elseif action == "menu" then
            state = "menu"
            Menu.selected = 1
        end
    elseif state == "game" and upgradeSelection then
        local upg = upgradeSelection:keypressed(key)
        if upg then
            player:applyUpgrade(upg)
            upgradeSelection = nil
        end
    end
end

function love.mousemoved(mx, my)
    if state == "menu" then
        Menu:mousemoved(mx, my)
    elseif state == "game" and player.state == "dead" then
        DeathScreen:mousemoved(mx, my)
    elseif state == "game" and upgradeSelection then
        upgradeSelection:mousemoved(mx, my)
    end
end

function love.mousepressed(mx, my, button)
    if state == "menu" then
        local action = Menu:mousepressed(mx, my, button)
        if action == "newgame" then
            resetGame()
            state = "game"
        elseif action == "continue" then
            state = "game"
        elseif action == "exit" then
            love.event.quit()
        end
    elseif state == "game" and player.state == "dead" then
        local action = DeathScreen:mousepressed(mx, my, button)
        if action == "restart" then
            resetGame()
        elseif action == "menu" then
            state = "menu"
            Menu.selected = 1
        end
    elseif state == "game" and upgradeSelection then
        local upg = upgradeSelection:mousepressed(mx, my, button)
        if upg then
            player:applyUpgrade(upg)
            upgradeSelection = nil
        end
    elseif state == "game" then
        if button == 1 then
            player:shoot(mx, my, gameList)
        end
        if button == 2 then
            player:teleport(mx, my)
        end
    end
end

function love.draw()
    if state == "menu" then
        Menu:draw()
    elseif state == "game" then
        if upgradeSelection then
            upgradeSelection:draw()
        else
            dungeon:draw()
            gameList:draw()
            drawHealthBar(player)
        end
        if player.state == "dead" then
            DeathScreen:draw()
        end
    end
end
