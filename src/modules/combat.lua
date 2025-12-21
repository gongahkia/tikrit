-- Combat module for player attacks and monster health
local CONFIG = require("config")

local Combat = {}

-- Combat state
Combat.attackCooldown = 0
Combat.isAttacking = false
Combat.attackDuration = 0
Combat.attackDirection = {x = 0, y = 1}  -- Default facing down

-- Monster health tracking
Combat.monsterHealth = {}

-- Initialize combat system
function Combat.init(monsterCount)
    Combat.attackCooldown = 0
    Combat.isAttacking = false
    Combat.attackDuration = 0
    Combat.monsterHealth = {}
    
    -- Initialize health for all monsters
    for i = 1, monsterCount do
        Combat.monsterHealth[i] = CONFIG.MONSTER_MAX_HEALTH or 3
    end
end

-- Update combat system
function Combat.update(dt)
    -- Update attack cooldown
    if Combat.attackCooldown > 0 then
        Combat.attackCooldown = Combat.attackCooldown - dt
    end
    
    -- Update attack animation duration
    if Combat.isAttacking then
        Combat.attackDuration = Combat.attackDuration + dt
        if Combat.attackDuration >= CONFIG.ATTACK_ANIMATION_DURATION then
            Combat.isAttacking = false
            Combat.attackDuration = 0
        end
    end
end

-- Try to perform an attack
function Combat.tryAttack(playerX, playerY, lastMoveX, lastMoveY)
    if Combat.attackCooldown > 0 then
        return false
    end
    
    -- Set attack direction based on last movement
    if lastMoveX ~= nil and lastMoveY ~= nil then
        local magnitude = math.sqrt(lastMoveX * lastMoveX + lastMoveY * lastMoveY)
        if magnitude > 0 then
            Combat.attackDirection.x = lastMoveX / magnitude
            Combat.attackDirection.y = lastMoveY / magnitude
        end
    end
    
    Combat.isAttacking = true
    Combat.attackDuration = 0
    Combat.attackCooldown = CONFIG.ATTACK_COOLDOWN or 1.0
    
    return true
end

-- Get attack hitbox
function Combat.getAttackHitbox(playerX, playerY)
    local range = CONFIG.ATTACK_RANGE or 30
    local centerX = playerX + CONFIG.TILE_SIZE / 2 + Combat.attackDirection.x * range
    local centerY = playerY + CONFIG.TILE_SIZE / 2 + Combat.attackDirection.y * range
    
    return {
        x = centerX - CONFIG.TILE_SIZE / 2,
        y = centerY - CONFIG.TILE_SIZE / 2,
        width = CONFIG.TILE_SIZE,
        height = CONFIG.TILE_SIZE
    }
end

-- Check if attack hits a monster
function Combat.checkAttackHit(attackBox, monsterX, monsterY)
    local monsterBox = {
        x = monsterX,
        y = monsterY,
        width = CONFIG.TILE_SIZE,
        height = CONFIG.TILE_SIZE
    }
    
    return attackBox.x < monsterBox.x + monsterBox.width and
           attackBox.x + attackBox.width > monsterBox.x and
           attackBox.y < monsterBox.y + monsterBox.height and
           attackBox.y + attackBox.height > monsterBox.y
end

-- Damage a monster
function Combat.damageMonster(monsterIndex)
    if Combat.monsterHealth[monsterIndex] then
        Combat.monsterHealth[monsterIndex] = Combat.monsterHealth[monsterIndex] - 1
        return Combat.monsterHealth[monsterIndex] <= 0
    end
    return false
end

-- Get monster health
function Combat.getMonsterHealth(monsterIndex)
    return Combat.monsterHealth[monsterIndex] or 0
end

-- Remove dead monster from health tracking
function Combat.removeMonster(monsterIndex)
    table.remove(Combat.monsterHealth, monsterIndex)
end

-- Check if currently attacking
function Combat.isCurrentlyAttacking()
    return Combat.isAttacking
end

-- Get attack cooldown percentage (for UI)
function Combat.getCooldownPercentage()
    local maxCooldown = CONFIG.ATTACK_COOLDOWN or 1.0
    return 1.0 - (Combat.attackCooldown / maxCooldown)
end

return Combat
