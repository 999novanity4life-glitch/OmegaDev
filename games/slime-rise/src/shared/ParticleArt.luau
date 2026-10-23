--!strict
-- Hand-drawn particle styles (art/particles.py). Textures are white with
-- shading in alpha so each emitter's Color tints them; without a Texture
-- Roblox falls back to its default sparkle, which reads as stars.
--   Bubble: toon bubble that wobbles and pops at the end of its life (2x2 OneShot)
--   Goo:    lumpy goo blob that wobbles while it flies (2x2 Loop)
--   Drip:   teardrop that points along its fall
--   Streak: soft air streak for updrafts

local ParticleArt = {}

export type Kind = "Bubble" | "Goo" | "Drip" | "Streak"

local TEXTURES: { [Kind]: string } = {
	Bubble = "rbxassetid://98099726734333",
	Goo = "rbxassetid://136986632132995",
	Drip = "rbxassetid://72061933320294",
	Streak = "rbxassetid://117948986562706",
}

function ParticleArt.style(emitter: ParticleEmitter, kind: Kind): ParticleEmitter
	emitter.Texture = TEXTURES[kind]
	emitter.Brightness = 1
	if kind == "Bubble" then
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
		emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot
		emitter.Orientation = Enum.ParticleOrientation.FacingCamera
		emitter.LightEmission = 0.15
		-- Stay solid until the pop frame, then fade it out.
		emitter.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.72, 0.05),
			NumberSequenceKeypoint.new(1, 0.7),
		})
	elseif kind == "Goo" then
		emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2
		emitter.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		emitter.FlipbookFramerate = NumberRange.new(6, 9)
		emitter.FlipbookStartRandom = true
		emitter.Orientation = Enum.ParticleOrientation.FacingCamera
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-60, 60)
		emitter.LightEmission = 0.1
	elseif kind == "Drip" then
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		emitter.LightEmission = 0.1
	else
		emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
		emitter.LightEmission = 0.3
	end
	return emitter
end

return ParticleArt
