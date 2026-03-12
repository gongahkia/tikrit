local TestRunner = require("test_runner")

local describe = TestRunner.describe
local it = TestRunner.it

local function makeParticleSystem()
    local particle = {
        count = 0,
        setParticleLifetime = function() end,
        setLinearAcceleration = function() end,
        setColors = function() end,
        emit = function(self, amount)
            self.count = amount or 0
        end,
        getBufferSize = function()
            return 8
        end,
        update = function(self)
            self.count = 0
        end,
        getCount = function(self)
            return self.count
        end,
    }

    function particle:clone()
        return makeParticleSystem()
    end

    return particle
end

describe("Runtime Smoke", function()
    it("loads the game callbacks and runs the supported flow headlessly", function()
        local originalLove = _G.love
        local ok, err = pcall(function()
            local files = {}
            local directories = {}
            local currentTime = 0
            local currentFont = nil

            local function makeSource()
                return {
                    playing = false,
                    setVolume = function() end,
                    setLooping = function() end,
                    isPlaying = function(self)
                        return self.playing
                    end,
                }
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
                    newImage = function()
                        return {
                            getWidth = function()
                                return 20
                            end,
                            getHeight = function()
                                return 20
                            end,
                        }
                    end,
                    newParticleSystem = function()
                        return makeParticleSystem()
                    end,
                    setColor = function() end,
                    print = function() end,
                    rectangle = function() end,
                    circle = function() end,
                    draw = function() end,
                    push = function() end,
                    pop = function() end,
                    translate = function() end,
                    scale = function() end,
                    clear = function() end,
                    line = function() end,
                },
                image = {
                    newImageData = function()
                        return {
                            setPixel = function() end,
                        }
                    end,
                },
                audio = {
                    newSource = function()
                        return makeSource()
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
                timer = {
                    getTime = function()
                        return currentTime
                    end,
                    getFPS = function()
                        return 60
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
            require("main")

            TestRunner.assertType(love.load, "function")
            love.load()

            love.keypressed("return")
            currentTime = currentTime + 0.2
            love.update(0.2)

            love.keypressed("escape")
            love.keypressed("down")
            love.keypressed("down")
            love.keypressed("return")
            TestRunner.assertTrue(next(files) ~= nil)

            love.keypressed("down")
            love.keypressed("down")
            love.keypressed("return")

            for _ = 1, 6 do
                love.keypressed("down")
            end
            love.keypressed("return")
            love.keypressed("return")
            currentTime = currentTime + 0.3
            love.update(0.3)
            love.keypressed("escape")

            love.keypressed("f3")
            love.keypressed("f5")
            love.wheelmoved(0, 1)
            love.keypressed("escape")
        end)
        _G.love = originalLove

        if not ok then
            error(err, 0)
        end
    end)
end)
