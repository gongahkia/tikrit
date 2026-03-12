local TestRunner = require("test_runner")
local Combat = require("combat")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Combat", function()
    it("starts attacks and creates a hitbox", function()
        Combat.init()
        TestRunner.assertTrue(Combat.tryAttack(1, 0))
        local hitbox = Combat.getAttackHitbox({40, 40})
        TestRunner.assertType(hitbox, "table")
        TestRunner.assertTrue(hitbox.x > 40)
    end)

    it("damages monsters and detects collision", function()
        local monster = {health = 2, coord = {60, 40}}
        local hitbox = {x = 60, y = 40, width = 20, height = 20}
        TestRunner.assertTrue(Combat.checkAttackHit(hitbox, monster.coord))
        TestRunner.assertFalse(Combat.hitMonster(monster, 1))
        TestRunner.assertTrue(Combat.hitMonster(monster, 1))
    end)
end)
