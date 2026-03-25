local Utils = require("modules/utils")

local Items = {}

Items.aliases = {
    medicine = "painkillers",
}

Items.definitions = {
    matches = {label = "Matches", weight = 0.05, stackable = true},
    accelerant = {label = "Accelerant", weight = 0.3, stackable = true},
    tinder = {label = "Tinder", weight = 0.08, stackable = true},
    sticks = {label = "Sticks", weight = 0.2, stackable = true},
    firewood = {label = "Firewood", weight = 0.7, stackable = true},
    cloth = {label = "Cloth", weight = 0.15, stackable = true},
    sewing_kit = {label = "Sewing Kit", weight = 0.1, stackable = true},
    snow = {label = "Packed Snow", weight = 0.25, stackable = true},
    water = {label = "Water", weight = 0.45, stackable = true, thirst = 24},
    canned_food = {
        label = "Canned Food",
        weight = 0.65,
        stackable = true,
        calories = 420,
        perishable = true,
        decayPerHour = 0.28,
    },
    raw_meat = {
        label = "Raw Meat",
        weight = 0.8,
        stackable = true,
        calories = 260,
        perishable = true,
        decayPerHour = 1.25,
        foodPoisoningThreshold = 85,
    },
    cooked_meat = {
        label = "Cooked Meat",
        weight = 0.7,
        stackable = true,
        calories = 520,
        perishable = true,
        decayPerHour = 0.75,
        foodPoisoningThreshold = 20,
    },
    raw_fish = {
        label = "Raw Fish",
        weight = 0.55,
        stackable = true,
        calories = 220,
        perishable = true,
        decayPerHour = 1.1,
        foodPoisoningThreshold = 80,
    },
    cooked_fish = {
        label = "Cooked Fish",
        weight = 0.5,
        stackable = true,
        calories = 420,
        perishable = true,
        decayPerHour = 0.68,
        foodPoisoningThreshold = 20,
    },
    tea = {
        label = "Tea",
        weight = 0.3,
        stackable = true,
        thirst = 12,
        warmth = 12,
        condition = 2,
        perishable = true,
        decayPerHour = 0.35,
    },
    bandage = {
        label = "Bandage",
        weight = 0.1,
        stackable = true,
        treatment = {sprain = true},
    },
    painkillers = {
        label = "Painkillers",
        weight = 0.08,
        stackable = true,
        treatment = {sprain = true},
        condition = 1,
    },
    antiseptic = {
        label = "Antiseptic",
        weight = 0.12,
        stackable = true,
        treatment = {infectionRisk = true},
    },
    antibiotics = {
        label = "Antibiotics",
        weight = 0.08,
        stackable = true,
        treatment = {infection = true, infectionRisk = true},
    },
    torch = {label = "Torch", weight = 0.4, stackable = true, lightHours = 1.5},
    flare = {label = "Flare", weight = 0.25, stackable = true, lightHours = 2.5},
    bedroll = {label = "Bedroll", weight = 1.2, stackable = false},
    knife = {label = "Knife", weight = 0.4, stackable = false, equipSlot = "tool"},
    hatchet = {label = "Hatchet", weight = 0.8, stackable = false, equipSlot = "tool"},
    bow = {label = "Bow", weight = 0.9, stackable = false, equipSlot = "weapon"},
    arrow = {label = "Arrow", weight = 0.08, stackable = true},
    snare = {label = "Snare", weight = 0.35, stackable = true},
    fishing_tackle = {label = "Fishing Tackle", weight = 0.18, stackable = true},
    charcoal = {label = "Charcoal", weight = 0.08, stackable = true},
    rabbit_pelt = {label = "Rabbit Pelt", weight = 0.35, stackable = true},
    deer_hide = {label = "Deer Hide", weight = 0.85, stackable = true},
    gut = {label = "Fresh Gut", weight = 0.18, stackable = true},
    cured_rabbit_pelt = {label = "Cured Rabbit Pelt", weight = 0.28, stackable = true},
    cured_deer_hide = {label = "Cured Deer Hide", weight = 0.72, stackable = true},
    cured_gut = {label = "Cured Gut", weight = 0.14, stackable = true},
    feather = {label = "Feather", weight = 0.02, stackable = true},
    rabbit_wraps = {label = "Rabbit Wraps", weight = 0.5, stackable = false},
}

local function cloneItem(item)
    local copy = {}
    for key, value in pairs(item) do
        copy[key] = Utils.deepCopy(value)
    end
    return copy
end

function Items.normalizeKind(kind)
    return Items.aliases[kind] or kind
end

function Items.getDefinition(kind)
    return Items.definitions[Items.normalizeKind(kind)]
end

function Items.describe(kind)
    local normalized = Items.normalizeKind(kind)
    local definition = Items.getDefinition(normalized)
    return definition and definition.label or tostring(normalized)
end

function Items.isPerishable(kind)
    local definition = Items.getDefinition(kind)
    return definition and definition.perishable == true
end

function Items.create(kind, quantity)
    local normalized = Items.normalizeKind(kind)
    local definition = Items.getDefinition(normalized)
    local item = {
        kind = normalized,
        quantity = quantity or 1,
    }
    if definition and definition.perishable then
        item.condition = 100
    end
    return item
end

function Items.cloneInventory(inventory)
    local copy = {}
    for index, item in ipairs(inventory or {}) do
        copy[index] = cloneItem(item)
    end
    return copy
end

function Items.add(inventory, kind, quantity)
    inventory = inventory or {}
    quantity = quantity or 1
    local normalized = Items.normalizeKind(kind)
    local definition = Items.getDefinition(normalized)
    if definition and definition.stackable ~= false then
        for _, item in ipairs(inventory) do
            if Items.normalizeKind(item.kind) == normalized then
                item.kind = normalized
                item.quantity = item.quantity + quantity
                if definition.perishable and item.condition == nil then
                    item.condition = 100
                end
                return item
            end
        end
    end

    local item = Items.create(normalized, quantity)
    table.insert(inventory, item)
    return item
end

function Items.remove(inventory, kind, quantity)
    inventory = inventory or {}
    quantity = quantity or 1
    local normalized = Items.normalizeKind(kind)

    for index = #inventory, 1, -1 do
        local item = inventory[index]
        if Items.normalizeKind(item.kind) == normalized then
            item.kind = normalized
            local amount = math.min(quantity, item.quantity or 1)
            item.quantity = (item.quantity or 1) - amount
            quantity = quantity - amount
            if item.quantity <= 0 then
                table.remove(inventory, index)
            end
            if quantity <= 0 then
                return true
            end
        end
    end

    return false
end

function Items.count(inventory, kind)
    local total = 0
    local normalized = Items.normalizeKind(kind)
    for _, item in ipairs(inventory or {}) do
        if Items.normalizeKind(item.kind) == normalized then
            total = total + (item.quantity or 1)
        end
    end
    return total
end

function Items.totalWeight(inventory)
    local total = 0
    for _, item in ipairs(inventory or {}) do
        local definition = Items.getDefinition(item.kind)
        if definition then
            total = total + (definition.weight * (item.quantity or 1))
        end
    end
    return total
end

function Items.findIndex(inventory, kind)
    local normalized = Items.normalizeKind(kind)
    for index, item in ipairs(inventory or {}) do
        if Items.normalizeKind(item.kind) == normalized then
            return index
        end
    end
    return nil
end

function Items.findItem(inventory, kind)
    local index = Items.findIndex(inventory, kind)
    return index and inventory[index] or nil, index
end

function Items.adjustCondition(item, delta)
    if not item then
        return nil
    end
    item.condition = Utils.clamp((item.condition or 100) + delta, 0, 100)
    return item.condition
end

function Items.sortInventory(inventory)
    table.sort(inventory, function(left, right)
        local leftLabel = Items.describe(left.kind)
        local rightLabel = Items.describe(right.kind)
        if leftLabel == rightLabel then
            local leftCondition = left.condition or 101
            local rightCondition = right.condition or 101
            if leftCondition == rightCondition then
                return (left.quantity or 1) > (right.quantity or 1)
            end
            return leftCondition > rightCondition
        end
        return leftLabel < rightLabel
    end)
end

return Items
