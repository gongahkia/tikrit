local TestRunner = require("test_runner")

local describe = TestRunner.describe
local it = TestRunner.it

local originalLove = _G.love

describe("Sound Events", function()
    it("logs missing events without crashing", function()
        local sources = {}
        _G.love = {
            audio = {
                newSource = function(path)
                    if path == "sound/bow-fire.mp3" then
                        error("missing")
                    end
                    local source = {
                        path = path,
                        playing = false,
                        setLooping = function() end,
                        setVolume = function() end,
                        isPlaying = function(self)
                            return self.playing
                        end,
                    }
                    sources[path] = source
                    return source
                end,
                play = function(source)
                    if source then
                        source.playing = true
                    end
                end,
                stop = function(source)
                    if source then
                        source.playing = false
                    end
                end,
            },
        }

        package.loaded["sound_events"] = nil
        package.loaded["modules/sound_events"] = nil
        local SoundEvents = require("sound_events")
        SoundEvents.init()
        SoundEvents.load()
        SoundEvents.clearEventLog()

        TestRunner.assertFalse(SoundEvents.play("bow_fire"))
        local log = SoundEvents.getEventLog()
        TestRunner.assertEqual(log[#log], "bow_fire")
    end)

    it("switches weather loops cleanly", function()
        local sources = {}
        _G.love = {
            audio = {
                newSource = function(path)
                    local source = {
                        path = path,
                        playing = false,
                        setLooping = function() end,
                        setVolume = function() end,
                        isPlaying = function(self)
                            return self.playing
                        end,
                    }
                    sources[path] = source
                    return source
                end,
                play = function(source)
                    if source then
                        source.playing = true
                    end
                end,
                stop = function(source)
                    if source then
                        source.playing = false
                    end
                end,
            },
        }

        package.loaded["sound_events"] = nil
        package.loaded["modules/sound_events"] = nil
        local SoundEvents = require("sound_events")
        SoundEvents.init()
        SoundEvents.load()

        SoundEvents.updateWeather("wind")
        TestRunner.assertTrue((sources["sound/weather-wind-loop.mp3"] or {}).playing)
        TestRunner.assertFalse((sources["sound/weather-blizzard-loop.mp3"] or {}).playing == true)

        SoundEvents.updateWeather("blizzard")
        TestRunner.assertFalse((sources["sound/weather-wind-loop.mp3"] or {}).playing)
        TestRunner.assertTrue((sources["sound/weather-blizzard-loop.mp3"] or {}).playing)

        SoundEvents.updateWeather("clear")
        TestRunner.assertFalse((sources["sound/weather-wind-loop.mp3"] or {}).playing)
        TestRunner.assertFalse((sources["sound/weather-blizzard-loop.mp3"] or {}).playing)
    end)
end)

_G.love = originalLove
