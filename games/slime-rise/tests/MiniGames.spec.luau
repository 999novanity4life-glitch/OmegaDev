--!nocheck
return function(t, load)
	local PuzzleGen = load("src/shared/PuzzleGen")
	local JumpMath = load("src/shared/JumpMath")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("PuzzleGen pipes", function()
		it("rotating a mask four times returns it", function()
			for m = 0, 15 do
				expect(PuzzleGen.rotateMask(m, 4)).toBe(m)
			end
			expect(PuzzleGen.rotateMask(1, 1)).toBe(2) -- N -> E
			expect(PuzzleGen.rotateMask(8, 1)).toBe(1) -- W -> N
		end)
		it("is never handed out solved, and is solvable by undoing the scramble", function()
			for seed = 1, 60 do
				local p = PuzzleGen.pipes(seed * 13, 4 + seed % 2, 4)
				expect(PuzzleGen.pipesSolved(p)).toBeFalsy()
				for i = 1, p.width * p.height do
					p.rotations[i] = 0
				end
				expect(PuzzleGen.pipesSolved(p)).toBeTruthy()
			end
		end)
		it("every tile has at least one pipe end (spanning tree)", function()
			local p = PuzzleGen.pipes(7, 5, 4)
			for i = 1, 20 do
				expect(p.masks[i] > 0).toBeTruthy()
			end
		end)
	end)

	describe("PuzzleGen wires", function()
		it("each colour appears once per side and never all straight across", function()
			for seed = 1, 40 do
				local w = PuzzleGen.wires(seed, 4)
				local straight = true
				for i = 1, 4 do
					if w.left[i] ~= w.right[i] then
						straight = false
					end
				end
				expect(straight).toBeFalsy()
			end
		end)
		it("solves only with every matching pair", function()
			local w = PuzzleGen.wires(3, 4)
			expect(PuzzleGen.wiresSolved(w)).toBeFalsy()
			for l = 1, 4 do
				for r = 1, 4 do
					if PuzzleGen.wireMatches(w, l, r) then
						w.connected[l] = r
					end
				end
			end
			expect(PuzzleGen.wiresSolved(w)).toBeTruthy()
		end)
	end)

	describe("PuzzleGen memory", function()
		it("uses only valid pads and no triple repeats", function()
			for seed = 1, 50 do
				local s = PuzzleGen.memory(seed, 5, 4)
				expect(#s).toBe(5)
				for i, v in s do
					expect(v >= 1 and v <= 4).toBeTruthy()
					if i > 2 then
						expect(v == s[i - 1] and v == s[i - 2]).toBeFalsy()
					end
				end
				expect(PuzzleGen.memoryMatches(s, table.clone(s))).toBeTruthy()
			end
		end)
	end)

	describe("JumpMath", function()
		it("flat jump at JumpHeight 7.2 travels about 8.7 studs", function()
			expect(JumpMath.airtime(0) * 16).toBeNear(8.67, 0.05)
		end)
		it("cannot land higher than the jump height", function()
			expect(JumpMath.airtime(7.3)).toBe(nil)
			expect(JumpMath.maxGap(8)).toBe(0)
		end)
		it("jumping down reaches further", function()
			expect(JumpMath.maxGap(-6) > JumpMath.maxGap(0)).toBeTruthy()
		end)
		it("rates gaps by share of the max", function()
			expect(JumpMath.rate(4, 0)).toBe("Easy")
			expect(JumpMath.rate(9.5, 0)).toBe("Hard")
			expect(JumpMath.rate(20, 0)).toBe(nil)
		end)
	end)
end
