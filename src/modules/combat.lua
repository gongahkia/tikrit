local CONFIG = require("config")

local Combat = {}

Combat.attackCooldown = 0
Combat.attackDuration = 0
Combat.isAttacking = false
Combat.attackDirection = {x = 0, y = 1}

function Combat.init()
    Combat.attackCooldown = 0
    Combat.attackDuration = 0
    Combat.isAttacking = false
    Combat.attackDirection = {x = 0, y = 1}
end

function Combat.update(dt)
    Combat.attackCooldown = math.max(0, Combat.attackCooldown - dt)
    if Combat.isAttacking then
        Combat.attackDuration = Combat.attackDuration + dt
        if Combat.attackDuration >= CONFIG.ATTACK_ANIMATION_DURATION then
            Combat.attackDuration = 0
            Combat.isAttacking = false
        end
    end
end

function Combat.tryAttack(lastMoveX, lastMoveY)
    if Combat.attackCooldown > 0 then
        return false
    end

    if lastMoveX ~= 0 or lastMoveY ~= 0 then
        Combat.attackDirection.x = lastMoveX
        Combat.attackDirection.y = lastMoveY
    end

    Combat.attackCooldown = CONFIG.ATTACK_COOLDOWN
    Combat.attackDuration = 0
    Combat.isAttacking = true
    return true
end

function Combat.getAttackHitbox(playerCoord)
    local centerX = playerCoord[1] + (CONFIG.TILE_SIZE / 2) + (Combat.attackDirection.x * CONFIG.ATTACK_RANGE)
    local centerY = playerCoord[2] + (CONFIG.TILE_SIZE / 2) + (Combat.attackDirection.y * CONFIG.ATTACK_RANGE)
    return {
        x = centerX - (CONFIG.TILE_SIZE / 2),
        y = centerY - (CONFIG.TILE_SIZE / 2),
        width = CONFIG.TILE_SIZE,
        height = CONFIG.TILE_SIZE,
    }
end

function Combat.hitMonster(monster, damage)
    monster.health = monster.health - (damage or CONFIG.PLAYER_ATTACK_DAMAGE)
    return monster.health <= 0
end

function Combat.checkAttackHit(box, coord)
    return box.x < coord[1] + CONFIG.TILE_SIZE
        and box.x + box.width > coord[1]
        and box.y < coord[2] + CONFIG.TILE_SIZE
        and box.y + box.height > coord[2]
end

function Combat.getCooldownPercentage()
    return 1 - (Combat.attackCooldown / CONFIG.ATTACK_COOLDOWN)
end

return Combat
