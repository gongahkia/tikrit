local CONFIG = require("config")

local Replay = {}

local FILE_VERSION = "3.0"
local REPLAY_DIR = "replays"

local recording = false
local playing = false
local playbackIndex = 1
local playbackTime = 0
local currentRecordingTime = 0

local function normalizeDifficulty(difficulty)
    if not difficulty or difficulty == "" then
        return "voyageur"
    end
    return CONFIG.DIFFICULTY_ALIASES[difficulty] or difficulty
end

local function newReplayData(seed, difficulty)
    return {
        version = FILE_VERSION,
        seed = seed,
        difficulty = normalizeDifficulty(difficulty),
        context = {},
        inputs = {},
        metadata = {
            recordingDate = os.date("%Y-%m-%d %H:%M:%S"),
            duration = 0,
            totalInputs = 0,
        },
    }
end

local replayData = newReplayData(nil, nil)

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, innerValue in pairs(value) do
        copy[deepCopy(key)] = deepCopy(innerValue)
    end
    return copy
end

local function getFilesystem()
    if love and love.filesystem then
        return {
            createDirectory = function(path)
                love.filesystem.createDirectory(path)
            end,
            getDirectoryItems = function(path)
                return love.filesystem.getDirectoryItems(path)
            end,
            read = function(path)
                return love.filesystem.read(path)
            end,
            write = function(path, contents)
                return love.filesystem.write(path, contents)
            end,
        }
    end

    return {
        createDirectory = function(path)
            os.execute(string.format('mkdir -p "%s"', path))
        end,
        getDirectoryItems = function(path)
            local items = {}
            local handle = io.popen(string.format('ls -1 "%s" 2>/dev/null', path))
            if not handle then
                return items
            end
            for line in handle:lines() do
                table.insert(items, line)
            end
            handle:close()
            return items
        end,
        read = function(path)
            local handle = io.open(path, "r")
            if not handle then
                return nil
            end
            local contents = handle:read("*all")
            handle:close()
            return contents
        end,
        write = function(path, contents)
            local handle = io.open(path, "w")
            if not handle then
                return false
            end
            handle:write(contents)
            handle:close()
            return true
        end,
    }
end

local function normalizeFilename(filename)
    filename = filename or string.format("replay_%s.txt", os.date("%Y%m%d_%H%M%S"))
    if not filename:match("%.txt$") then
        filename = filename .. ".txt"
    end
    return filename
end

local function serialize(data)
    local lines = {
        "VERSION:" .. tostring(data.version),
        "SEED:" .. tostring(data.seed or ""),
        "DIFFICULTY:" .. tostring(normalizeDifficulty(data.difficulty)),
        "DATE:" .. tostring(data.metadata.recordingDate or ""),
        "DURATION:" .. tostring(data.metadata.duration or 0),
        "TOTAL_INPUTS:" .. tostring(data.metadata.totalInputs or #data.inputs),
    }

    local function flatten(prefix, value)
        if type(value) ~= "table" then
            table.insert(lines, string.format("CONTEXT:%s=%s", prefix, tostring(value)))
            return
        end
        for key, innerValue in pairs(value) do
            local nextPrefix = prefix ~= "" and (prefix .. "." .. key) or key
            flatten(nextPrefix, innerValue)
        end
    end

    flatten("", data.context or {})
    table.insert(lines, "INPUTS:")
    for _, input in ipairs(data.inputs or {}) do
        table.insert(lines, string.format("%s|%s|%.4f", input.type, input.key, input.timestamp))
    end
    return table.concat(lines, "\n")
end

local function deserialize(contents)
    if not contents or contents == "" then
        return nil
    end

    local replay = newReplayData(nil, "voyageur")
    local parsingInputs = false

    local function coerce(value)
        if value == "true" then
            return true
        elseif value == "false" then
            return false
        end
        return tonumber(value) or value
    end

    local function assignContext(path, value)
        local current = replay.context
        local parts = {}
        for part in path:gmatch("[^%.]+") do
            table.insert(parts, part)
        end
        for index = 1, #parts - 1 do
            local part = parts[index]
            if type(current[part]) ~= "table" then
                current[part] = {}
            end
            current = current[part]
        end
        current[parts[#parts]] = coerce(value)
    end

    for line in contents:gmatch("[^\r\n]+") do
        if line == "INPUTS:" then
            parsingInputs = true
        elseif parsingInputs then
            local inputType, key, timestamp = line:match("([^|]+)|([^|]+)|([%d%.%-]+)")
            if inputType and key and timestamp then
                table.insert(replay.inputs, {
                    type = inputType,
                    key = key,
                    timestamp = tonumber(timestamp) or 0,
                })
            end
        else
            local key, value = line:match("([^:]+):(.*)")
            if key == "VERSION" then
                replay.version = value
            elseif key == "SEED" then
                replay.seed = tonumber(value) or value
            elseif key == "DIFFICULTY" then
                replay.difficulty = normalizeDifficulty(value)
            elseif key == "DATE" then
                replay.metadata.recordingDate = value
            elseif key == "DURATION" then
                replay.metadata.duration = tonumber(value) or 0
            elseif key == "TOTAL_INPUTS" then
                replay.metadata.totalInputs = tonumber(value) or 0
            elseif key == "CONTEXT" then
                local path, rawValue = value:match("^([%w%.]+)=(.+)$")
                if path and rawValue then
                    assignContext(path, rawValue)
                end
            end
        end
    end

    replay.metadata.totalInputs = replay.metadata.totalInputs or #replay.inputs
    return replay
end

function Replay.init()
    getFilesystem().createDirectory(REPLAY_DIR)
    replayData = newReplayData(nil, nil)
    recording = false
    playing = false
    playbackIndex = 1
    playbackTime = 0
    currentRecordingTime = 0
end

function Replay.startRecording(seed, difficulty, context)
    replayData = newReplayData(seed, difficulty)
    replayData.context = deepCopy(context or {})
    recording = true
    playing = false
    playbackIndex = 1
    playbackTime = 0
    currentRecordingTime = 0
end

function Replay.stopRecording()
    if not recording then
        return
    end
    replayData.metadata.duration = currentRecordingTime
    replayData.metadata.totalInputs = #replayData.inputs
    recording = false
end

function Replay.recordInput(inputType, key, timestamp)
    if not recording then
        return
    end
    table.insert(replayData.inputs, {
        type = inputType,
        key = key,
        timestamp = timestamp or currentRecordingTime,
    })
end

function Replay.recordKeyState(key, isDown, timestamp)
    Replay.recordInput(isDown and "keydown" or "keyup", key, timestamp)
end

function Replay.update(dt)
    if recording then
        currentRecordingTime = currentRecordingTime + dt
    elseif playing then
        playbackTime = playbackTime + dt
    end
end

function Replay.save(filename)
    if not replayData or #replayData.inputs == 0 then
        return false
    end
    local fs = getFilesystem()
    fs.createDirectory(REPLAY_DIR)
    replayData.metadata.duration = currentRecordingTime > 0 and currentRecordingTime or replayData.metadata.duration
    replayData.metadata.totalInputs = #replayData.inputs
    return fs.write(REPLAY_DIR .. "/" .. normalizeFilename(filename), serialize(replayData))
end

function Replay.load(filename)
    local contents = getFilesystem().read(REPLAY_DIR .. "/" .. normalizeFilename(filename))
    local parsed = deserialize(contents)
    if not parsed then
        return false
    end
    replayData = parsed
    recording = false
    playing = false
    playbackIndex = 1
    playbackTime = 0
    return true
end

function Replay.inspect(filename)
    return deserialize(getFilesystem().read(REPLAY_DIR .. "/" .. normalizeFilename(filename)))
end

function Replay.startPlayback()
    if not replayData or #replayData.inputs == 0 then
        return false
    end
    playing = true
    recording = false
    playbackIndex = 1
    playbackTime = 0
    return true
end

function Replay.stopPlayback()
    playing = false
    playbackIndex = 1
    playbackTime = 0
end

function Replay.getNextInput()
    if not playing or playbackIndex > #replayData.inputs then
        return nil
    end
    local input = replayData.inputs[playbackIndex]
    if playbackTime >= input.timestamp then
        playbackIndex = playbackIndex + 1
        if playbackIndex > #replayData.inputs then
            playing = false
        end
        return input
    end
    return nil
end

function Replay.isRecording()
    return recording
end

function Replay.isPlaying()
    return playing
end

function Replay.hasData()
    return replayData ~= nil and #replayData.inputs > 0
end

function Replay.getPlaybackProgress()
    local duration = replayData.metadata.duration or 0
    if duration <= 0 then
        return 0
    end
    return math.min(1, playbackTime / duration)
end

function Replay.listReplays()
    local items = {}
    for _, file in ipairs(getFilesystem().getDirectoryItems(REPLAY_DIR)) do
        if file:match("%.txt$") then
            table.insert(items, file)
        end
    end
    table.sort(items, function(left, right)
        return left > right
    end)
    return items
end

return Replay
