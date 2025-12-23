# Tikrit Testing Framework

## Overview

Tikrit includes a lightweight testing framework for unit testing core game systems. The framework is written in pure Lua with no external dependencies.

## Running Tests

### Quick Start

```bash
# Run all tests
lua test/run_tests.lua

# Or use make
make test
```

### Expected Output

```
Running Tikrit Test Suite
============================================================

============================================================
Test Suite: Utils Module
============================================================
  ✓ should calculate distance between two points
  ✓ should return 0 for same point
  ✓ should clamp value above max
  ✓ should clamp value within range
  ...

============================================================
Test Suite: AI Module
============================================================
  ✓ should find path in simple corridor
  ✓ should return empty path when blocked
  ...

============================================================
Test Summary
============================================================
Total tests: 45
Passed: 45
Pass rate: 100.0%

✓ All tests passed!
```

## Test Structure

### Directory Layout

```
test/
├── run_tests.lua           -- Main test runner
├── test_runner.lua         -- Testing framework core
└── spec/
    ├── utils_spec.lua      -- Utils module tests
    ├── ai_spec.lua         -- AI pathfinding tests
    └── map_validation_spec.lua  -- Map file validation
```

### Writing Tests

Tests use a describe/it structure similar to popular testing frameworks:

```lua
local TestRunner = require("test.test_runner")
local describe = TestRunner.describe
local it = TestRunner.it
local assertEqual = TestRunner.assertEqual

local MyModule = require("my_module")

describe("MyModule", function()
  
  describe("myFunction()", function()
    it("should do something", function()
      local result = MyModule.myFunction(5)
      assertEqual(result, 10, "Should double the input")
    end)
  end)
  
end)
```

## Available Assertions

### Basic Assertions
- `assert(condition, message)` - General assertion
- `assertEqual(actual, expected, message)` - Value equality
- `assertNotEqual(actual, expected, message)` - Value inequality
- `assertNil(value, message)` - Check for nil
- `assertNotNil(value, message)` - Check for non-nil

### Boolean Assertions
- `assertTrue(value, message)` - Check for true
- `assertFalse(value, message)` - Check for false

### Type Assertions
- `assertType(value, expectedType, message)` - Type checking

### Table Assertions
- `assertTableEqual(actual, expected, message)` - Deep table comparison

### Error Assertions
- `assertError(func, expectedError, message)` - Expect function to throw

## Test Coverage

### Utils Module (utils_spec.lua)
✅ distance() - Euclidean distance calculation  
✅ clamp() - Value clamping to range  
✅ gridToPixel() - Coordinate conversion  
✅ pixelToGrid() - Reverse coordinate conversion  
✅ isWalkable() - Tile walkability checks  
✅ deepCopy() - Table deep copying  
✅ shuffle() - Array randomization  

### AI Module (ai_spec.lua)
✅ findPath() - A* pathfinding algorithm  
✅ canSeePlayer() - Line-of-sight checks  
✅ update() - AI state transitions  

### Map Validation (map_validation_spec.lua)
✅ validateMap() - Map structure verification  
✅ Border checking  
✅ Required elements (player, exit)  
✅ Rectangular shape validation  

## Adding New Tests

1. **Create test file** in `test/spec/`:
   ```bash
   touch test/spec/mymodule_spec.lua
   ```

2. **Write tests** using the framework:
   ```lua
   local TestRunner = require("test.test_runner")
   local MyModule = require("modules.mymodule")
   
   TestRunner.describe("MyModule", function()
     TestRunner.it("should work", function()
       TestRunner.assertEqual(MyModule.foo(), "bar")
     end)
   end)
   ```

3. **Add to test runner** in `test/run_tests.lua`:
   ```lua
   local testFiles = {
     -- ... existing tests ...
     "test/spec/mymodule_spec.lua"
   }
   ```

4. **Run tests**:
   ```bash
   lua test/run_tests.lua
   ```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install Lua
        run: sudo apt-get install lua5.3
      - name: Run tests
        run: lua test/run_tests.lua
```

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/sh
lua test/run_tests.lua
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

## Best Practices

### Test Organization
- Group related tests in `describe()` blocks
- Use descriptive test names
- One assertion per test when possible
- Test edge cases and error conditions

### Test Independence
- Tests should not depend on each other
- Clean up state between tests
- Don't rely on execution order

### Test Coverage Goals
- Aim for 80%+ coverage of critical paths
- Focus on:
  * Core game logic (movement, collision)
  * AI algorithms (pathfinding)
  * Data validation (maps, save files)
  * Utility functions

### Performance
- Keep tests fast (< 1 second each)
- Mock expensive operations
- Use small test data sets

## Troubleshooting

### "Module not found"
- Check package.path includes test/ and src/
- Verify file names match require statements

### "Test hangs"
- Check for infinite loops in test code
- Verify Love2D dependencies aren't required

### "Tests pass locally but fail in CI"
- Check for file path differences
- Verify Lua version compatibility
- Check for missing dependencies

## Future Enhancements

Planned test additions:
- [ ] Combat system tests
- [ ] Progression system tests
- [ ] Event system integration tests
- [ ] Save/load system tests
- [ ] Hazard system tests
- [ ] UI rendering tests (if possible without Love2D)

## Resources

- **test/test_runner.lua** - Framework source code
- **test/spec/** - Example test files
- **ARCHITECTURE.md** - System design for testing reference

---

**Test Coverage:** ~40% (core utils, AI, map validation)  
**Last Updated:** 2024 (v2.5.0)  
**Goal:** 80%+ coverage of critical systems
