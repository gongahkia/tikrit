-- test/spec/map_validation_spec.lua
-- Tests for map file validation

local TestRunner = require("test.test_runner")
local describe = TestRunner.describe
local it = TestRunner.it
local assertEqual = TestRunner.assertEqual
local assertTrue = TestRunner.assertTrue
local assertFalse = TestRunner.assertFalse
local assertNotNil = TestRunner.assertNotNil

-- Helper function to validate map structure
local function validateMap(mapString)
  local errors = {}
  local warnings = {}
  
  if not mapString or mapString == "" then
    table.insert(errors, "Map is empty")
    return false, errors, warnings
  end
  
  local lines = {}
  for line in mapString:gmatch("[^\n]+") do
    table.insert(lines, line)
  end
  
  if #lines == 0 then
    table.insert(errors, "No lines in map")
    return false, errors, warnings
  end
  
  -- Check rectangular shape
  local width = #lines[1]
  for i, line in ipairs(lines) do
    if #line ~= width then
      table.insert(errors, string.format("Line %d has width %d, expected %d", i, #line, width))
    end
  end
  
  -- Check for required elements
  local hasPlayer = mapString:find("@") ~= nil
  local hasExit = mapString:find("E") ~= nil
  local hasKey = mapString:find("k") ~= nil
  
  if not hasPlayer then
    table.insert(errors, "No player start (@) found")
  end
  
  if not hasExit then
    table.insert(errors, "No exit (E) found")
  end
  
  -- Count player starts (should be exactly 1)
  local playerCount = 0
  for _ in mapString:gmatch("@") do
    playerCount = playerCount + 1
  end
  
  if playerCount > 1 then
    table.insert(errors, string.format("Multiple player starts found (%d)", playerCount))
  end
  
  -- Check for walls on borders
  local firstLine = lines[1]
  local lastLine = lines[#lines]
  
  for i = 1, #firstLine do
    if firstLine:sub(i, i) ~= "#" then
      table.insert(warnings, "Top border missing wall at column " .. i)
    end
  end
  
  for i = 1, #lastLine do
    if lastLine:sub(i, i) ~= "#" then
      table.insert(warnings, "Bottom border missing wall at column " .. i)
    end
  end
  
  -- Check left/right borders
  for i, line in ipairs(lines) do
    if line:sub(1, 1) ~= "#" then
      table.insert(warnings, "Left border missing wall at line " .. i)
    end
    if line:sub(#line, #line) ~= "#" then
      table.insert(warnings, "Right border missing wall at line " .. i)
    end
  end
  
  local isValid = #errors == 0
  return isValid, errors, warnings
end

describe("Map Validation", function()
  
  describe("validateMap()", function()
    it("should validate a correct minimal map", function()
      local map = [[
#####
#@ E#
#####
]]
      local isValid, errors, warnings = validateMap(map)
      assertTrue(isValid, "Minimal valid map should pass: " .. table.concat(errors, ", "))
    end)
    
    it("should require player start", function()
      local map = [[
#####
#  E#
#####
]]
      local isValid, errors, warnings = validateMap(map)
      assertFalse(isValid, "Map without player should be invalid")
      assertTrue(#errors > 0, "Should have error about missing player")
    end)
    
    it("should require exit", function()
      local map = [[
#####
#@  #
#####
]]
      local isValid, errors, warnings = validateMap(map)
      assertFalse(isValid, "Map without exit should be invalid")
    end)
    
    it("should reject multiple player starts", function()
      local map = [[
#######
#@   @#
#  E  #
#######
]]
      local isValid, errors, warnings = validateMap(map)
      assertFalse(isValid, "Map with multiple players should be invalid")
    end)
    
    it("should check rectangular shape", function()
      local map = [[
#######
#@  E#
#####
]]
      local isValid, errors, warnings = validateMap(map)
      assertFalse(isValid, "Non-rectangular map should be invalid")
    end)
    
    it("should warn about missing border walls", function()
      local map = [[
 #####
#@  E#
###### 
]]
      local isValid, errors, warnings = validateMap(map)
      -- Might still be valid structurally, but should have warnings
      assertTrue(#warnings > 0, "Should warn about border walls")
    end)
    
    it("should validate complex map with items", function()
      local map = [[
#############
#@  H  k  S #
# ### ### # #
# #G# #G# # #
# ### ### # #
#   ^   ^  E#
#############
]]
      local isValid, errors, warnings = validateMap(map)
      assertTrue(isValid, "Complex map should be valid: " .. table.concat(errors, ", "))
    end)
  end)
  
  describe("Real Map Files", function()
    it("should validate map 1.txt structure", function()
      -- Try to load actual map file
      local success, content = pcall(function()
        local file = io.open("map/1.txt", "r")
        if file then
          local data = file:read("*all")
          file:close()
          return data
        end
        return nil
      end)
      
      if success and content then
        local isValid, errors, warnings = validateMap(content)
        assertTrue(isValid, "map/1.txt should be valid: " .. table.concat(errors or {}, ", "))
      else
        TestRunner.skip("map/1.txt not accessible from test environment")
      end
    end)
  end)
  
  describe("Edge Cases", function()
    it("should handle empty map", function()
      local isValid, errors, warnings = validateMap("")
      assertFalse(isValid, "Empty map should be invalid")
      assertTrue(#errors > 0, "Should have errors for empty map")
    end)
    
    it("should handle nil map", function()
      local isValid, errors, warnings = validateMap(nil)
      assertFalse(isValid, "Nil map should be invalid")
    end)
    
    it("should handle very large map", function()
      -- Create 50x50 map
      local lines = {}
      table.insert(lines, string.rep("#", 50))
      for i = 1, 48 do
        if i == 1 then
          table.insert(lines, "#@" .. string.rep(" ", 46) .. "E#")
        else
          table.insert(lines, "#" .. string.rep(" ", 48) .. "#")
        end
      end
      table.insert(lines, string.rep("#", 50))
      
      local map = table.concat(lines, "\n")
      local isValid, errors, warnings = validateMap(map)
      assertTrue(isValid, "Large map should be valid")
    end)
  end)
  
end)
