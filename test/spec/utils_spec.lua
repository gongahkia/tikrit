local TestRunner = require("test_runner")
local Utils = require("utils")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Utils", function()
    it("calculates distance and handles nil safely", function()
        TestRunner.assertEqual(Utils.distance(0, 0, 3, 4), 5)
        TestRunner.assertEqual(Utils.distance(nil, 0, 0, 0), 0)
    end)

    it("clamps values", function()
        TestRunner.assertEqual(Utils.clamp(12, 0, 10), 10)
        TestRunner.assertEqual(Utils.clamp(-1, 0, 10), 0)
        TestRunner.assertEqual(Utils.clamp(5, 0, 10), 5)
    end)

    it("converts between grid and pixel coordinates", function()
        local px, py = Utils.gridToPixel(3, 4)
        TestRunner.assertEqual(px, 60)
        TestRunner.assertEqual(py, 80)

        local gx, gy = Utils.pixelToGrid(65, 81)
        TestRunner.assertEqual(gx, 3)
        TestRunner.assertEqual(gy, 4)
    end)

    it("deep copies tables and shuffles in place", function()
        local original = {1, 2, {3, 4}}
        local copy = Utils.deepCopy(original)
        copy[3][1] = 9
        TestRunner.assertEqual(original[3][1], 3)

        local array = {1, 2, 3, 4, 5}
        local reference = array
        Utils.shuffle(array)
        TestRunner.assertEqual(array, reference)
        table.sort(array)
        TestRunner.assertTableEqual(array, {1, 2, 3, 4, 5})
    end)

    it("checks walkability and containment", function()
        local grid = {
            {"#", "#", "#"},
            {"#", ".", "#"},
            {"#", "#", "#"},
        }

        TestRunner.assertTrue(Utils.isWalkable(1, 1, grid))
        TestRunner.assertFalse(Utils.isWalkable(0, 0, grid))
        TestRunner.assertTrue(Utils.inside({20, 40}, {{0, 0}, {20, 40}}))
    end)
end)
