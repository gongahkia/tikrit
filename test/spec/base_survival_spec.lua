local TestRunner = require("test_runner")
local CONFIG = require("config")
local Items = require("items")
local Replay = require("replay")
local Survival = require("survival")
local Wildlife = require("wildlife")

local describe = TestRunner.describe
local it = TestRunner.it

local function buildWorld(tile)
    return {
        grid = {
            {tile or "snow", tile or "snow", tile or "snow", tile or "snow", tile or "snow"},
            {tile or "snow", tile or "snow", tile or "snow", tile or "snow", tile or "snow"},
            {tile or "snow", tile or "snow", tile or "snow", tile or "snow", tile or "snow"},
            {tile or "snow", tile or "snow", tile or "snow", tile or "snow", tile or "snow"},
            {tile or "snow", tile or "snow", tile or "snow", tile or "snow", tile or "snow"},
        },
        fires = {},
        weather = {current = "clear", hoursUntilChange = 4},
        timeOfDay = 10,
        dayCount = 1,
        snowShelters = {},
        weakIceTiles = {},
        temperatureBands = {},
        curingStations = {},
        curing = {},
        mapNodes = {},
        climbNodes = {},
        fishingSpots = {},
        traps = {},
        carcasses = {},
        mappedTiles = {},
        workbenches = {},
        rabbitZones = {},
        structures = {},
        wildlife = {
            wolves = {},
            rabbits = {},
            deer = {},
        },
    }
end

local function buildRun(tile, difficultyName)
    local run = {
        difficultyName = difficultyName or "voyageur",
        player = Survival.createPlayer({}),
        world = buildWorld(tile),
        runtime = {
            message = "",
            causeOfDeath = "exposure",
        },
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

describe("Base Survival", function()
    it("escalates afflictions, allows treatment, and decays food by storage context", function()
        local outdoorRun = buildRun("snow", "interloper")
        local shelteredRun = buildRun("cabin_floor", "voyageur")

        outdoorRun.world.weather.current = "blizzard"
        outdoorRun.player.warmth = 5
        for _, item in pairs(outdoorRun.player.clothing) do
            item.warmth = 0
            item.windproof = 0
            item.wetness = 100
        end

        Items.add(outdoorRun.player.inventory, "raw_meat", 1)
        Items.add(shelteredRun.player.inventory, "raw_meat", 1)
        local outdoorMeat = Items.findItem(outdoorRun.player.inventory, "raw_meat")
        local shelteredMeat = Items.findItem(shelteredRun.player.inventory, "raw_meat")

        Survival.update(outdoorRun, 3.0, {})
        Survival.update(shelteredRun, 3.0, {})
        TestRunner.assertTrue(outdoorRun.player.afflictions.hypothermia or outdoorRun.player.afflictions.hypothermiaRisk > 0)
        TestRunner.assertTrue(outdoorMeat.condition < shelteredMeat.condition)

        Survival.applyInfectionRisk(outdoorRun.player, CONFIG.INFECTION_RISK_HOURS)
        Items.add(outdoorRun.player.inventory, "antibiotics", 1)
        local ok = Survival.autoTreat(outdoorRun)
        TestRunner.assertTrue(ok)
        TestRunner.assertEqual(outdoorRun.player.afflictions.infectionRiskHours, 0)

        Items.add(outdoorRun.player.inventory, "cooked_meat", 1)
        local cooked = Items.findItem(outdoorRun.player.inventory, "cooked_meat")
        cooked.condition = 10
        local cookedIndex = Items.findIndex(outdoorRun.player.inventory, "cooked_meat")
        Survival.consumeInventoryIndex(outdoorRun, cookedIndex)
        TestRunner.assertTrue((outdoorRun.player.afflictions.foodPoisoningHours or 0) > 0)
    end)

    it("supports curing, crafting, rope climbs, and charcoal mapping", function()
        local run = buildRun("cabin_floor")
        run.world.curingStations = {{coord = {20, 20}}}
        run.world.workbenches = {{coord = {20, 20}}}
        run.world.mapNodes = {{coord = {20, 20}}}
        run.world.climbNodes = {{coord = {20, 20}, targetCoord = {60, 20}}}

        Items.add(run.player.inventory, "rabbit_pelt", 2)
        Items.add(run.player.inventory, "gut", 2)
        local ok = Survival.startCuring(run)
        TestRunner.assertTrue(ok)
        Survival.update(run, 12.0, {})
        ok = Survival.collectCuredItems(run)
        TestRunner.assertTrue(ok)
        TestRunner.assertTrue(Items.count(run.player.inventory, "cured_rabbit_pelt") >= 2)
        TestRunner.assertTrue(Items.count(run.player.inventory, "cured_gut") >= 2)

        Items.add(run.player.inventory, "cloth", 1)
        ok = Survival.craftRecipe(run, "bandage")
        TestRunner.assertTrue(ok)
        TestRunner.assertTrue(Items.count(run.player.inventory, "bandage") >= 2)

        Items.add(run.player.inventory, "sticks", 1)
        Items.add(run.player.inventory, "feather", 2)
        ok = Survival.craftRecipe(run, "arrow")
        TestRunner.assertTrue(ok)
        TestRunner.assertTrue(Items.count(run.player.inventory, "arrow") >= 2)

        local climbOk = Survival.useRopeClimb(run)
        TestRunner.assertTrue(climbOk)
        TestRunner.assertTableEqual(run.player.coord, {60, 20})

        run.player.coord = {20, 20}
        local mapOk = Survival.mapArea(run)
        TestRunner.assertTrue(mapOk)
        TestRunner.assertTrue(next(run.world.mappedTiles) ~= nil)
    end)

    it("supports trapping, fishing, bow hunting, and carcass harvesting", function()
        local run = buildRun("snow")
        run.world.rabbitZones = {{x = 1, y = 1, width = 3, height = 3}}
        run.world.fishingSpots = {{coord = {20, 20}}}
        run.world.wildlife.rabbits = {
            {kind = "rabbit", coord = {60, 20}, zone = {x = 1, y = 1, width = 3, height = 3}, speed = 20},
        }
        run.world.wildlife.deer = {
            {kind = "deer", coord = {80, 20}, zone = {x = 1, y = 1, width = 4, height = 4}, speed = 20},
        }

        Items.add(run.player.inventory, "snare", 1)
        local ok = Wildlife.placeSnare(run)
        TestRunner.assertTrue(ok)
        run.world.traps[1].hoursUntilCatch = 0
        Wildlife.update(run, 0.1)
        ok = Wildlife.collectTrap(run)
        TestRunner.assertTrue(ok)
        TestRunner.assertEqual(#run.world.carcasses, 1)

        ok = Wildlife.harvestNearbyCarcass(run)
        TestRunner.assertTrue(ok)
        TestRunner.assertTrue(Items.count(run.player.inventory, "raw_meat") >= 1)
        TestRunner.assertTrue(Items.count(run.player.inventory, "rabbit_pelt") >= 1)

        Items.add(run.player.inventory, "bow", 1)
        Items.add(run.player.inventory, "arrow", 2)
        run.player.equippedWeapon = "bow"
        run.player.lastMoveX = 1
        run.player.lastMoveY = 0
        ok = Wildlife.fireBow(run)
        TestRunner.assertTrue(ok)
        TestRunner.assertEqual(#run.world.wildlife.rabbits, 0)
        TestRunner.assertTrue(#run.world.carcasses >= 1)

        Items.add(run.player.inventory, "fishing_tackle", 1)
        run.player.skills.Fishing.level = 5
        local caught = false
        for _ = 1, 8 do
            local fishOk = Wildlife.fish(run)
            if fishOk then
                caught = true
                break
            end
        end
        TestRunner.assertTrue(caught)
    end)

    it("uses renamed experience modes and preserves extended replay context", function()
        TestRunner.assertTrue(CONFIG.DIFFICULTY_SETTINGS.pilgrim.exposureMultiplier < CONFIG.DIFFICULTY_SETTINGS.interloper.exposureMultiplier)
        TestRunner.assertTrue(CONFIG.DIFFICULTY_SETTINGS.pilgrim.lootMultiplier > CONFIG.DIFFICULTY_SETTINGS.interloper.lootMultiplier)

        Replay.init()
        Replay.startRecording(77, "interloper", {
            mode = "daily",
            isDaily = true,
            dailySeed = 77,
            player = {
                equippedTool = "hatchet",
                equippedWeapon = "bow",
            },
        })
        Replay.recordKeyState("space", true, 0.1)
        Replay.recordKeyState("space", false, 0.2)
        Replay.stopRecording()
        TestRunner.assertTrue(Replay.save("mode_context"))
        local replay = Replay.inspect("mode_context")
        TestRunner.assertEqual(replay.difficulty, "interloper")
        TestRunner.assertEqual(replay.context.player.equippedTool, "hatchet")
        TestRunner.assertEqual(replay.context.player.equippedWeapon, "bow")
    end)
end)
