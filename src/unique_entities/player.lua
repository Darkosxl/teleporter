Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(hp, speed, shape, image)
    local self = setmetatable(Entity.new(hp, speed, shape, image), Player)
    self.max_hp      = hp
    self.x           = 400
    self.y           = 300
    self.vx          = 0
    self.vy          = 0
    self.shield_cd   = 5
    self.shield_timer = 0
    return self
end

function Player:shoot(mousex, mousey)
    local direction = { x = mousex - self.x, y = mousey - self.y }
    local len = math.sqrt(direction.x * direction.x + direction.y * direction.y)
    if len > 0 then
        direction.x = direction.x / len
        direction.y = direction.y / len
    end
    spawnBullet(1, 800, { { x = 0, y = 0 }, { x = 40, y = 0 }, { x = 40, y = 40 }, { x = 0, y = 40 } }, direction,
        self.x + 20, self.y + 20)
end

function Player:getShape()
    return {
        {x = self.x,      y = self.y},
        {x = self.x + 40, y = self.y},
        {x = self.x + 40, y = self.y + 40},
        {x = self.x,      y = self.y + 40},
    }
end

function Player:update(dt)
    self.shield_cd    = math.max(0, self.shield_cd - dt)
    self.shield_timer = math.max(0, self.shield_timer - dt)

    if love.keyboard.isDown("space") and self.shield_cd <= 0 then
        self.shield_timer = 1
        self.shield_cd    = 5
    end

    if love.keyboard.isDown("d") then self.vx = self.vx + self.speed * dt end
    if love.keyboard.isDown("a") then self.vx = self.vx - self.speed * dt end
    if love.keyboard.isDown("s") then self.vy = self.vy + self.speed * dt end
    if love.keyboard.isDown("w") then self.vy = self.vy - self.speed * dt end

    self.vx = self.vx * 0.85
    self.vy = self.vy * 0.85
    self.x  = self.x + self.vx
    self.y  = self.y + self.vy

    local W, H = love.graphics.getDimensions()
    self.x = math.max(0, math.min(self.x, W - 40))
    self.y = math.max(0, math.min(self.y, H - 40))
end

function Player:teleport(mx, my)
    self.x  = mx
    self.y  = my
    self.vx = 0
    self.vy = 0
end

function Player:draw()
    love.graphics.setColor(0.2, 0.8, 0.4)
    love.graphics.rectangle("fill", self.x, self.y, 40, 40)

    if self.shield_timer > 0 then
        love.graphics.setLineWidth(3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.circle("line", self.x + 20, self.y + 20, 36)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
    end
end
