local TestRunner = require("test_runner")

local describe = TestRunner.describe
local it = TestRunner.it

local originalLove = _G.love
local files = {}
local directories = {}

_G.love = {
    filesystem = {
        createDirectory = function(path)
            directories[path] = true
        end,
        getDirectoryItems = function(path)
            local items = {}
            for filePath in pairs(files) do
                local item = filePath:match("^" .. path .. "/(.+)$")
                if item then
                    table.insert(items, item)
                end
            end
            table.sort(items)
            return items
        end,
        read = function(path)
            return files[path]
        end,
        write = function(path, contents)
            files[path] = contents
            return true
        end,
        getInfo = function(path)
            if directories[path] or files[path] then
                return {type = directories[path] and "directory" or "file"}
            end
            return nil
        end,
    },
}

package.loaded["replay"] = nil
local Replay = require("replay")

describe("Replay", function()
    it("records and inspects survival replay context", function()
        Replay.init()
        Replay.startRecording(12345, "hard", {
            mode = "survival",
            isDaily = false,
            weather = {current = "snow"},
            timeOfDay = 12,
            player = {carryCapacity = 25},
        })
        Replay.recordKeyState("w", true, 0.1)
        Replay.recordKeyState("w", false, 0.6)
        Replay.stopRecording()
        TestRunner.assertTrue(Replay.save("spec_run"))

        local replay = Replay.inspect("spec_run")
        TestRunner.assertEqual(replay.version, "3.0")
        TestRunner.assertEqual(replay.difficulty, "stalker")
        TestRunner.assertEqual(replay.context.mode, "survival")
        TestRunner.assertEqual(replay.context.weather.current, "snow")
        TestRunner.assertEqual(replay.context.player.carryCapacity, 25)
    end)

    it("round-trips daily replay metadata", function()
        Replay.init()
        Replay.startRecording(20260325, "normal", {
            mode = "daily",
            isDaily = true,
            dailySeed = 20260325,
            weather = {current = "wind"},
        })
        Replay.recordKeyState("r", true, 0.2)
        Replay.recordKeyState("r", false, 0.4)
        Replay.stopRecording()
        TestRunner.assertTrue(Replay.save("daily_run"))

        local replay = Replay.inspect("daily_run")
        TestRunner.assertEqual(replay.difficulty, "voyageur")
        TestRunner.assertEqual(replay.context.mode, "daily")
        TestRunner.assertTrue(replay.context.isDaily)
        TestRunner.assertEqual(replay.context.dailySeed, 20260325)

        TestRunner.assertTrue(Replay.load("daily_run"))
        TestRunner.assertTrue(Replay.startPlayback())
        Replay.update(0.2)
        local first = Replay.getNextInput()
        TestRunner.assertEqual(first.key, "r")
    end)

    it("plays back key state changes in timestamp order", function()
        Replay.init()
        Replay.startRecording(7, "voyageur")
        Replay.recordKeyState("f", true, 0.1)
        Replay.recordKeyState("f", false, 0.2)
        Replay.stopRecording()
        Replay.save("timing")

        TestRunner.assertTrue(Replay.load("timing"))
        TestRunner.assertTrue(Replay.startPlayback())

        Replay.update(0.1)
        local first = Replay.getNextInput()
        TestRunner.assertEqual(first.type, "keydown")
        TestRunner.assertEqual(first.key, "f")

        Replay.update(0.1)
        local second = Replay.getNextInput()
        TestRunner.assertEqual(second.type, "keyup")
        TestRunner.assertEqual(second.key, "f")
    end)

    it("loads legacy difficulty aliases as canonical names", function()
        Replay.init()
        files["replays/legacy_alias.txt"] = table.concat({
            "VERSION:3.0",
            "SEED:42",
            "DIFFICULTY:normal",
            "DATE:2026-03-25 09:00:00",
            "DURATION:1.0",
            "TOTAL_INPUTS:1",
            "CONTEXT:mode=survival",
            "INPUTS:",
            "keydown|e|0.1000",
        }, "\n")

        local replay = Replay.inspect("legacy_alias.txt")
        TestRunner.assertEqual(replay.difficulty, "voyageur")
    end)
end)

_G.love = originalLove
