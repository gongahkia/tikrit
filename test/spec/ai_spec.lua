-- test/spec/ai_spec.lua
-- Unit tests for AI module pathfinding

local TestRunner = require("test.test_runner")
local describe = TestRunner.describe
local it = TestRunner.it
local assertEqual = TestRunner.assertEqual
local assertNotEqual = TestRunner.assertNotEqual
local assertType = TestRunner.assertType
local assertTrue = TestRunner.assertTrue
local assertFalse = TestRunner.assertFalse
local assertTableEqual = TestRunner.assertTableEqual
local assertNotNil = TestRunner.assertNotNil
local assertNil = TestRunner.assertNil

package.path = package.path .. ";src/?.lua;src/modules/?.lua"
local AI = require("ai")

describe("AI Module", function()
  
  describe("findPath()", function()
    it("should find path in simple corridor", function()
      local world = {
        {"#", "#", "#", "#", "#"},
        {"#", ".", ".", ".", "#"},
        {"#", "#", "#", "#", "#"}
      }
      
      local start = {x = 1, y = 1}
      local goal = {x = 3, y = 1}
      local path = AI.findPath(start, goal, world)
      
      assertNotNil(path, "Path should exist")
      assertType(path, "table", "Path should be a table")
      assertTrue(#path > 0, "Path should have steps")
    end)
    
    it("should return empty path when blocked", function()
      local world = {
        {"#", "#", "#", "#", "#"},
        {"#", ".", "#", ".", "#"},
        {"#", "#", "#", "#", "#"}
      }
      
      local start = {x = 1, y = 1}
      local goal = {x = 3, y = 1}
      local path = AI.findPath(start, goal, world)
      
      assertType(path, "table", "Should return table")
      assertEqual(#path, 0, "Path should be empty when blocked")
    end)
    
    it("should find shortest path around obstacle", function()
      local world = {
        {"#", "#", "#", "#", "#", "#", "#"},
        {"#", ".", ".", "#", ".", ".", "#"},
        {"#", ".", ".", "#", ".", ".", "#"},
        {"#", ".", ".", ".", ".", ".", "#"},
        {"#", "#", "#", "#", "#", "#", "#"}
      }
      
      local start = {x = 1, y = 1}
      local goal = {x = 5, y = 1}
      local path = AI.findPath(start, goal, world)
      
      assertNotNil(path, "Path should exist around obstacle")
      assertTrue(#path > 0, "Path should have steps")
      
      -- Path should go around the wall at x=3
      local crossesWall = false
      for _, step in ipairs(path) do
        if step.x == 3 and (step.y == 1 or step.y == 2) then
          crossesWall = true
        end
      end
      assertFalse(crossesWall, "Path should not cross wall")
    end)
    
    it("should return empty path for same start/goal", function()
      local world = {
        {"#", "#", "#"},
        {"#", ".", "#"},
        {"#", "#", "#"}
      }
      
      local pos = {x = 1, y = 1}
      local path = AI.findPath(pos, pos, world)
      
      -- Path to same position should be empty or just the position
      assertTrue(#path <= 1, "Path to same position should be minimal")
    end)
    
    it("should handle large maps efficiently", function()
      -- Create 20x20 map
      local world = {}
      for y = 0, 19 do
        world[y] = {}
        for x = 0, 19 do
          if y == 0 or y == 19 or x == 0 or x == 19 then
            world[y][x] = "#"  -- Walls
          else
            world[y][x] = "."  -- Floor
          end
        end
      end
      
      local start = {x = 1, y = 1}
      local goal = {x = 18, y = 18}
      
      local startTime = os.clock()
      local path = AI.findPath(start, goal, world)
      local endTime = os.clock()
      
      local duration = endTime - startTime
      assertNotNil(path, "Should find path in large map")
      assertTrue(duration < 1.0, "Pathfinding should be fast (< 1 second)")
    end)
  end)
  
  describe("canSeePlayer()", function()
    it("should see player when in direct line of sight", function()
      local world = {
        {"#", "#", "#", "#", "#", "#", "#"},
        {"#", ".", ".", ".", ".", ".", "#"},
        {"#", "#", "#", "#", "#", "#", "#"}
      }
      
      local ghost = {
        coord = {x = 1, y = 1},
        visionRadius = 5
      }
      local playerCoord = {x = 3, y = 1}
      
      local canSee = AI.canSeePlayer(ghost, playerCoord, world)
      assertTrue(canSee, "Ghost should see player in direct line")
    end)
    
    it("should not see player through walls", function()
      local world = {
        {"#", "#", "#", "#", "#", "#", "#"},
        {"#", ".", "#", ".", ".", ".", "#"},
        {"#", "#", "#", "#", "#", "#", "#"}
      }
      
      local ghost = {
        coord = {x = 1, y = 1},
        visionRadius = 10
      }
      local playerCoord = {x = 3, y = 1}
      
      local canSee = AI.canSeePlayer(ghost, playerCoord, world)
      assertFalse(canSee, "Ghost should not see through walls")
    end)
    
    it("should not see player beyond vision radius", function()
      local world = {
        {"#", "#", "#", "#", "#", "#", "#", "#", "#", "#"},
        {"#", ".", ".", ".", ".", ".", ".", ".", ".", "#"},
        {"#", "#", "#", "#", "#", "#", "#", "#", "#", "#"}
      }
      
      local ghost = {
        coord = {x = 1, y = 1},
        visionRadius = 3
      }
      local playerCoord = {x = 8, y = 1}  -- Far away
      
      local canSee = AI.canSeePlayer(ghost, playerCoord, world)
      assertFalse(canSee, "Ghost should not see beyond vision radius")
    end)
  end)
  
  describe("update()", function()
    it("should switch to chase when player is visible", function()
      local world = {
        {"#", "#", "#", "#", "#"},
        {"#", ".", ".", ".", "#"},
        {"#", "#", "#", "#", "#"}
      }
      
      local ghost = {
        coord = {x = 1, y = 1},
        state = "PATROL",
        speed = 50,
        visionRadius = 5
      }
      local playerCoord = {x = 3, y = 1}
      
      AI.update(ghost, playerCoord, 0.016)  -- 60 FPS frame
      
      assertEqual(ghost.state, "CHASE", "Ghost should chase when player visible")
    end)
    
    it("should patrol when player not visible", function()
      local world = {
        {"#", "#", "#", "#", "#", "#", "#"},
        {"#", ".", "#", "#", "#", ".", "#"},
        {"#", "#", "#", "#", "#", "#", "#"}
      }
      
      local ghost = {
        coord = {x = 1, y = 1},
        state = "CHASE",
        speed = 50,
        visionRadius = 3
      }
      local playerCoord = {x = 5, y = 1}  -- Behind wall
      
      AI.update(ghost, playerCoord, 0.016)
      
      assertEqual(ghost.state, "PATROL", "Ghost should patrol when player not visible")
    end)
  end)
  
  describe("Edge Cases", function()
    it("should handle nil world gracefully", function()
      local start = {x = 0, y = 0}
      local goal = {x = 5, y = 5}
      
      local path = AI.findPath(start, goal, nil)
      assertType(path, "table", "Should return table even with nil world")
      assertEqual(#path, 0, "Should return empty path for nil world")
    end)
    
    it("should handle out-of-bounds coordinates", function()
      local world = {
        {"#", "#", "#"},
        {"#", ".", "#"},
        {"#", "#", "#"}
      }
      
      local start = {x = -5, y = -5}
      local goal = {x = 100, y = 100}
      
      local path = AI.findPath(start, goal, world)
      assertType(path, "table", "Should handle out of bounds")
      assertEqual(#path, 0, "Should return empty path for out of bounds")
    end)
  end)
  
end)
