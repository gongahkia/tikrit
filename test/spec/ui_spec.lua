local TestRunner = require("test_runner")
local UI = require("ui")
local Accessibility = require("accessibility")

local describe = TestRunner.describe
local it = TestRunner.it

local originalLove = _G.love

describe("UI", function()
    local printed = {}
    local rectangles = 0
    local draws = 0

    _G.love = {
        graphics = {
            setColor = function() end,
            setFont = function() end,
            print = function(text)
                table.insert(printed, tostring(text))
            end,
            rectangle = function()
                rectangles = rectangles + 1
            end,
            draw = function()
                draws = draws + 1
            end,
        },
    }

    local fonts = {
        large = {getWidth = function(_, text) return #text * 8 end},
        medium = {getWidth = function(_, text) return #text * 8 end},
        small = {getWidth = function(_, text) return #text * 8 end},
    }

    it("respects showHints on the title screen and HUD", function()
        printed = {}
        draws = 0
        local state = {
            titleItems = {{label = "Start Survival"}},
            titleIndex = 1,
        }
        local settings = {
            gameplay = {showHints = false},
            accessibility = {colorblindMode = "none", highContrast = false, slowMode = false, fontScale = 1.0, visualAlerts = true},
        }
        UI.drawTitleScreen(state, fonts, settings)
        local joined = table.concat(printed, " | ")
        TestRunner.assertFalse(joined:find("WASD move") ~= nil)

        printed = {}
        settings.gameplay.showHints = true
        UI.drawTitleScreen(state, fonts, settings)
        joined = table.concat(printed, " | ")
        TestRunner.assertTrue(joined:find("C craft, X context, H repair, T treat, M map", 1, true) ~= nil)
        TestRunner.assertTrue(joined:find("B ready bow, Space fire bow", 1, true) ~= nil)

        printed = {}
        UI.drawHUD({
            mode = "survival",
            sourceMode = "survival",
            world = {dayCount = 1, timeOfDay = 8, weather = {current = "clear"}},
            player = {
                condition = 100,
                maxCondition = 100,
                warmth = 80,
                fatigue = 70,
                thirst = 60,
                calories = 1200,
                carryWeight = 5,
                carryCapacity = 25,
                inventory = {
                    {kind = "raw_meat", quantity = 1, condition = 40},
                },
                equippedTool = "knife",
                equippedWeapon = "bow",
                equippedLight = "torch",
                afflictions = {sprain = true, infection = false, hypothermia = false, hypothermiaRisk = 0, infectionRiskHours = 0, foodPoisoningHours = 0},
                skills = {
                    FireStarting = {level = 2},
                    Cooking = {level = 1},
                    Fishing = {level = 1},
                    Harvesting = {level = 1},
                    Mending = {level = 1},
                    Archery = {level = 3},
                },
            },
            stats = {firesLit = 0, wolvesRepelled = 0},
            runtime = {
                message = "",
                interactionHint = "E scavenge supplies.",
                currentPOI = "Ranger Cabin",
                currentStation = {label = "Workbench / Curing Rack", state = "ready"},
                discoveryToast = "Frozen Lake",
                discoveryToastTimer = 1,
            },
        }, fonts, settings, {
            items = {
                loot = {},
                knife = {},
                bow = {},
                affliction = {sprain = {}},
                skills = {firestarting = {}, archery = {}},
            },
        })
        joined = table.concat(printed, " | ")
        TestRunner.assertTrue(joined:find("E scavenge supplies") ~= nil)
        TestRunner.assertTrue(joined:find("POI Ranger Cabin") ~= nil)
        TestRunner.assertTrue(joined:find("Bench/Cure", 1, true) ~= nil)
        TestRunner.assertTrue(joined:find("ready", 1, true) ~= nil)
        TestRunner.assertTrue(joined:find("Discovered Frozen Lake") ~= nil)
        TestRunner.assertTrue(joined:find("%[stale%]") ~= nil)
        TestRunner.assertTrue(draws > 0)
    end)

    it("renders text fallbacks when icons are missing", function()
        printed = {}
        draws = 0
        local settings = {
            gameplay = {showHints = false},
            accessibility = {colorblindMode = "none", highContrast = false, slowMode = false, fontScale = 1.0, visualAlerts = true},
        }
        UI.drawHUD({
            mode = "survival",
            sourceMode = "survival",
            world = {dayCount = 2, timeOfDay = 22.5, weather = {current = "wind"}},
            player = {
                condition = 72,
                maxCondition = 100,
                warmth = 18,
                fatigue = 55,
                thirst = 44,
                calories = 900,
                carryWeight = 12,
                carryCapacity = 25,
                inventory = {},
                afflictions = {sprain = false, infection = false, hypothermia = true, hypothermiaRisk = 0, infectionRiskHours = 0, foodPoisoningHours = 0},
                skills = {},
            },
            stats = {firesLit = 2, wolvesRepelled = 1},
            runtime = {message = "", interactionHint = "", currentPOI = nil, currentStation = nil, discoveryToast = "", discoveryToastTimer = 0},
        }, fonts, settings, nil)
        local joined = table.concat(printed, " | ")
        TestRunner.assertTrue(joined:find("Hypothermia") ~= nil)
        TestRunner.assertEqual(draws, 0)
    end)

    it("draws visual alerts only when enabled", function()
        rectangles = 0
        local settings = {
            accessibility = {colorblindMode = "none", highContrast = false, slowMode = false, fontScale = 1.0, visualAlerts = false},
        }
        Accessibility.drawVisualAlerts(settings, {wolfThreat = 1}, 1)
        TestRunner.assertEqual(rectangles, 0)

        settings.accessibility.visualAlerts = true
        Accessibility.drawVisualAlerts(settings, {wolfThreat = 1, blizzard = 0.5}, 1)
        TestRunner.assertTrue(rectangles > 0)
    end)
end)

_G.love = originalLove
