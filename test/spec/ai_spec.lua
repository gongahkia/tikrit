local TestRunner = require("test_runner")
local AI = require("ai")

local describe = TestRunner.describe
local it = TestRunner.it

describe("AI", function()
    it("creates typed monsters with archetype data", function()
        local monster = AI.createMonster({
            type = "stalker",
            coord = {40, 40},
            patrolPoints = {{40, 40}, {80, 40}},
        }, 50)

        TestRunner.assertEqual(monster.type, "stalker")
        TestRunner.assertType(monster.cooldowns, "table")
        TestRunner.assertTrue(monster.aggroRadius > 0)
    end)

    it("checks line of sight against walls", function()
        local monster = AI.createMonster({type = "chaser", coord = {0, 0}}, 40)
        TestRunner.assertTrue(AI.canSeePlayer(monster, {60, 0}, {}))
        TestRunner.assertFalse(AI.canSeePlayer(monster, {60, 0}, {{20, 0}}))
    end)

    it("moves monsters according to archetype rules", function()
        local player = {coord = {120, 120}, lastMoveX = 1, lastMoveY = 0}
        local world = {walls = {}}

        local chaser = AI.createMonster({type = "chaser", coord = {20, 20}}, 40)
        local stalker = AI.createMonster({type = "stalker", coord = {20, 80}}, 40)
        local lurker = AI.createMonster({type = "lurker", coord = {100, 100}}, 40)

        local summary = AI.updateMonsters({chaser, stalker, lurker}, player, world, {
            sanityEffects = {
                tier = "broken",
                monsterSpeedMultiplier = 1.0,
            }
        }, 1)

        TestRunner.assertTrue(chaser.coord[1] > 20)
        TestRunner.assertEqual(stalker.state, "pressing")
        TestRunner.assertTrue(lurker.state == "burst" or lurker.state == "rest")
        TestRunner.assertTrue(summary.newDetections >= 1)
    end)
end)
