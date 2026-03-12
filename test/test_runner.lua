local TestRunner = {}

local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    cyan = "\27[36m",
}

function TestRunner.reset()
    TestRunner.stats = {
        total = 0,
        passed = 0,
        failed = 0,
        skipped = 0,
    }
    TestRunner.currentSuite = nil
    TestRunner.results = {}
end

TestRunner.reset()

function TestRunner.print(color, text)
    io.write(colors[color] .. text .. colors.reset .. "\n")
end

function TestRunner.describe(name, func)
    TestRunner.currentSuite = name
    TestRunner.print("cyan", "\n" .. string.rep("=", 60))
    TestRunner.print("cyan", "Test Suite: " .. name)
    TestRunner.print("cyan", string.rep("=", 60))
    local ok, err = pcall(func)
    if not ok then
        TestRunner.stats.failed = TestRunner.stats.failed + 1
        TestRunner.print("red", "Suite setup failed: " .. tostring(err))
    end
end

function TestRunner.it(description, func)
    TestRunner.stats.total = TestRunner.stats.total + 1
    local ok, err = pcall(func)
    if ok then
        TestRunner.stats.passed = TestRunner.stats.passed + 1
        TestRunner.print("green", "  ✓ " .. description)
    else
        TestRunner.stats.failed = TestRunner.stats.failed + 1
        TestRunner.print("red", "  ✗ " .. description)
        TestRunner.print("red", "    " .. tostring(err))
    end
end

function TestRunner.skip(description)
    TestRunner.stats.total = TestRunner.stats.total + 1
    TestRunner.stats.skipped = TestRunner.stats.skipped + 1
    TestRunner.print("yellow", "  ⊘ " .. description)
end

function TestRunner.assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function TestRunner.assertEqual(actual, expected, message)
    if actual ~= expected then
        error(message or string.format("Expected %s, got %s", tostring(expected), tostring(actual)), 2)
    end
end

function TestRunner.assertNotEqual(actual, expected, message)
    if actual == expected then
        error(message or string.format("Expected value different from %s", tostring(expected)), 2)
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

function TestRunner.assertNear(actual, expected, delta, message)
    if math.abs(actual - expected) > delta then
        error(message or string.format("Expected %.4f to be within %.4f of %.4f", actual, delta, expected), 2)
    end
end

function TestRunner.assertType(value, expectedType, message)
    if type(value) ~= expectedType then
        error(message or string.format("Expected %s, got %s", expectedType, type(value)), 2)
    end
end

function TestRunner.assertTableEqual(actual, expected, message)
    local function compare(left, right)
        if type(left) ~= type(right) then
            return false
        end
        if type(left) ~= "table" then
            return left == right
        end
        for key, value in pairs(left) do
            if not compare(value, right[key]) then
                return false
            end
        end
        for key, value in pairs(right) do
            if not compare(value, left[key]) then
                return false
            end
        end
        return true
    end

    if not compare(actual, expected) then
        error(message or "Tables differ", 2)
    end
end

function TestRunner.summary()
    TestRunner.print("cyan", "\n" .. string.rep("=", 60))
    TestRunner.print("cyan", "Test Summary")
    TestRunner.print("cyan", string.rep("=", 60))
    TestRunner.print("blue", "Total: " .. TestRunner.stats.total)
    TestRunner.print("green", "Passed: " .. TestRunner.stats.passed)
    if TestRunner.stats.failed > 0 then
        TestRunner.print("red", "Failed: " .. TestRunner.stats.failed)
    end
    if TestRunner.stats.skipped > 0 then
        TestRunner.print("yellow", "Skipped: " .. TestRunner.stats.skipped)
    end

    if TestRunner.stats.failed > 0 then
        TestRunner.print("red", "\n✗ Some tests failed")
        return 1
    end

    TestRunner.print("green", "\n✓ All tests passed")
    return 0
end

function TestRunner.runAll(testFiles)
    TestRunner.reset()
    TestRunner.print("cyan", "Running Tikrit tests")
    TestRunner.print("cyan", string.rep("=", 60))

    for _, file in ipairs(testFiles) do
        local ok, err = pcall(dofile, file)
        if not ok then
            TestRunner.stats.failed = TestRunner.stats.failed + 1
            TestRunner.print("red", "Failed to load " .. file)
            TestRunner.print("red", "  " .. tostring(err))
        end
    end

    return TestRunner.summary()
end

return TestRunner
