-- Effects module for particle systems and item effects
local CONFIG = require("config")

local Effects = {}

-- Active particle emitters
Effects.activeParticles = {}

-- Active item effects tracking
Effects.activeEffects = {
    invincibility = false,
    invincibilityTimer = 0,
    mapReveal = false,
    mapRevealTimer = 0,
    ghostSlow = false,
    ghostSlowTimer = 0,
}

-- Particle system templates
Effects.particleSystems = {}

-- Screen shake
Effects.screenShake = {
    active = false,
    duration = 0,
    intensity = 0,
    offsetX = 0,
    offsetY = 0,
}

-- Initialize particle systems
function Effects.init()
    local particleImage = Effects.createParticleImage()
    
    -- Key pickup particles (gold)
    Effects.particleSystems.key = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_KEY or 20)
    Effects.particleSystems.key:setParticleLifetime(0.5, 1)
    Effects.particleSystems.key:setEmissionRate(30)
    Effects.particleSystems.key:setSizeVariation(1)
    Effects.particleSystems.key:setLinearAcceleration(-100, -100, 100, 100)
    Effects.particleSystems.key:setColors(1, 0.84, 0, 1, 1, 0.84, 0, 0)
    
    -- Item pickup particles (cyan)
    Effects.particleSystems.item = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_ITEM or 15)
    Effects.particleSystems.item:setParticleLifetime(0.4, 0.8)
    Effects.particleSystems.item:setEmissionRate(25)
    Effects.particleSystems.item:setSizeVariation(1)
    Effects.particleSystems.item:setLinearAcceleration(-80, -80, 80, 80)
    Effects.particleSystems.item:setColors(0, 1, 1, 1, 0, 1, 1, 0)
    
    -- Death particles (red)
    Effects.particleSystems.death = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_DEATH or 30)
    Effects.particleSystems.death:setParticleLifetime(0.6, 1.2)
    Effects.particleSystems.death:setEmissionRate(40)
    Effects.particleSystems.death:setSizeVariation(1)
    Effects.particleSystems.death:setLinearAcceleration(-150, -150, 150, 150)
    Effects.particleSystems.death:setColors(1, 0, 0, 1, 1, 0, 0, 0)
    
    -- Door particles (gray dust)
    Effects.particleSystems.door = love.graphics.newParticleSystem(particleImage, CONFIG.PARTICLE_COUNT_DOOR or 10)
    Effects.particleSystems.door:setParticleLifetime(0.3, 0.6)
    Effects.particleSystems.door:setEmissionRate(20)
    Effects.particleSystems.door:setSizeVariation(1)
    Effects.particleSystems.door:setLinearAcceleration(-60, -60, 60, 60)
    Effects.particleSystems.door:setColors(0.5, 0.5, 0.5, 1, 0.5, 0.5, 0.5, 0)
end

-- Create particle image
function Effects.createParticleImage()
    local imageData = love.image.newImageData(2, 2)
    for x = 0, 1 do
        for y = 0, 1 do
            imageData:setPixel(x, y, 1, 1, 1, 1)
        end
    end
    return love.graphics.newImage(imageData)
end

-- Spawn particles at location
function Effects.spawn(x, y, particleType)
    if not CONFIG.PARTICLES_ENABLED then
        return
    end
    
    local ps = Effects.particleSystems[particleType]
    if ps then
        local emitter = {
            system = ps:clone(),
            x = x + CONFIG.TILE_SIZE / 2,
            y = y + CONFIG.TILE_SIZE / 2,
        }
        emitter.system:emit(CONFIG["PARTICLE_COUNT_" .. string.upper(particleType)] or 15)
        table.insert(Effects.activeParticles, emitter)
    end
end

-- Update all particles
function Effects.updateParticles(dt)
    for i = #Effects.activeParticles, 1, -1 do
        local emitter = Effects.activeParticles[i]
        emitter.system:update(dt)
        
        if emitter.system:getCount() == 0 then
            table.remove(Effects.activeParticles, i)
        end
    end
end

-- Draw all particles
function Effects.drawParticles()
    if CONFIG.PARTICLES_ENABLED then
        for _, emitter in ipairs(Effects.activeParticles) do
            love.graphics.draw(emitter.system, emitter.x, emitter.y)
        end
    end
end

-- Start screen shake
function Effects.startScreenShake(intensity, duration)
    if not CONFIG.SCREEN_SHAKE_ENABLED then
        return
    end
    
    Effects.screenShake.active = true
    Effects.screenShake.intensity = intensity or CONFIG.SHAKE_INTENSITY
    Effects.screenShake.duration = duration or CONFIG.SHAKE_DURATION
end

-- Update screen shake
function Effects.updateScreenShake(dt)
    if Effects.screenShake.active then
        Effects.screenShake.duration = Effects.screenShake.duration - dt
        
        if Effects.screenShake.duration <= 0 then
            Effects.screenShake.active = false
            Effects.screenShake.offsetX = 0
            Effects.screenShake.offsetY = 0
        else
            Effects.screenShake.offsetX = (math.random() * 2 - 1) * Effects.screenShake.intensity
            Effects.screenShake.offsetY = (math.random() * 2 - 1) * Effects.screenShake.intensity
        end
    end
end

-- Apply item effect
function Effects.applyRandomItemEffect(world)
    math.randomseed(os.time())
    local effect = math.random(1, 6)
    
    if effect == 1 then
        world.player.speed = world.player.speed + CONFIG.PLAYER_SPEED_BUFF
        print("Item effect: Speed Boost!")
        return "Speed Boost!"
    elseif effect == 2 then
        world.player.speed = math.max(100, world.player.speed - 100)
        print("Item effect: Speed Reduced!")
        return "Speed Reduced!"
    elseif effect == 3 then
        Effects.activeEffects.ghostSlow = true
        Effects.activeEffects.ghostSlowTimer = CONFIG.PLAYER_SPEED_BUFF_DURATION
        print("Item effect: Ghosts Slowed!")
        return "Ghosts Slowed!"
    elseif effect == 4 then
        Effects.activeEffects.invincibility = true
        Effects.activeEffects.invincibilityTimer = CONFIG.INVINCIBILITY_DURATION
        print("Item effect: Invincibility!")
        return "Invincibility!"
    elseif effect == 5 then
        Effects.activeEffects.mapReveal = true
        Effects.activeEffects.mapRevealTimer = CONFIG.MAP_REVEAL_DURATION
        print("Item effect: Map Revealed!")
        return "Map Revealed!"
    else
        world.player.speed = world.player.speed + CONFIG.PLAYER_SPEED_BUFF
        print("Item effect: Speed Boost!")
        return "Speed Boost!"
    end
end

-- Update item effects
function Effects.updateItemEffects(dt)
    if Effects.activeEffects.invincibility then
        Effects.activeEffects.invincibilityTimer = Effects.activeEffects.invincibilityTimer - dt
        if Effects.activeEffects.invincibilityTimer <= 0 then
            Effects.activeEffects.invincibility = false
            Effects.activeEffects.invincibilityTimer = 0
            print("Invincibility wore off")
        end
    end
    
    if Effects.activeEffects.mapReveal then
        Effects.activeEffects.mapRevealTimer = Effects.activeEffects.mapRevealTimer - dt
        if Effects.activeEffects.mapRevealTimer <= 0 then
            Effects.activeEffects.mapReveal = false
            Effects.activeEffects.mapRevealTimer = 0
            print("Map reveal wore off")
        end
    end
    
    if Effects.activeEffects.ghostSlow then
        Effects.activeEffects.ghostSlowTimer = Effects.activeEffects.ghostSlowTimer - dt
        if Effects.activeEffects.ghostSlowTimer <= 0 then
            Effects.activeEffects.ghostSlow = false
            Effects.activeEffects.ghostSlowTimer = 0
            print("Ghost slow wore off")
        end
    end
end

return Effects
