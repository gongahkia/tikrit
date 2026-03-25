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
    "test/spec/ui_spec.lua",
    "test/spec/sound_events_spec.lua",
    "test/spec/station_affordance_spec.lua",
    "test/spec/procgen_spec.lua",
    "test/spec/survival_spec.lua",
    "test/spec/base_survival_spec.lua",
    "test/spec/fire_spec.lua",
    "test/spec/wildlife_spec.lua",
    "test/spec/progression_spec.lua",
    "test/spec/replay_spec.lua",
    "test/spec/repo_cleanup_spec.lua",
    "test/spec/runtime_smoke_spec.lua",
}

os.exit(TestRunner.runAll(testFiles))
