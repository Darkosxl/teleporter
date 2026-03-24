local function circleShape(r, segments)
    local verts = {}
    for i = 1, segments do
        local angle = (2 * math.pi / segments) * (i - 1)
        verts[i] = {x = math.cos(angle) * r, y = math.sin(angle) * r}
    end
    return verts
end

Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player.new(hp, speed, shape, image)
    local self = setmetatable(Entity.new(hp, speed, shape, image), Player)
    self.max_hp      = hp
    self.x           = 400
    self.y           = 300
    self.vx          = 0
    self.vy          = 0
    self.sweep_cd     = 1
    self.sweep_timer  = 0
    self.sweep_active = false
    self.sweep_angle   = 0
    self.type = "player"
    return self
end

function Player:shoot(mousex, mousey, gameList)
    local direction = { x = mousex - self.x, y = mousey - self.y }
    local len = math.sqrt(direction.x * direction.x + direction.y * direction.y)
    if len > 0 then
        direction.x = direction.x / len
        direction.y = direction.y / len
    end
    gameList:spawnBullet(1, 800, circleShape(4, 8), direction, self.x + 20, self.y + 20)
end

function Player:getSweepShape()
    local cx, cy   = self.x + 20, self.y + 20
    local R        = 70
    local half     = math.pi / 3
    local segments = 12
    local verts    = {{x = cx, y = cy}}
    for i = 0, segments do
        local a = self.sweep_angle - half + (2 * half) * i / segments
        table.insert(verts, {x = cx + math.cos(a) * R, y = cy + math.sin(a) * R})
    end
    return verts
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
    self.sweep_cd    = math.max(0, self.sweep_cd - dt)
    self.sweep_timer = math.max(0, self.sweep_timer - dt)
    
    if self.sweep_timer <= 0 then
        self.sweep_active = false
    end

    if love.keyboard.isDown("space") and self.sweep_cd <= 0 then
        self.sweep_active = true
        self.sweep_timer  = 0.3
        self.sweep_cd     = 1
        local mx, my = love.mouse.getPosition()
        self.sweep_angle = math.atan2(my - (self.y + 20), mx - (self.x + 20))
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

    if self.sweep_timer > 0 then
        local t        = 0.3 - self.sweep_timer
        local cx, cy   = self.x + 20, self.y + 20
        local R        = 80
        local r        = 80
        local half     = math.pi / 3  -- 60 degrees
        local segments = 24

        local a_from = self.sweep_angle - half
        local a_to   = self.sweep_angle + half

        local arc_start, arc_end
        if t < 0.12 then
            arc_start = a_from
            arc_end   = a_from + (t / 0.12) * (a_to - a_from)
        elseif t < 0.18 then
            arc_start = a_from
            arc_end   = a_to
        else
            arc_start = a_from + ((t - 0.18) / 0.12) * (a_to - a_from)
            arc_end   = a_to
        end

        -- crescent: same radius, inner center offset toward player for pointed tips
        local ocx = cx - math.cos(self.sweep_angle) * 15
        local ocy = cy - math.sin(self.sweep_angle) * 15
        local verts = {}
        for i = 0, segments do
            local a = arc_start + (arc_end - arc_start) * i / segments
            table.insert(verts, cx  + math.cos(a) * R)
            table.insert(verts, cy  + math.sin(a) * R)
        end
        for i = segments, 0, -1 do
            local a = arc_start + (arc_end - arc_start) * i / segments
            table.insert(verts, ocx + math.cos(a) * r)
            table.insert(verts, ocy + math.sin(a) * r)
        end

        love.graphics.setColor(0.9, 0.95, 1, 0.9)
        love.graphics.polygon("fill", verts)
        love.graphics.setColor(1, 1, 1, 1)
    end
end
