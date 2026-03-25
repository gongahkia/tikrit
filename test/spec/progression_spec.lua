local TestRunner = require("test_runner")
local Progression = require("progression")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Progression", function()
    it("deserializes missing fields into safe defaults", function()
        local data = Progression.deserialize("totalRuns=3\n[unlocks]\nFirestarter=true")
        TestRunner.assertEqual(data.totalRuns, 3)
        TestRunner.assertTrue(data.unlocks.Firestarter)
        TestRunner.assertFalse(data.unlocks.Outdoorsman)
    end)

    it("records runs and unlocks survival feats", function()
        os.remove("progression.txt")
        Progression.data = Progression.deserialize("")
        Progression.recordRun({
            daysSurvived = 5,
            firesLit = 3,
            waterBoiled = 2,
            meatCooked = 1,
            clothingRepairs = 4,
            wolvesRepelled = 2,
        })

        Progression.load()
        TestRunner.assertEqual(Progression.data.totalRuns, 1)
        TestRunner.assertEqual(Progression.data.bestDays, 5)
        TestRunner.assertTrue(Progression.data.unlocks.Outdoorsman)
        TestRunner.assertTrue(Progression.data.unlocks.PackMule)
        TestRunner.assertTrue(Progression.data.unlocks.Seamster)
        os.remove("progression.txt")
    end)
end)
