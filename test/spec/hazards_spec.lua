local TestRunner = require("test_runner")
local Hazards = require("hazards")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Hazards", function()
    it("triggers cursed rooms only once", function()
        local hazards = {
            spikes = {},
            cursedZones = {
                {x = 0, y = 0, width = 40, height = 40, triggered = false},
            },
        }
        local player = {coord = {10, 10}}

        local first = Hazards.update(hazards, player, 0.1)
        local second = Hazards.update(hazards, player, 0.1)

        TestRunner.assertTrue(first.cursedTriggered)
        TestRunner.assertTrue(first.sanityShock > 0)
        TestRunner.assertFalse(second.cursedTriggered)
        TestRunner.assertEqual(second.sanityShock, 0)
    end)

    it("kills the player when an active spike overlaps them", function()
        local hazards = {
            spikes = {
                {coord = {0, 0}, timer = 0, active = false, hitCooldown = 0},
            },
            cursedZones = {},
        }
        local player = {coord = {0, 0}}

        local result = Hazards.update(hazards, player, 0.1)

        TestRunner.assertTrue(result.playerKilled)
        TestRunner.assertTrue(result.spikeTriggered)
    end)
end)
