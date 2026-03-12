#!/usr/bin/env lua

package.path = table.concat({
    package.path,
    "src/?.lua",
    "src/modules/?.lua",
    "test/?.lua",
    "test/spec/?.lua",
}, ";")

local TestRunner = require("test_runner")

local testFiles = {
    "test/spec/utils_spec.lua",
    "test/spec/settings_spec.lua",
    "test/spec/sanity_spec.lua",
    "test/spec/ai_spec.lua",
    "test/spec/procgen_spec.lua",
    "test/spec/hazards_spec.lua",
    "test/spec/combat_spec.lua",
    "test/spec/progression_spec.lua",
    "test/spec/replay_spec.lua",
    "test/spec/runtime_smoke_spec.lua",
}

os.exit(TestRunner.runAll(testFiles))
