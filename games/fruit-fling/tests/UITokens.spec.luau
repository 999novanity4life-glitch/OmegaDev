--!nocheck
return function(t, load)
	local UITokens = load("src/shared/UITokens")
	local describe, it, expect = t.describe, t.it, t.expect

	describe("UITokens", function()
		it("contrast ratio matches WCAG reference values", function()
			expect(UITokens.contrastRatio({ 0, 0, 0 }, { 255, 255, 255 })).toBeNear(21, 1e-6)
			expect(UITokens.contrastRatio({ 119, 119, 119 }, { 255, 255, 255 })).toBeNear(4.48, 0.01)
			expect(UITokens.contrastRatio({ 10, 20, 30 }, { 10, 20, 30 })).toBe(1)
		end)
		it("every text pair reaches 4.5:1", function()
			for _, pair in UITokens.TEXT_PAIRS do
				local ratio = UITokens.contrastRatio(UITokens.Color[pair[1]], UITokens.Color[pair[2]])
				if ratio < 4.5 then
					print(string.format("%s on %s = %.2f", pair[1], pair[2], ratio))
				end
				expect(ratio >= 4.5).toBeTruthy()
			end
		end)
		it("text sizes respect the floor", function()
			for _, size in UITokens.Text do
				expect(size >= UITokens.MIN_TEXT).toBeTruthy()
			end
		end)
	end)
end
