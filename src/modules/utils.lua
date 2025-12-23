-- Utility functions module

local Utils = {}

function Utils.rstrip(str)
    if #str > 0 and str:sub(#str) == "\n" then
        return str:sub(1, #str - 1)
    else
        return str
    end
end

function Utils.inside(targetCoord, tbl)
    for _, coord in ipairs(tbl) do
        if targetCoord[1] == coord[1] and targetCoord[2] == coord[2] then
            return true
        end 
    end
    return false
end

function Utils.removeByValue(targetValue, tbl)
    for i, value in ipairs(tbl) do
        if value[1] == targetValue[1] and value[2] == targetValue[2] then
            table.remove(tbl, i)
        end
    end
end

function Utils.split(str, delimiter)
    local fin = {}
    local tem = ""
    for i = 1, #str do
        local char = str:sub(i, i)
        if char == delimiter then
            table.insert(fin,tem)
            tem = ""
        else
            tem = tem .. char
        end
    end
    tem = tem:gsub("\r$", "")
    table.insert(fin,tem)
    return fin
end

function Utils.shallowCopy(og) 
    local fin = {}
    for key, value in ipairs(og) do
        fin[key] = value
    end
    return fin
end

function Utils.distance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

-- Get daily challenge seed based on current date
function Utils.getDailySeed()
    local date = os.date("*t")
    -- Create seed from year, month, day
    local seed = date.year * 10000 + date.month * 100 + date.day
    return seed
end

-- Get formatted date string for display
function Utils.getDailyDateString()
    return os.date("%Y-%m-%d")
end

-- Set random seed based on daily challenge or time
function Utils.setGameSeed(useDailyChallenge, customSeed)
    local seed
    if customSeed then
        seed = customSeed
    elseif useDailyChallenge then
        seed = Utils.getDailySeed()
    else
        seed = os.time()
    end
    math.randomseed(seed)
    return seed
end

return Utils
