--!strict
-- Generated from the Blender kits (assets/slime_cryo_kit_manifest.json, assets/slime_lab_kit_manifest.json) by art/gen_kit_manifest.py. Do not edit by hand.
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
