local TestRunner = require("test_runner")
local Progression = require("progression")
local Effects = require("effects")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Progression", function()
    it("deserializes missing fields into safe defaults", function()
        local data = Progression.deserialize("totalRuns=3\n[unlocks]\nspeedBoostStart=true")
        TestRunner.assertEqual(data.totalRuns, 3)
        TestRunner.assertTrue(data.unlocks.speedBoostStart)
        TestRunner.assertFalse(data.unlocks.invincibilityStart)
    end)

    it("applies starting unlocks to runtime state", function()
        os.remove("progression.txt")
        Effects.resetRun()
        Progression.data = Progression.deserialize("")
        Progression.data.unlocks.speedBoostStart = true
        Progression.data.unlocks.extraInventorySlot = true
        Progression.data.unlocks.combatMaster = true
        Progression.data.unlocks.survivor = true

        local run = {
            world = {
                player = {
                    speedBonus = 0,
                    inventorySize = 3,
                    attackDamage = 1,
                    extraLife = 0,
                    visionBonus = 0,
                }
            }
        }

        Progression.applyStartingUnlocks(run)
        TestRunner.assertEqual(run.world.player.speedBonus, 50)
        TestRunner.assertEqual(run.world.player.inventorySize, 4)
        TestRunner.assertEqual(run.world.player.attackDamage, 2)
        TestRunner.assertEqual(run.world.player.extraLife, 1)
    end)

    it("records runs and persists them", function()
        os.remove("progression.txt")
        Progression.data = Progression.deserialize("")
        Progression.recordRun({
            won = true,
            deaths = 1,
            keysCollected = 4,
            monstersKilled = 3,
            itemsCollected = 2,
            timeTaken = 95,
        })

        Progression.load()
        TestRunner.assertEqual(Progression.data.totalRuns, 1)
        TestRunner.assertEqual(Progression.data.totalWins, 1)
        TestRunner.assertEqual(Progression.data.fastestTime, 95)
        os.remove("progression.txt")
    end)
end)
