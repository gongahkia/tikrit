local CONFIG = require("config")

local Utils = {}

local function toNumber(value, fallback)
    local num = tonumber(value)
    if num == nil then
        return fallback
    end
    return num
end

function Utils.rstrip(str)
    str = tostring(str or "")
    if #str > 0 and str:sub(#str) == "\n" then
        return str:sub(1, #str - 1)
    end
    return str
end

function Utils.split(str, delimiter)
    local result = {}
    local token = ""
    str = tostring(str or "")
    delimiter = delimiter or ","

    for i = 1, #str do
        local char = str:sub(i, i)
        if char == delimiter then
            table.insert(result, token)
            token = ""
        else
            token = token .. char
        end
    end

    token = token:gsub("\r$", "")
    table.insert(result, token)
    return result
end

function Utils.distance(x1, y1, x2, y2)
    x1 = toNumber(x1, 0)
    y1 = toNumber(y1, 0)
    x2 = toNumber(x2, 0)
    y2 = toNumber(y2, 0)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function Utils.clamp(value, minValue, maxValue)
    value = toNumber(value, minValue or 0)
    minValue = toNumber(minValue, 0)
    maxValue = toNumber(maxValue, minValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

function Utils.gridToPixel(gridX, gridY)
    return gridX * CONFIG.TILE_SIZE, gridY * CONFIG.TILE_SIZE
end

function Utils.pixelToGrid(pixelX, pixelY)
    pixelX = toNumber(pixelX, 0)
    pixelY = toNumber(pixelY, 0)
    return math.floor(pixelX / CONFIG.TILE_SIZE), math.floor(pixelY / CONFIG.TILE_SIZE)
end

function Utils.deepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for key, innerValue in pairs(value) do
        copy[Utils.deepCopy(key)] = Utils.deepCopy(innerValue)
    end
    return copy
end

function Utils.shuffle(array)
    if type(array) ~= "table" then
        return array
    end

    for i = #array, 2, -1 do
        local j = math.random(i)
        array[i], array[j] = array[j], array[i]
    end
    return array
end

function Utils.inside(targetCoord, coordinates)
    if type(targetCoord) ~= "table" or type(coordinates) ~= "table" then
        return false
    end

    for _, coord in ipairs(coordinates) do
        if coord[1] == targetCoord[1] and coord[2] == targetCoord[2] then
            return true
        end
    end
    return false
end

function Utils.removeByValue(targetCoord, coordinates)
    if type(coordinates) ~= "table" then
        return
    end

    for index = #coordinates, 1, -1 do
        local coord = coordinates[index]
        if coord[1] == targetCoord[1] and coord[2] == targetCoord[2] then
            table.remove(coordinates, index)
        end
    end
end

function Utils.isWalkable(gridX, gridY, grid)
    if type(grid) ~= "table" or gridX == nil or gridY == nil then
        return false
    end

    local row = grid[gridY + 1] or grid[gridY]
    if type(row) ~= "table" then
        return false
    end

    local tile = row[gridX + 1] or row[gridX]
    if tile == nil then
        return false
    end

    local blocked = {
        ["#"] = true,
        ["tree"] = true,
        ["rock"] = true,
        ["lake"] = true,
        ["cabin_wall"] = true,
        ["cave_wall"] = true,
    }
    return tile ~= 1 and blocked[tile] ~= true
end

function Utils.getDailySeed(dateTable)
    local date = dateTable or os.date("*t")
    return date.year * 10000 + date.month * 100 + date.day
end

function Utils.getDailyDateString(timeValue)
    return os.date("%Y-%m-%d", timeValue)
end

function Utils.setGameSeed(useDailyChallenge, customSeed)
    local seed
    if customSeed ~= nil then
        seed = customSeed
    elseif useDailyChallenge then
        seed = Utils.getDailySeed()
    else
        seed = os.time()
    end
    math.randomseed(seed)
    return seed
end

function Utils.sign(value)
    if value > 0 then
        return 1
    elseif value < 0 then
        return -1
    end
    return 0
end

return Utils
