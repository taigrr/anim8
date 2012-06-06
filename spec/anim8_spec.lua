require 'spec.love-mocks'

local anim8 = require 'anim8'

local newQuad   = love.graphics.newQuad
local getLastDrawq = love.graphics.getLastDrawq

local newGrid = anim8.newGrid
local newAnimation = anim8.newAnimation

local function assert_equivalent(arr1, arr2)
  assert_equal(type(arr1), type(arr2))
  for k,v in pairs(arr1) do assert_equal(v, arr2[k]) end
  for k,v in pairs(arr2) do assert_equal(v, arr1[k]) end
end


describe("anim8", function()
  describe("newGrid", function()
    it("throws error if any of its parameters is not a positive integer", function()
      assert_error(function() newGrid() end)
      assert_error(function() newGrid(1) end)
      assert_error(function() newGrid(1,1,1,-1) end)
      assert_error(function() newGrid(0,1,1,1) end)
      assert_error(function() newGrid(1,1,'a',1) end)
    end)

    it("preserves the values", function()
      local g = newGrid(1,2,3,4,5,6,7)
      assert_equal(1, g.frameWidth)
      assert_equal(2, g.frameHeight)
      assert_equal(3, g.imageWidth)
      assert_equal(4, g.imageHeight)
      assert_equal(5, g.left)
      assert_equal(6, g.top)
      assert_equal(7, g.border)
    end)

    it("calculates width and height", function()
      local g = newGrid(32,32,64,256)
      assert_equal(2, g.width)
      assert_equal(8, g.height)
    end)

    it("presets border and offsets to 0", function()
      local g = newGrid(32,32,64,256)
      assert_equal(0, g.left)
      assert_equal(0, g.top)
      assert_equal(0, g.border)
    end)
  end)

  describe("Grid", function()
    describe("getFrames", function()
      local g, f
      before(function()
        g = newGrid(16,16,64,64)
        nq = function(x,y) return newQuad(x,y, 16,16, 64,64) end
      end)

      describe("with 2 integers", function()
        it("returns a single frame", function()
          assert_equal(nq(0,0), g:getFrames(1,1)[1])
        end)
        it("returns another single frame", function()
          assert_equal(nq(32,16), g:getFrames(3,2)[1])
        end)
        it("throws an error if the frame does not exist", function()
          assert_error(function() g:getFrames(10,10) end)
        end)
      end)

      describe("with several pairs of integers", function()
        it("returns a list of frames", function()
          local frames = g:getFrames(1,3, 2,2, 3,1)
          assert_equivalent({nq(0,32), nq(16,16), nq(32,0)}, frames)
        end)
        it("takes into account border widths", function()
          g = newGrid(16,16,64,64,0,0,1)
          local frames = g:getFrames(1,3, 2,2, 3,1)
          assert_equivalent({nq(1,35), nq(18,18), nq(35,1)}, frames)

        end)
        it("takes into account left and top", function()
          g = newGrid(16,16,64,64,10,20)
          local frames = g:getFrames(1,3, 2,2, 3,1)
          assert_equivalent({nq(10,52), nq(26,36), nq(42,20)}, frames)

        end)
      end)

      describe("with a string", function()
        it("returns a list of frames", function()
          local frames = g:getFrames('1-2,2')
          assert_equal(nq(0,16) , frames[1])
          assert_equal(nq(16,16), frames[2])
        end)
        it("throws an error for invalid strings", function()
          assert_error(function() g:getFrames('foo') end)
          assert_error(function() g:getFrames('foo,bar') end)
          assert_error(function() g:getFrames('1,foo') end)
        end)
        it("throws an error for valid strings representing too big indexes", function()
          assert_error(function() g:getFrames('1000,1') end)
        end)
      end)

      describe("with several strings", function()
        it("returns a list of frames", function()
          local frames = g:getFrames('1-2,2', '3,2')
          assert_equivalent({nq(0,16), nq(16,16), nq(32,16)}, frames)
        end)
        it("counts backwards if the first number in the string is greater than the second one", function()
          local frames = g:getFrames('3-1,2')
          assert_equivalent({nq(32,16), nq(16,16), nq(0,16)}, frames)
        end)
      end)

      describe("with strings mixed up with numbers", function()
        it("returns a list of frames", function()
          local frames = g:getFrames('1-2,2', 3,2)
          assert_equivalent({nq(0,16), nq(16,16), nq(32,16)}, frames)
        end)
      end)

      describe("with a non-number or string", function()
        it("throws an error", function()
          assert_error(function() g:getFrames({1,10}) end)
        end)
      end)

      describe("When two similar grids are requested for the same quad", function()
        it("is not created twice", function()
          local g2 = newGrid(16,16,64,64)
          local q1 = setmetatable(g:getFrames(1,1)[1], nil)
          local q2 = setmetatable(g2:getFrames(1,1)[1], nil)
          assert_equal(q1, q2)
        end)
      end)

    end)

    describe("()", function()
      it("is a shortcut to :getFrames", function()
        local g = newGrid(16,16,64,64)
        assert_equal(g:getFrames(1,1)[1], g(1,1)[1])
      end)
    end)

  end)



  describe("newAnimation", function()

    it("Throws an error if the mode is not one of the 3 valid ones", function()
      assert_error(    function() newAnimation("foo",    {}, 1) end)
      assert_not_error(function() newAnimation("loop",   {}, 1) end)
      assert_not_error(function() newAnimation("once",   {}, 1) end)
      assert_not_error(function() newAnimation("bounce", {}, 1) end)
    end)
    it("Throws an error if defaultDelay is not a positive number", function()
      assert_error(function() newAnimation("loop", {}, 'foo') end)
      assert_error(function() newAnimation("loop", {}, -1)    end)
      assert_error(function() newAnimation("loop", {}, 0)     end)
    end)
    it("Throws an error if delays is not a table or nil", function()
      assert_error(function() newAnimation("loop", {}, 1, "") end)
      assert_error(function() newAnimation("loop", {}, 1, 5)  end)
    end)

    it("sets the basic stuff", function()
      local a = newAnimation("loop", {1,2,3}, 4)
      assert_equal("loop",    a.mode)
      assert_equal(0,         a.timer)
      assert_equal(1,         a.position)
      assert_equal(1,         a.direction)
      assert_equal("playing", a.status)
      assert_equivalent({1,2,3}, a.frames)
      assert_equivalent({4,4,4}, a.delays)
    end)
    it("makes a clone of the frame table", function()
      local frames = {1,2,3}
      local a = newAnimation("loop", frames, 4)
      assert_equivalent(frames, a.frames)
      assert_not_equal (frames, a.frames)
    end)

    describe("when parsing the delays", function()
      it("reads a simple array", function()
        local a = newAnimation("loop", {1,2,3,4}, 4, {5,6,7,8})
        assert_equivalent({5,6,7,8}, a.delays)
      end)
      it("reads a hash of numbers, padding the rest with the default", function()
        local a = newAnimation("loop", {1,2,3,4}, 4, {[2]=3, [4]=3})
        assert_equivalent({4,3,4,3}, a.delays)
      end)
      it("reads a hash with strings, padding the rest with the default", function()
        local a = newAnimation("loop", {1,2,3,4}, 4, {['1-3']=1})
        assert_equivalent({1,1,1,4}, a.delays)
      end)
      it("reads mixed-up delays", function()
        local a = newAnimation("loop", {1,2,3,4}, 4, {5, ['2-3']=2})
        assert_equivalent({5,2,2,4}, a.delays)
      end)
      describe("when given erroneous imput", function()
        it("throws errors for keys that are not integers or strings", function()
          assert_error(function() newAnimation("loop", {1}, 4, {[{}]=1}) end)
          assert_error(function() newAnimation("loop", {1}, 4, {[print]=1}) end)
        end)
        it("throws errors for integers with no frames", function()
          assert_error(function() newAnimation("loop", {1,2}, 4, {[3]=1}) end)
        end)
        it("throws errors for strings representing delays with no frames", function()
          assert_error(function() newAnimation("loop", {1,2}, 4, {["3-5"]=1}) end)
        end)
        it("throws errors for bogus strings", function()
          assert_error(function() newAnimation("loop", {1,2}, 4, {["foo"]=1}) end)
        end)
      end)
    end)
  end)

  describe("Animation", function()
    describe(":update", function()
      it("moves to the next frame", function()
        local a = newAnimation("loop", {1,2,3,4}, 1)
        a:update(1)
        assert_equal(1, a.position)
        a:update(0.1)
        assert_equal(2, a.position)
      end)
      it("moves several frames if needed", function()
        local a = newAnimation("loop", {1,2,3,4}, 1)
        a:update(2.1)
        assert_equal(3, a.position)
      end)

      describe("When the last frame is spent", function()
        it("goes back to the first frame in 'loop' animations", function()
          local a = newAnimation("loop", {1,2,3,4}, 1)
          a:update(4.1)
          assert_equal(1, a.position)
        end)
        it("stays there in 'once' animations", function()
          local a = newAnimation("once", {1,2,3,4}, 1)
          a:update(4.1)
          assert_equal(4, a.position)
        end)
        it("changes the status to 'finished' in 'once' animations", function()
          local a = newAnimation("once", {1,2,3,4}, 1)
          a:update(4.1)
          assert_equal("finished", a.status)
        end)
        it("bounces in 'bounce' animations", function()
          local a = newAnimation("bounce", {1,2,3}, 1)
          a:update(3.1)
          assert_equal(2, a.position)
          a:update(1)
          assert_equal(1, a.position)
          a:update(1)
          assert_equal(2, a.position)
          a:update(1)
          assert_equal(3, a.position)
        end)
      end)

      describe("When there are different delays per frame", function()
        it("moves the frame correctly", function()
          local a = newAnimation("loop", {1,2,3,4}, 1, {[2]=2})
          a:update(1.1)
          assert_equal(2, a.position)
          a:update(1.1)
          assert_equal(2, a.position)
          a:update(1.1)
          assert_equal(3, a.position)
        end)
      end)
    end)

    describe(":pause", function()
      it("stops animations from happening", function()
        local a = newAnimation("loop", {1,2,3,4}, 1)
        a:update(1.1)
        a:pause()
        a:update(1)
        assert_equal(2, a.position)
      end)
    end)

    describe(":resume", function()
      it("reanudates paused animations", function()
        local a = newAnimation("loop", {1,2,3,4}, 1)
        a:update(1.1)
        a:pause()
        a:resume()
        a:update(1)
        assert_equal(3, a.position)
      end)
    end)

    describe(":gotoFrame", function()
      it("moves the position to the frame specified", function()
        local a = newAnimation("loop", {1,2,3,4}, 1)
        a:update(1.1)
        a:gotoFrame(1)
        assert_equal(1, a.position)
      end)
    end)

    describe(":draw", function()
      it("invokes love.graphics.drawq with the expected parameters", function()
        local img, frame1, frame2, frame3 = {},{},{},{}
        local a   = newAnimation("loop", {frame1, frame2, frame3}, 1)
        a:draw(img, 10, 20, 0, 1,2,3,4)
        assert_equivalent({img, frame1, 10, 20, 0, 1,2,3,4}, getLastDrawq())

      end)
    end)

    describe(":clone", function()
      it("returns a new animation with the same properties - but reset to the initial frame", function()
        local frames = {1,2,3,4}
        local a = newAnimation("loop", frames, 1)
        a:update(1)
        a:pause()
        local b = a:clone()
        assert_equal(      "loop", b.mode)
        assert_not_equal(  frames, b.frames)
        assert_equivalent( frames, b.frames)
        assert_equivalent( a.delays, b.delays)
        assert_equal(      0, b.timer)
        assert_equal(      1, b.position)
        assert_equal(      1, b.direction)
        assert_equal(     "playing", b.status )
      end)
    end)


  end)

end)
