local TestRunner = require("test_runner")
local ProcGen = require("procgen")
local Utils = require("utils")

local describe = TestRunner.describe
local it = TestRunner.it

local function countNodes(nodes, nodeType)
    local total = 0
    for _, node in ipairs(nodes or {}) do
        if node.type == nodeType then
            total = total + 1
        end
    end
    return total
end

local function buildEditorLayout()
    local rows = {}
    for y = 1, 30 do
        rows[y] = {}
        for x = 1, 30 do
            rows[y][x] = "."
        end
    end

    for x = 1, 30 do
        rows[1][x] = "#"
        rows[30][x] = "#"
    end
    for y = 1, 30 do
        rows[y][1] = "#"
        rows[y][30] = "#"
    end

    rows[6][6] = "@"
    for y = 4, 8 do
        for x = 4, 9 do
            rows[y][x] = "C"
        end
    end
    for y = 4, 8 do
        for x = 20, 26 do
            rows[y][x] = "V"
        end
    end
    for y = 14, 18 do
        for x = 12, 17 do
            rows[y][x] = "L"
        end
    end
    rows[15][14] = "W"
    rows[16][15] = "W"
    rows[10][10] = "O"
    rows[11][10] = "O"
    rows[12][10] = "O"
    rows[22][8] = "R"
    rows[22][9] = "R"
    rows[24][22] = "D"
    rows[24][23] = "D"
    rows[18][23] = "K"
    rows[18][24] = "K"
    rows[9][7] = "H"
    rows[20][7] = "F"
    rows[6][8] = "B"
    rows[12][14] = "I"
    rows[5][12] = "M"
    rows[7][13] = "P"
    rows[9][9] = "Q"

    local lines = {}
    for y = 1, 30 do
        lines[y] = table.concat(rows[y])
    end
    return {lines = lines}
end

describe("ProcGen", function()
    it("creates deterministic regions for a fixed seed", function()
        Utils.setGameSeed(false, 12345)
        local first = ProcGen.generateRunData("normal")
        Utils.setGameSeed(false, 12345)
        local second = ProcGen.generateRunData("normal")

        TestRunner.assertTableEqual(first.playerStart, second.playerStart)
        TestRunner.assertEqual(#first.resourceNodes, #second.resourceNodes)
        TestRunner.assertEqual(#first.weakIceTiles, #second.weakIceTiles)
        TestRunner.assertEqual(#first.wildlife.wolves, #second.wildlife.wolves)
    end)

    it("guarantees shelters, weak ice, resource nodes, and wildlife zones", function()
        Utils.setGameSeed(false, 77)
        local region = ProcGen.generateRunData("hard")

        TestRunner.assertEqual(#region.structures, 3)
        TestRunner.assertTrue(#region.safeSleepSpots >= 3)
        TestRunner.assertTrue(#region.weakIceTiles >= 6)
        TestRunner.assertTrue(countNodes(region.resourceNodes, "wood") >= 8)
        TestRunner.assertTrue(countNodes(region.resourceNodes, "loot") + countNodes(region.resourceNodes, "cache") >= 6)
        TestRunner.assertEqual(#region.wildlife.wolves, 2)
        TestRunner.assertEqual(#region.wildlife.rabbits, 2)
        TestRunner.assertEqual(#region.wildlife.deer, 1)
        TestRunner.assertTrue(#region.fishingSpots >= 1)
        TestRunner.assertTrue(#region.climbNodes >= 1)
        TestRunner.assertTrue(#region.workbenches >= 1)
        TestRunner.assertTrue(#region.mapNodes >= 1)
        TestRunner.assertTrue(#region.carcasses >= 1)
    end)

    it("builds runtime world data from editor-authored layouts", function()
        local region = ProcGen.generateRunData("normal", {
            layout = buildEditorLayout(),
        })

        TestRunner.assertEqual(region.source, "editor")
        TestRunner.assertTrue(#region.structures >= 2)
        TestRunner.assertTrue(#region.safeSleepSpots >= 2)
        TestRunner.assertTrue(#region.weakIceTiles >= 2)
        TestRunner.assertTrue(countNodes(region.resourceNodes, "loot") + countNodes(region.resourceNodes, "cache") >= 1)
        TestRunner.assertEqual(#region.wildlife.wolves, 1)
        TestRunner.assertEqual(#region.wildlife.rabbits, 1)
        TestRunner.assertEqual(#region.wildlife.deer, 1)
        TestRunner.assertTrue(#region.fishingSpots >= 1)
        TestRunner.assertTrue(#region.climbNodes >= 1)
        TestRunner.assertTrue(#region.mapNodes >= 1)
        TestRunner.assertTrue(#region.workbenches >= 1)
        TestRunner.assertTrue(#region.carcasses >= 1)

        local startTileX = math.floor(region.playerStart[1] / 20) + 1
        local startTileY = math.floor(region.playerStart[2] / 20) + 1
        TestRunner.assertNotEqual(region.grid[startTileY][startTileX], "rock")
        TestRunner.assertNotEqual(region.grid[startTileY][startTileX], "lake")
    end)
end)
