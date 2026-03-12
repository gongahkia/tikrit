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
    it("records, saves, and inspects replay context", function()
        Replay.init()
        Replay.startRecording(12345, "hard", {
            fogEnabled = true,
            player = {
                speedBonus = 80,
            },
        })
        Replay.recordKeyState("w", true, 0.1)
        Replay.recordKeyState("w", false, 0.6)
        Replay.stopRecording()

        TestRunner.assertTrue(Replay.save("spec_run"))

        local replay = Replay.inspect("spec_run")
        TestRunner.assertEqual(replay.seed, 12345)
        TestRunner.assertEqual(replay.difficulty, "hard")
        TestRunner.assertTrue(replay.context.fogEnabled)
        TestRunner.assertEqual(replay.context.player.speedBonus, 80)
        TestRunner.assertEqual(#Replay.listReplays(), 1)
    end)

    it("plays back recorded key state changes in timestamp order", function()
        Replay.init()
        Replay.startRecording(7, "normal")
        Replay.recordKeyState("space", true, 0.1)
        Replay.recordKeyState("space", false, 0.2)
        Replay.stopRecording()
        Replay.save("timing")

        TestRunner.assertTrue(Replay.load("timing"))
        local ok = Replay.startPlayback()
        TestRunner.assertTrue(ok)

        Replay.update(0.1)
        local first = Replay.getNextInput()
        TestRunner.assertEqual(first.type, "keydown")
        TestRunner.assertEqual(first.key, "space")

        Replay.update(0.1)
        local second = Replay.getNextInput()
        TestRunner.assertEqual(second.type, "keyup")
        TestRunner.assertEqual(second.key, "space")
    end)
end)

_G.love = originalLove
