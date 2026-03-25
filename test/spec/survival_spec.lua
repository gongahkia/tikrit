local TestRunner = require("test_runner")
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
                {tile or "snow", tile or "snow", tile or "snow"},
                {tile or "snow", tile or "snow", tile or "snow"},
                {tile or "snow", tile or "snow", tile or "snow"},
            },
            fires = {},
            weather = {current = weather or "clear", hoursUntilChange = 3},
            timeOfDay = 22,
            dayCount = 1,
            snowShelters = {},
        },
        runtime = {},
        stats = {
            daysSurvived = 1,
            firesLit = 0,
            metersWalked = 0,
            wolvesRepelled = 0,
            clothingRepairs = 0,
            waterBoiled = 0,
            meatCooked = 0,
        },
        feats = {},
    }
    run.player.coord = {20, 20}
    run.player.lastSafeCoord = {20, 20}
    return run
end

describe("Survival", function()
    it("initializes the player with survival stats and inventory weight", function()
        local player = Survival.createPlayer({})
        TestRunner.assertEqual(player.maxCondition, 100)
        TestRunner.assertEqual(player.carryCapacity, 25.0)
        TestRunner.assertTrue(player.carryWeight > 0)
        TestRunner.assertTrue(Items.count(player.inventory, "bedroll") >= 1)
    end)

    it("drains warmth and then condition under exposure", function()
        local run = buildRun("snow", "blizzard")
        run.player.warmth = 0
        for _, item in pairs(run.player.clothing) do
            item.warmth = 0
            item.windproof = 0
            item.wetness = 100
        end
        local startCondition = run.player.condition
        Survival.update(run, 1.0, {})
        TestRunner.assertTrue(run.player.condition < startCondition)
    end)

    it("sleep restores fatigue and condition only with needs met", function()
        local run = buildRun("cabin_floor", "clear")
        run.player.fatigue = 20
        run.player.condition = 60
        run.player.thirst = 80
        run.player.calories = 1600
        Survival.update(run, 1.0, {sleeping = true})
        TestRunner.assertTrue(run.player.fatigue > 20)
        TestRunner.assertTrue(run.player.condition > 60)

        local deprivedRun = buildRun("cabin_floor", "clear")
        deprivedRun.player.condition = 60
        deprivedRun.player.fatigue = 20
        deprivedRun.player.thirst = 0
        Survival.update(deprivedRun, 1.0, {sleeping = true})
        TestRunner.assertTrue(deprivedRun.player.condition <= 60)
    end)

    it("overweight fatigue drains faster and frostbite can reduce max condition", function()
        local run = buildRun("snow", "blizzard")
        Items.add(run.player.inventory, "firewood", 30)
        Survival.updateCarryWeight(run.player)
        run.player.fatigue = 100
        Survival.update(run, 1.0, {})
        local overweightFatigue = run.player.fatigue

        local lightRun = buildRun("snow", "clear")
        lightRun.player.fatigue = 100
        Survival.update(lightRun, 1.0, {})
        TestRunner.assertTrue(overweightFatigue < lightRun.player.fatigue)

        local frostRun = buildRun("snow", "blizzard")
        frostRun.player.warmth = 0
        for _, item in pairs(frostRun.player.clothing) do
            item.wetness = 100
        end
        Survival.update(frostRun, 3.0, {})
        TestRunner.assertTrue(frostRun.player.maxCondition < 100)
    end)

    it("repairs clothing and consumes sewing resources", function()
        local run = buildRun("cabin_floor", "clear")
        run.player.clothing.torso.condition = 40
        local clothBefore = Items.count(run.player.inventory, "cloth")
        local sewingBefore = Items.count(run.player.inventory, "sewing_kit")
        local ok = Survival.repairWorstClothing(run)
        TestRunner.assertTrue(ok)
        TestRunner.assertTrue(run.player.clothing.torso.condition > 40)
        TestRunner.assertEqual(Items.count(run.player.inventory, "cloth"), clothBefore - 1)
        TestRunner.assertEqual(Items.count(run.player.inventory, "sewing_kit"), sewingBefore - 1)
    end)
end)
