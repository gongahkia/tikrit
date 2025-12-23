-- ---------- CONFIGURATION ----------
-- All game constants and configurable values
-- This allows easy tweaking without modifying core game code

local CONFIG = {}

-- ---------- GAMEPLAY SETTINGS ----------

-- Player settings
CONFIG.PLAYER_SPEED = 200
CONFIG.PLAYER_SPEED_BUFF = 200
CONFIG.PLAYER_SPEED_BUFF_DURATION = 5 -- seconds
CONFIG.INVINCIBILITY_DURATION = 5 -- seconds
CONFIG.MAP_REVEAL_DURATION = 3 -- seconds

-- Monster settings
CONFIG.MONSTER_SPEED = 50
CONFIG.GHOST_PROXIMITY_THRESHOLD = 100 -- distance for ghost scream sound
CONFIG.GHOST_SLOW_MULTIPLIER = 0.5 -- how much to slow ghosts

-- Map settings
CONFIG.TILE_SIZE = 20
CONFIG.MAP_WIDTH = 600
CONFIG.MAP_HEIGHT = 600
CONFIG.MAX_ROOMS = 9
CONFIG.MIN_ROOMS = 3

-- Vision settings (for fog of war)
CONFIG.VISION_RADIUS = 7 -- tiles
CONFIG.FOG_ENABLED = false -- toggle fog of war
CONFIG.SHOW_VISITED = true -- show previously visited areas
CONFIG.VISITED_ALPHA = 0.3 -- transparency for visited areas

-- Debug settings
CONFIG.DEBUG_MODE = false -- toggle with F3
CONFIG.GOD_MODE = false -- toggle with F4 (no collision)
CONFIG.SHOW_FPS = true
CONFIG.SHOW_COLLISION_BOXES = true
CONFIG.SHOW_AI_VECTORS = true

-- Difficulty settings (affects spawn rates and speeds)
CONFIG.DIFFICULTY = "normal" -- easy, normal, hard, nightmare
CONFIG.DIFFICULTY_SETTINGS = {
    easy = {
        monsterSpeed = 35,
        playerSpeed = 250,
        itemSpawnMultiplier = 1.5,
        requiredKeyPercentage = 0.6
    },
    normal = {
        monsterSpeed = 50,
        playerSpeed = 200,
        itemSpawnMultiplier = 1.0,
        requiredKeyPercentage = 1.0
    },
    hard = {
        monsterSpeed = 70,
        playerSpeed = 180,
        itemSpawnMultiplier = 0.7,
        requiredKeyPercentage = 1.0
    },
    nightmare = {
        monsterSpeed = 90,
        playerSpeed = 150,
        itemSpawnMultiplier = 0.4,
        requiredKeyPercentage = 1.0,
        fogEnabled = true,
        permadeath = true
    }
}

-- ---------- VISUAL SETTINGS ----------

CONFIG.WINDOW_TITLE = "tikrit"
CONFIG.WINDOW_WIDTH = 600
CONFIG.WINDOW_HEIGHT = 600
CONFIG.BACKGROUND_GRAY = 0.5

-- ---------- AUDIO SETTINGS ----------

CONFIG.VOLUME_MASTER = 1.0
CONFIG.VOLUME_MUSIC = 0.7
CONFIG.VOLUME_SFX = 1.0

-- ---------- UI SETTINGS ----------

CONFIG.FONT_SIZE_LARGE = 80
CONFIG.FONT_SIZE_MEDIUM = 40
CONFIG.FONT_SIZE_SMALL = 25

-- ---------- STATISTICS TRACKING ----------

CONFIG.TRACK_STATS = true
CONFIG.STATS_FILE = "stats.txt"
CONFIG.HIGH_SCORES_FILE = "highscores.txt"

-- ---------- PARTICLE EFFECTS ----------

CONFIG.PARTICLES_ENABLED = true
CONFIG.PARTICLE_COUNT_KEY = 20
CONFIG.PARTICLE_COUNT_ITEM = 15
CONFIG.PARTICLE_COUNT_DEATH = 30
CONFIG.PARTICLE_COUNT_DOOR = 10
CONFIG.PARTICLE_LIFETIME = 1.0

-- ---------- SCREEN SHAKE ----------

CONFIG.SCREEN_SHAKE_ENABLED = true
CONFIG.SHAKE_INTENSITY = 5
CONFIG.SHAKE_DURATION = 0.3

-- Animation settings
CONFIG.ANIMATIONS_ENABLED = true
CONFIG.GHOST_BOB_SPEED = 3
CONFIG.GHOST_BOB_AMOUNT = 3
CONFIG.CHEST_OPEN_DURATION = 0.3
CONFIG.DOOR_OPEN_DURATION = 0.4
CONFIG.PLAYER_IDLE_PULSE_SPEED = 2
CONFIG.PLAYER_IDLE_PULSE_AMOUNT = 0.02

-- Audio settings
CONFIG.MASTER_VOLUME = 0.7
CONFIG.GHOST_AUDIO_MAX_DISTANCE = 300
CONFIG.GHOST_AUDIO_MIN_DISTANCE = 50
CONFIG.AMBIENT_BASE_VOLUME = 0.3
CONFIG.POSITIONAL_AUDIO_ENABLED = true

-- Combat settings
CONFIG.COMBAT_ENABLED = true
CONFIG.MONSTER_MAX_HEALTH = 3
CONFIG.ATTACK_COOLDOWN = 1.0
CONFIG.ATTACK_RANGE = 30
CONFIG.ATTACK_ANIMATION_DURATION = 0.2
CONFIG.DROP_CHANCE_KEY = 0.5  -- 50% chance to drop key
CONFIG.DROP_CHANCE_ITEM = 0.3  -- 30% chance to drop item

-- Procedural generation settings
CONFIG.PROCGEN_ENABLED = true
CONFIG.PROCGEN_ALGORITHM = "bsp"  -- "bsp" or "cave"
CONFIG.PROCGEN_MAX_DEPTH = 4  -- BSP recursion depth
CONFIG.PROCGEN_MIN_ROOM_SIZE = 8
CONFIG.PROCGEN_MAX_ROOM_SIZE = 15
CONFIG.PROCGEN_CAVE_FILL_PERCENT = 45  -- for cellular automata
CONFIG.PROCGEN_CAVE_SMOOTH_ITERATIONS = 5

-- Minimap settings
CONFIG.MINIMAP_ENABLED = true
CONFIG.MINIMAP_TOGGLE_KEY = "m"  -- Toggle minimap with M key
CONFIG.MINIMAP_SIZE = 150  -- Size of minimap in pixels
CONFIG.MINIMAP_POSITION_X = 10  -- X position (from left)
CONFIG.MINIMAP_POSITION_Y = 120  -- Y position (from top, below HUD)
CONFIG.MINIMAP_SCALE = 0.25  -- Scale factor for minimap
CONFIG.MINIMAP_BACKGROUND_ALPHA = 0.7  -- Background transparency
CONFIG.MINIMAP_SHOW_GHOSTS = true  -- Show ghosts on minimap
CONFIG.MINIMAP_SHOW_ITEMS = true  -- Show items on minimap
CONFIG.MINIMAP_SHOW_KEYS = true  -- Show keys on minimap

-- Daily Challenge Mode
CONFIG.DAILY_CHALLENGE_ENABLED = false  -- Toggle daily challenge mode
CONFIG.DAILY_CHALLENGE_SEED = nil  -- Will be set based on date
CONFIG.USE_CUSTOM_SEED = false  -- For testing/replays
CONFIG.CUSTOM_SEED = 12345  -- Custom seed value

-- Performance Profiling
CONFIG.PROFILING_ENABLED = false  -- Toggle with F6
CONFIG.PROFILING_HISTORY_SIZE = 60  -- Number of frames to track
CONFIG.PROFILING_UPDATE_INTERVAL = 0.5  -- Update stats every 0.5s

return CONFIG
