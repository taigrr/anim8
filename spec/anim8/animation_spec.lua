require("spec.love-mocks")

local anim8 = require("anim8")
local newAnimation = anim8.newAnimation

describe("anim8", function()
	describe("newAnimation", function()
		it("Throws an error if durations is not a positive number or a table", function()
			assert.error(function()
				newAnimation({}, "foo")
			end)
			assert.error(function()
				newAnimation({}, -1)
			end)
			assert.error(function()
				newAnimation({}, 0)
			end)
		end)

		it("sets the basic stuff", function()
			local a = newAnimation({ 1, 2, 3 }, 4)
			assert.equal(0, a.timer)
			assert.equal(1, a.position)
			assert.equal("playing", a.status)
			assert.same({ 1, 2, 3 }, a.frames)
			assert.same({ 4, 4, 4 }, a.durations)
			assert.same({ 0, 4, 8, 12 }, a.intervals)
			assert.equal(12, a.totalDuration)
		end)
		it("makes a clone of the frame table", function()
			local frames = { 1, 2, 3 }
			local a = newAnimation(frames, 4)
			assert.same(frames, a.frames)
			assert.not_equal(frames, a.frames)
		end)

		describe("when parsing the durations", function()
			it("reads a simple array", function()
				local a = newAnimation({ 1, 2, 3, 4 }, { 5, 6, 7, 8 })
				assert.same({ 5, 6, 7, 8 }, a.durations)
			end)
			it("reads a hash with strings or numbers", function()
				local a = newAnimation({ 1, 2, 3, 4 }, { ["1-3"] = 1, [4] = 4 })
				assert.same({ 1, 1, 1, 4 }, a.durations)
			end)
			it("reads mixed-up durations", function()
				local a = newAnimation({ 1, 2, 3, 4 }, { 5, ["2-4"] = 2 })
				assert.same({ 5, 2, 2, 2 }, a.durations)
			end)
			describe("when given erroneous imput", function()
				it("throws errors for keys that are not integers or strings", function()
					assert.error(function()
						newAnimation({ 1 }, { [{}] = 1 })
					end)
					assert.error(function()
						newAnimation({ 1 }, { [print] = 1 })
					end)
					assert.error(function()
						newAnimation({ 1 }, { print })
					end)
				end)
				it("throws errors when frames are missing durations", function()
					assert.error(function()
						newAnimation({ 1, 2, 3, 4, 5 }, { ["1-3"] = 1 })
					end)
					assert.error(function()
						newAnimation({ 1, 2, 3, 4, 5 }, { 1, 2, 3, 4 })
					end)
				end)
			end)
		end)
	end)

	describe("Animation", function()
		describe(":update", function()
			it("moves to the next frame #focus", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:update(0.5)
				assert.equal(1, a.position)
				a:update(0.5)
				assert.equal(2, a.position)
			end)
			it("moves several frames if needed", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:update(2.1)
				assert.equal(3, a.position)
			end)

			describe("When the last frame is spent", function()
				it("goes back to the first frame in animations", function()
					local a = newAnimation({ 1, 2, 3, 4 }, 1)
					a:update(4.1)
					assert.equal(1, a.position)
				end)
			end)

			describe("When there are different durations per frame", function()
				it("moves the frame correctly", function()
					local a = newAnimation({ 1, 2, 3, 4 }, { 1, 2, 1, 1 })
					a:update(1.1)
					assert.equal(2, a.position)
					a:update(1.1)
					assert.equal(2, a.position)
					a:update(1.1)
					assert.equal(3, a.position)
				end)
			end)

			describe("When the animation loops", function()
				it("invokes the onloop callback", function()
					local looped = false
					local a = newAnimation({ 1, 2, 3 }, 1, function()
						looped = true
					end)
					assert.False(looped)
					a:update(4)
					assert.True(looped)
				end)
				it("accepts the callback as a string", function()
					local a = newAnimation({ 1, 2, 3 }, 1, "foo")
					a.foo = function(self)
						self.looped = true
					end
					assert.Nil(a.looped)
					a:update(4)
					assert.True(a.looped)
				end)
				it("counts the loops", function()
					local count = 0
					local a = newAnimation({ 1, 2, 3 }, 1, function(_, x)
						count = count + x
					end)
					a:update(4)
					assert.equals(count, 1)
					a:update(7)
					assert.equals(count, 3)
				end)
				it("counts negative loops", function()
					local count = 0
					local a = newAnimation({ 1, 2, 3 }, 1, function(_, x)
						count = count + x
					end)
					a:update(-2)
					assert.equals(count, -1)
					a:update(-6)
					assert.equals(count, -3)
				end)
			end)
		end)

		describe(":pause", function()
			it("stops animations from happening", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:update(1.1)
				a:pause()
				a:update(1)
				assert.equal(2, a.position)
			end)
		end)

		describe(":resume", function()
			it("reanudates paused animations", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:update(1.1)
				a:pause()
				a:resume()
				a:update(1)
				assert.equal(3, a.position)
			end)
		end)

		describe(":gotoFrame", function()
			it("moves the position and time to the frame specified", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:update(1.1)
				a:gotoFrame(1)
				assert.equal(1, a.position)
				assert.equal(0, a.timer)
			end)
		end)

		describe(":pauseAtEnd", function()
			it("goes to the last frame, and pauses", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:pauseAtEnd()
				assert.equal(4, a.position)
				assert.equal(4, a.timer)
				assert.equal("paused", a.status)
			end)
		end)

		describe(":pauseAtStart", function()
			it("goes to the first frame, and pauses", function()
				local a = newAnimation({ 1, 2, 3, 4 }, 1)
				a:pauseAtStart()
				assert.equal(1, a.position)
				assert.equal(0, a.timer)
				assert.equal("paused", a.status)
			end)
		end)

		describe(":draw", function()
			it("invokes love.graphics.draw with the expected parameters", function()
				spy.on(love.graphics, "draw")
				local img, frame1, frame2, frame3 = {}, {}, {}, {}
				local a = newAnimation({ frame1, frame2, frame3 }, 1)
				a:draw(img, 1, 2, 3, 4, 5, 6, 7, 8, 9)
				assert.spy(love.graphics.draw).was.called_with(img, frame1, 1, 2, 3, 4, 5, 6, 7, 8, 9)
			end)
		end)

		describe(":clone", function()
			it("returns a new animation with the same properties - but reset to the initial frame", function()
				local frames = { 1, 2, 3, 4 }
				local a = newAnimation(frames, 1)
				a:update(1)
				a:pause()
				local b = a:clone()
				assert.not_equal(frames, b.frames)
				assert.same(frames, b.frames)
				assert.same(a.durations, b.durations)
				assert.equal(0, b.timer)
				assert.equal(1, b.position)
				assert.equal("playing", b.status)

				assert.False(b.flippedH)
				assert.False(b.flippedV)

				a:flipV()
				assert.True(a:clone().flippedV)

				a:flipH()
				assert.True(a:clone().flippedH)
			end)
		end)

		describe(":getDimensions", function()
			it("returns the width and height of the current frame", function()
				local frame1 = love.graphics.newQuad(0, 0, 10, 10)
				local frame2 = love.graphics.newQuad(0, 0, 20, 30)
				local frame3 = love.graphics.newQuad(0, 0, 5, 15)

				local a = newAnimation({ frame1, frame2, frame3 }, 1)

				assert.same({ 10, 10 }, { a:getDimensions() })
				a:update(1.1)
				assert.same({ 20, 30 }, { a:getDimensions() })
				a:update(1)
				assert.same({ 5, 15 }, { a:getDimensions() })
				a:update(1)
				assert.same({ 10, 10 }, { a:getDimensions() })
			end)
		end)

		describe(":flipH and :flipV", function()
			local img, frame, a
			before_each(function()
				spy.on(love.graphics, "draw")
				img = {}
				frame = love.graphics.newQuad(1, 2, 3, 4) -- x,y,width, height
				a = newAnimation({ frame }, 1)
			end)
			it("defaults to non-flipped", function()
				assert.False(a.flippedH)
				assert.False(a.flippedV)
			end)

			it("Flips the animation horizontally (does not create a clone)", function()
				a:flipH()
				a:draw(img, 10, 20, 0, 5, 6, 7, 8, 9, 10)
				assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, -5, 6, 3 - 7, 8, -9, -10)

				assert.equal(a, a:flipH())
				a:draw(img, 10, 20, 0, 5, 6, 7, 8, 9, 10)
				assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, 5, 6, 7, 8, 9, 10)
			end)

			it("Flips the animation vertically (does not create a clone)", function()
				a:flipV()
				a:draw(img, 10, 20, 0, 5, 6, 7, 8, 9, 10)
				assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, 5, -6, 7, 4 - 8, -9, -10)

				assert.equal(a, a:flipV())
				a:draw(img, 10, 20, 0, 5, 6, 7, 8, 9, 10)
				assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, 5, 6, 7, 8, 9, 10)
			end)
		end)
	end)
end)
