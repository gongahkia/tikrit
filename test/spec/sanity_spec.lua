local TestRunner = require("test_runner")
local Sanity = require("sanity")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Sanity", function()
    it("initializes player sanity state", function()
        local player = {}
        Sanity.initPlayer(player)
        TestRunner.assertEqual(player.maxSanity, 100)
        TestRunner.assertEqual(player.sanity, 100)
        TestRunner.assertFalse(player.panicActive)
    end)

    it("applies shock, restore, and tier transitions", function()
        local player = {}
        Sanity.initPlayer(player)
        Sanity.applyShock(player, 60)
        TestRunner.assertEqual(Sanity.getTier(player), "critical")
        Sanity.applyShock(player, 30)
        TestRunner.assertEqual(Sanity.getTier(player), "broken")
        Sanity.restore(player, 20)
        TestRunner.assertEqual(player.sanity, 30)
    end)

    it("drains in dark zones and recovers in safe zones", function()
        local player = {coord = {50, 50}}
        Sanity.initPlayer(player)

        local world = {
            monsters = {
                {type = "wailer", coord = {80, 60}, aggroRadius = 120, auraRadius = 120},
            },
            darkZones = {
                {x = 0, y = 0, width = 120, height = 120},
            },
            safeZones = {},
        }

        local result = Sanity.update(player, world, {fogEnabled = true}, 1)
        TestRunner.assertTrue(player.sanity < 100)
        TestRunner.assertTrue(result.inDarkZone)

        local recoveryPlayer = {coord = {50, 50}, sanity = 40, maxSanity = 100, panicActive = false, safeRecoveryTimer = 0}
        local recoveryWorld = {
            monsters = {},
            darkZones = {},
            safeZones = {
                {x = 0, y = 0, width = 120, height = 120},
            },
        }

        Sanity.update(recoveryPlayer, recoveryWorld, {fogEnabled = false}, 1)
        TestRunner.assertTrue(recoveryPlayer.sanity > 40)
    end)
end)
