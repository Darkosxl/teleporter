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

    local minOverlap = math.huge
    local pushAxis = nil

    local axes = getAxes(verts1)
    for _, a in ipairs(getAxes(verts2)) do
        axes[#axes + 1] = a
    end

    for _, axis in ipairs(axes) do
        local min1, max1 = project(verts1, axis)
        local min2, max2 = project(verts2, axis)

        local overlap = math.min(max1, max2) - math.max(min1, min2)
        if overlap <= 0 then
            return false, nil
        end

        if overlap < minOverlap then
            minOverlap = overlap
            pushAxis = axis
        end
    end

    local cx1, cy1 = 0, 0
    for _, v in ipairs(verts1) do cx1 = cx1 + v.x; cy1 = cy1 + v.y end
    cx1 = cx1 / #verts1; cy1 = cy1 / #verts1

    local cx2, cy2 = 0, 0
    for _, v in ipairs(verts2) do cx2 = cx2 + v.x; cy2 = cy2 + v.y end
    cx2 = cx2 / #verts2; cy2 = cy2 / #verts2

    local len = math.sqrt(pushAxis.x^2 + pushAxis.y^2)
    local nx, ny = pushAxis.x / len, pushAxis.y / len

    if nx * (cx1 - cx2) + ny * (cy1 - cy2) < 0 then
        nx, ny = -nx, -ny
    end

    return true, {x = nx * minOverlap, y = ny * minOverlap}
end