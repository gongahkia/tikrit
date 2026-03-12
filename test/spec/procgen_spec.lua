local TestRunner = require("test_runner")
local ProcGen = require("procgen")
local Utils = require("utils")

local describe = TestRunner.describe
local it = TestRunner.it

describe("ProcGen", function()
    it("creates deterministic runs for a fixed seed", function()
        Utils.setGameSeed(false, 12345)
        local first = ProcGen.generateRunData("normal")
        Utils.setGameSeed(false, 12345)
        local second = ProcGen.generateRunData("normal")

        TestRunner.assertTableEqual(first.playerStart, second.playerStart)
        TestRunner.assertEqual(#first.monsters, #second.monsters)
        TestRunner.assertEqual(first.monsters[1].type, second.monsters[1].type)
    end)

    it("guarantees safe zones, dark zones, keys, and monsters", function()
        Utils.setGameSeed(false, 77)
        local runData = ProcGen.generateRunData("hard")
        TestRunner.assertTrue(#runData.safeZones >= 2)
        TestRunner.assertTrue(#runData.darkZones >= 1)
        TestRunner.assertTrue(#runData.keys >= 5)
        TestRunner.assertTrue(#runData.monsters >= 8)
    end)
end)
