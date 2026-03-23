local dash_width  = 10
local dash_height = 4
local dash_gap    = 3
local offset_y    = 10  -- how far above the player

function drawHealthBar(player)
    local third = player.max_hp / 3
    local total_width = 3 * dash_width + 2 * dash_gap
    local start_x = player.x + 20 - total_width / 2  -- centered on player (player is 40px wide)
    local bar_y = player.y - offset_y

    for i = 1, 3 do
        local threshold = (3 - i) * third
        local filled = player.hp > threshold

        local dx = start_x + (i - 1) * (dash_width + dash_gap)

        if filled then
            love.graphics.setColor(0.2, 0.8, 0.4, 1)
            love.graphics.rectangle("fill", dx, bar_y, dash_width, dash_height)
        else
            love.graphics.setColor(0.2, 0.8, 0.4, 0.15)
            love.graphics.rectangle("fill", dx, bar_y, dash_width, dash_height)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end
