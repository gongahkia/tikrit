#!/usr/bin/env lua
-- test/run_tests.lua
-- Main test runner script

-- Add paths for modules
package.path = package.path .. ";test/?.lua;test/spec/?.lua"

-- Load test runner
local TestRunner = require("test_runner")

-- List of test files to run
local testFiles = {
  "test/spec/utils_spec.lua",
  "test/spec/ai_spec.lua",
  "test/spec/map_validation_spec.lua"
}

-- Run all tests
local exitCode = TestRunner.runAll(testFiles)

-- Exit with appropriate code
os.exit(exitCode)
