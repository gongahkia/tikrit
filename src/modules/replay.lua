-- Replay System Module
-- Records all player inputs with timestamps for deterministic playback
-- Useful for bug reproduction, speedrun verification, and tutorials

local Replay = {}

-- Replay state
local recording = false
local playing = false
local replayData = {
    version = "1.0",
    seed = nil,
    difficulty = nil,
    inputs = {},
    metadata = {
        recordingDate = nil,
        duration = 0,
        totalInputs = 0
    }
}
local playbackIndex = 1
local playbackTime = 0
local currentRecordingTime = 0

-- Directory for replay files
local REPLAY_DIR = "replays"

-- Initialize replay system
function Replay.init()
    -- Create replays directory if it doesn't exist
    local info = love.filesystem.getInfo(REPLAY_DIR)
    if not info then
        love.filesystem.createDirectory(REPLAY_DIR)
    end
    
    recording = false
    playing = false
    playbackIndex = 1
    playbackTime = 0
    currentRecordingTime = 0
    
    print("[Replay] System initialized")
end

-- Start recording inputs
function Replay.startRecording(seed, difficulty)
    replayData = {
        version = "1.0",
        seed = seed,
        difficulty = difficulty,
        inputs = {},
        metadata = {
            recordingDate = os.date("%Y-%m-%d %H:%M:%S"),
            duration = 0,
            totalInputs = 0
        }
    }
    
    recording = true
    playing = false
    currentRecordingTime = 0
    
    print("[Replay] Recording started - Seed:", seed, "Difficulty:", difficulty)
end

-- Stop recording
function Replay.stopRecording()
    if recording then
        replayData.metadata.duration = currentRecordingTime
        replayData.metadata.totalInputs = #replayData.inputs
        recording = false
        print("[Replay] Recording stopped - Duration:", currentRecordingTime, "Inputs:", #replayData.inputs)
    end
end

-- Record an input event
function Replay.recordInput(inputType, key, timestamp)
    if not recording then return end
    
    table.insert(replayData.inputs, {
        type = inputType,  -- "keydown", "keyup", "keypress"
        key = key,
        timestamp = timestamp or currentRecordingTime
    })
end

-- Update recording time
function Replay.update(dt)
    if recording then
        currentRecordingTime = currentRecordingTime + dt
    elseif playing then
        playbackTime = playbackTime + dt
    end
end

-- Save replay to file
function Replay.save(filename)
    if not replayData or #replayData.inputs == 0 then
        print("[Replay] No replay data to save")
        return false
    end
    
    -- Use default filename if none provided
    filename = filename or string.format("replay_%s.txt", os.date("%Y%m%d_%H%M%S"))
    
    -- Ensure .txt extension
    if not filename:match("%.txt$") then
        filename = filename .. ".txt"
    end
    
    local filepath = REPLAY_DIR .. "/" .. filename
    
    -- Serialize replay data
    local data = serializeReplayData(replayData)
    
    -- Save to file
    local success = love.filesystem.write(filepath, data)
    
    if success then
        print("[Replay] Saved to", filepath)
        return true
    else
        print("[Replay] Failed to save replay")
        return false
    end
end

-- Load replay from file
function Replay.load(filename)
    -- Ensure .txt extension
    if not filename:match("%.txt$") then
        filename = filename .. ".txt"
    end
    
    local filepath = REPLAY_DIR .. "/" .. filename
    
    local data = love.filesystem.read(filepath)
    if not data then
        print("[Replay] Failed to load replay:", filepath)
        return false
    end
    
    -- Deserialize replay data
    replayData = deserializeReplayData(data)
    
    if replayData then
        print("[Replay] Loaded:", filename, "- Inputs:", #replayData.inputs, "Duration:", replayData.metadata.duration)
        return true
    else
        print("[Replay] Failed to parse replay data")
        return false
    end
end

-- Start playback
function Replay.startPlayback()
    if not replayData or #replayData.inputs == 0 then
        print("[Replay] No replay data to play")
        return false
    end
    
    playing = true
    recording = false
    playbackIndex = 1
    playbackTime = 0
    
    print("[Replay] Playback started - Seed:", replayData.seed)
    return true, replayData.seed, replayData.difficulty
end

-- Stop playback
function Replay.stopPlayback()
    playing = false
    playbackIndex = 1
    playbackTime = 0
    print("[Replay] Playback stopped")
end

-- Get next input during playback
function Replay.getNextInput()
    if not playing or playbackIndex > #replayData.inputs then
        return nil
    end
    
    local input = replayData.inputs[playbackIndex]
    
    -- Check if it's time to execute this input
    if playbackTime >= input.timestamp then
        playbackIndex = playbackIndex + 1
        return input
    end
    
    return nil
end

-- Check if currently recording
function Replay.isRecording()
    return recording
end

-- Check if currently playing
function Replay.isPlaying()
    return playing
end

-- Get replay metadata
function Replay.getMetadata()
    return replayData.metadata
end

-- Get current playback progress (0 to 1)
function Replay.getPlaybackProgress()
    if not playing or not replayData.metadata.duration or replayData.metadata.duration == 0 then
        return 0
    end
    return math.min(1, playbackTime / replayData.metadata.duration)
end

-- List available replay files
function Replay.listReplays()
    local files = love.filesystem.getDirectoryItems(REPLAY_DIR)
    local replays = {}
    
    for _, file in ipairs(files) do
        if file:match("%.txt$") then
            table.insert(replays, file)
        end
    end
    
    return replays
end

-- Helper: Serialize replay data to string
function serializeReplayData(data)
    local lines = {}
    
    -- Header
    table.insert(lines, "VERSION:" .. data.version)
    table.insert(lines, "SEED:" .. (data.seed or ""))
    table.insert(lines, "DIFFICULTY:" .. (data.difficulty or "normal"))
    table.insert(lines, "DATE:" .. data.metadata.recordingDate)
    table.insert(lines, "DURATION:" .. data.metadata.duration)
    table.insert(lines, "TOTAL_INPUTS:" .. data.metadata.totalInputs)
    table.insert(lines, "INPUTS:")
    
    -- Input events
    for _, input in ipairs(data.inputs) do
        table.insert(lines, string.format("%s|%s|%.4f", input.type, input.key, input.timestamp))
    end
    
    return table.concat(lines, "\n")
end

-- Helper: Deserialize replay data from string
function deserializeReplayData(data)
    local replay = {
        version = "1.0",
        seed = nil,
        difficulty = "normal",
        inputs = {},
        metadata = {
            recordingDate = "",
            duration = 0,
            totalInputs = 0
        }
    }
    
    local parsingInputs = false
    
    for line in data:gmatch("[^\r\n]+") do
        if line == "INPUTS:" then
            parsingInputs = true
        elseif parsingInputs then
            -- Parse input: type|key|timestamp
            local inputType, key, timestamp = line:match("([^|]+)|([^|]+)|([%d%.]+)")
            if inputType and key and timestamp then
                table.insert(replay.inputs, {
                    type = inputType,
                    key = key,
                    timestamp = tonumber(timestamp)
                })
            end
        else
            -- Parse header
            local key, value = line:match("([^:]+):(.*)")
            if key and value then
                if key == "VERSION" then
                    replay.version = value
                elseif key == "SEED" then
                    replay.seed = tonumber(value) or value
                elseif key == "DIFFICULTY" then
                    replay.difficulty = value
                elseif key == "DATE" then
                    replay.metadata.recordingDate = value
                elseif key == "DURATION" then
                    replay.metadata.duration = tonumber(value) or 0
                elseif key == "TOTAL_INPUTS" then
                    replay.metadata.totalInputs = tonumber(value) or 0
                end
            end
        end
    end
    
    return replay
end

return Replay
