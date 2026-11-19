--!strict
-- Pure "game feel" rules for combat: how hard each hit lands on screen
-- (hit-stop, shake, FOV kick, impact frames, slow-mo, sound pitch) and the
-- frame timing of a move (wind-up -> active -> recovery). No services, so it is
-- unit-tested under Lune; ImpactFX (client) plays the recipe.
--
-- Sources (see vault/17):
--   [VIDEO 2 @17:44] hit-stop around 20 ms registers without being noticed
--   (docs/research/videos-2026-10-28/02-art-of-screenshake.md); our rulebook
--   uses 70 ms for heavy hits (docs/rulebooks/SKILLS_VFX_RULEBOOK.md section 6).
--   [VIDEO 6 @3:41] rising pitch sells a combo.
--   [DOC] AnimationTrack:AdjustSpeed(0) pauses a track (hit-stop), and
--   ParticleEmitter.TimeScale 0..1 slows particles (slow-mo):
--   https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
--   https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
-- Tier numbers are studio starting points [INFERRED]; balance them in
-- Config.Feel, never here.

export type Tier = "Light" | "Heavy" | "Finisher" | "Ultimate"

export type TierFeel = {
	hitStop: number, -- seconds the attacker's and victim's tracks freeze
	shake: number, -- camera shake in studs (Juice.shakeCamera)
	fovKick: number, -- degrees added to FOV, then eased back
	impactFrames: number, -- rendered frames of high-contrast flash (0 = none)
	slowMo: number, -- seconds of slow motion after the hit (0 = none)
	slowMoScale: number, -- time scale during slow-mo (0..1]
	particles: number, -- multiplier on each emitter's EmitCount
	pitch: number, -- base sound pitch
}

export type FeelConfig = {
	Tiers: { Light: TierFeel, Heavy: TierFeel, Finisher: TierFeel, Ultimate: TierFeel },
	ComboPitchStep: number, -- pitch added per combo hit
	ComboPitchMax: number,
	ComboShakeStep: number, -- fraction of extra shake per combo hit
	ComboShakeMax: number,
	MaxHitStop: number,
	Fps: number, -- authoring frame rate for move timings
}

export type Recipe = TierFeel & { tier: Tier, combo: number }

export type Move = {
	name: string,
	tier: Tier,
	windup: number, -- frames of anticipation (readable telegraph)
	active: number, -- frames the hitbox is live
	recovery: number, -- frames before the next input is accepted
	hits: { number }?, -- frames (from move start) where a hit marker fires; default: first active frame
}

export type Beats = {
	total: number, -- seconds
	windupEnd: number,
	activeEnd: number,
	hits: { number }, -- seconds from move start
	cancelFrom: number, -- seconds when the next combo input is accepted
}

local CombatFeel = {}

local TIERS: { Tier } = { "Light" :: Tier, "Heavy" :: Tier, "Finisher" :: Tier, "Ultimate" :: Tier }
CombatFeel.TIERS = TIERS

local function isTier(s: string): boolean
	return table.find(TIERS, s :: Tier) ~= nil
end

local function tierFeel(config: FeelConfig, tier: string): TierFeel?
	local t = config.Tiers
	if tier == "Light" then
		return t.Light
	elseif tier == "Heavy" then
		return t.Heavy
	elseif tier == "Finisher" then
		return t.Finisher
	elseif tier == "Ultimate" then
		return t.Ultimate
	end
	return nil
end

-- The recipe for one hit. `combo` is 1 for the first hit of a string.
-- Reduced Motion keeps hit-stop and sound but drops shake, FOV kick, impact
-- frames and slow-mo (CLAUDE.md rule 4; GuiService.ReducedMotionEnabled).
function CombatFeel.forHit(config: FeelConfig, tier: Tier, combo: number, reducedMotion: boolean): Recipe
	local base = tierFeel(config, tier)
	assert(base, "unknown tier")
	local n = math.max(1, math.floor(combo))
	local shakeBoost = math.min(config.ComboShakeMax, (n - 1) * config.ComboShakeStep)
	local recipe: Recipe = {
		tier = tier,
		combo = n,
		hitStop = math.min(base.hitStop, config.MaxHitStop),
		shake = base.shake * (1 + shakeBoost),
		fovKick = base.fovKick,
		impactFrames = base.impactFrames,
		slowMo = base.slowMo,
		slowMoScale = math.clamp(base.slowMoScale, 0.05, 1),
		particles = base.particles,
		pitch = base.pitch + math.min(config.ComboPitchMax, (n - 1) * config.ComboPitchStep),
	}
	if reducedMotion then
		recipe.shake = 0
		recipe.fovKick = 0
		recipe.impactFrames = 0
		recipe.slowMo = 0
		recipe.slowMoScale = 1
	end
	return recipe
end

-- Frame data -> seconds. Hit markers must land inside the active window,
-- otherwise the animation and the hitbox disagree (the #1 "feels off" bug).
function CombatFeel.beats(config: FeelConfig, move: Move): Beats
	local fps = config.Fps
	local windupEnd = move.windup / fps
	local activeEnd = (move.windup + move.active) / fps
	local hits = {}
	local frames: { number } = move.hits or { move.windup }
	for _, frame in frames do
		table.insert(hits, frame / fps)
	end
	return {
		total = (move.windup + move.active + move.recovery) / fps,
		windupEnd = windupEnd,
		activeEnd = activeEnd,
		hits = hits,
		cancelFrom = activeEnd,
	}
end

function CombatFeel.validateMove(move: Move): (boolean, string?)
	if not isTier(move.tier) then
		return false, move.name .. ": unknown tier"
	end
	for _, key in { "windup", "active", "recovery" } do
		local v = (move :: any)[key] -- any: indexing the three numeric fields by name
		if type(v) ~= "number" or v < 0 or v ~= math.floor(v) then
			return false, move.name .. ": " .. key .. " must be a whole number of frames >= 0"
		end
	end
	if move.active < 1 then
		return false, move.name .. ": active needs at least 1 frame"
	end
	local frames: { number } = move.hits or {}
	for _, frame in frames do
		if frame < move.windup or frame >= move.windup + move.active then
			return false, string.format("%s: hit at frame %d is outside the active window", move.name, frame)
		end
	end
	return true, nil
end

-- Every tier must hit harder than the one below it, or the escalation reads flat.
function CombatFeel.validateConfig(config: FeelConfig): (boolean, string?)
	local prev: TierFeel? = nil
	for _, tier in TIERS do
		local feel = tierFeel(config, tier)
		if not feel then
			return false, "missing tier " .. tier
		end
		if feel.slowMoScale <= 0 or feel.slowMoScale > 1 then
			return false, tier .. ": slowMoScale must be in (0, 1]"
		end
		if prev then
			if feel.hitStop < prev.hitStop or feel.shake < prev.shake or feel.particles < prev.particles then
				return false, tier .. " must not be weaker than the tier below"
			end
		end
		prev = feel
	end
	return true, nil
end

return CombatFeel
