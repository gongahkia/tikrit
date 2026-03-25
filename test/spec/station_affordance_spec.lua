local TestRunner = require("test_runner")
local SpriteRegistry = require("sprite_registry")

local describe = TestRunner.describe
local it = TestRunner.it

local originalLove = _G.love

describe("Station Affordances", function()
    it("draws merged stations once and distinguishes ready vs curing overlays", function()
        local drawCalls = 0
        local rectangleCalls = {fill = 0, line = 0}
        local circleCalls = 0
        local lineCalls = 0

        _G.love = {
            graphics = {
                setColor = function() end,
                newImage = function() end,
                draw = function()
                    drawCalls = drawCalls + 1
                end,
                rectangle = function(mode)
                    rectangleCalls[mode] = (rectangleCalls[mode] or 0) + 1
                end,
                circle = function()
                    circleCalls = circleCalls + 1
                end,
                line = function()
                    lineCalls = lineCalls + 1
                end,
            },
        }

        local bundle = {
            world = {
                workbench = {},
            },
        }
        local settings = {
            accessibility = {
                colorblindMode = "none",
                highContrast = false,
                slowMode = false,
                fontScale = 1.0,
                visualAlerts = true,
            },
        }

        SpriteRegistry.drawStation(bundle, {
            coord = {40, 60},
            hasWorkbench = true,
            hasCuring = true,
            state = "ready",
            overlayOnly = false,
        }, settings)
        TestRunner.assertEqual(drawCalls, 1)
        TestRunner.assertTrue(rectangleCalls.fill > 0)
        TestRunner.assertTrue(lineCalls > 0)

        drawCalls = 0
        rectangleCalls = {fill = 0, line = 0}
        circleCalls = 0
        lineCalls = 0

        SpriteRegistry.drawStation(bundle, {
            coord = {40, 60},
            hasWorkbench = true,
            hasCuring = true,
            state = "curing",
            overlayOnly = true,
        }, settings)
        TestRunner.assertEqual(drawCalls, 0)
        TestRunner.assertTrue(circleCalls > 0)
        TestRunner.assertTrue(lineCalls > 0)
        TestRunner.assertEqual(rectangleCalls.fill, 0)
    end)
end)

_G.love = originalLove
