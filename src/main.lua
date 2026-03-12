local CONFIG = require("config")

local Utils = require("modules/utils")
local AI = require("modules/ai")
local Effects = require("modules/effects")
local UI = require("modules/ui")
local Animation = require("modules/animation")
local Audio = require("modules/audio")
local Combat = require("modules/combat")
local ProcGen = require("modules/procgen")
local Accessibility = require("modules/accessibility")
local Events = require("modules/events")
local Progression = require("modules/progression")
local Editor = require("modules/editor")
local Replay = require("modules/replay")
local Settings = require("modules/settings")
local Sanity = require("modules/sanity")

local game = {
    screen = "title",
    previousScreen = "title",
    difficultyNames = {"easy", "normal", "hard", "nightmare"},
    selectedDifficulty = "normal",
    titleIndex = 1,
    titleItems = {},
    pauseIndex = 1,
    pauseOptions = {
        {label = "Resume"},
        {label = "Settings"},
        {label = "Restart"},
        {label = "Quit to Title"},
    },
    settingsScreen = {
        categories = {"audio", "gameplay", "accessibility"},
        categoryIndex = 1,
        optionIndex = 1,
        options = {},
    },
    debugToolsEnabled = false,
    settings = nil,
    run = nil,
}

local sprites = {}
local sounds = {}
local fonts = {}

local SETTINGS_DEFS = {
    audio = {
        {path = "audio.master", label = "Master", kind = "float", min = 0, max = 1, step = 0.1},
        {path = "audio.music", label = "Music", kind = "float", min = 0, max = 1, step = 0.1},
        {path = "audio.sfx", label = "SFX", kind = "float", min = 0, max = 1, step = 0.1},
    },
    gameplay = {
        {path = "gameplay.minimap", label = "Minimap", kind = "bool"},
        {path = "gameplay.screenShake", label = "Screen Shake", kind = "bool"},
        {path = "gameplay.fog", label = "Fog", kind = "bool"},
        {path = "gameplay.dailyChallenge", label = "Daily Challenge", kind = "bool"},
        {path = "gameplay.timeAttack", label = "Time Attack", kind = "bool"},
    },
    accessibility = {
        {path = "accessibility.colorblindMode", label = "Colorblind", kind = "enum", values = {"none", "protanopia", "deuteranopia", "tritanopia"}},
        {path = "accessibility.highContrast", label = "High Contrast", kind = "bool"},
        {path = "accessibility.slowMode", label = "Slow Mode", kind = "bool"},
        {path = "accessibility.fontScale", label = "Font Scale", kind = "float", min = 0.8, max = 1.5, step = 0.1},
        {path = "accessibility.visualAudioIndicators", label = "Visual Audio", kind = "bool"},
    },
}

local function formatBool(value)
    return value and "ON" or "OFF"
end

local function titleCase(value)
    return value:gsub("^%l", string.upper)
end

local function formatSettingValue(def)
    local value = Settings.get(def.path)
    if def.kind == "bool" then
        return formatBool(value)
    elseif def.kind == "float" then
        return string.format("%.1f", value)
    end
    return tostring(value)
end

local function rebuildFonts()
    local scale = game.settings.accessibility.fontScale
    fonts.large = love.graphics.newFont("font/Amatic-Bold.ttf", math.floor(CONFIG.FONT_SIZE_LARGE * scale))
    fonts.medium = love.graphics.newFont("font/Amatic-Bold.ttf", math.floor(CONFIG.FONT_SIZE_MEDIUM * scale))
    fonts.small = love.graphics.newFont("font/Amatic-Bold.ttf", math.floor(CONFIG.FONT_SIZE_SMALL * scale))
end

local function buildTitleItems()
    game.titleItems = {
        {label = "Start Run"},
        {label = "Difficulty", value = titleCase(game.selectedDifficulty)},
        {label = "Daily Challenge", value = formatBool(game.settings.gameplay.dailyChallenge)},
        {label = "Time Attack", value = formatBool(game.settings.gameplay.timeAttack)},
        {label = "Settings"},
        {label = "Progression"},
        {label = "Quit"},
    }
end

local function refreshSettingsOptions()
    local category = game.settingsScreen.categories[game.settingsScreen.categoryIndex]
    local definitions = SETTINGS_DEFS[category]
    game.settingsScreen.options = {}

    for _, def in ipairs(definitions) do
        table.insert(game.settingsScreen.options, {
            path = def.path,
            label = def.label,
            value = formatSettingValue(def),
            definition = def,
        })
    end

    if game.settingsScreen.optionIndex > #game.settingsScreen.options then
        game.settingsScreen.optionIndex = #game.settingsScreen.options
    end
    if game.settingsScreen.optionIndex < 1 then
        game.settingsScreen.optionIndex = 1
    end
end

local function applyAudioSettings()
    sounds.ambient:setVolume(game.settings.audio.master * game.settings.audio.music * CONFIG.AMBIENT_BASE_VOLUME)
    sounds.walking:setVolume(game.settings.audio.master * game.settings.audio.sfx)
    sounds.playerDeath:setVolume(game.settings.audio.master * game.settings.audio.sfx)
    sounds.item:setVolume(game.settings.audio.master * game.settings.audio.sfx)
    sounds.key:setVolume(game.settings.audio.master * game.settings.audio.sfx)
    sounds.door:setVolume(game.settings.audio.master * game.settings.audio.sfx)
    sounds.ghost:setVolume(game.settings.audio.master * game.settings.audio.sfx)
end

local function persistSettings()
    Settings.save()
    game.settings = Settings.getAll()
    rebuildFonts()
    buildTitleItems()
    refreshSettingsOptions()
    applyAudioSettings()
end

local function adjustSetting(definition, direction)
    local current = Settings.get(definition.path)

    if definition.kind == "bool" then
        Settings.set(definition.path, not current)
    elseif definition.kind == "float" then
        local nextValue = Utils.clamp(current + (definition.step * direction), definition.min, definition.max)
        Settings.set(definition.path, math.floor(nextValue * 10 + 0.5) / 10)
    elseif definition.kind == "enum" then
        local currentIndex = 1
        for index, value in ipairs(definition.values) do
            if value == current then
                currentIndex = index
                break
            end
        end
        currentIndex = currentIndex + direction
        if currentIndex < 1 then
            currentIndex = #definition.values
        elseif currentIndex > #definition.values then
            currentIndex = 1
        end
        Settings.set(definition.path, definition.values[currentIndex])
    end

    persistSettings()
end

local function buildWalls(grid)
    local walls = {}
    for y = 1, #grid do
        for x = 1, #grid[y] do
            if grid[y][x] == 1 then
                table.insert(walls, {(x - 1) * CONFIG.TILE_SIZE, (y - 1) * CONFIG.TILE_SIZE})
            end
        end
    end
    return walls
end

local function createRuntimeWorld(generated, difficultyName)
    local difficulty = CONFIG.DIFFICULTY_SETTINGS[difficultyName]
    local player = {
        coord = {generated.playerStart[1], generated.playerStart[2]},
        lastMoveX = 0,
        lastMoveY = 1,
        alive = true,
        baseSpeed = difficulty.playerSpeed,
        speedBonus = 0,
        inventory = {},
        inventorySize = CONFIG.INVENTORY_SIZE,
        overallKeyCount = 0,
        attackDamage = CONFIG.PLAYER_ATTACK_DAMAGE,
        extraLife = 0,
        wardCharges = 0,
        visionBonus = difficulty.visionBonus,
    }
    Sanity.initPlayer(player)

    local monsters = {}
    for _, spawn in ipairs(generated.monsters) do
        table.insert(monsters, AI.createMonster(spawn, difficulty.monsterSpeed))
    end

    local world = {
        grid = generated.grid,
        floorVariants = generated.floorVariants,
        wallVariants = generated.wallVariants,
        walls = buildWalls(generated.grid),
        keys = Utils.deepCopy(generated.keys),
        totalKeys = #generated.keys,
        items = Utils.deepCopy(generated.items),
        shrines = Utils.deepCopy(generated.shrines),
        safeZones = Utils.deepCopy(generated.safeZones),
        darkZones = Utils.deepCopy(generated.darkZones),
        monsters = monsters,
        player = player,
    }

    return world
end

local function setRunMessage(text)
    if game.run then
        game.run.runtime.message = text
        game.run.runtime.messageTimer = 2.2
    end
end

local function registerRunEvents()
    Events.clear()
    Events.on(Events.GAME_EVENTS.KEY_COLLECTED, function()
        setRunMessage("A key steadies your nerves.")
    end)
    Events.on(Events.GAME_EVENTS.ITEM_COLLECTED, function(itemKind)
        setRunMessage("Recovered " .. itemKind)
    end)
    Events.on(Events.GAME_EVENTS.ITEM_USED, function(itemKind)
        setRunMessage("Used " .. itemKind)
    end)
    Events.on(Events.GAME_EVENTS.MONSTER_KILLED, function(monsterType)
        setRunMessage("Silenced a " .. monsterType)
    end)
    Events.on(Events.GAME_EVENTS.PLAYER_DEATH, function()
        setRunMessage("The halls finally caught up.")
    end)
end

local function computeVisionRadius()
    local run = game.run
    local player = run.world.player
    local effects = run.runtime.sanityEffects
    local radius = CONFIG.VISION_BASE_RADIUS + player.visionBonus - effects.visionPenalty
    if run.runtime.sanityStatus and run.runtime.sanityStatus.inDarkZone then
        radius = radius - 1
    end
    return Utils.clamp(radius, CONFIG.VISION_MIN_RADIUS, 12)
end

local function updateVisibility()
    local run = game.run
    run.runtime.currentVisibleTiles = {}

    if not run.runtime.fogEnabled then
        return
    end

    local playerTileX = math.floor(run.world.player.coord[1] / CONFIG.TILE_SIZE) + 1
    local playerTileY = math.floor(run.world.player.coord[2] / CONFIG.TILE_SIZE) + 1
    local radius = computeVisionRadius()

    for dy = -radius, radius do
        for dx = -radius, radius do
            if math.sqrt((dx * dx) + (dy * dy)) <= radius then
                local tx = playerTileX + dx
                local ty = playerTileY + dy
                if run.world.grid[ty] and run.world.grid[ty][tx] then
                    local key = tx .. ":" .. ty
                    run.runtime.currentVisibleTiles[key] = true
                    run.runtime.seenTiles[key] = true
                end
            end
        end
    end
end

local function isVisibleTile(gridX, gridY)
    local run = game.run
    if not run.runtime.fogEnabled then
        return true
    end
    return run.runtime.currentVisibleTiles[gridX .. ":" .. gridY] == true
end

local function hasSeenTile(gridX, gridY)
    local run = game.run
    if not run.runtime.fogEnabled then
        return true
    end
    return run.runtime.seenTiles[gridX .. ":" .. gridY] == true
end

local function startNewRun()
    if Replay.isRecording() then
        Replay.stopRecording()
    end
    love.audio.stop(sounds.walking)
    love.audio.stop(sounds.ghost)

    local difficulty = game.selectedDifficulty
    local seed = Utils.setGameSeed(game.settings.gameplay.dailyChallenge)
    local generated = ProcGen.generateRunData(difficulty)

    Effects.resetRun()
    Combat.init()
    Animation.init()

    local run = {
        seed = seed,
        difficultyName = difficulty,
        world = createRuntimeWorld(generated, difficulty),
        runtime = {
            fogEnabled = game.settings.gameplay.fog or CONFIG.DIFFICULTY_SETTINGS[difficulty].forcedFog,
            minimapEnabled = game.settings.gameplay.minimap,
            currentVisibleTiles = {},
            seenTiles = {},
            message = "",
            messageTimer = 0,
            sanityEffects = Sanity.getEffects({sanity = CONFIG.SANITY_MAX, panicActive = false}),
            sanityStatus = nil,
            timeAttack = {
                enabled = game.settings.gameplay.timeAttack,
                startTime = love.timer.getTime(),
                elapsed = 0,
                lastIncrease = 0,
                parTime = CONFIG.TIME_ATTACK_PAR_TIMES[difficulty],
            },
        },
        stats = {
            startTime = love.timer.getTime(),
            finishTime = love.timer.getTime(),
            keysCollected = 0,
            monstersKilled = 0,
            itemsCollected = 0,
            itemsUsed = 0,
            deaths = 0,
        },
        finished = false,
    }

    game.run = run
    Progression.applyStartingUnlocks(run)
    registerRunEvents()
    Animation.initGhostBobbing(#run.world.monsters)
    Replay.startRecording(seed, difficulty)
    updateVisibility()
    game.screen = "game"
end

local function returnToTitle()
    if Replay.isRecording() then
        Replay.stopRecording()
    end
    love.audio.stop(sounds.walking)
    love.audio.stop(sounds.ghost)
    game.run = nil
    game.screen = "title"
    game.pauseIndex = 1
end

local function finalizeRun(won)
    local run = game.run
    if not run or run.finished then
        return
    end

    run.finished = true
    run.stats.finishTime = love.timer.getTime()
    Replay.stopRecording()
    love.audio.stop(sounds.walking)
    love.audio.stop(sounds.ghost)
    Progression.recordRun({
        won = won,
        deaths = run.stats.deaths,
        keysCollected = run.stats.keysCollected,
        monstersKilled = run.stats.monstersKilled,
        itemsCollected = run.stats.itemsCollected,
        timeTaken = run.stats.finishTime - run.stats.startTime,
    })
    game.screen = won and "win" or "lose"
end

local function useInventorySlot(slot)
    local run = game.run
    local item = run.world.player.inventory[slot]
    if not item then
        return
    end

    Effects.applyItem(run, item.kind)
    table.remove(run.world.player.inventory, slot)
    run.stats.itemsUsed = run.stats.itemsUsed + 1
    love.audio.play(sounds.item)
    Events.trigger(Events.GAME_EVENTS.ITEM_USED, item.kind)
end

local function addItemToInventory(item)
    local player = game.run.world.player
    if #player.inventory < player.inventorySize then
        table.insert(player.inventory, item)
        return true
    end
    return false
end

local function dropMonsterLoot(monster)
    local world = game.run.world
    local roll = math.random()
    if monster.lootBias == "key" and roll < 0.35 then
        table.insert(world.keys, {coord = {monster.coord[1], monster.coord[2]}})
        world.totalKeys = world.totalKeys + 1
    else
        local kind = "calming_tonic"
        if monster.lootBias == "ward" or (monster.lootBias == "item" and roll > 0.66) then
            kind = "ward_charge"
        elseif monster.lootBias == "item" and roll > 0.33 then
            kind = "speed_tonic"
        end
        table.insert(world.items, {
            coord = {monster.coord[1], monster.coord[2]},
            kind = kind,
        })
    end
end

local function consumeEmergencySave()
    local player = game.run.world.player
    if player.extraLife and player.extraLife > 0 then
        player.extraLife = player.extraLife - 1
        player.sanity = math.max(player.sanity, 30)
        Effects.activeEffects.invincibility = true
        Effects.activeEffects.invincibilityTimer = 2
        return true
    end

    if player.wardCharges and player.wardCharges > 0 then
        player.wardCharges = player.wardCharges - 1
        Sanity.restore(player, CONFIG.SANITY_WARD_RECOVERY)
        Effects.activeEffects.invincibility = true
        Effects.activeEffects.invincibilityTimer = 1.5
        return true
    end

    return false
end

local function killPlayer()
    local run = game.run
    if Effects.activeEffects.invincibility then
        return
    end
    if consumeEmergencySave() then
        setRunMessage("A last reserve keeps you moving.")
        return
    end

    run.world.player.alive = false
    run.stats.deaths = run.stats.deaths + 1
    Effects.spawn(run.world.player.coord[1], run.world.player.coord[2], "death")
    Effects.startScreenShake(game.settings.gameplay.screenShake, CONFIG.SCREEN_SHAKE_INTENSITY * 1.6, 0.45)
    love.audio.play(sounds.playerDeath)
    Events.trigger(Events.GAME_EVENTS.PLAYER_DEATH)
end

local function rectanglesOverlap(a, b)
    return a[1] + CONFIG.TILE_SIZE > b[1]
        and a[1] < b[1] + CONFIG.TILE_SIZE
        and a[2] + CONFIG.TILE_SIZE > b[2]
        and a[2] < b[2] + CONFIG.TILE_SIZE
end

local function movePlayer(dt)
    local run = game.run
    local player = run.world.player
    local sanityEffects = run.runtime.sanityEffects

    local speed = player.baseSpeed + player.speedBonus
    speed = speed * sanityEffects.playerSpeedMultiplier
    speed = Accessibility.getAdjustedSpeed(game.settings, speed)

    local dx = 0
    local dy = 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        dy = dy - 1
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        dy = dy + 1
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        dx = dx - 1
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        dx = dx + 1
    end

    local moved = dx ~= 0 or dy ~= 0
    if moved then
        local length = math.sqrt((dx * dx) + (dy * dy))
        dx = dx / length
        dy = dy / length
        player.lastMoveX = dx
        player.lastMoveY = dy

        local previous = {player.coord[1], player.coord[2]}
        player.coord[1] = player.coord[1] + (dx * speed * dt)
        player.coord[2] = player.coord[2] + (dy * speed * dt)

        for _, wall in ipairs(run.world.walls) do
            if rectanglesOverlap(player.coord, wall) then
                player.coord = previous
                break
            end
        end

        if not sounds.walking:isPlaying() then
            sounds.walking:setLooping(true)
            love.audio.play(sounds.walking)
        end
    elseif sounds.walking:isPlaying() then
        love.audio.stop(sounds.walking)
    end
end

local function processCombat()
    local run = game.run
    local player = run.world.player

    if Combat.isAttacking then
        local attackBox = Combat.getAttackHitbox(player.coord)
        for index = #run.world.monsters, 1, -1 do
            local monster = run.world.monsters[index]
            if Combat.checkAttackHit(attackBox, monster.coord) then
                local died = Combat.hitMonster(monster, player.attackDamage)
                Effects.startScreenShake(game.settings.gameplay.screenShake, CONFIG.SCREEN_SHAKE_INTENSITY, 0.18)
                if died then
                    Effects.spawn(monster.coord[1], monster.coord[2], "death")
                    dropMonsterLoot(monster)
                    run.stats.monstersKilled = run.stats.monstersKilled + 1
                    Events.trigger(Events.GAME_EVENTS.MONSTER_KILLED, monster.type)
                    table.remove(run.world.monsters, index)
                end
                break
            end
        end
    end

    for _, monster in ipairs(run.world.monsters) do
        if rectanglesOverlap(player.coord, monster.coord) then
            killPlayer()
            break
        end
    end
end

local function processPickups()
    local run = game.run
    local player = run.world.player

    for index = #run.world.items, 1, -1 do
        local item = run.world.items[index]
        if rectanglesOverlap(player.coord, item.coord) then
            if addItemToInventory(item) then
                Effects.spawn(item.coord[1], item.coord[2], "item")
                table.remove(run.world.items, index)
                run.stats.itemsCollected = run.stats.itemsCollected + 1
                love.audio.play(sounds.item)
                Events.trigger(Events.GAME_EVENTS.ITEM_COLLECTED, item.kind)
            end
        end
    end

    for index = #run.world.keys, 1, -1 do
        local key = run.world.keys[index]
        if rectanglesOverlap(player.coord, key.coord) then
            Effects.spawn(key.coord[1], key.coord[2], "key")
            table.remove(run.world.keys, index)
            player.overallKeyCount = player.overallKeyCount + 1
            run.stats.keysCollected = run.stats.keysCollected + 1
            Sanity.restore(player, CONFIG.SANITY_KEY_RECOVERY)
            love.audio.play(sounds.key)
            Events.trigger(Events.GAME_EVENTS.KEY_COLLECTED, key.coord)
        end
    end
end

local function updateGame(dt)
    local run = game.run
    if not run then
        return
    end

    Replay.update(dt)
    if run.runtime.messageTimer > 0 then
        run.runtime.messageTimer = run.runtime.messageTimer - dt
        if run.runtime.messageTimer <= 0 then
            run.runtime.message = ""
        end
    end

    if run.finished then
        return
    end

    Animation.update(dt)
    Combat.update(dt)
    Effects.updateItemEffects(run, dt)
    Effects.updateParticles(dt)
    Effects.updateScreenShake(dt)

    run.runtime.sanityStatus = Sanity.update(run.world.player, run.world, {fogEnabled = run.runtime.fogEnabled}, dt)
    run.runtime.sanityEffects = run.runtime.sanityStatus.effects

    if run.runtime.timeAttack.enabled then
        run.runtime.timeAttack.elapsed = love.timer.getTime() - run.runtime.timeAttack.startTime
        if run.runtime.timeAttack.elapsed - run.runtime.timeAttack.lastIncrease >= CONFIG.TIME_ATTACK_SPEED_INCREASE_INTERVAL then
            run.runtime.timeAttack.lastIncrease = run.runtime.timeAttack.elapsed
            for _, monster in ipairs(run.world.monsters) do
                monster.speed = monster.speed + CONFIG.TIME_ATTACK_SPEED_INCREASE_AMOUNT
            end
        end
    end

    movePlayer(dt)
    AI.updateMonsters(run.world.monsters, run.world.player, run.world, {sanityEffects = run.runtime.sanityEffects}, dt)
    processCombat()
    processPickups()

    updateVisibility()
    Audio.updateGhostAudio(game.settings, sounds.ghost, run.world.player.coord, run.world.monsters, run.runtime.sanityEffects)
    Audio.updateAmbientMusic(game.settings, sounds.ambient, run.world.player.alive, run.runtime.sanityEffects)

    if run.world.player.overallKeyCount >= run.world.totalKeys and run.world.totalKeys > 0 then
        love.audio.play(sounds.door)
        finalizeRun(true)
    elseif not run.world.player.alive then
        finalizeRun(false)
    end
end

local function drawTileSprite(sprite, variant, x, y, tint)
    local image = sprite[variant]
    Accessibility.setColor(game.settings, tint[1], tint[2], tint[3], tint[4] or 1)
    love.graphics.draw(image, x, y)
end

local function drawWorld()
    local run = game.run
    local world = run.world

    love.graphics.clear(0.06, 0.06, 0.06, 1)
    love.graphics.push()
    if Effects.screenShake.active then
        love.graphics.translate(Effects.screenShake.offsetX, Effects.screenShake.offsetY)
    end

    for y = 1, #world.grid do
        for x = 1, #world.grid[y] do
            local visible = isVisibleTile(x, y)
            local seen = hasSeenTile(x, y)
            if visible or seen then
                local alpha = visible and 1 or 0.3
                local drawX = (x - 1) * CONFIG.TILE_SIZE
                local drawY = (y - 1) * CONFIG.TILE_SIZE

                drawTileSprite(sprites.floor, world.floorVariants[y][x], drawX, drawY, {0.85, 0.85, 0.85, alpha})
                if world.grid[y][x] == 1 then
                    drawTileSprite(sprites.wall, world.wallVariants[y][x], drawX, drawY, {0.82, 0.82, 0.82, alpha})
                end
            end
        end
    end

    for _, zone in ipairs(world.darkZones) do
        Accessibility.setColor(game.settings, 0.05, 0.05, 0.05, 0.28)
        love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height)
    end

    for _, zone in ipairs(world.safeZones) do
        Accessibility.setColor(game.settings, 0.18, 0.32, 0.18, 0.1)
        love.graphics.rectangle("fill", zone.x, zone.y, zone.width, zone.height)
    end

    for _, shrine in ipairs(world.shrines) do
        Accessibility.setColor(game.settings, 0.5, 0.95, 0.7, 0.9)
        love.graphics.circle("fill", shrine[1] + (CONFIG.TILE_SIZE / 2), shrine[2] + (CONFIG.TILE_SIZE / 2), 6)
    end

    for _, item in ipairs(world.items) do
        Accessibility.setColor(game.settings, 0.9, 0.9, 0.9, 1)
        love.graphics.draw(sprites.item, item.coord[1], item.coord[2])
    end

    for _, key in ipairs(world.keys) do
        Accessibility.setColor(game.settings, 0.95, 0.95, 0.95, 1)
        love.graphics.draw(sprites.chest, key.coord[1], key.coord[2])
    end

    for index, monster in ipairs(world.monsters) do
        local style = AI.getDrawStyle(monster)
        local bob = Animation.getGhostBobOffset(index, love.timer.getTime()) * style.bob
        local sprite = (monster.type == "patrol_warden" or monster.type == "wailer" or monster.type == "stalker") and sprites.ghost[2] or sprites.ghost[1]
        Accessibility.setColor(game.settings, style.color[1], style.color[2], style.color[3], style.color[4])
        love.graphics.draw(sprite, monster.coord[1], monster.coord[2] + bob)
    end

    if world.player.alive then
        local scale = Animation.getPlayerIdleScale()
        local ox = sprites.player:getWidth() / 2
        local oy = sprites.player:getHeight() / 2
        if Effects.activeEffects.invincibility then
            Accessibility.setColor(game.settings, 1, 1, 0.4, 1)
        else
            Accessibility.setColor(game.settings, 0.95, 0.95, 0.95, 1)
        end
        love.graphics.draw(sprites.player, world.player.coord[1] + ox, world.player.coord[2] + oy, 0, scale, scale, ox, oy)
    else
        Accessibility.setColor(game.settings, 1, 1, 1, 1)
        love.graphics.draw(sprites.deadPlayer, world.player.coord[1], world.player.coord[2])
    end

    Effects.drawParticles()
    love.graphics.pop()

    UI.drawHUD(run, fonts, game.settings)
    if run.runtime.minimapEnabled and not run.runtime.sanityEffects.minimapDisabled then
        UI.drawMinimap(run, game.settings)
    end
    UI.drawSanityOverlay(run, fonts, game.settings)
    Accessibility.drawAudioIndicator(game.settings, run.world.player.coord, run.world.monsters)

    if run.runtime.timeAttack.enabled then
        local adjusted = run.runtime.timeAttack.elapsed
        local text = string.format("TIME %02d:%02d / PAR %02d:%02d",
            math.floor(adjusted / 60),
            math.floor(adjusted % 60),
            math.floor(run.runtime.timeAttack.parTime / 60),
            math.floor(run.runtime.timeAttack.parTime % 60)
        )
        Accessibility.setColor(game.settings, 1, 1, 1, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.print(text, 10, 176)
    end

    if run.runtime.message ~= "" then
        Accessibility.setColor(game.settings, 1, 0.92, 0.38, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.print(run.runtime.message, 10, CONFIG.WINDOW_HEIGHT - 28)
    end

    if game.debugToolsEnabled then
        Accessibility.setColor(game.settings, 1, 1, 1, 1)
        love.graphics.setFont(fonts.small)
        love.graphics.print("FPS: " .. love.timer.getFPS(), CONFIG.WINDOW_WIDTH - 80, 10)
        love.graphics.print("Seed: " .. tostring(run.seed), CONFIG.WINDOW_WIDTH - 150, 34)
        love.graphics.print("Monsters: " .. #world.monsters, CONFIG.WINDOW_WIDTH - 120, 58)
    end
end

function love.load()
    love.window.setTitle(string.format("%s v%s", CONFIG.WINDOW_TITLE, CONFIG.VERSION))
    love.window.setMode(CONFIG.WINDOW_WIDTH, CONFIG.WINDOW_HEIGHT)

    game.settings = Settings.load()
    Progression.load()

    rebuildFonts()
    buildTitleItems()
    refreshSettingsOptions()

    sprites.player = love.graphics.newImage("sprite/player-default.png")
    sprites.deadPlayer = love.graphics.newImage("sprite/player-tombstone.png")
    sprites.ghost = {
        love.graphics.newImage("sprite/ghost-1.png"),
        love.graphics.newImage("sprite/ghost-2.png"),
    }
    sprites.item = love.graphics.newImage("sprite/potion-1.png")
    sprites.chest = love.graphics.newImage("sprite/closed-chest.png")
    sprites.floor = {
        love.graphics.newImage("sprite/floor-stone-1.png"),
        love.graphics.newImage("sprite/floor-stone-2.png"),
    }
    sprites.wall = {
        love.graphics.newImage("sprite/dirt-wall-1.png"),
        love.graphics.newImage("sprite/dirt-wall-2.png"),
        love.graphics.newImage("sprite/dirt-wall-3.png"),
    }

    sounds.ambient = love.audio.newSource("sound/ambient-background.mp3", "stream")
    sounds.walking = love.audio.newSource("sound/player-walking.mp3", "static")
    sounds.playerDeath = love.audio.newSource("sound/player-death.mp3", "static")
    sounds.item = love.audio.newSource("sound/player-collect-item.mp3", "static")
    sounds.key = love.audio.newSource("sound/player-collect-key.mp3", "static")
    sounds.door = love.audio.newSource("sound/door-open.mp3", "static")
    sounds.ghost = love.audio.newSource("sound/ghost-scream.mp3", "static")

    sounds.ambient:setLooping(true)
    love.audio.play(sounds.ambient)
    applyAudioSettings()

    Effects.init()
    Editor.init()
    Replay.init()
end

function love.update(dt)
    if Editor.isActive() then
        Editor.update(dt)
        return
    end

    if game.screen == "game" then
        updateGame(dt)
    elseif game.screen == "pause" and game.run then
        Effects.updateParticles(dt)
        Effects.updateScreenShake(dt)
    end
end

function love.draw()
    if Editor.isActive() then
        Editor.draw()
        return
    end

    if game.screen == "title" then
        UI.drawTitleScreen(game, fonts, game.settings)
    elseif game.screen == "settings" then
        UI.drawSettingsScreen(game.settingsScreen, fonts, game.settings)
    elseif game.screen == "progression" then
        UI.drawProgressionScreen(Progression.data, fonts, game.settings)
    elseif game.screen == "game" then
        drawWorld()
    elseif game.screen == "pause" then
        drawWorld()
        UI.drawPauseScreen(game.pauseOptions, game.pauseIndex, fonts, game.settings)
    elseif game.screen == "win" then
        UI.drawWinScreen(game.run, fonts, game.settings)
    elseif game.screen == "lose" then
        UI.drawLoseScreen(game.run, fonts, game.settings)
    end
end

local function cycleDifficulty(direction)
    local currentIndex = 1
    for index, name in ipairs(game.difficultyNames) do
        if name == game.selectedDifficulty then
            currentIndex = index
            break
        end
    end
    currentIndex = currentIndex + direction
    if currentIndex < 1 then
        currentIndex = #game.difficultyNames
    elseif currentIndex > #game.difficultyNames then
        currentIndex = 1
    end
    game.selectedDifficulty = game.difficultyNames[currentIndex]
    buildTitleItems()
end

local function adjustTitleValue(direction)
    if game.titleIndex == 2 then
        cycleDifficulty(direction)
    elseif game.titleIndex == 3 then
        Settings.set("gameplay.dailyChallenge", not game.settings.gameplay.dailyChallenge)
        persistSettings()
    elseif game.titleIndex == 4 then
        Settings.set("gameplay.timeAttack", not game.settings.gameplay.timeAttack)
        persistSettings()
    end
end

local function openSettings(previousScreen)
    game.previousScreen = previousScreen
    game.screen = "settings"
    refreshSettingsOptions()
end

function love.keypressed(key)
    if Replay.isRecording() and game.screen == "game" then
        Replay.recordInput("keypress", key, love.timer.getTime() - game.run.stats.startTime)
    end

    if Editor.isActive() then
        Editor.keypressed(key)
        return
    end

    if key == "f3" then
        game.debugToolsEnabled = not game.debugToolsEnabled
        return
    end

    if key == "f5" and game.debugToolsEnabled then
        Editor.toggle()
        return
    end

    if game.screen == "title" then
        if key == "up" then
            game.titleIndex = math.max(1, game.titleIndex - 1)
        elseif key == "down" then
            game.titleIndex = math.min(#game.titleItems, game.titleIndex + 1)
        elseif key == "left" then
            adjustTitleValue(-1)
        elseif key == "right" then
            adjustTitleValue(1)
        elseif key == "f6" then
            Replay.save()
        elseif key == "return" then
            if game.titleIndex == 1 then
                startNewRun()
            elseif game.titleIndex == 2 then
                cycleDifficulty(1)
            elseif game.titleIndex == 3 or game.titleIndex == 4 then
                adjustTitleValue(1)
            elseif game.titleIndex == 5 then
                openSettings("title")
            elseif game.titleIndex == 6 then
                game.previousScreen = "title"
                game.screen = "progression"
            elseif game.titleIndex == 7 then
                love.event.quit()
            end
        elseif key == "escape" then
            love.event.quit()
        end
        return
    end

    if game.screen == "settings" then
        if key == "tab" then
            game.settingsScreen.categoryIndex = (game.settingsScreen.categoryIndex % #game.settingsScreen.categories) + 1
            refreshSettingsOptions()
        elseif key == "up" then
            game.settingsScreen.optionIndex = math.max(1, game.settingsScreen.optionIndex - 1)
        elseif key == "down" then
            game.settingsScreen.optionIndex = math.min(#game.settingsScreen.options, game.settingsScreen.optionIndex + 1)
        elseif key == "left" or key == "right" then
            local option = game.settingsScreen.options[game.settingsScreen.optionIndex]
            if option then
                adjustSetting(option.definition, key == "left" and -1 or 1)
            end
        elseif key == "r" then
            Settings.resetDefaults()
            persistSettings()
        elseif key == "escape" then
            game.screen = game.previousScreen
        end
        return
    end

    if game.screen == "progression" then
        if key == "escape" or key == "return" then
            game.screen = game.previousScreen
        end
        return
    end

    if game.screen == "game" then
        if key == "p" or key == "escape" then
            love.audio.stop(sounds.walking)
            game.screen = "pause"
            return
        elseif key == "space" then
            Combat.tryAttack(game.run.world.player.lastMoveX, game.run.world.player.lastMoveY)
        elseif key == "1" then
            useInventorySlot(1)
        elseif key == "2" then
            useInventorySlot(2)
        elseif key == "3" then
            useInventorySlot(3)
        elseif key == "4" then
            useInventorySlot(4)
        end
        return
    end

    if game.screen == "pause" then
        if key == "up" then
            game.pauseIndex = math.max(1, game.pauseIndex - 1)
        elseif key == "down" then
            game.pauseIndex = math.min(#game.pauseOptions, game.pauseIndex + 1)
        elseif key == "return" then
            if game.pauseIndex == 1 then
                game.screen = "game"
            elseif game.pauseIndex == 2 then
                openSettings("pause")
            elseif game.pauseIndex == 3 then
                startNewRun()
            elseif game.pauseIndex == 4 then
                returnToTitle()
            end
        elseif key == "p" or key == "escape" then
            game.screen = "game"
        end
        return
    end

    if game.screen == "win" or game.screen == "lose" then
        if key == "return" or key == "escape" then
            returnToTitle()
        end
    end
end

function love.mousereleased(x, y, button)
    if Editor.isActive() then
        Editor.mousereleased(x, y, button)
    end
end
