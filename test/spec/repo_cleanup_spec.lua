local TestRunner = require("test_runner")

local describe = TestRunner.describe
local it = TestRunner.it

local function readFile(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end
    local contents = handle:read("*all")
    handle:close()
    return contents
end

describe("Repo Cleanup", function()
    it("no longer references removed horror modules or deleted sound assets", function()
        local mainContents = readFile("src/main.lua")
        local uiContents = readFile("src/modules/ui.lua")
        local allContents = (mainContents or "") .. "\n" .. (uiContents or "")

        TestRunner.assertTrue(not allContents:find("modules/ai", 1, true))
        TestRunner.assertTrue(not allContents:find("modules/sanity", 1, true))
        TestRunner.assertTrue(not allContents:find("ghost%-scream", 1))
        TestRunner.assertTrue(not allContents:find("player%-collect%-key", 1))
        TestRunner.assertTrue(not allContents:find("player%-equip", 1))
        TestRunner.assertTrue(not allContents:find("player%-lose%-screen", 1))
        TestRunner.assertTrue((mainContents or ""):find("SoundEvents", 1, true) ~= nil)
    end)

    it("ships placeholder sprite slots for the added survival mechanics", function()
        local expected = {
            "src/sprite/item-bow.png",
            "src/sprite/item-arrow.png",
            "src/sprite/item-knife.png",
            "src/sprite/item-hatchet.png",
            "src/sprite/item-snare.png",
            "src/sprite/item-fishing-tackle.png",
            "src/sprite/item-bandage.png",
            "src/sprite/item-antiseptic.png",
            "src/sprite/item-antibiotics.png",
            "src/sprite/item-painkillers.png",
            "src/sprite/item-charcoal.png",
            "src/sprite/world-fishing-hole.png",
            "src/sprite/world-rope-climb.png",
            "src/sprite/world-workbench.png",
            "src/sprite/world-map-node.png",
            "src/sprite/world-snare.png",
            "src/sprite/world-rabbit-carcass.png",
            "src/sprite/world-deer-carcass.png",
            "src/sprite/world-fish-carcass.png",
            "src/sprite/ui-affliction-hypothermia.png",
            "src/sprite/ui-affliction-sprain.png",
            "src/sprite/ui-affliction-infection.png",
            "src/sprite/ui-affliction-food-poisoning.png",
            "src/sprite/ui-skill-archery.png",
            "src/sprite/ui-skill-cooking.png",
            "src/sprite/ui-skill-fishing.png",
            "src/sprite/ui-skill-harvesting.png",
            "src/sprite/ui-skill-firestarting.png",
            "src/sprite/ui-skill-mending.png",
        }

        for _, path in ipairs(expected) do
            local handle = io.open(path, "rb")
            TestRunner.assertTrue(handle ~= nil, "Missing placeholder asset: " .. path)
            if handle then
                handle:close()
            end
        end
    end)

    it("documents the audio event manifest for missing sound assets", function()
        local manifest = readFile("docs/audio_manifest.md")
        TestRunner.assertTrue(manifest ~= nil)
        TestRunner.assertTrue(manifest:find("bow_fire", 1, true) ~= nil)
        TestRunner.assertTrue(manifest:find("weather_blizzard_loop", 1, true) ~= nil)
    end)
end)
