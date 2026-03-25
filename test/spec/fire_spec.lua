local TestRunner = require("test_runner")
local Fire = require("fire")
local Survival = require("survival")
local Items = require("items")

local describe = TestRunner.describe
local it = TestRunner.it

local function buildRun(tile, weather)
    local run = {
        difficultyName = "normal",
        player = Survival.createPlayer({}),
        world = {
            grid = {
                {tile, tile, tile},
                {tile, tile, tile},
                {tile, tile, tile},
            },
            fires = {},
            weather = {current = weather, hoursUntilChange = 3},
            timeOfDay = 12,
            dayCount = 1,
            snowShelters = {},
        },
        stats = {
            firesLit = 0,
            meatCooked = 0,
            waterBoiled = 0,
        },
        feats = {},
    }
    run.player.coord = {20, 20}
    Items.add(run.player.inventory, "accelerant", 1)
    return run
end

describe("Fire", function()
    it("starts sheltered fires and tracks burn time", function()
        local run = buildRun("cabin_floor", "blizzard")
        local ok = Fire.start(run, true)
        TestRunner.assertTrue(ok)
        TestRunner.assertEqual(#run.world.fires, 1)
        Fire.update(run, 3.2)
        TestRunner.assertEqual(#run.world.fires, 1)
        Fire.update(run, 1.2)
        TestRunner.assertEqual(#run.world.fires, 0)
    end)

    it("blocks exposed fires during blizzards", function()
        local run = buildRun("snow", "blizzard")
        local ok = Fire.start(run, false)
        TestRunner.assertFalse(ok)
        TestRunner.assertEqual(#run.world.fires, 0)
    end)

    it("cooks meat and boils water at an active fire", function()
        local run = buildRun("cabin_floor", "clear")
        Fire.start(run, true)
        Items.add(run.player.inventory, "raw_meat", 1)
        local ok = Fire.interact(run)
        TestRunner.assertTrue(ok)
        TestRunner.assertEqual(Items.count(run.player.inventory, "cooked_meat"), 1)

        Items.add(run.player.inventory, "snow", 1)
        Fire.interact(run)
        TestRunner.assertTrue(Items.count(run.player.inventory, "water") >= 3)
    end)
end)
