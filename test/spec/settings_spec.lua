local TestRunner = require("test_runner")
local Settings = require("settings")

local describe = TestRunner.describe
local it = TestRunner.it

describe("Settings", function()
    it("resets to defaults and supports get/set", function()
        os.remove("settings.txt")
        Settings.resetDefaults()
        TestRunner.assertEqual(Settings.get("audio.master"), 0.7)
        Settings.set("audio.master", 0.4)
        TestRunner.assertEqual(Settings.get("audio.master"), 0.4)
    end)

    it("saves and loads settings from disk", function()
        os.remove("settings.txt")
        Settings.resetDefaults()
        Settings.set("gameplay.minimap", true)
        Settings.set("accessibility.colorblindMode", "deuteranopia")
        TestRunner.assertTrue(Settings.save())

        Settings.resetDefaults()
        TestRunner.assertFalse(Settings.get("gameplay.minimap"))
        Settings.load()
        TestRunner.assertTrue(Settings.get("gameplay.minimap"))
        TestRunner.assertEqual(Settings.get("accessibility.colorblindMode"), "deuteranopia")
        os.remove("settings.txt")
    end)
end)
