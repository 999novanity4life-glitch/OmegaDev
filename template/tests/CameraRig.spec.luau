--!nocheck
return function(t, load)
	local CameraRig = load("src/shared/CameraRig")
	local describe, it, expect = t.describe, t.it, t.expect
	local Shots = CameraRig.Shots

	describe("CameraRig", function()
		it("every ease starts at 0 and ends at 1", function()
			for _, name in { "Linear", "SineInOut", "QuadOut", "CubicInOut", "ExpoOut", "ExpoIn", "BackOut" } do
				expect(CameraRig.ease(name, 0)).toBeNear(0, 1e-3)
				expect(CameraRig.ease(name, 1)).toBeNear(1, 1e-3)
			end
		end)
		it("ease clamps outside 0..1 and rejects unknown names", function()
			expect(CameraRig.ease("Linear", -1)).toBe(0)
			expect(CameraRig.ease("Linear", 2)).toBe(1)
			expect(pcall(CameraRig.ease, "Wobble", 0.5)).toBe(false)
		end)
		it("sample hits the from and to poses at the ends", function()
			local shot = Shots.pushIn(2)
			local a = CameraRig.sample(shot, 0)
			local b = CameraRig.sample(shot, 1)
			expect(a.fov).toBeNear(shot.from.fov, 1e-6)
			expect(b.fov).toBeNear(shot.to.fov, 1e-6)
			expect(b.offset[3]).toBeNear(shot.to.offset[3], 1e-6)
		end)
		it("orbit sweeps the camera around the subject at constant distance", function()
			local shot = Shots.heroOrbit(3, 90)
			shot.from = { offset = { 0, 0.5, 9 }, look = { 0, 2.5, 0 }, fov = 55 }
			shot.to = shot.from
			local a = CameraRig.sample(shot, 0)
			local b = CameraRig.sample(shot, 1)
			local function flat(v)
				return math.sqrt(v[1] * v[1] + v[3] * v[3])
			end
			expect(flat(a.offset)).toBeNear(flat(b.offset), 1e-6)
			expect(b.offset[1]).toBeNear(9, 1e-6) -- {0,_,9} yawed 90 degrees -> {9,_,0}
			expect(b.offset[3]).toBeNear(0, 1e-6)
		end)
		it("toWorld puts 'back' behind a subject facing -Z, and turns with yaw", function()
			local p = CameraRig.toWorld({ 10, 0, 10 }, 0, { 0, 2, 5 })
			expect(p[1]).toBeNear(10, 1e-9)
			expect(p[2]).toBeNear(2, 1e-9)
			expect(p[3]).toBeNear(15, 1e-9)
			-- facing -X (yaw 90 degrees): behind is +X
			local q = CameraRig.toWorld({ 0, 0, 0 }, math.rad(90), { 0, 0, 5 })
			expect(q[1]).toBeNear(5, 1e-9)
			expect(q[3]).toBeNear(0, 1e-9)
		end)
		it("bezier passes through its end points", function()
			local p = CameraRig.bezier({ 0, 0, 0 }, { 1, 5, 0 }, { 2, 5, 0 }, { 3, 0, 0 }, 1)
			expect(p[1]).toBeNear(3, 1e-9)
			expect(p[2]).toBeNear(0, 1e-9)
		end)
		it("shake stays within its amplitude and is deterministic", function()
			for i = 0, 200 do
				local v = CameraRig.shake(i / 37, 0.5, 3)
				expect(math.sqrt(v[1] ^ 2 + v[2] ^ 2 + v[3] ^ 2) <= 0.5 + 1e-9).toBeTruthy()
			end
			expect(CameraRig.shake(1.25, 1, 2)[1]).toBe(CameraRig.shake(1.25, 1, 2)[1])
			expect(CameraRig.shake(1, 0)[1]).toBe(0)
		end)
		it("locate walks a shot list and clamps at the end", function()
			local shots = { Shots.pushIn(1), Shots.whipToFront(0.5), Shots.craneOut(2) }
			expect(CameraRig.total(shots)).toBeNear(3.5, 1e-9)
			local i, a = CameraRig.locate(shots, 0.5)
			expect(i).toBe(1)
			expect(a).toBeNear(0.5, 1e-9)
			i, a = CameraRig.locate(shots, 1.25)
			expect(i).toBe(2)
			expect(a).toBeNear(0.5, 1e-9)
			i, a = CameraRig.locate(shots, 99)
			expect(i).toBe(3)
			expect(a).toBe(1)
			expect((CameraRig.locate({}, 1))).toBe(nil)
		end)
		it("every built-in shot validates", function()
			local shots = {
				Shots.pushIn(1),
				Shots.heroOrbit(2),
				Shots.overShoulder(1),
				Shots.whipToFront(0.3),
				Shots.craneOut(2),
				Shots.lockedWide(3),
			}
			local ok, err = CameraRig.validate(shots)
			if not ok then
				print(err)
			end
			expect(ok).toBe(true)
		end)
		it("validate rejects bad shots", function()
			local bad = Shots.pushIn(0)
			expect((CameraRig.validate({ bad }))).toBe(false)
			local fov = Shots.pushIn(1)
			fov.to = { offset = { 0, 2, 5 }, look = { 0, 1, 0 }, fov = 150 }
			expect((CameraRig.validate({ fov }))).toBe(false)
			local nan = Shots.pushIn(1)
			nan.from = { offset = { 0 / 0, 2, 5 }, look = { 0, 1, 0 }, fov = 60 }
			expect((CameraRig.validate({ nan }))).toBe(false)
			local onTop = Shots.pushIn(1)
			onTop.to = { offset = { 0, 1, 0 }, look = { 0, 1, 0 }, fov = 60 }
			expect((CameraRig.validate({ onTop }))).toBe(false)
			local slow = Shots.pushIn(1)
			slow.timeScale = 0
			expect((CameraRig.validate({ slow }))).toBe(false)
			expect((CameraRig.validate({}))).toBe(false)
		end)
	end)
end
