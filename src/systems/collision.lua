function math.sign(n)
    return n > 0 and 1 or (n < 0 and -1 or 0)
end

local function getAxes(vertices)
    local axes = {}
    for i = 1, #vertices do
        local a = vertices[i]
        local b = vertices[(i % #vertices) + 1]
        local dx, dy = b.x - a.x, b.y - a.y
        axes[i] = {x = -dy, y = dx}
    end
    return axes
end

local function project(vertices, axis)
    local min = math.huge
    local max = -math.huge
    for _, v in ipairs(vertices) do
        local dot = v.x * axis.x + v.y * axis.y
        min = math.min(min, dot)
        max = math.max(max, dot)
    end
    return min, max
end

function aabb(entity1, entity2)
    local verts1 = entity1.shape
    local verts2 = entity2.shape

    local axes = getAxes(verts1)
    for _, a in ipairs(getAxes(verts2)) do
        axes[#axes + 1] = a
    end

    for _, axis in ipairs(axes) do
        local min1, max1 = project(verts1, axis)
        local min2, max2 = project(verts2, axis)
        if math.min(max1, max2) - math.max(min1, min2) <= 0 then
            return false
        end
    end

    return true
end

function deflect(bullet, player)
    local nx = bullet.x - player.x
    local ny = bullet.y - player.y
    local len = math.sqrt(nx*nx + ny*ny)
    nx, ny = nx / len, ny / len
    local dot = bullet.direction.x * nx + bullet.direction.y * ny
    bullet.direction.x = bullet.direction.x - 2 * dot * nx
    bullet.direction.y = bullet.direction.y - 2 * dot * ny
end
