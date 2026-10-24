--!strict
-- Generated from the Blender kits (assets/slime_cryo_kit_manifest.json, assets/slime_green_kit_manifest.json, assets/slime_lab_kit_manifest.json) by art/gen_kit_manifest.py. Do not edit by hand.
-- size/offset are in studs, Roblox axes (x, y up, z forward); offset is from the piece origin (base centre).

export type Part = { mesh: string, size: Vector3, offset: Vector3 }

local KitManifest: { [string]: { [string]: Part } } = {
	ArmPlatform = {
		Hazard = {
			mesh = "ArmPlatform__Hazard",
			size = Vector3.new(6.0, 0.12, 6.0),
			offset = Vector3.new(0.0, 0.66, 0.0),
		},
		Rubber = {
			mesh = "ArmPlatform__Rubber",
			size = Vector3.new(5.4, 0.1, 5.4),
			offset = Vector3.new(0.0, 0.65, 0.0),
		},
		Steel = {
			mesh = "ArmPlatform__Steel",
			size = Vector3.new(6.0, 1.7, 6.0),
			offset = Vector3.new(0.0, -0.25, 0.0),
		},
	},
	BouncePad = {
		Dark = {
			mesh = "BouncePad__Dark",
			size = Vector3.new(5.3, 0.5, 4.657),
			offset = Vector3.new(0.0, 0.35, 0.0),
		},
		Hazard = {
			mesh = "BouncePad__Hazard",
			size = Vector3.new(5.18, 0.28, 5.18),
			offset = Vector3.new(0.0, 0.62, 0.0),
		},
		Slime = {
			mesh = "BouncePad__Slime",
			size = Vector3.new(4.4, 1.98, 4.4),
			offset = Vector3.new(0.0, 0.6, 0.0),
		},
		Steel = {
			mesh = "BouncePad__Steel",
			size = Vector3.new(5.2, 0.6, 5.2),
			offset = Vector3.new(0.0, 0.3, 0.0),
		},
	},
	Catwalk = {
		Dark = {
			mesh = "Catwalk__Dark",
			size = Vector3.new(7.4, 0.12, 3.18),
			offset = Vector3.new(0.0, 0.04, 0.0),
		},
		Hazard = {
			mesh = "Catwalk__Hazard",
			size = Vector3.new(8.0, 3.2, 0.18),
			offset = Vector3.new(0.0, 1.6, 1.85),
		},
		Steel = {
			mesh = "Catwalk__Steel",
			size = Vector3.new(8.0, 0.9, 4.0),
			offset = Vector3.new(0.0, 0.05, 0.0),
		},
	},
	CentrifugeBase = {
		Dark = {
			mesh = "CentrifugeBase__Dark",
			size = Vector3.new(5.2, 1.6, 5.2),
			offset = Vector3.new(0.0, 0.8, 0.0),
		},
		Steel = {
			mesh = "CentrifugeBase__Steel",
			size = Vector3.new(2.4, 1.2, 2.4),
			offset = Vector3.new(0.0, 2.2, 0.0),
		},
	},
	CentrifugeDisc = {
		Glow = {
			mesh = "CentrifugeDisc__Glow",
			size = Vector3.new(11.46, 0.16, 11.46),
			offset = Vector3.new(0.0, 0.82, 0.0),
		},
		Hazard = {
			mesh = "CentrifugeDisc__Hazard",
			size = Vector3.new(10.6, 0.06, 10.6),
			offset = Vector3.new(0.0, 0.92, 0.0),
		},
		Rubber = {
			mesh = "CentrifugeDisc__Rubber",
			size = Vector3.new(11.2, 0.1, 11.2),
			offset = Vector3.new(0.0, 0.85, 0.0),
		},
		Steel = {
			mesh = "CentrifugeDisc__Steel",
			size = Vector3.new(12.0, 1.2, 12.0),
			offset = Vector3.new(0.0, 0.6, 0.0),
		},
	},
	Conveyor = {
		Dark = {
			mesh = "Conveyor__Dark",
			size = Vector3.new(14.7, 1.1, 3.4),
			offset = Vector3.new(0.0, 1.9, 0.0),
		},
		Glow = {
			mesh = "Conveyor__Glow",
			size = Vector3.new(12.5, 0.12, 0.1),
			offset = Vector3.new(0.0, 1.5, -2.02),
		},
		Hazard = {
			mesh = "Conveyor__Hazard",
			size = Vector3.new(14.0, 0.45, 4.0),
			offset = Vector3.new(0.0, 2.45, 0.0),
		},
		Rubber = {
			mesh = "Conveyor__Rubber",
			size = Vector3.new(13.6, 0.18, 3.1),
			offset = Vector3.new(0.0, 2.19, 0.0),
		},
		Steel = {
			mesh = "Conveyor__Steel",
			size = Vector3.new(14.0, 2.1, 4.0),
			offset = Vector3.new(0.0, 1.05, 0.0),
		},
	},
	Crate = {
		Dark = {
			mesh = "Crate__Dark",
			size = Vector3.new(3.268, 3.131, 0.08),
			offset = Vector3.new(0.167, 1.02, -1.8),
		},
		Frame = {
			mesh = "Crate__Frame",
			size = Vector3.new(3.5, 3.5, 3.5),
			offset = Vector3.new(0.0, 2.0, 0.0),
		},
		Hazard = {
			mesh = "Crate__Hazard",
			size = Vector3.new(2.2, 0.6, 0.08),
			offset = Vector3.new(0.0, 2.2, -1.8),
		},
		Rubber = {
			mesh = "Crate__Rubber",
			size = Vector3.new(3.3, 0.2, 3.3),
			offset = Vector3.new(0.0, 3.9, 0.0),
		},
		Steel = {
			mesh = "Crate__Steel",
			size = Vector3.new(4.01, 4.01, 4.01),
			offset = Vector3.new(0.0, 2.0, 0.0),
		},
	},
	CryoCatwalk = {
		Dark = {
			mesh = "CryoCatwalk__Dark",
			size = Vector3.new(7.5, 0.84, 4.01),
			offset = Vector3.new(0.0, -0.03, -0.025),
		},
		Frame = {
			mesh = "CryoCatwalk__Frame",
			size = Vector3.new(7.7, 0.5, 0.1),
			offset = Vector3.new(0.0, 0.75, 1.77),
		},
		Frost = {
			mesh = "CryoCatwalk__Frost",
			size = Vector3.new(7.992, 2.86, 3.992),
			offset = Vector3.new(0.0, 1.755, 0.0),
		},
		Glow = {
			mesh = "CryoCatwalk__Glow",
			size = Vector3.new(7.1, 0.06, 0.04),
			offset = Vector3.new(0.0, 0.8, 1.71),
		},
		Hazard = {
			mesh = "CryoCatwalk__Hazard",
			size = Vector3.new(6.9, 0.36, 0.06),
			offset = Vector3.new(0.0, 0.095, -1.98),
		},
		Ice = {
			mesh = "CryoCatwalk__Ice",
			size = Vector3.new(7.207, 0.705, 4.009),
			offset = Vector3.new(-0.004, -0.653, -0.011),
		},
		Steel = {
			mesh = "CryoCatwalk__Steel",
			size = Vector3.new(7.9, 3.46, 3.9),
			offset = Vector3.new(0.0, 1.38, 0.0),
		},
	},
	CryoColumn = {
		Dark = {
			mesh = "CryoColumn__Dark",
			size = Vector3.new(9.5, 10.46, 9.5),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frame = {
			mesh = "CryoColumn__Frame",
			size = Vector3.new(8.4, 9.3, 8.4),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frost = {
			mesh = "CryoColumn__Frost",
			size = Vector3.new(9.251, 9.074, 9.251),
			offset = Vector3.new(-0.0, 5.156, 0.0),
		},
		Glow = {
			mesh = "CryoColumn__Glow",
			size = Vector3.new(8.92, 6.61, 8.92),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Hazard = {
			mesh = "CryoColumn__Hazard",
			size = Vector3.new(8.132, 8.35, 7.043),
			offset = Vector3.new(0.0, 5.2, -0.799),
		},
		Ice = {
			mesh = "CryoColumn__Ice",
			size = Vector3.new(9.343, 4.23, 9.325),
			offset = Vector3.new(0.011, 4.625, 0.02),
		},
		Inset = {
			mesh = "CryoColumn__Inset",
			size = Vector3.new(8.651, 8.9, 8.651),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Steel = {
			mesh = "CryoColumn__Steel",
			size = Vector3.new(10.0, 10.5, 10.0),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
	},
	CryoCrate = {
		Dark = {
			mesh = "CryoCrate__Dark",
			size = Vector3.new(3.56, 3.338, 3.78),
			offset = Vector3.new(0.0, 1.909, -0.11),
		},
		Frame = {
			mesh = "CryoCrate__Frame",
			size = Vector3.new(3.76, 3.72, 3.76),
			offset = Vector3.new(-0.0, 1.98, -0.0),
		},
		Frost = {
			mesh = "CryoCrate__Frost",
			size = Vector3.new(3.94, 3.882, 3.878),
			offset = Vector3.new(-0.002, 2.046, -0.003),
		},
		Glow = {
			mesh = "CryoCrate__Glow",
			size = Vector3.new(3.6, 3.205, 3.8),
			offset = Vector3.new(0.0, 1.903, -0.1),
		},
		Inset = {
			mesh = "CryoCrate__Inset",
			size = Vector3.new(3.26, 3.2, 3.26),
			offset = Vector3.new(0.0, 2.3, -0.0),
		},
		Rubber = {
			mesh = "CryoCrate__Rubber",
			size = Vector3.new(3.76, 0.16, 3.76),
			offset = Vector3.new(-0.0, 0.08, -0.0),
		},
		Steel = {
			mesh = "CryoCrate__Steel",
			size = Vector3.new(3.82, 3.42, 3.97),
			offset = Vector3.new(-0.0, 1.9, -0.015),
		},
	},
	CryoPipe = {
		Dark = {
			mesh = "CryoPipe__Dark",
			size = Vector3.new(11.96, 1.8, 2.394),
			offset = Vector3.new(0.0, 0.9, -0.247),
		},
		Frame = {
			mesh = "CryoPipe__Frame",
			size = Vector3.new(11.38, 2.2, 2.2),
			offset = Vector3.new(0.0, 1.2, 0.0),
		},
		Frost = {
			mesh = "CryoPipe__Frost",
			size = Vector3.new(11.042, 2.624, 2.543),
			offset = Vector3.new(-0.006, 1.318, 0.01),
		},
		Glow = {
			mesh = "CryoPipe__Glow",
			size = Vector3.new(7.47, 2.24, 2.24),
			offset = Vector3.new(0.0, 1.2, 0.0),
		},
		Hazard = {
			mesh = "CryoPipe__Hazard",
			size = Vector3.new(4.53, 0.869, 0.432),
			offset = Vector3.new(-1.085, 1.325, -1.216),
		},
		Ice = {
			mesh = "CryoPipe__Ice",
			size = Vector3.new(9.73, 0.574, 1.991),
			offset = Vector3.new(-0.025, 0.32, -0.0),
		},
		Inset = {
			mesh = "CryoPipe__Inset",
			size = Vector3.new(10.8, 2.0, 2.46),
			offset = Vector3.new(0.0, 1.2, -0.23),
		},
		Steel = {
			mesh = "CryoPipe__Steel",
			size = Vector3.new(12.0, 2.34, 2.594),
			offset = Vector3.new(0.0, 1.2, -0.127),
		},
	},
	CryoPod = {
		Dark = {
			mesh = "CryoPod__Dark",
			size = Vector3.new(3.4, 9.58, 3.651),
			offset = Vector3.new(0.0, 5.08, -0.126),
		},
		Frame = {
			mesh = "CryoPod__Frame",
			size = Vector3.new(3.9, 9.25, 3.9),
			offset = Vector3.new(0.0, 4.625, 0.0),
		},
		Frost = {
			mesh = "CryoPod__Frost",
			size = Vector3.new(3.744, 1.518, 3.744),
			offset = Vector3.new(0.0, 0.764, -0.0),
		},
		Glass = {
			mesh = "CryoPod__Glass",
			size = Vector3.new(2.76, 7.2, 2.76),
			offset = Vector3.new(0.0, 4.6, 0.0),
		},
		Glow = {
			mesh = "CryoPod__Glow",
			size = Vector3.new(3.94, 8.37, 3.94),
			offset = Vector3.new(0.0, 4.65, 0.0),
		},
		Hazard = {
			mesh = "CryoPod__Hazard",
			size = Vector3.new(0.14, 0.144, 0.106),
			offset = Vector3.new(0.0, 0.65, -1.839),
		},
		Ice = {
			mesh = "CryoPod__Ice",
			size = Vector3.new(2.264, 1.292, 2.257),
			offset = Vector3.new(0.046, 1.79, -0.058),
		},
		Rubber = {
			mesh = "CryoPod__Rubber",
			size = Vector3.new(3.98, 7.682, 0.507),
			offset = Vector3.new(0.0, 4.679, 0.729),
		},
		Slime = {
			mesh = "CryoPod__Slime",
			size = Vector3.new(1.568, 1.52, 1.368),
			offset = Vector3.new(0.063, 4.402, 0.0),
		},
		Steel = {
			mesh = "CryoPod__Steel",
			size = Vector3.new(3.98, 9.94, 3.98),
			offset = Vector3.new(0.0, 5.01, 0.0),
		},
	},
	CryoRack = {
		Dark = {
			mesh = "CryoRack__Dark",
			size = Vector3.new(5.6, 11.035, 2.82),
			offset = Vector3.new(0.0, 5.712, -0.05),
		},
		Frame = {
			mesh = "CryoRack__Frame",
			size = Vector3.new(5.9, 11.78, 2.84),
			offset = Vector3.new(0.0, 5.89, 0.0),
		},
		Frost = {
			mesh = "CryoRack__Frost",
			size = Vector3.new(6.01, 11.347, 2.95),
			offset = Vector3.new(0.0, 6.278, 0.0),
		},
		Glass = {
			mesh = "CryoRack__Glass",
			size = Vector3.new(3.0, 8.637, 0.06),
			offset = Vector3.new(0.0, 6.065, -1.36),
		},
		Glow = {
			mesh = "CryoRack__Glow",
			size = Vector3.new(2.6, 7.727, 0.105),
			offset = Vector3.new(0.0, 5.135, -1.048),
		},
		Hazard = {
			mesh = "CryoRack__Hazard",
			size = Vector3.new(0.12, 7.207, 0.06),
			offset = Vector3.new(1.15, 4.895, -1.07),
		},
		Rubber = {
			mesh = "CryoRack__Rubber",
			size = Vector3.new(0.44, 8.923, 0.304),
			offset = Vector3.new(-1.05, 6.622, 1.342),
		},
		Slime = {
			mesh = "CryoRack__Slime",
			size = Vector3.new(2.029, 7.987, 0.28),
			offset = Vector3.new(0.114, 5.795, -1.16),
		},
		Steel = {
			mesh = "CryoRack__Steel",
			size = Vector3.new(5.9, 10.98, 2.94),
			offset = Vector3.new(0.0, 5.75, -0.05),
		},
	},
	CryoTank = {
		Dark = {
			mesh = "CryoTank__Dark",
			size = Vector3.new(5.4, 6.17, 5.4),
			offset = Vector3.new(0.0, 3.585, 0.0),
		},
		Frame = {
			mesh = "CryoTank__Frame",
			size = Vector3.new(5.7, 8.845, 5.7),
			offset = Vector3.new(0.0, 4.422, -0.0),
		},
		Frost = {
			mesh = "CryoTank__Frost",
			size = Vector3.new(5.497, 7.609, 5.497),
			offset = Vector3.new(-0.0, 4.421, 0.0),
		},
		Glass = {
			mesh = "CryoTank__Glass",
			size = Vector3.new(1.32, 3.9, 0.06),
			offset = Vector3.new(0.0, 3.35, -2.78),
		},
		Glow = {
			mesh = "CryoTank__Glow",
			size = Vector3.new(4.98, 5.145, 5.267),
			offset = Vector3.new(0.0, 4.023, -0.143),
		},
		Hazard = {
			mesh = "CryoTank__Hazard",
			size = Vector3.new(4.82, 7.63, 5.872),
			offset = Vector3.new(0.0, 5.185, 0.059),
		},
		Ice = {
			mesh = "CryoTank__Ice",
			size = Vector3.new(5.54, 1.027, 5.0),
			offset = Vector3.new(0.023, 7.587, 0.196),
		},
		Inset = {
			mesh = "CryoTank__Inset",
			size = Vector3.new(3.291, 0.604, 0.302),
			offset = Vector3.new(0.029, 6.2, -2.582),
		},
		Rubber = {
			mesh = "CryoTank__Rubber",
			size = Vector3.new(4.4, 0.08, 4.4),
			offset = Vector3.new(0.0, 8.96, 0.0),
		},
		Steel = {
			mesh = "CryoTank__Steel",
			size = Vector3.new(5.456, 8.935, 6.12),
			offset = Vector3.new(0.0, 4.497, 0.17),
		},
	},
	CryoWallPlain = {
		Dark = {
			mesh = "CryoWallPlain__Dark",
			size = Vector3.new(6.8, 9.95, 1.35),
			offset = Vector3.new(0.0, 5.285, -0.095),
		},
		Frame = {
			mesh = "CryoWallPlain__Frame",
			size = Vector3.new(8.0, 10.5, 1.4),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frost = {
			mesh = "CryoWallPlain__Frost",
			size = Vector3.new(6.561, 8.882, 0.709),
			offset = Vector3.new(0.0, 5.079, -0.42),
		},
		Glow = {
			mesh = "CryoWallPlain__Glow",
			size = Vector3.new(6.2, 5.485, 0.095),
			offset = Vector3.new(0.0, 6.962, -0.702),
		},
		Hazard = {
			mesh = "CryoWallPlain__Hazard",
			size = Vector3.new(5.8, 0.34, 0.06),
			offset = Vector3.new(0.0, 0.42, -0.71),
		},
		Ice = {
			mesh = "CryoWallPlain__Ice",
			size = Vector3.new(5.9, 0.735, 0.247),
			offset = Vector3.new(-0.037, 9.283, -0.64),
		},
		Inset = {
			mesh = "CryoWallPlain__Inset",
			size = Vector3.new(6.46, 8.66, 0.5),
			offset = Vector3.new(0.0, 5.2, -0.2),
		},
		Steel = {
			mesh = "CryoWallPlain__Steel",
			size = Vector3.new(7.9, 9.03, 0.44),
			offset = Vector3.new(0.0, 5.715, -0.57),
		},
	},
	CryoWallVent = {
		Dark = {
			mesh = "CryoWallVent__Dark",
			size = Vector3.new(6.8, 9.95, 1.35),
			offset = Vector3.new(0.0, 5.285, -0.095),
		},
		Frame = {
			mesh = "CryoWallVent__Frame",
			size = Vector3.new(8.0, 10.5, 1.4),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frost = {
			mesh = "CryoWallVent__Frost",
			size = Vector3.new(6.561, 8.882, 0.94),
			offset = Vector3.new(0.0, 5.079, -0.305),
		},
		Glow = {
			mesh = "CryoWallVent__Glow",
			size = Vector3.new(6.2, 7.005, 0.14),
			offset = Vector3.new(0.0, 6.202, -0.68),
		},
		Hazard = {
			mesh = "CryoWallVent__Hazard",
			size = Vector3.new(5.8, 8.45, 0.1),
			offset = Vector3.new(0.0, 4.475, -0.69),
		},
		Ice = {
			mesh = "CryoWallVent__Ice",
			size = Vector3.new(5.617, 7.994, 0.266),
			offset = Vector3.new(-0.033, 5.653, -0.613),
		},
		Inset = {
			mesh = "CryoWallVent__Inset",
			size = Vector3.new(6.46, 8.66, 0.5),
			offset = Vector3.new(0.0, 5.2, -0.2),
		},
		Steel = {
			mesh = "CryoWallVent__Steel",
			size = Vector3.new(7.9, 9.03, 0.94),
			offset = Vector3.new(0.0, 5.715, -0.32),
		},
	},
	CryoWallWindow = {
		Dark = {
			mesh = "CryoWallWindow__Dark",
			size = Vector3.new(6.8, 9.95, 1.35),
			offset = Vector3.new(0.0, 5.285, -0.095),
		},
		Frame = {
			mesh = "CryoWallWindow__Frame",
			size = Vector3.new(8.0, 10.5, 1.4),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frost = {
			mesh = "CryoWallWindow__Frost",
			size = Vector3.new(6.561, 6.949, 0.936),
			offset = Vector3.new(0.0, 4.125, -0.307),
		},
		Glass = {
			mesh = "CryoWallWindow__Glass",
			size = Vector3.new(4.4, 4.6, 0.06),
			offset = Vector3.new(0.0, 5.3, -0.33),
		},
		Glow = {
			mesh = "CryoWallWindow__Glow",
			size = Vector3.new(6.2, 2.265, 0.85),
			offset = Vector3.new(0.0, 8.573, -0.325),
		},
		Hazard = {
			mesh = "CryoWallWindow__Hazard",
			size = Vector3.new(5.8, 0.34, 0.06),
			offset = Vector3.new(0.0, 0.42, -0.71),
		},
		Ice = {
			mesh = "CryoWallWindow__Ice",
			size = Vector3.new(5.618, 6.832, 1.014),
			offset = Vector3.new(-0.047, 6.234, -0.263),
		},
		Inset = {
			mesh = "CryoWallWindow__Inset",
			size = Vector3.new(6.46, 8.66, 0.5),
			offset = Vector3.new(0.0, 5.2, -0.2),
		},
		Steel = {
			mesh = "CryoWallWindow__Steel",
			size = Vector3.new(7.9, 9.03, 0.915),
			offset = Vector3.new(0.0, 5.715, -0.333),
		},
	},
	Fan = {
		Dark = {
			mesh = "Fan__Dark",
			size = Vector3.new(7.0, 0.6, 7.0),
			offset = Vector3.new(0.0, 0.75, 0.0),
		},
		Glow = {
			mesh = "Fan__Glow",
			size = Vector3.new(7.56, 0.16, 7.56),
			offset = Vector3.new(0.0, 1.02, 0.0),
		},
		Steel = {
			mesh = "Fan__Steel",
			size = Vector3.new(7.8, 1.12, 7.8),
			offset = Vector3.new(0.0, 0.56, 0.0),
		},
	},
	FanBlades = {
		Dark = {
			mesh = "FanBlades__Dark",
			size = Vector3.new(5.483, 3.913, 5.923),
			offset = Vector3.new(0.158, 0.2, 0.0),
		},
		Steel = {
			mesh = "FanBlades__Steel",
			size = Vector3.new(1.0, 0.4, 1.0),
			offset = Vector3.new(0.0, 0.2, 0.0),
		},
	},
	FrostPanel = {
		Dark = {
			mesh = "FrostPanel__Dark",
			size = Vector3.new(4.18, 0.06, 4.18),
			offset = Vector3.new(0.0, 0.12, 0.0),
		},
		Frame = {
			mesh = "FrostPanel__Frame",
			size = Vector3.new(4.94, 0.62, 4.94),
			offset = Vector3.new(0.0, 0.31, 0.0),
		},
		Frost = {
			mesh = "FrostPanel__Frost",
			size = Vector3.new(5.014, 0.207, 5.014),
			offset = Vector3.new(0.0, 0.582, 0.0),
		},
		Glass = {
			mesh = "FrostPanel__Glass",
			size = Vector3.new(4.22, 0.34, 4.22),
			offset = Vector3.new(0.0, 0.4, 0.0),
		},
		Glow = {
			mesh = "FrostPanel__Glow",
			size = Vector3.new(4.98, 0.35, 4.98),
			offset = Vector3.new(0.0, 0.435, -0.0),
		},
		Steel = {
			mesh = "FrostPanel__Steel",
			size = Vector3.new(4.94, 0.67, 4.94),
			offset = Vector3.new(0.0, 0.335, 0.0),
		},
	},
	GreenBeam = {
		Bark = {
			mesh = "GreenBeam__Bark",
			size = Vector3.new(11.313, 2.403, 2.509),
			offset = Vector3.new(-0.009, 1.027, -0.007),
		},
		Frame = {
			mesh = "GreenBeam__Frame",
			size = Vector3.new(12.0, 2.4, 2.4),
			offset = Vector3.new(0.0, 1.2, 0.0),
		},
		Glow = {
			mesh = "GreenBeam__Glow",
			size = Vector3.new(12.02, 1.381, 2.45),
			offset = Vector3.new(0.0, 1.394, 0.0),
		},
		Inset = {
			mesh = "GreenBeam__Inset",
			size = Vector3.new(10.8, 0.04, 1.7),
			offset = Vector3.new(0.0, 2.39, 0.0),
		},
		Leaf = {
			mesh = "GreenBeam__Leaf",
			size = Vector3.new(11.143, 2.524, 3.658),
			offset = Vector3.new(-0.047, 0.893, -0.016),
		},
		Petal = {
			mesh = "GreenBeam__Petal",
			size = Vector3.new(9.799, 1.311, 2.413),
			offset = Vector3.new(0.279, 1.044, -0.027),
		},
		Slime = {
			mesh = "GreenBeam__Slime",
			size = Vector3.new(9.389, 0.919, 2.418),
			offset = Vector3.new(0.3, 1.058, 0.001),
		},
		Steel = {
			mesh = "GreenBeam__Steel",
			size = Vector3.new(12.02, 2.295, 1.86),
			offset = Vector3.new(0.0, 1.278, 0.0),
		},
	},
	GreenCatwalk = {
		Bark = {
			mesh = "GreenCatwalk__Bark",
			size = Vector3.new(7.347, 4.025, 4.096),
			offset = Vector3.new(0.038, 1.101, -0.15),
		},
		Dark = {
			mesh = "GreenCatwalk__Dark",
			size = Vector3.new(7.26, 0.87, 3.26),
			offset = Vector3.new(0.0, -0.045, 0.0),
		},
		Frame = {
			mesh = "GreenCatwalk__Frame",
			size = Vector3.new(7.9, 1.89, 3.905),
			offset = Vector3.new(0.0, 0.565, 0.002),
		},
		Glow = {
			mesh = "GreenCatwalk__Glow",
			size = Vector3.new(6.9, 0.05, 0.05),
			offset = Vector3.new(0.0, 0.38, -1.97),
		},
		Inset = {
			mesh = "GreenCatwalk__Inset",
			size = Vector3.new(7.6, 0.95, 0.75),
			offset = Vector3.new(0.0, 0.975, 1.53),
		},
		Leaf = {
			mesh = "GreenCatwalk__Leaf",
			size = Vector3.new(8.078, 3.686, 4.496),
			offset = Vector3.new(0.047, 1.364, 0.088),
		},
		Petal = {
			mesh = "GreenCatwalk__Petal",
			size = Vector3.new(3.763, 0.391, 0.428),
			offset = Vector3.new(0.335, 2.168, 1.477),
		},
		Slime = {
			mesh = "GreenCatwalk__Slime",
			size = Vector3.new(3.453, 0.294, 0.147),
			offset = Vector3.new(0.349, 2.175, 1.462),
		},
		Soil = {
			mesh = "GreenCatwalk__Soil",
			size = Vector3.new(7.4, 0.248, 0.52),
			offset = Vector3.new(0.0, 1.394, 1.53),
		},
		Steel = {
			mesh = "GreenCatwalk__Steel",
			size = Vector3.new(7.9, 3.39, 3.89),
			offset = Vector3.new(0.0, 1.315, -0.035),
		},
	},
	GreenColumn = {
		Bark = {
			mesh = "GreenColumn__Bark",
			size = Vector3.new(3.405, 8.355, 3.427),
			offset = Vector3.new(-0.036, 5.717, 0.167),
		},
		Dark = {
			mesh = "GreenColumn__Dark",
			size = Vector3.new(10.0, 9.7, 10.0),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frame = {
			mesh = "GreenColumn__Frame",
			size = Vector3.new(9.999, 10.5, 10.02),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Glass = {
			mesh = "GreenColumn__Glass",
			size = Vector3.new(8.7, 8.9, 8.7),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Glow = {
			mesh = "GreenColumn__Glow",
			size = Vector3.new(10.02, 9.6, 10.02),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Leaf = {
			mesh = "GreenColumn__Leaf",
			size = Vector3.new(7.641, 10.5, 8.55),
			offset = Vector3.new(0.283, 5.25, 0.022),
		},
		Slime = {
			mesh = "GreenColumn__Slime",
			size = Vector3.new(2.396, 8.028, 2.553),
			offset = Vector3.new(-0.152, 5.85, -0.103),
		},
		Steel = {
			mesh = "GreenColumn__Steel",
			size = Vector3.new(10.04, 10.5, 10.04),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
	},
	GreenPlanter = {
		Bark = {
			mesh = "GreenPlanter__Bark",
			size = Vector3.new(3.866, 3.138, 4.037),
			offset = Vector3.new(0.0, 2.219, 0.0),
		},
		Dark = {
			mesh = "GreenPlanter__Dark",
			size = Vector3.new(3.2, 3.45, 3.39),
			offset = Vector3.new(0.0, 1.725, -0.095),
		},
		Frame = {
			mesh = "GreenPlanter__Frame",
			size = Vector3.new(3.6, 3.76, 3.6),
			offset = Vector3.new(0.0, 2.0, 0.0),
		},
		Glass = {
			mesh = "GreenPlanter__Glass",
			size = Vector3.new(1.24, 1.074, 0.03),
			offset = Vector3.new(0.0, 2.05, -1.745),
		},
		Glow = {
			mesh = "GreenPlanter__Glow",
			size = Vector3.new(0.24, 0.24, 0.06),
			offset = Vector3.new(0.95, 1.05, -1.82),
		},
		Inset = {
			mesh = "GreenPlanter__Inset",
			size = Vector3.new(2.55, 2.85, 0.18),
			offset = Vector3.new(0.0, 2.025, -1.63),
		},
		Leaf = {
			mesh = "GreenPlanter__Leaf",
			size = Vector3.new(4.028, 1.967, 4.02),
			offset = Vector3.new(-0.003, 2.989, 0.008),
		},
		Petal = {
			mesh = "GreenPlanter__Petal",
			size = Vector3.new(3.466, 0.691, 0.184),
			offset = Vector3.new(-0.001, 3.308, -1.846),
		},
		Rubber = {
			mesh = "GreenPlanter__Rubber",
			size = Vector3.new(3.56, 0.14, 3.56),
			offset = Vector3.new(0.0, 0.07, 0.0),
		},
		Slime = {
			mesh = "GreenPlanter__Slime",
			size = Vector3.new(3.194, 2.573, 0.283),
			offset = Vector3.new(0.021, 2.252, -1.791),
		},
		Soil = {
			mesh = "GreenPlanter__Soil",
			size = Vector3.new(2.84, 0.36, 2.84),
			offset = Vector3.new(0.0, 3.75, 0.0),
		},
		Steel = {
			mesh = "GreenPlanter__Steel",
			size = Vector3.new(3.66, 3.66, 3.695),
			offset = Vector3.new(-0.0, 2.17, -0.038),
		},
	},
	GreenRack = {
		Bark = {
			mesh = "GreenRack__Bark",
			size = Vector3.new(0.385, 3.05, 0.393),
			offset = Vector3.new(-2.745, 9.997, -1.441),
		},
		Dark = {
			mesh = "GreenRack__Dark",
			size = Vector3.new(5.7, 11.65, 2.77),
			offset = Vector3.new(0.0, 5.825, 0.035),
		},
		Frame = {
			mesh = "GreenRack__Frame",
			size = Vector3.new(6.0, 12.0, 3.0),
			offset = Vector3.new(0.0, 6.0, 0.0),
		},
		Glass = {
			mesh = "GreenRack__Glass",
			size = Vector3.new(0.39, 1.2, 0.4),
			offset = Vector3.new(2.4, 2.2, 1.12),
		},
		Glow = {
			mesh = "GreenRack__Glow",
			size = Vector3.new(5.1, 10.95, 2.095),
			offset = Vector3.new(0.0, 6.395, -0.477),
		},
		Hazard = {
			mesh = "GreenRack__Hazard",
			size = Vector3.new(0.65, 0.64, 0.08),
			offset = Vector3.new(2.4, 3.2, 0.88),
		},
		Inset = {
			mesh = "GreenRack__Inset",
			size = Vector3.new(5.3, 11.15, 2.48),
			offset = Vector3.new(0.0, 6.435, -0.09),
		},
		Leaf = {
			mesh = "GreenRack__Leaf",
			size = Vector3.new(6.195, 10.459, 3.09),
			offset = Vector3.new(-0.184, 6.415, -0.087),
		},
		Petal = {
			mesh = "GreenRack__Petal",
			size = Vector3.new(0.501, 0.238, 0.479),
			offset = Vector3.new(0.579, 5.779, -0.016),
		},
		Slime = {
			mesh = "GreenRack__Slime",
			size = Vector3.new(4.795, 10.02, 2.635),
			offset = Vector3.new(0.153, 5.93, -0.047),
		},
		Soil = {
			mesh = "GreenRack__Soil",
			size = Vector3.new(5.1, 7.554, 2.2),
			offset = Vector3.new(0.0, 4.817, 0.02),
		},
		Steel = {
			mesh = "GreenRack__Steel",
			size = Vector3.new(6.06, 11.569, 3.06),
			offset = Vector3.new(0.0, 5.884, 0.0),
		},
	},
	GreenTank = {
		Bark = {
			mesh = "GreenTank__Bark",
			size = Vector3.new(0.55, 7.815, 1.128),
			offset = Vector3.new(-2.114, 4.765, -1.507),
		},
		Dark = {
			mesh = "GreenTank__Dark",
			size = Vector3.new(5.04, 7.73, 5.355),
			offset = Vector3.new(0.0, 4.395, -0.063),
		},
		Frame = {
			mesh = "GreenTank__Frame",
			size = Vector3.new(5.0, 9.0, 5.637),
			offset = Vector3.new(0.0, 4.5, 0.0),
		},
		Glass = {
			mesh = "GreenTank__Glass",
			size = Vector3.new(4.4, 5.9, 4.4),
			offset = Vector3.new(0.0, 4.6, 0.0),
		},
		Glow = {
			mesh = "GreenTank__Glow",
			size = Vector3.new(5.08, 7.185, 5.31),
			offset = Vector3.new(0.0, 4.608, -0.115),
		},
		Hazard = {
			mesh = "GreenTank__Hazard",
			size = Vector3.new(0.106, 0.296, 0.037),
			offset = Vector3.new(1.146, 2.58, -2.484),
		},
		Inset = {
			mesh = "GreenTank__Inset",
			size = Vector3.new(1.925, 6.679, 3.432),
			offset = Vector3.new(0.253, 5.65, -0.896),
		},
		Leaf = {
			mesh = "GreenTank__Leaf",
			size = Vector3.new(5.188, 6.303, 3.958),
			offset = Vector3.new(-0.562, 4.902, -0.181),
		},
		Petal = {
			mesh = "GreenTank__Petal",
			size = Vector3.new(0.747, 0.8, 0.72),
			offset = Vector3.new(0.03, 6.8, 0.0),
		},
		Rubber = {
			mesh = "GreenTank__Rubber",
			size = Vector3.new(4.4, 8.24, 5.406),
			offset = Vector3.new(0.0, 4.88, 0.503),
		},
		Slime = {
			mesh = "GreenTank__Slime",
			size = Vector3.new(4.16, 6.185, 4.85),
			offset = Vector3.new(0.0, 4.247, -0.345),
		},
		Soil = {
			mesh = "GreenTank__Soil",
			size = Vector3.new(2.0, 0.31, 2.0),
			offset = Vector3.new(0.0, 2.655, 0.0),
		},
		Steel = {
			mesh = "GreenTank__Steel",
			size = Vector3.new(5.0, 8.85, 5.818),
			offset = Vector3.new(0.0, 4.575, 0.328),
		},
	},
	GreenWallPlain = {
		Bark = {
			mesh = "GreenWallPlain__Bark",
			size = Vector3.new(5.856, 6.004, 0.429),
			offset = Vector3.new(-0.167, 4.157, -0.764),
		},
		Dark = {
			mesh = "GreenWallPlain__Dark",
			size = Vector3.new(6.8, 9.11, 1.3),
			offset = Vector3.new(0.0, 5.755, -0.07),
		},
		Frame = {
			mesh = "GreenWallPlain__Frame",
			size = Vector3.new(8.0, 10.5, 1.495),
			offset = Vector3.new(0.0, 5.25, -0.078),
		},
		Glass = {
			mesh = "GreenWallPlain__Glass",
			size = Vector3.new(5.527, 0.58, 0.04),
			offset = Vector3.new(0.175, 10.01, -0.72),
		},
		Glow = {
			mesh = "GreenWallPlain__Glow",
			size = Vector3.new(6.2, 0.07, 0.16),
			offset = Vector3.new(0.0, 9.42, -0.62),
		},
		Inset = {
			mesh = "GreenWallPlain__Inset",
			size = Vector3.new(6.7, 9.39, 0.75),
			offset = Vector3.new(0.0, 4.695, -0.4),
		},
		Leaf = {
			mesh = "GreenWallPlain__Leaf",
			size = Vector3.new(7.282, 5.983, 2.479),
			offset = Vector3.new(0.001, 4.221, -0.409),
		},
		Petal = {
			mesh = "GreenWallPlain__Petal",
			size = Vector3.new(0.551, 0.519, 0.193),
			offset = Vector3.new(-2.295, 5.338, -0.845),
		},
		Slime = {
			mesh = "GreenWallPlain__Slime",
			size = Vector3.new(5.039, 5.088, 0.441),
			offset = Vector3.new(-0.419, 7.756, -0.72),
		},
		Soil = {
			mesh = "GreenWallPlain__Soil",
			size = Vector3.new(6.4, 0.237, 0.55),
			offset = Vector3.new(0.0, 1.099, -0.38),
		},
		Steel = {
			mesh = "GreenWallPlain__Steel",
			size = Vector3.new(7.56, 9.275, 0.365),
			offset = Vector3.new(0.0, 4.882, -0.632),
		},
	},
	GreenWallVent = {
		Bark = {
			mesh = "GreenWallVent__Bark",
			size = Vector3.new(0.341, 2.423, 0.494),
			offset = Vector3.new(-2.9, 2.405, -0.847),
		},
		Dark = {
			mesh = "GreenWallVent__Dark",
			size = Vector3.new(6.8, 9.11, 1.3),
			offset = Vector3.new(0.0, 5.755, -0.07),
		},
		Frame = {
			mesh = "GreenWallVent__Frame",
			size = Vector3.new(8.0, 10.5, 1.495),
			offset = Vector3.new(0.0, 5.25, -0.078),
		},
		Glass = {
			mesh = "GreenWallVent__Glass",
			size = Vector3.new(5.527, 0.58, 0.04),
			offset = Vector3.new(0.175, 10.01, -0.72),
		},
		Glow = {
			mesh = "GreenWallVent__Glow",
			size = Vector3.new(6.2, 6.455, 0.46),
			offset = Vector3.new(0.0, 6.227, -0.77),
		},
		Hazard = {
			mesh = "GreenWallVent__Hazard",
			size = Vector3.new(1.518, 6.403, 0.562),
			offset = Vector3.new(2.509, 5.541, -0.711),
		},
		Inset = {
			mesh = "GreenWallVent__Inset",
			size = Vector3.new(6.7, 9.39, 0.75),
			offset = Vector3.new(0.0, 4.695, -0.4),
		},
		Leaf = {
			mesh = "GreenWallVent__Leaf",
			size = Vector3.new(7.172, 7.515, 2.617),
			offset = Vector3.new(-0.067, 4.987, -0.321),
		},
		Slime = {
			mesh = "GreenWallVent__Slime",
			size = Vector3.new(4.477, 5.08, 0.19),
			offset = Vector3.new(-0.7, 7.76, -0.795),
		},
		Soil = {
			mesh = "GreenWallVent__Soil",
			size = Vector3.new(6.4, 0.251, 0.55),
			offset = Vector3.new(0.0, 1.105, -0.38),
		},
		Steel = {
			mesh = "GreenWallVent__Steel",
			size = Vector3.new(7.56, 9.275, 0.583),
			offset = Vector3.new(0.0, 4.882, -0.711),
		},
	},
	GreenWallWindow = {
		Bark = {
			mesh = "GreenWallWindow__Bark",
			size = Vector3.new(6.135, 7.996, 0.428),
			offset = Vector3.new(-0.06, 5.176, -0.864),
		},
		Dark = {
			mesh = "GreenWallWindow__Dark",
			size = Vector3.new(6.8, 9.11, 1.3),
			offset = Vector3.new(0.0, 5.755, -0.07),
		},
		Frame = {
			mesh = "GreenWallWindow__Frame",
			size = Vector3.new(8.0, 10.5, 1.545),
			offset = Vector3.new(0.0, 5.25, -0.103),
		},
		Glass = {
			mesh = "GreenWallWindow__Glass",
			size = Vector3.new(5.639, 8.4, 0.435),
			offset = Vector3.new(0.119, 6.1, -0.523),
		},
		Glow = {
			mesh = "GreenWallWindow__Glow",
			size = Vector3.new(6.2, 0.745, 0.7),
			offset = Vector3.new(0.0, 9.083, -0.35),
		},
		Inset = {
			mesh = "GreenWallWindow__Inset",
			size = Vector3.new(6.7, 9.39, 0.75),
			offset = Vector3.new(0.0, 4.695, -0.4),
		},
		Leaf = {
			mesh = "GreenWallWindow__Leaf",
			size = Vector3.new(7.403, 8.505, 2.568),
			offset = Vector3.new(-0.045, 5.483, -0.283),
		},
		Petal = {
			mesh = "GreenWallWindow__Petal",
			size = Vector3.new(5.955, 3.422, 0.197),
			offset = Vector3.new(0.119, 4.98, -0.955),
		},
		Slime = {
			mesh = "GreenWallWindow__Slime",
			size = Vector3.new(5.859, 6.877, 0.366),
			offset = Vector3.new(-0.009, 6.861, -0.883),
		},
		Soil = {
			mesh = "GreenWallWindow__Soil",
			size = Vector3.new(6.4, 0.243, 0.55),
			offset = Vector3.new(0.0, 1.101, -0.38),
		},
		Steel = {
			mesh = "GreenWallWindow__Steel",
			size = Vector3.new(7.56, 9.275, 0.175),
			offset = Vector3.new(0.0, 4.882, -0.727),
		},
	},
	GrowLight = {
		Bark = {
			mesh = "GrowLight__Bark",
			size = Vector3.new(1.29, 0.763, 0.179),
			offset = Vector3.new(-1.243, 1.08, 0.345),
		},
		Dark = {
			mesh = "GrowLight__Dark",
			size = Vector3.new(3.94, 0.64, 0.9),
			offset = Vector3.new(0.0, 0.435, 0.0),
		},
		Frame = {
			mesh = "GrowLight__Frame",
			size = Vector3.new(3.6, 0.527, 1.265),
			offset = Vector3.new(0.0, 0.267, 0.0),
		},
		Glow = {
			mesh = "GrowLight__Glow",
			size = Vector3.new(3.15, 0.06, 0.69),
			offset = Vector3.new(0.0, 0.15, 0.0),
		},
		Inset = {
			mesh = "GrowLight__Inset",
			size = Vector3.new(0.7, 0.2, 0.4),
			offset = Vector3.new(0.9, 0.78, 0.0),
		},
		Leaf = {
			mesh = "GrowLight__Leaf",
			size = Vector3.new(0.855, 0.414, 0.506),
			offset = Vector3.new(-1.191, 0.699, 0.431),
		},
		Rubber = {
			mesh = "GrowLight__Rubber",
			size = Vector3.new(3.251, 0.69, 0.183),
			offset = Vector3.new(0.167, 1.111, 0.052),
		},
		Slime = {
			mesh = "GrowLight__Slime",
			size = Vector3.new(0.095, 0.1, 0.04),
			offset = Vector3.new(0.9, 0.8, -0.21),
		},
		Steel = {
			mesh = "GrowLight__Steel",
			size = Vector3.new(3.9, 1.4, 1.2),
			offset = Vector3.new(0.0, 0.75, 0.0),
		},
	},
	IceCluster = {
		Frost = {
			mesh = "IceCluster__Frost",
			size = Vector3.new(2.728, 0.518, 2.073),
			offset = Vector3.new(0.004, 0.263, 0.025),
		},
		Ice = {
			mesh = "IceCluster__Ice",
			size = Vector3.new(2.917, 2.601, 2.705),
			offset = Vector3.new(-0.011, 1.326, 0.022),
		},
	},
	IceLedge = {
		Dark = {
			mesh = "IceLedge__Dark",
			size = Vector3.new(4.8, 0.42, 0.05),
			offset = Vector3.new(0.0, 0.29, -1.22),
		},
		Frame = {
			mesh = "IceLedge__Frame",
			size = Vector3.new(5.98, 0.64, 2.8),
			offset = Vector3.new(0.0, 0.32, 0.1),
		},
		Glow = {
			mesh = "IceLedge__Glow",
			size = Vector3.new(4.5, 0.05, 0.05),
			offset = Vector3.new(0.0, 0.35, -1.245),
		},
		Hazard = {
			mesh = "IceLedge__Hazard",
			size = Vector3.new(4.6, 0.07, 0.04),
			offset = Vector3.new(0.0, 0.1, -1.22),
		},
		Ice = {
			mesh = "IceLedge__Ice",
			size = Vector3.new(5.9, 0.913, 2.928),
			offset = Vector3.new(0.0, 0.543, -0.014),
		},
		Steel = {
			mesh = "IceLedge__Steel",
			size = Vector3.new(5.75, 0.58, 2.76),
			offset = Vector3.new(0.0, 0.29, 0.12),
		},
	},
	LeafPad = {
		Bark = {
			mesh = "LeafPad__Bark",
			size = Vector3.new(1.198, 0.14, 1.147),
			offset = Vector3.new(0.002, 0.07, 0.349),
		},
		Leaf = {
			mesh = "LeafPad__Leaf",
			size = Vector3.new(5.012, 0.591, 4.988),
			offset = Vector3.new(0.0, 0.355, -0.001),
		},
		Slime = {
			mesh = "LeafPad__Slime",
			size = Vector3.new(3.855, 0.24, 4.698),
			offset = Vector3.new(-0.001, 0.445, -0.196),
		},
	},
	MushroomPad = {
		Bark = {
			mesh = "MushroomPad__Bark",
			size = Vector3.new(2.912, 0.409, 3.229),
			offset = Vector3.new(0.0, 0.44, 0.0),
		},
		Dark = {
			mesh = "MushroomPad__Dark",
			size = Vector3.new(3.603, 0.06, 4.16),
			offset = Vector3.new(0.0, 0.22, 0.0),
		},
		Frame = {
			mesh = "MushroomPad__Frame",
			size = Vector3.new(3.984, 0.2, 4.563),
			offset = Vector3.new(0.0, 0.1, 0.0),
		},
		Glow = {
			mesh = "MushroomPad__Glow",
			size = Vector3.new(3.776, 0.05, 4.36),
			offset = Vector3.new(0.0, 0.21, 0.0),
		},
		Inset = {
			mesh = "MushroomPad__Inset",
			size = Vector3.new(4.5, 0.75, 4.5),
			offset = Vector3.new(0.0, 0.675, 0.0),
		},
		Leaf = {
			mesh = "MushroomPad__Leaf",
			size = Vector3.new(2.268, 0.201, 3.631),
			offset = Vector3.new(0.236, 0.458, 0.147),
		},
		Petal = {
			mesh = "MushroomPad__Petal",
			size = Vector3.new(5.022, 1.1, 5.06),
			offset = Vector3.new(0.051, 1.05, 0.0),
		},
		Slime = {
			mesh = "MushroomPad__Slime",
			size = Vector3.new(4.208, 0.94, 4.198),
			offset = Vector3.new(0.0, 1.19, 0.0),
		},
		Soil = {
			mesh = "MushroomPad__Soil",
			size = Vector3.new(3.5, 0.32, 3.5),
			offset = Vector3.new(0.0, 0.36, 0.0),
		},
		Steel = {
			mesh = "MushroomPad__Steel",
			size = Vector3.new(4.24, 0.1, 3.704),
			offset = Vector3.new(0.0, 0.24, 0.0),
		},
	},
	MutantPlant = {
		Dark = {
			mesh = "MutantPlant__Dark",
			size = Vector3.new(2.893, 0.12, 3.34),
			offset = Vector3.new(0.0, 0.32, 0.0),
		},
		Frame = {
			mesh = "MutantPlant__Frame",
			size = Vector3.new(2.858, 1.35, 3.237),
			offset = Vector3.new(0.0, 0.675, 0.0),
		},
		Glow = {
			mesh = "MutantPlant__Glow",
			size = Vector3.new(2.91, 0.04, 3.36),
			offset = Vector3.new(0.0, 0.32, 0.0),
		},
		Inset = {
			mesh = "MutantPlant__Inset",
			size = Vector3.new(3.002, 5.279, 3.097),
			offset = Vector3.new(0.0, 3.239, -0.088),
		},
		Leaf = {
			mesh = "MutantPlant__Leaf",
			size = Vector3.new(3.577, 4.869, 3.835),
			offset = Vector3.new(0.104, 3.686, 0.084),
		},
		Petal = {
			mesh = "MutantPlant__Petal",
			size = Vector3.new(2.547, 3.349, 2.542),
			offset = Vector3.new(0.327, 4.207, -0.271),
		},
		Slime = {
			mesh = "MutantPlant__Slime",
			size = Vector3.new(1.61, 1.912, 2.457),
			offset = Vector3.new(0.605, 4.173, -0.552),
		},
		Soil = {
			mesh = "MutantPlant__Soil",
			size = Vector3.new(2.9, 0.16, 2.856),
			offset = Vector3.new(0.0, 1.44, 0.0),
		},
		Steel = {
			mesh = "MutantPlant__Steel",
			size = Vector3.new(2.737, 0.16, 3.139),
			offset = Vector3.new(0.0, 1.38, 0.0),
		},
	},
	Pillar = {
		Dark = {
			mesh = "Pillar__Dark",
			size = Vector3.new(0.4, 7.0, 2.3),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Frame = {
			mesh = "Pillar__Frame",
			size = Vector3.new(2.2, 10.5, 2.2),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Glow = {
			mesh = "Pillar__Glow",
			size = Vector3.new(0.15, 6.0, 2.32),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
		Steel = {
			mesh = "Pillar__Steel",
			size = Vector3.new(2.6, 10.5, 2.6),
			offset = Vector3.new(0.0, 5.25, 0.0),
		},
	},
	PipeBeam = {
		Dark = {
			mesh = "PipeBeam__Dark",
			size = Vector3.new(11.8, 2.36, 2.36),
			offset = Vector3.new(0.0, 1.0, 0.0),
		},
		Hazard = {
			mesh = "PipeBeam__Hazard",
			size = Vector3.new(1.2, 0.1, 2.2),
			offset = Vector3.new(0.0, 2.02, 0.0),
		},
		Steel = {
			mesh = "PipeBeam__Steel",
			size = Vector3.new(12.0, 2.056, 2.351),
			offset = Vector3.new(0.0, 1.0, 0.0),
		},
	},
	PlantSweeper = {
		Bark = {
			mesh = "PlantSweeper__Bark",
			size = Vector3.new(2.868, 1.12, 2.788),
			offset = Vector3.new(-0.025, 1.3, 0.111),
		},
		Dark = {
			mesh = "PlantSweeper__Dark",
			size = Vector3.new(2.633, 1.78, 3.04),
			offset = Vector3.new(0.0, 1.13, 0.0),
		},
		Frame = {
			mesh = "PlantSweeper__Frame",
			size = Vector3.new(2.598, 0.9, 2.948),
			offset = Vector3.new(0.0, 0.45, 0.0),
		},
		Glow = {
			mesh = "PlantSweeper__Glow",
			size = Vector3.new(2.65, 1.7, 3.06),
			offset = Vector3.new(0.0, 1.13, 0.0),
		},
		Inset = {
			mesh = "PlantSweeper__Inset",
			size = Vector3.new(2.734, 0.32, 2.66),
			offset = Vector3.new(0.0, 0.62, -0.0),
		},
		Leaf = {
			mesh = "PlantSweeper__Leaf",
			size = Vector3.new(1.775, 0.375, 1.738),
			offset = Vector3.new(0.069, 1.053, -0.019),
		},
		Petal = {
			mesh = "PlantSweeper__Petal",
			size = Vector3.new(1.163, 0.185, 1.163),
			offset = Vector3.new(0.0, 1.512, 0.0),
		},
		Soil = {
			mesh = "PlantSweeper__Soil",
			size = Vector3.new(2.6, 0.16, 2.561),
			offset = Vector3.new(0.0, 1.0, 0.0),
		},
		Steel = {
			mesh = "PlantSweeper__Steel",
			size = Vector3.new(2.46, 1.12, 2.819),
			offset = Vector3.new(0.0, 1.42, 0.0),
		},
	},
	PlantSweeperArm = {
		Bark = {
			mesh = "PlantSweeperArm__Bark",
			size = Vector3.new(9.532, 0.849, 0.895),
			offset = Vector3.new(0.0, 0.0, 0.0),
		},
		Frame = {
			mesh = "PlantSweeperArm__Frame",
			size = Vector3.new(1.2, 0.14, 1.2),
			offset = Vector3.new(0.0, 0.0, 0.0),
		},
		Glow = {
			mesh = "PlantSweeperArm__Glow",
			size = Vector3.new(0.5, 0.44, 0.5),
			offset = Vector3.new(0.0, 0.0, 0.0),
		},
		Leaf = {
			mesh = "PlantSweeperArm__Leaf",
			size = Vector3.new(9.96, 0.893, 1.166),
			offset = Vector3.new(0.0, 0.027, -0.039),
		},
		Petal = {
			mesh = "PlantSweeperArm__Petal",
			size = Vector3.new(10.141, 1.225, 1.172),
			offset = Vector3.new(0.0, 0.002, 0.001),
		},
		Slime = {
			mesh = "PlantSweeperArm__Slime",
			size = Vector3.new(9.385, 0.877, 0.856),
			offset = Vector3.new(0.0, 0.0, 0.0),
		},
		Steel = {
			mesh = "PlantSweeperArm__Steel",
			size = Vector3.new(1.1, 0.4, 1.1),
			offset = Vector3.new(0.0, 0.0, 0.0),
		},
	},
	RobotBase = {
		Dark = {
			mesh = "RobotBase__Dark",
			size = Vector3.new(4.0, 1.2, 4.0),
			offset = Vector3.new(0.0, 0.6, 0.0),
		},
		Frame = {
			mesh = "RobotBase__Frame",
			size = Vector3.new(3.687, 4.669, 1.0),
			offset = Vector3.new(0.0, 6.6, 0.0),
		},
		Hazard = {
			mesh = "RobotBase__Hazard",
			size = Vector3.new(2.2, 2.2, 2.2),
			offset = Vector3.new(0.0, 4.3, 0.0),
		},
		Steel = {
			mesh = "RobotBase__Steel",
			size = Vector3.new(3.55, 8.3, 2.6),
			offset = Vector3.new(0.475, 5.25, 0.0),
		},
	},
	Shelf = {
		Dark = {
			mesh = "Shelf__Dark",
			size = Vector3.new(5.5, 11.4, 0.15),
			offset = Vector3.new(0.0, 6.0, 1.4),
		},
		Frame = {
			mesh = "Shelf__Frame",
			size = Vector3.new(4.0, 7.0, 1.2),
			offset = Vector3.new(0.5, 6.55, 0.6),
		},
		Glass = {
			mesh = "Shelf__Glass",
			size = Vector3.new(4.9, 7.3, 0.9),
			offset = Vector3.new(0.0, 6.7, 0.6),
		},
		Hazard = {
			mesh = "Shelf__Hazard",
			size = Vector3.new(3.8, 6.25, 0.05),
			offset = Vector3.new(0.5, 6.7, 0.0),
		},
		Rubber = {
			mesh = "Shelf__Rubber",
			size = Vector3.new(5.4, 11.78, 2.5),
			offset = Vector3.new(0.0, 6.18, 0.0),
		},
		Slime = {
			mesh = "Shelf__Slime",
			size = Vector3.new(4.76, 6.8, 0.76),
			offset = Vector3.new(0.0, 6.45, 0.6),
		},
		Steel = {
			mesh = "Shelf__Steel",
			size = Vector3.new(6.0, 12.0, 3.0),
			offset = Vector3.new(0.0, 6.0, 0.0),
		},
	},
	Tank = {
		Dark = {
			mesh = "Tank__Dark",
			size = Vector3.new(5.2, 0.4, 5.2),
			offset = Vector3.new(0.0, 1.4, 0.0),
		},
		Glass = {
			mesh = "Tank__Glass",
			size = Vector3.new(5.0, 6.4, 5.0),
			offset = Vector3.new(0.0, 4.4, 0.0),
		},
		Hazard = {
			mesh = "Tank__Hazard",
			size = Vector3.new(5.56, 0.2, 5.56),
			offset = Vector3.new(0.0, 8.7, 0.0),
		},
		Rubber = {
			mesh = "Tank__Rubber",
			size = Vector3.new(5.1, 0.15, 5.1),
			offset = Vector3.new(0.0, 8.67, 0.0),
		},
		Slime = {
			mesh = "Tank__Slime",
			size = Vector3.new(4.5, 4.48, 4.5),
			offset = Vector3.new(0.0, 3.54, 0.0),
		},
		Steel = {
			mesh = "Tank__Steel",
			size = Vector3.new(5.728, 8.65, 6.27),
			offset = Vector3.new(0.0, 4.325, 0.265),
		},
	},
	VineTruss = {
		Bark = {
			mesh = "VineTruss__Bark",
			size = Vector3.new(2.661, 11.238, 2.569),
			offset = Vector3.new(0.005, 5.802, -0.005),
		},
		Dark = {
			mesh = "VineTruss__Dark",
			size = Vector3.new(1.9, 0.08, 1.9),
			offset = Vector3.new(0.0, 11.62, 0.0),
		},
		Frame = {
			mesh = "VineTruss__Frame",
			size = Vector3.new(2.0, 12.0, 2.0),
			offset = Vector3.new(0.0, 6.0, 0.0),
		},
		Glow = {
			mesh = "VineTruss__Glow",
			size = Vector3.new(1.94, 0.04, 1.94),
			offset = Vector3.new(0.0, 11.62, 0.0),
		},
		Inset = {
			mesh = "VineTruss__Inset",
			size = Vector3.new(1.5, 0.04, 1.5),
			offset = Vector3.new(0.0, 12.0, 0.0),
		},
		Leaf = {
			mesh = "VineTruss__Leaf",
			size = Vector3.new(3.985, 9.291, 4.36),
			offset = Vector3.new(0.013, 6.056, 0.007),
		},
		Petal = {
			mesh = "VineTruss__Petal",
			size = Vector3.new(2.535, 7.911, 2.753),
			offset = Vector3.new(-0.024, 6.509, 0.01),
		},
		Slime = {
			mesh = "VineTruss__Slime",
			size = Vector3.new(2.351, 7.605, 2.686),
			offset = Vector3.new(-0.02, 6.51, 0.03),
		},
		Steel = {
			mesh = "VineTruss__Steel",
			size = Vector3.new(2.06, 11.3, 2.06),
			offset = Vector3.new(0.0, 6.0, 0.0),
		},
	},
	WallPipes = {
		Dark = {
			mesh = "WallPipes__Dark",
			size = Vector3.new(6.4, 7.2, 0.6),
			offset = Vector3.new(0.0, 6.075, -0.25),
		},
		Frame = {
			mesh = "WallPipes__Frame",
			size = Vector3.new(8.0, 10.5, 1.38),
			offset = Vector3.new(0.0, 5.25, -0.05),
		},
		Glass = {
			mesh = "WallPipes__Glass",
			size = Vector3.new(3.92, 8.1, 1.2),
			offset = Vector3.new(1.36, 5.6, -0.75),
		},
		Glow = {
			mesh = "WallPipes__Glow",
			size = Vector3.new(6.1, 0.14, 0.12),
			offset = Vector3.new(0.0, 9.5, -0.48),
		},
		Hazard = {
			mesh = "WallPipes__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = {
			mesh = "WallPipes__Inset",
			size = Vector3.new(7.6, 10.1, 0.7),
			offset = Vector3.new(0.0, 5.25, 0.1),
		},
		Slime = {
			mesh = "WallPipes__Slime",
			size = Vector3.new(0.9, 7.9, 0.9),
			offset = Vector3.new(0.0, 5.6, -0.75),
		},
		Steel = {
			mesh = "WallPipes__Steel",
			size = Vector3.new(5.84, 8.1, 1.48),
			offset = Vector3.new(0.53, 5.6, -0.75),
		},
	},
	WallPlain = {
		Dark = {
			mesh = "WallPlain__Dark",
			size = Vector3.new(6.4, 0.35, 0.5),
			offset = Vector3.new(0.0, 9.5, -0.25),
		},
		Frame = {
			mesh = "WallPlain__Frame",
			size = Vector3.new(8.0, 10.5, 1.38),
			offset = Vector3.new(0.0, 5.25, -0.05),
		},
		Glow = {
			mesh = "WallPlain__Glow",
			size = Vector3.new(6.1, 0.14, 0.12),
			offset = Vector3.new(0.0, 9.5, -0.48),
		},
		Hazard = {
			mesh = "WallPlain__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = {
			mesh = "WallPlain__Inset",
			size = Vector3.new(7.6, 10.1, 0.75),
			offset = Vector3.new(0.0, 5.25, 0.075),
		},
		Steel = {
			mesh = "WallPlain__Steel",
			size = Vector3.new(6.04, 7.34, 0.12),
			offset = Vector3.new(0.0, 5.45, -0.3),
		},
	},
	WallVent = {
		Dark = {
			mesh = "WallVent__Dark",
			size = Vector3.new(6.4, 7.375, 0.53),
			offset = Vector3.new(0.0, 5.988, -0.235),
		},
		Frame = {
			mesh = "WallVent__Frame",
			size = Vector3.new(8.0, 10.5, 1.38),
			offset = Vector3.new(0.0, 5.25, -0.05),
		},
		Glow = {
			mesh = "WallVent__Glow",
			size = Vector3.new(6.1, 0.14, 0.12),
			offset = Vector3.new(0.0, 9.5, -0.48),
		},
		Hazard = {
			mesh = "WallVent__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = {
			mesh = "WallVent__Inset",
			size = Vector3.new(7.6, 10.1, 0.5),
			offset = Vector3.new(0.0, 5.25, 0.2),
		},
		Steel = {
			mesh = "WallVent__Steel",
			size = Vector3.new(6.04, 6.307, 5.261),
			offset = Vector3.new(0.0, 5.1, -0.32),
		},
	},
	WallWindow = {
		Dark = {
			mesh = "WallWindow__Dark",
			size = Vector3.new(6.4, 6.875, 0.65),
			offset = Vector3.new(0.0, 6.238, -0.175),
		},
		Frame = {
			mesh = "WallWindow__Frame",
			size = Vector3.new(8.0, 10.5, 1.38),
			offset = Vector3.new(0.0, 5.25, -0.05),
		},
		Glass = {
			mesh = "WallWindow__Glass",
			size = Vector3.new(5.3, 4.9, 0.1),
			offset = Vector3.new(0.0, 5.3, -0.3),
		},
		Glow = {
			mesh = "WallWindow__Glow",
			size = Vector3.new(6.1, 0.14, 0.12),
			offset = Vector3.new(0.0, 9.5, -0.48),
		},
		Hazard = {
			mesh = "WallWindow__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = {
			mesh = "WallWindow__Inset",
			size = Vector3.new(7.6, 10.1, 0.5),
			offset = Vector3.new(0.0, 5.25, 0.2),
		},
		Slime = {
			mesh = "WallWindow__Slime",
			size = Vector3.new(5.2, 2.2, 0.2),
			offset = Vector3.new(0.0, 3.9, 0.05),
		},
		Steel = {
			mesh = "WallWindow__Steel",
			size = Vector3.new(6.4, 6.0, 0.69),
			offset = Vector3.new(0.0, 5.3, -0.195),
		},
	},
}

return KitManifest
