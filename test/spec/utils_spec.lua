-- test/spec/utils_spec.lua
-- Unit tests for Utils module

-- Load test framework
local TestRunner = require("test.test_runner")
local describe = TestRunner.describe
local it = TestRunner.it
local assertEqual = TestRunner.assertEqual
local assertNotEqual = TestRunner.assertNotEqual
local assertType = TestRunner.assertType
local assertTrue = TestRunner.assertTrue
local assertFalse = TestRunner.assertFalse
local assertTableEqual = TestRunner.assertTableEqual

-- Load module to test
package.path = package.path .. ";src/?.lua;src/modules/?.lua"
local Utils = require("utils")

describe("Utils Module", function()
  
  describe("distance()", function()
    it("should calculate distance between two points", function()
      local dist = Utils.distance(0, 0, 3, 4)
      assertEqual(dist, 5, "Distance from (0,0) to (3,4) should be 5")
    end)
    
    it("should return 0 for same point", function()
      local dist = Utils.distance(5, 5, 5, 5)
      assertEqual(dist, 0, "Distance from point to itself should be 0")
    end)
    
    it("should handle negative coordinates", function()
      local dist = Utils.distance(-3, -4, 0, 0)
      assertEqual(dist, 5, "Should work with negative coordinates")
    end)
    
    it("should be symmetric", function()
      local dist1 = Utils.distance(1, 2, 5, 7)
      local dist2 = Utils.distance(5, 7, 1, 2)
      assertEqual(dist1, dist2, "Distance should be symmetric")
    end)
  end)
  
  describe("clamp()", function()
    it("should clamp value above max", function()
      local result = Utils.clamp(150, 0, 100)
      assertEqual(result, 100, "Value above max should be clamped to max")
    end)
    
    it("should clamp value below min", function()
      local result = Utils.clamp(-50, 0, 100)
      assertEqual(result, 0, "Value below min should be clamped to min")
    end)
    
    it("should not clamp value within range", function()
      local result = Utils.clamp(50, 0, 100)
      assertEqual(result, 50, "Value within range should not be modified")
    end)
    
    it("should handle edge cases", function()
      assertEqual(Utils.clamp(0, 0, 100), 0, "Min edge case")
      assertEqual(Utils.clamp(100, 0, 100), 100, "Max edge case")
    end)
  end)
  
  describe("gridToPixel()", function()
    it("should convert grid to pixel coordinates", function()
      -- Assuming GRID_SIZE = 40 (from config.lua)
      local GRID_SIZE = 40
      local screenX, screenY = Utils.gridToPixel(5, 10)
      assertEqual(screenX, 5 * GRID_SIZE, "X coordinate conversion")
      assertEqual(screenY, 10 * GRID_SIZE, "Y coordinate conversion")
    end)
    
    it("should handle zero coordinates", function()
      local screenX, screenY = Utils.gridToPixel(0, 0)
      assertEqual(screenX, 0, "Zero X")
      assertEqual(screenY, 0, "Zero Y")
    end)
  end)
  
  describe("pixelToGrid()", function()
    it("should convert pixel to grid coordinates", function()
      local GRID_SIZE = 40
      local gridX, gridY = Utils.pixelToGrid(200, 400)
      assertEqual(gridX, math.floor(200 / GRID_SIZE), "X coordinate conversion")
      assertEqual(gridY, math.floor(400 / GRID_SIZE), "Y coordinate conversion")
    end)
    
    it("should round down for partial grid cells", function()
      local GRID_SIZE = 40
      local gridX, gridY = Utils.pixelToGrid(75, 135)
      -- 75/40 = 1.875 -> 1, 135/40 = 3.375 -> 3
      assertEqual(gridX, 1, "Partial X rounds down")
      assertEqual(gridY, 3, "Partial Y rounds down")
    end)
  end)
  
  describe("isWalkable()", function()
    it("should return true for floor tiles", function()
      local world = {
        {" ", " ", " "},
        {" ", ".", " "},
        {" ", " ", " "}
      }
      assertTrue(Utils.isWalkable(1, 1, world), "Floor tile should be walkable")
      assertTrue(Utils.isWalkable(0, 0, world), "Space should be walkable")
    end)
    
    it("should return false for wall tiles", function()
      local world = {
        {"#", "#", "#"},
        {"#", ".", "#"},
        {"#", "#", "#"}
      }
      assertFalse(Utils.isWalkable(0, 0, world), "Wall should not be walkable")
    end)
    
    it("should return false for out of bounds", function()
      local world = {
        {".", ".", "."},
        {".", ".", "."}
      }
      assertFalse(Utils.isWalkable(-1, 0, world), "Negative X out of bounds")
      assertFalse(Utils.isWalkable(0, -1, world), "Negative Y out of bounds")
      assertFalse(Utils.isWalkable(10, 10, world), "Large coordinates out of bounds")
    end)
  end)
  
  describe("deepCopy()", function()
    it("should create independent copy of table", function()
      local original = {a = 1, b = 2, c = {d = 3}}
      local copy = Utils.deepCopy(original)
      
      assertNotEqual(copy, original, "Copy should be different table reference")
      assertEqual(copy.a, original.a, "Shallow values should match")
      assertEqual(copy.c.d, original.c.d, "Nested values should match")
    end)
    
    it("should not affect original when modifying copy", function()
      local original = {a = 1, b = {c = 2}}
      local copy = Utils.deepCopy(original)
      
      copy.a = 999
      copy.b.c = 888
      
      assertEqual(original.a, 1, "Original shallow value unchanged")
      assertEqual(original.b.c, 2, "Original nested value unchanged")
    end)
    
    it("should handle nested tables", function()
      local original = {
        level1 = {
          level2 = {
            level3 = {
              value = 42
            }
          }
        }
      }
      local copy = Utils.deepCopy(original)
      assertEqual(copy.level1.level2.level3.value, 42, "Deep nesting preserved")
    end)
    
    it("should handle arrays", function()
      local original = {1, 2, 3, {4, 5, 6}}
      local copy = Utils.deepCopy(original)
      
      assertTableEqual(copy, original, "Array copy should match original")
      copy[4][1] = 999
      assertEqual(original[4][1], 4, "Original array unchanged")
    end)
  end)
  
  describe("shuffle()", function()
    it("should return table with same length", function()
      local array = {1, 2, 3, 4, 5}
      local originalLength = #array
      Utils.shuffle(array)
      assertEqual(#array, originalLength, "Length should not change")
    end)
    
    it("should contain all original elements", function()
      local array = {1, 2, 3, 4, 5}
      local copy = Utils.deepCopy(array)
      Utils.shuffle(array)
      
      -- Check all elements still present
      table.sort(array)
      table.sort(copy)
      assertTableEqual(array, copy, "All elements should be present after shuffle")
    end)
    
    it("should modify array in-place", function()
      local array = {1, 2, 3, 4, 5}
      local reference = array
      Utils.shuffle(array)
      assertEqual(array, reference, "Should be same table reference")
    end)
  end)
  
  describe("Edge Cases", function()
    it("should handle nil gracefully", function()
      -- These should not crash
      local dist = Utils.distance(nil, 0, 0, 0)
      assertType(dist, "number", "Should return number even with nil input")
    end)
    
    it("should handle empty tables", function()
      local empty = {}
      local copy = Utils.deepCopy(empty)
      assertTableEqual(copy, {}, "Empty table copy should work")
    end)
  end)
  
end)
