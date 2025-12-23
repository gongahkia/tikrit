-- test/test_runner.lua
-- Lightweight testing framework for Tikrit
-- No external dependencies required

local TestRunner = {}

-- Test statistics
TestRunner.stats = {
  total = 0,
  passed = 0,
  failed = 0,
  skipped = 0
}

-- Current test suite
TestRunner.currentSuite = nil

-- Test results
TestRunner.results = {}

-- ANSI color codes for terminal output
local colors = {
  reset = "\27[0m",
  red = "\27[31m",
  green = "\27[32m",
  yellow = "\27[33m",
  blue = "\27[34m",
  magenta = "\27[35m",
  cyan = "\27[36m"
}

-- Print colored text
function TestRunner.print(color, text)
  io.write(colors[color] .. text .. colors.reset .. "\n")
end

-- Create a new test suite
function TestRunner.describe(name, func)
  TestRunner.currentSuite = name
  TestRunner.print("cyan", "\n" .. string.rep("=", 60))
  TestRunner.print("cyan", "Test Suite: " .. name)
  TestRunner.print("cyan", string.rep("=", 60))
  
  -- Run the test suite
  local success, err = pcall(func)
  if not success then
    TestRunner.print("red", "ERROR: Suite failed to run: " .. tostring(err))
  end
end

-- Run a single test
function TestRunner.it(description, func)
  TestRunner.stats.total = TestRunner.stats.total + 1
  
  -- Run the test
  local success, err = pcall(func)
  
  if success then
    TestRunner.stats.passed = TestRunner.stats.passed + 1
    TestRunner.print("green", "  ✓ " .. description)
    table.insert(TestRunner.results, {
      suite = TestRunner.currentSuite,
      test = description,
      status = "passed"
    })
  else
    TestRunner.stats.failed = TestRunner.stats.failed + 1
    TestRunner.print("red", "  ✗ " .. description)
    TestRunner.print("red", "    Error: " .. tostring(err))
    table.insert(TestRunner.results, {
      suite = TestRunner.currentSuite,
      test = description,
      status = "failed",
      error = tostring(err)
    })
  end
end

-- Assertion functions
function TestRunner.assert(condition, message)
  if not condition then
    error(message or "Assertion failed", 2)
  end
end

function TestRunner.assertEqual(actual, expected, message)
  if actual ~= expected then
    local msg = message or string.format(
      "Expected %s, got %s",
      tostring(expected),
      tostring(actual)
    )
    error(msg, 2)
  end
end

function TestRunner.assertNotEqual(actual, expected, message)
  if actual == expected then
    local msg = message or string.format(
      "Expected values to be different, but both were %s",
      tostring(actual)
    )
    error(msg, 2)
  end
end

function TestRunner.assertNil(value, message)
  if value ~= nil then
    local msg = message or string.format("Expected nil, got %s", tostring(value))
    error(msg, 2)
  end
end

function TestRunner.assertNotNil(value, message)
  if value == nil then
    error(message or "Expected non-nil value", 2)
  end
end

function TestRunner.assertTrue(value, message)
  if value ~= true then
    error(message or "Expected true", 2)
  end
end

function TestRunner.assertFalse(value, message)
  if value ~= false then
    error(message or "Expected false", 2)
  end
end

function TestRunner.assertType(value, expectedType, message)
  local actualType = type(value)
  if actualType ~= expectedType then
    local msg = message or string.format(
      "Expected type %s, got type %s",
      expectedType,
      actualType
    )
    error(msg, 2)
  end
end

function TestRunner.assertTableEqual(actual, expected, message)
  -- Deep comparison of tables
  local function deepCompare(t1, t2)
    if type(t1) ~= type(t2) then return false end
    if type(t1) ~= "table" then return t1 == t2 end
    
    for k, v in pairs(t1) do
      if not deepCompare(v, t2[k]) then return false end
    end
    
    for k, v in pairs(t2) do
      if not deepCompare(v, t1[k]) then return false end
    end
    
    return true
  end
  
  if not deepCompare(actual, expected) then
    error(message or "Tables are not equal", 2)
  end
end

function TestRunner.assertError(func, expectedError, message)
  local success, err = pcall(func)
  if success then
    error(message or "Expected function to throw an error", 2)
  end
  if expectedError and not string.find(err, expectedError) then
    local msg = message or string.format(
      "Expected error containing '%s', got '%s'",
      expectedError,
      err
    )
    error(msg, 2)
  end
end

-- Skip a test
function TestRunner.skip(description)
  TestRunner.stats.skipped = TestRunner.stats.skipped + 1
  TestRunner.print("yellow", "  ⊘ " .. description .. " (skipped)")
end

-- Print final summary
function TestRunner.summary()
  TestRunner.print("cyan", "\n" .. string.rep("=", 60))
  TestRunner.print("cyan", "Test Summary")
  TestRunner.print("cyan", string.rep("=", 60))
  
  local passRate = 0
  if TestRunner.stats.total > 0 then
    passRate = (TestRunner.stats.passed / TestRunner.stats.total) * 100
  end
  
  TestRunner.print("blue", string.format("Total tests: %d", TestRunner.stats.total))
  TestRunner.print("green", string.format("Passed: %d", TestRunner.stats.passed))
  
  if TestRunner.stats.failed > 0 then
    TestRunner.print("red", string.format("Failed: %d", TestRunner.stats.failed))
  end
  
  if TestRunner.stats.skipped > 0 then
    TestRunner.print("yellow", string.format("Skipped: %d", TestRunner.stats.skipped))
  end
  
  TestRunner.print("magenta", string.format("Pass rate: %.1f%%", passRate))
  
  if TestRunner.stats.failed == 0 then
    TestRunner.print("green", "\n✓ All tests passed!")
    return 0
  else
    TestRunner.print("red", "\n✗ Some tests failed")
    return 1
  end
end

-- Run all test files
function TestRunner.runAll(testFiles)
  TestRunner.print("cyan", "Running Tikrit Test Suite")
  TestRunner.print("cyan", string.rep("=", 60))
  
  for _, file in ipairs(testFiles) do
    local success, err = pcall(dofile, file)
    if not success then
      TestRunner.print("red", "Failed to load test file: " .. file)
      TestRunner.print("red", "  Error: " .. tostring(err))
    end
  end
  
  return TestRunner.summary()
end

return TestRunner
