local CONFIG = require("config")
local Accessibility = require("modules/accessibility")

local SpriteRegistry = {}

local function safeLoad(path)
    local ok, image = pcall(love.graphics.newImage, path)
    if ok then
        return image
    end
    return nil
end

local function drawFallbackRect(settings, x, y, color, inset)
    Accessibility.setColor(settings, color[1], color[2], color[3], color[4] or 1)
    love.graphics.rectangle("fill", x + inset, y + inset, CONFIG.TILE_SIZE - (inset * 2), CONFIG.TILE_SIZE - (inset * 2))
end

function SpriteRegistry.load()
    return {
        player = safeLoad("sprite/player-default.png"),
        deadPlayer = safeLoad("sprite/player-tombstone.png"),
        closedChest = safeLoad("sprite/closed-chest.png"),
        openChest = safeLoad("sprite/opened-chest.png"),
        closedDoor = safeLoad("sprite/closed-door.png"),
        openDoor = safeLoad("sprite/opened-door.png"),
        items = {
            loot = safeLoad("sprite/resource-loot.png") or safeLoad("sprite/potion-1.png"),
            wood = safeLoad("sprite/resource-wood.png"),
            bow = safeLoad("sprite/item-bow.png"),
            arrow = safeLoad("sprite/item-arrow.png"),
            knife = safeLoad("sprite/item-knife.png"),
            hatchet = safeLoad("sprite/item-hatchet.png"),
            snare = safeLoad("sprite/item-snare.png"),
            fishing_tackle = safeLoad("sprite/item-fishing-tackle.png"),
            bandage = safeLoad("sprite/item-bandage.png"),
            antiseptic = safeLoad("sprite/item-antiseptic.png"),
            antibiotics = safeLoad("sprite/item-antibiotics.png"),
            painkillers = safeLoad("sprite/item-painkillers.png"),
            charcoal = safeLoad("sprite/item-charcoal.png"),
            affliction = {
                hypothermia = safeLoad("sprite/ui-affliction-hypothermia.png"),
                sprain = safeLoad("sprite/ui-affliction-sprain.png"),
                infection = safeLoad("sprite/ui-affliction-infection.png"),
                food_poisoning = safeLoad("sprite/ui-affliction-food-poisoning.png"),
            },
            skills = {
                archery = safeLoad("sprite/ui-skill-archery.png"),
                cooking = safeLoad("sprite/ui-skill-cooking.png"),
                fishing = safeLoad("sprite/ui-skill-fishing.png"),
                harvesting = safeLoad("sprite/ui-skill-harvesting.png"),
                firestarting = safeLoad("sprite/ui-skill-firestarting.png"),
                mending = safeLoad("sprite/ui-skill-mending.png"),
            },
        },
        world = {
            fire = safeLoad("sprite/effect-fire.png"),
            fishingHole = safeLoad("sprite/world-fishing-hole.png"),
            ropeClimb = safeLoad("sprite/world-rope-climb.png"),
            workbench = safeLoad("sprite/world-workbench.png"),
            mapNode = safeLoad("sprite/world-map-node.png"),
            trap = safeLoad("sprite/world-snare.png"),
            rabbitCarcass = safeLoad("sprite/world-rabbit-carcass.png"),
            deerCarcass = safeLoad("sprite/world-deer-carcass.png"),
            fishCarcass = safeLoad("sprite/world-fish-carcass.png"),
        },
        wildlife = {
            wolf = safeLoad("sprite/wildlife-wolf.png"),
            rabbit = safeLoad("sprite/wildlife-rabbit.png"),
            deer = safeLoad("sprite/wildlife-deer.png"),
        },
        tiles = {
            snow = safeLoad("sprite/terrain-snow.png"),
            path = safeLoad("sprite/terrain-path.png"),
            fire_safe = safeLoad("sprite/terrain-fire-safe.png"),
            ice = safeLoad("sprite/terrain-ice.png"),
            weak_ice = safeLoad("sprite/terrain-weak-ice.png"),
            tree = safeLoad("sprite/terrain-tree.png"),
            rock = safeLoad("sprite/terrain-rock.png"),
            cabin_wall = safeLoad("sprite/dirt-wall-1.png"),
            cave_wall = safeLoad("sprite/dirt-wall-2.png"),
            cabin_floor = safeLoad("sprite/floor-stone-1.png"),
            cave_floor = safeLoad("sprite/floor-stone-2.png"),
            cabin_bed = safeLoad("sprite/shelter-bed.png"),
            cabin_stove = safeLoad("sprite/shelter-stove.png"),
            cabin_workbench = safeLoad("sprite/world-workbench.png"),
            snow_shelter = safeLoad("sprite/shelter-snow.png"),
        },
    }
end

function SpriteRegistry.drawTile(bundle, tile, x, y, settings)
    local image = bundle.tiles[tile]
    if image then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(image, x, y)
        return
    end

    if tile == "snow" then
        drawFallbackRect(settings, x, y, {0.92, 0.95, 1, 1}, 0)
    elseif tile == "path" then
        drawFallbackRect(settings, x, y, {0.78, 0.82, 0.85, 1}, 0)
    elseif tile == "fire_safe" then
        drawFallbackRect(settings, x, y, {0.92, 0.95, 1, 1}, 0)
        Accessibility.setColor(settings, 0.76, 0.82, 0.88, 0.45)
        love.graphics.rectangle("line", x + 2, y + 2, CONFIG.TILE_SIZE - 4, CONFIG.TILE_SIZE - 4)
    elseif tile == "ice" then
        drawFallbackRect(settings, x, y, {0.7, 0.86, 0.98, 1}, 0)
    elseif tile == "weak_ice" then
        drawFallbackRect(settings, x, y, {0.62, 0.82, 0.96, 1}, 0)
        Accessibility.setColor(settings, 0.16, 0.3, 0.45, 0.9)
        love.graphics.line(x + 4, y + 5, x + 10, y + 10)
        love.graphics.line(x + 10, y + 10, x + 6, y + 16)
        love.graphics.line(x + 10, y + 10, x + 15, y + 6)
    elseif tile == "tree" then
        drawFallbackRect(settings, x, y, {0.9, 0.95, 1, 1}, 0)
        Accessibility.setColor(settings, 0.1, 0.42, 0.2, 1)
        love.graphics.circle("fill", x + 10, y + 8, 7)
    elseif tile == "rock" then
        drawFallbackRect(settings, x, y, {0.68, 0.7, 0.74, 1}, 2)
    elseif tile == "cabin_wall" or tile == "cave_wall" then
        drawFallbackRect(settings, x, y, {0.46, 0.38, 0.32, 1}, 1)
    elseif tile == "cabin_floor" or tile == "cave_floor" then
        drawFallbackRect(settings, x, y, {0.72, 0.72, 0.74, 1}, 0)
    elseif tile == "cabin_bed" then
        drawFallbackRect(settings, x, y, {0.72, 0.72, 0.74, 1}, 0)
        Accessibility.setColor(settings, 0.74, 0.2, 0.2, 0.9)
        love.graphics.rectangle("fill", x + 4, y + 5, 12, 10)
    elseif tile == "cabin_stove" then
        drawFallbackRect(settings, x, y, {0.72, 0.72, 0.74, 1}, 0)
        Accessibility.setColor(settings, 0.2, 0.2, 0.2, 0.95)
        love.graphics.rectangle("fill", x + 4, y + 4, 12, 12)
    elseif tile == "cabin_workbench" then
        drawFallbackRect(settings, x, y, {0.72, 0.72, 0.74, 1}, 0)
        Accessibility.setColor(settings, 0.45, 0.28, 0.14, 1)
        love.graphics.rectangle("fill", x + 3, y + 9, 14, 6)
    elseif tile == "snow_shelter" then
        drawFallbackRect(settings, x, y, {0.86, 0.94, 1, 1}, 0)
        Accessibility.setColor(settings, 0.82, 0.92, 1, 0.92)
        love.graphics.polygon("fill", x + 3, y + 16, x + 10, y + 4, x + 17, y + 16)
    else
        drawFallbackRect(settings, x, y, {0.2, 0.2, 0.2, 1}, 0)
    end
end

function SpriteRegistry.drawDoor(bundle, doorOpen, x, y, settings)
    Accessibility.setColor(settings, 1, 1, 1, 1)
    love.graphics.draw(doorOpen and bundle.openDoor or bundle.closedDoor, x, y)
end

function SpriteRegistry.drawResourceNode(bundle, node, settings)
    if node.type == "cache" then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(node.opened and bundle.openChest or bundle.closedChest, node.coord[1], node.coord[2])
    elseif node.type == "wood" and bundle.items.wood then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(bundle.items.wood, node.coord[1], node.coord[2])
    elseif node.type == "wood" then
        drawFallbackRect(settings, node.coord[1], node.coord[2], {0.52, 0.32, 0.18, 1}, 4)
    else
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(bundle.items.loot, node.coord[1], node.coord[2])
    end
end

function SpriteRegistry.drawFire(bundle, fire, settings, pulseTime)
    if bundle.world.fire then
        Accessibility.setColor(settings, 1, 1, 1, 0.9 + (math.sin((pulseTime or 0) * 6) * 0.08))
        love.graphics.draw(bundle.world.fire, fire.coord[1], fire.coord[2])
        return
    end

    local pulse = math.sin((pulseTime or 0) * 6) * 2
    Accessibility.setColor(settings, 1, 0.55, 0.1, 0.95)
    love.graphics.circle("fill", fire.coord[1] + 10, fire.coord[2] + 10, 5 + pulse)
end

function SpriteRegistry.drawWildlife(bundle, animal, settings)
    local image = bundle.wildlife[animal.kind]
    if image then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(image, animal.coord[1], animal.coord[2])
        return
    end

    if animal.kind == "wolf" then
        drawFallbackRect(settings, animal.coord[1], animal.coord[2], {0.72, 0.76, 0.82, 1}, 3)
    elseif animal.kind == "rabbit" then
        Accessibility.setColor(settings, 0.94, 0.94, 0.98, 1)
        love.graphics.circle("fill", animal.coord[1] + 10, animal.coord[2] + 10, 4)
    elseif animal.kind == "deer" then
        drawFallbackRect(settings, animal.coord[1], animal.coord[2], {0.56, 0.34, 0.18, 1}, 2)
    end
end

function SpriteRegistry.drawTrap(bundle, trap, settings)
    if bundle.world.trap then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(bundle.world.trap, trap.coord[1], trap.coord[2])
        return
    end

    local color = trap.state == "caught" and {0.86, 0.24, 0.2, 1} or {0.45, 0.34, 0.18, 1}
    drawFallbackRect(settings, trap.coord[1], trap.coord[2], color, 5)
end

function SpriteRegistry.drawCarcass(bundle, carcass, settings)
    local image
    if carcass.kind == "rabbit" then
        image = bundle.world.rabbitCarcass
    elseif carcass.kind == "deer" then
        image = bundle.world.deerCarcass
    elseif carcass.kind == "fish" then
        image = bundle.world.fishCarcass
    end

    if image then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(image, carcass.coord[1], carcass.coord[2])
        return
    end

    local color = carcass.kind == "deer" and {0.55, 0.18, 0.12, 1}
        or carcass.kind == "fish" and {0.3, 0.6, 0.86, 1}
        or {0.74, 0.26, 0.2, 1}
    drawFallbackRect(settings, carcass.coord[1], carcass.coord[2], color, 4)
end

function SpriteRegistry.drawWorldMarker(bundle, kind, coord, settings)
    local image
    if kind == "fishing" then
        image = bundle.world.fishingHole
    elseif kind == "climb" then
        image = bundle.world.ropeClimb
    elseif kind == "workbench" then
        image = bundle.world.workbench
    elseif kind == "map" then
        image = bundle.world.mapNode
    end

    if image then
        Accessibility.setColor(settings, 1, 1, 1, 1)
        love.graphics.draw(image, coord[1], coord[2])
        return
    end

    if kind == "fishing" then
        Accessibility.setColor(settings, 0.3, 0.64, 0.92, 0.9)
        love.graphics.circle("line", coord[1] + 10, coord[2] + 10, 6)
    elseif kind == "climb" then
        Accessibility.setColor(settings, 0.72, 0.58, 0.36, 1)
        love.graphics.line(coord[1] + 5, coord[2] + 4, coord[1] + 5, coord[2] + 16)
        love.graphics.line(coord[1] + 14, coord[2] + 4, coord[1] + 14, coord[2] + 16)
        love.graphics.line(coord[1] + 5, coord[2] + 7, coord[1] + 14, coord[2] + 7)
        love.graphics.line(coord[1] + 5, coord[2] + 12, coord[1] + 14, coord[2] + 12)
    elseif kind == "workbench" then
        drawFallbackRect(settings, coord[1], coord[2], {0.45, 0.28, 0.14, 1}, 2)
    elseif kind == "map" then
        Accessibility.setColor(settings, 0.96, 0.86, 0.5, 1)
        love.graphics.rectangle("line", coord[1] + 4, coord[2] + 4, 12, 12)
    end
end

function SpriteRegistry.drawStation(bundle, station, settings)
    if not station then
        return
    end

    local coord = station.coord
    local drawBase = not station.overlayOnly

    if drawBase then
        if station.hasWorkbench and bundle.world.workbench then
            Accessibility.setColor(settings, 1, 1, 1, 1)
            love.graphics.draw(bundle.world.workbench, coord[1], coord[2])
        elseif station.hasWorkbench then
            drawFallbackRect(settings, coord[1], coord[2], {0.45, 0.28, 0.14, 1}, 2)
        else
            Accessibility.setColor(settings, 0.72, 0.58, 0.36, 1)
            love.graphics.line(coord[1] + 6, coord[2] + 4, coord[1] + 6, coord[2] + 16)
            love.graphics.line(coord[1] + 14, coord[2] + 4, coord[1] + 14, coord[2] + 16)
            love.graphics.line(coord[1] + 6, coord[2] + 7, coord[1] + 14, coord[2] + 7)
            love.graphics.line(coord[1] + 6, coord[2] + 11, coord[1] + 14, coord[2] + 11)
        end
    end

    if station.hasCuring then
        Accessibility.setColor(settings, 0.58, 0.38, 0.22, 0.95)
        love.graphics.line(coord[1] + 4, coord[2] + 5, coord[1] + 4, coord[2] + 15)
        love.graphics.line(coord[1] + 16, coord[2] + 5, coord[1] + 16, coord[2] + 15)
        love.graphics.line(coord[1] + 4, coord[2] + 5, coord[1] + 16, coord[2] + 5)
    end

    if station.state == "ready" then
        Accessibility.setColor(settings, 0.32, 0.92, 0.48, 1)
        love.graphics.rectangle("fill", coord[1] + 13, coord[2] + 2, 5, 5)
    elseif station.state == "curing" then
        Accessibility.setColor(settings, 0.98, 0.76, 0.28, 1)
        love.graphics.circle("fill", coord[1] + 15, coord[2] + 5, 3)
    else
        Accessibility.setColor(settings, 0.68, 0.72, 0.76, 1)
        love.graphics.rectangle("line", coord[1] + 13, coord[2] + 2, 5, 5)
    end
end

function SpriteRegistry.drawPlayer(bundle, alive, coord, settings)
    Accessibility.setColor(settings, 1, 1, 1, 1)
    love.graphics.draw(alive and bundle.player or bundle.deadPlayer, coord[1], coord[2])
end

return SpriteRegistry
