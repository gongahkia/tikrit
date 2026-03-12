local CONFIG = require("config")
local Sanity = require("modules/sanity")

local Effects = {}

Effects.activeParticles = {}
Effects.activeEffects = {}
Effects.particleSystems = {}
Effects.screenShake = {}

local function resetEffects()
    Effects.activeEffects = {
        invincibility = false,
        invincibilityTimer = 0,
        ghostSlow = false,
        ghostSlowTimer = 0,
        speedBoost = false,
        speedBoostTimer = 0,
    }

    Effects.screenShake = {
        active = false,
        duration = 0,
        intensity = 0,
        offsetX = 0,
        offsetY = 0,
    }
end

function Effects.createParticleImage()
    local imageData = love.image.newImageData(2, 2)
    for x = 0, 1 do
        for y = 0, 1 do
            imageData:setPixel(x, y, 1, 1, 1, 1)
        end
    end
    return love.graphics.newImage(imageData)
end

function Effects.init()
    local particleImage = Effects.createParticleImage()
    Effects.activeParticles = {}
    resetEffects()

    Effects.particleSystems.key = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_KEY)
    Effects.particleSystems.key:setParticleLifetime(0.4, 0.8)
    Effects.particleSystems.key:setLinearAcceleration(-90, -90, 90, 90)
    Effects.particleSystems.key:setColors(1, 0.84, 0, 1, 1, 0.84, 0, 0)

    Effects.particleSystems.item = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_ITEM)
    Effects.particleSystems.item:setParticleLifetime(0.4, 0.7)
    Effects.particleSystems.item:setLinearAcceleration(-60, -60, 60, 60)
    Effects.particleSystems.item:setColors(0, 1, 1, 1, 0, 1, 1, 0)

    Effects.particleSystems.death = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_DEATH)
    Effects.particleSystems.death:setParticleLifetime(0.5, 1.0)
    Effects.particleSystems.death:setLinearAcceleration(-130, -130, 130, 130)
    Effects.particleSystems.death:setColors(1, 0.2, 0.2, 1, 1, 0.2, 0.2, 0)

    Effects.particleSystems.door = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_DOOR)
    Effects.particleSystems.door:setParticleLifetime(0.25, 0.5)
    Effects.particleSystems.door:setLinearAcceleration(-50, -50, 50, 50)
    Effects.particleSystems.door:setColors(0.8, 0.8, 0.8, 1, 0.8, 0.8, 0.8, 0)
end

function Effects.resetRun()
    Effects.activeParticles = {}
    resetEffects()
end

function Effects.spawn(x, y, particleType)
    local template = Effects.particleSystems[particleType]
    if not template then
        return
    end

    local emitter = {
        system = template:clone(),
        x = x + CONFIG.TILE_SIZE / 2,
        y = y + CONFIG.TILE_SIZE / 2,
    }
    emitter.system:emit(template:getBufferSize())
    table.insert(Effects.activeParticles, emitter)
end

function Effects.updateParticles(dt)
    for index = #Effects.activeParticles, 1, -1 do
        local emitter = Effects.activeParticles[index]
        emitter.system:update(dt)
        if emitter.system:getCount() == 0 then
            table.remove(Effects.activeParticles, index)
        end
    end
end

function Effects.drawParticles()
    for _, emitter in ipairs(Effects.activeParticles) do
        love.graphics.draw(emitter.system, emitter.x, emitter.y)
    end
end

function Effects.startScreenShake(enabled, intensity, duration)
    if not enabled then
        return
    end

    Effects.screenShake.active = true
    Effects.screenShake.intensity = intensity or CONFIG.SCREEN_SHAKE_INTENSITY
    Effects.screenShake.duration = duration or CONFIG.SCREEN_SHAKE_DURATION
end

function Effects.updateScreenShake(dt)
    if not Effects.screenShake.active then
        return
    end

    Effects.screenShake.duration = Effects.screenShake.duration - dt
    if Effects.screenShake.duration <= 0 then
        Effects.screenShake.active = false
        Effects.screenShake.offsetX = 0
        Effects.screenShake.offsetY = 0
        return
    end

    Effects.screenShake.offsetX = (math.random() * 2 - 1) * Effects.screenShake.intensity
    Effects.screenShake.offsetY = (math.random() * 2 - 1) * Effects.screenShake.intensity
end

function Effects.updateItemEffects(run, dt)
    local effects = Effects.activeEffects

    if effects.invincibility then
        effects.invincibilityTimer = effects.invincibilityTimer - dt
        if effects.invincibilityTimer <= 0 then
            effects.invincibility = false
            effects.invincibilityTimer = 0
        end
    end

    if effects.ghostSlow then
        effects.ghostSlowTimer = effects.ghostSlowTimer - dt
        if effects.ghostSlowTimer <= 0 then
            effects.ghostSlow = false
            effects.ghostSlowTimer = 0
        end
    end

    if effects.speedBoost then
        effects.speedBoostTimer = effects.speedBoostTimer - dt
        if effects.speedBoostTimer <= 0 then
            effects.speedBoost = false
            effects.speedBoostTimer = 0
            run.world.player.speedBonus = 0
        end
    end
end

function Effects.applyItem(run, itemKind)
    local player = run.world.player
    local effects = Effects.activeEffects

    if itemKind == "calming_tonic" then
        Sanity.restore(player, CONFIG.SANITY_TONIC_RECOVERY)
    elseif itemKind == "speed_tonic" then
        player.speedBonus = CONFIG.PLAYER_SPEED_BUFF
        effects.speedBoost = true
        effects.speedBoostTimer = CONFIG.PLAYER_SPEED_BUFF_DURATION
    elseif itemKind == "ward_charge" then
        player.wardCharges = (player.wardCharges or 0) + 1
        Sanity.restore(player, CONFIG.SANITY_WARD_RECOVERY)
    end
end

return Effects
