local TestRunner = require("test_runner")

local describe = TestRunner.describe
local it = TestRunner.it

local function buildEditorLayout()
    local rows = {}
    for y = 1, 30 do
        rows[y] = {}
        for x = 1, 30 do
            rows[y][x] = "."
        end
    end

    for x = 1, 30 do
        rows[1][x] = "#"
        rows[30][x] = "#"
    end
    for y = 1, 30 do
        rows[y][1] = "#"
        rows[y][30] = "#"
    end

    for y = 4, 8 do
        for x = 4, 9 do
            rows[y][x] = "C"
        end
    end
    for y = 3, 7 do
        for x = 14, 19 do
            rows[y][x] = "C"
        end
    end
    rows[6][6] = "@"
    rows[9][7] = "H"
    rows[10][10] = "O"
    rows[18][22] = "K"
    rows[22][8] = "R"
    rows[24][22] = "D"
    rows[15][14] = "W"
    rows[16][15] = "W"
    rows[6][8] = "B"
    rows[18][12] = "B"
    rows[12][14] = "I"
    rows[5][12] = "M"
    rows[7][13] = "P"
    rows[9][9] = "Q"

    local lines = {}
    for y = 1, 30 do
        lines[y] = table.concat(rows[y])
    end
    return {lines = lines, filename = "smoke_layout.txt"}
end

describe("Runtime Smoke", function()
    it("starts an editor playtest, triggers door audio, visual alerts, and screen shake gating", function()
        local originalLove = _G.love
        local ok, err = pcall(function()
            local files = {}
            local directories = {}
            local sources = {}
            local printed = {}
            local currentTime = 0
            local currentFont = nil
            local rectangleCalls = 0
            local run

            local function countEvent(events, target)
                local total = 0
                for _, eventId in ipairs(events or {}) do
                    if eventId == target then
                        total = total + 1
                    end
                end
                return total
            end

            local function countKeys(map)
                local total = 0
                for _ in pairs(map or {}) do
                    total = total + 1
                end
                return total
            end

            local function tileAt(coord)
                local gx = math.floor(coord[1] / 20) + 1
                local gy = math.floor(coord[2] / 20) + 1
                return ((run.world.grid[gy] or {})[gx])
            end

            local function makeSource(path)
                local source = {
                    path = path,
                    playing = false,
                    plays = 0,
                    setVolume = function() end,
                    setLooping = function() end,
                    isPlaying = function(self)
                        return self.playing
                    end,
                }
                sources[path] = source
                return source
            end

            _G.love = {
                window = {
                    setTitle = function() end,
                    setMode = function() end,
                },
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
                graphics = {
                    newFont = function(_, size)
                        return {
                            size = size,
                            getWidth = function(_, text)
                                return #tostring(text) * math.max(8, math.floor(size / 3))
                            end,
                        }
                    end,
                    setFont = function(font)
                        currentFont = font
                    end,
                    getFont = function()
                        return currentFont
                    end,
                    newImage = function(path)
                        return {
                            path = path,
                            getWidth = function() return 20 end,
                            getHeight = function() return 20 end,
                        }
                    end,
                    setColor = function() end,
                    print = function(text)
                        table.insert(printed, tostring(text))
                    end,
                    rectangle = function()
                        rectangleCalls = rectangleCalls + 1
                    end,
                    circle = function() end,
                    draw = function() end,
                    push = function() end,
                    pop = function() end,
                    translate = function() end,
                    scale = function() end,
                    clear = function() end,
                    line = function() end,
                    polygon = function() end,
                },
                audio = {
                    newSource = function(path)
                        return makeSource(path)
                    end,
                    play = function(source)
                        if source then
                            source.playing = true
                            source.plays = source.plays + 1
                        end
                    end,
                    stop = function(source)
                        if source then
                            source.playing = false
                        end
                    end,
                },
                timer = {
                    getTime = function()
                        return currentTime
                    end,
                },
                keyboard = {
                    isDown = function()
                        return false
                    end,
                },
                mouse = {
                    getPosition = function()
                        return 0, 0
                    end,
                    isDown = function()
                        return false
                    end,
                },
                event = {
                    quit = function() end,
                },
            }

            package.loaded["main"] = nil
            package.loaded["modules/editor"] = nil
            package.loaded["modules/effects"] = nil
            require("main")
            local Editor = require("modules/editor")
            local Effects = require("modules/effects")
            local Items = require("modules/items")
            local SoundEvents = require("modules/sound_events")
            love.load()

            love.keypressed("f5")
            Editor.setLayout(buildEditorLayout())
            love.keypressed("f6")

            local state = love._tikritDebug.getGameState()
            run = state.run
            TestRunner.assertType(run, "table")
            TestRunner.assertEqual(run.world.source, "editor")
            TestRunner.assertEqual(countKeys(run.world.discoveredPOIs), 1)
            TestRunner.assertTrue(run.runtime.currentPOI == "Editor Cabin 1" or run.runtime.currentPOI == "Editor Cabin 2")
            local startPOI = run.runtime.currentPOI
            local remotePOI = startPOI == "Editor Cabin 1" and "Editor Cabin 2" or "Editor Cabin 1"
            local standaloneStation
            for _, station in ipairs(run.runtime.stations or {}) do
                if tileAt(station.coord) ~= "cabin_workbench" then
                    standaloneStation = station
                    break
                end
            end
            TestRunner.assertType(standaloneStation, "table")

            printed = {}
            love.draw()
            local initialDraw = table.concat(printed, " | ")
            TestRunner.assertTrue(initialDraw:find(startPOI, 1, true) ~= nil)
            TestRunner.assertTrue(initialDraw:find(remotePOI, 1, true) == nil)
            local initialPoiEvents = countEvent(SoundEvents.getEventLog(), "poi_discovery")
            currentTime = currentTime + 0.1
            love.update(0.1)
            TestRunner.assertEqual(countEvent(SoundEvents.getEventLog(), "poi_discovery"), initialPoiEvents)

            run.player.coord = {(run.world.structures[1].door.x - 1) * 20, (run.world.structures[1].door.y - 1) * 20}
            currentTime = currentTime + 0.1
            love.update(0.1)
            TestRunner.assertTrue((sources["sound/door-open.mp3"] or {}).plays > 0)

            run.player.coord = {220, 220}
            run.player.lastSafeCoord = {220, 220}
            run.player.warmth = 12
            run.world.weather.current = "blizzard"
            currentTime = currentTime + 0.1
            love.update(0.1)
            TestRunner.assertTrue(run.runtime.alerts.blizzard > 0 or run.runtime.alerts.fireRisk > 0)

            state.settings.gameplay.screenShake = false
            Effects.init()
            love.keypressed("f")
            TestRunner.assertFalse(Effects.screenShake.active)

            state.settings.gameplay.screenShake = true
            love.keypressed("f")
            TestRunner.assertTrue(Effects.screenShake.active)

            run.player.coord = {standaloneStation.coord[1], standaloneStation.coord[2]}
            currentTime = currentTime + 0.1
            love.update(0.1)
            TestRunner.assertEqual(run.runtime.currentStation.label, "Workbench / Curing Rack")
            TestRunner.assertEqual(run.runtime.currentStation.state, "idle")
            TestRunner.assertTrue(run.runtime.interactionHint:find("C craft at the Workbench / Curing Rack", 1, true) ~= nil)
            TestRunner.assertTrue(run.runtime.interactionHint:find("X hang fresh hides or gut to cure", 1, true) ~= nil)

            run.player.coord = {run.world.workbenches[1].coord[1], run.world.workbenches[1].coord[2]}
            Items.add(run.player.inventory, "cloth", 1)
            Items.add(run.player.inventory, "cured_gut", 2)
            Items.add(run.player.inventory, "sticks", 1)
            Items.add(run.player.inventory, "feather", 2)
            local bandagesBefore = Items.count(run.player.inventory, "bandage")
            love.keypressed("c")
            love.keypressed("return")
            TestRunner.assertTrue(Items.count(run.player.inventory, "bandage") > bandagesBefore)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "craft") > 0)
            love.keypressed("c")

            run.player.afflictions.infectionRiskHours = 6
            Items.add(run.player.inventory, "antiseptic", 1)
            love.keypressed("t")
            TestRunner.assertEqual(run.player.afflictions.infectionRiskHours, 0)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "treat") > 0)

            run.player.coord = {140, 440}
            Items.add(run.player.inventory, "snare", 1)
            love.keypressed("x")
            TestRunner.assertEqual(#run.world.traps, 1)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "snare_set") > 0)
            run.world.traps[1].state = "caught"
            local meatBefore = Items.count(run.player.inventory, "raw_meat")
            love.keypressed("e")
            love.keypressed("e")
            TestRunner.assertTrue(Items.count(run.player.inventory, "raw_meat") > meatBefore)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "snare_catch") > 0)

            run.player.coord = {run.world.mapNodes[1].coord[1], run.world.mapNodes[1].coord[2]}
            Items.add(run.player.inventory, "charcoal", 1)
            local discoveredBeforeMap = countKeys(run.world.discoveredPOIs)
            love.keypressed("m")
            TestRunner.assertTrue(next(run.world.mappedTiles) ~= nil)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "map_reveal") > 0)
            TestRunner.assertTrue(countKeys(run.world.discoveredPOIs) >= discoveredBeforeMap)

            printed = {}
            love.draw()
            local mappedDraw = table.concat(printed, " | ")
            TestRunner.assertTrue(mappedDraw:find(remotePOI, 1, true) ~= nil)

            run.player.coord = {run.world.structures[1].bed.x * 20 - 20, run.world.structures[1].bed.y * 20 - 20}
            run.world.timeOfDay = 23.5
            love.keypressed("r")
            TestRunner.assertTrue(run.world.dayCount >= 2)

            run.player.coord = {standaloneStation.coord[1], standaloneStation.coord[2]}
            Items.add(run.player.inventory, "rabbit_pelt", 1)
            currentTime = currentTime + 0.1
            love.update(0.1)
            love.keypressed("x")
            currentTime = currentTime + 0.1
            love.update(0.1)
            TestRunner.assertEqual(run.runtime.currentStation.state, "curing")
            TestRunner.assertTrue(run.runtime.interactionHint:find("X hang fresh hides or gut to cure", 1, true) ~= nil)
            for _, curing in ipairs(run.world.curing) do
                curing.hoursRemaining = 0.05
            end
            currentTime = currentTime + 1.0
            love.update(1.0)
            TestRunner.assertEqual(run.runtime.currentStation.state, "ready")
            TestRunner.assertTrue(run.runtime.interactionHint:find("E collect cured items", 1, true) ~= nil)
            love.keypressed("e")
            currentTime = currentTime + 0.1
            love.update(0.1)
            TestRunner.assertEqual(run.runtime.currentStation.state, "idle")
            TestRunner.assertEqual(#run.world.curing, 0)

            run.player.coord = {100, 100}
            run.player.lastMoveX = 1
            run.player.lastMoveY = 0
            table.insert(run.world.wildlife.rabbits, {coord = {160, 100}, kind = "rabbit"})
            Items.add(run.player.inventory, "bow", 1)
            Items.add(run.player.inventory, "arrow", 1)
            love.keypressed("b")
            love.keypressed("space")
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "bow_ready") > 0)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "bow_fire") > 0)
            TestRunner.assertTrue(countEvent(SoundEvents.getEventLog(), "arrow_hit") > 0)

            run.world.weather.current = "clear"
            run.player.warmth = 90
            currentTime = currentTime + 2.6
            love.update(2.6)
            TestRunner.assertEqual(run.runtime.discoveryToast, "")

            rectangleCalls = 0
            love.draw()
            TestRunner.assertTrue(rectangleCalls > 0)
        end)
        _G.love = originalLove
        if not ok then
            error(err, 0)
        end
    end)
end)
