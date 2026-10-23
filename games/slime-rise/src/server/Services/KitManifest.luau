--!strict
-- Generated from the Blender kit (assets/slime_lab_kit_manifest.json). Do not edit by hand.
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
		Dark = { mesh = "BouncePad__Dark", size = Vector3.new(5.3, 0.5, 4.657), offset = Vector3.new(0.0, 0.35, 0.0) },
		Hazard = {
			mesh = "BouncePad__Hazard",
			size = Vector3.new(5.18, 0.28, 5.18),
			offset = Vector3.new(0.0, 0.62, 0.0),
		},
		Slime = { mesh = "BouncePad__Slime", size = Vector3.new(4.4, 1.98, 4.4), offset = Vector3.new(0.0, 0.6, 0.0) },
		Steel = { mesh = "BouncePad__Steel", size = Vector3.new(5.2, 0.6, 5.2), offset = Vector3.new(0.0, 0.3, 0.0) },
	},
	Catwalk = {
		Dark = { mesh = "Catwalk__Dark", size = Vector3.new(7.4, 0.12, 3.18), offset = Vector3.new(0.0, 0.04, 0.0) },
		Hazard = { mesh = "Catwalk__Hazard", size = Vector3.new(8.0, 3.2, 0.18), offset = Vector3.new(0.0, 1.6, 1.85) },
		Steel = { mesh = "Catwalk__Steel", size = Vector3.new(8.0, 0.9, 4.0), offset = Vector3.new(0.0, 0.05, 0.0) },
	},
	CentrifugeBase = {
		Dark = { mesh = "CentrifugeBase__Dark", size = Vector3.new(5.2, 1.6, 5.2), offset = Vector3.new(0.0, 0.8, 0.0) },
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
		Dark = { mesh = "Conveyor__Dark", size = Vector3.new(14.7, 1.1, 3.4), offset = Vector3.new(0.0, 1.9, 0.0) },
		Glow = { mesh = "Conveyor__Glow", size = Vector3.new(12.5, 0.12, 0.1), offset = Vector3.new(0.0, 1.5, -2.02) },
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
		Steel = { mesh = "Conveyor__Steel", size = Vector3.new(14.0, 2.1, 4.0), offset = Vector3.new(0.0, 1.05, 0.0) },
	},
	Crate = {
		Dark = { mesh = "Crate__Dark", size = Vector3.new(3.268, 3.131, 0.08), offset = Vector3.new(0.167, 1.02, -1.8) },
		Frame = { mesh = "Crate__Frame", size = Vector3.new(3.5, 3.5, 3.5), offset = Vector3.new(0.0, 2.0, 0.0) },
		Hazard = { mesh = "Crate__Hazard", size = Vector3.new(2.2, 0.6, 0.08), offset = Vector3.new(0.0, 2.2, -1.8) },
		Rubber = { mesh = "Crate__Rubber", size = Vector3.new(3.3, 0.2, 3.3), offset = Vector3.new(0.0, 3.9, 0.0) },
		Steel = { mesh = "Crate__Steel", size = Vector3.new(4.01, 4.01, 4.01), offset = Vector3.new(0.0, 2.0, 0.0) },
	},
	Fan = {
		Dark = { mesh = "Fan__Dark", size = Vector3.new(7.0, 0.6, 7.0), offset = Vector3.new(0.0, 0.75, 0.0) },
		Glow = { mesh = "Fan__Glow", size = Vector3.new(7.56, 0.16, 7.56), offset = Vector3.new(0.0, 1.02, 0.0) },
		Steel = { mesh = "Fan__Steel", size = Vector3.new(7.8, 1.12, 7.8), offset = Vector3.new(0.0, 0.56, 0.0) },
	},
	FanBlades = {
		Dark = {
			mesh = "FanBlades__Dark",
			size = Vector3.new(5.483, 3.913, 5.923),
			offset = Vector3.new(0.158, 0.2, 0.0),
		},
		Steel = { mesh = "FanBlades__Steel", size = Vector3.new(1.0, 0.4, 1.0), offset = Vector3.new(0.0, 0.2, 0.0) },
	},
	Pillar = {
		Dark = { mesh = "Pillar__Dark", size = Vector3.new(0.4, 7.0, 2.3), offset = Vector3.new(0.0, 5.25, 0.0) },
		Frame = { mesh = "Pillar__Frame", size = Vector3.new(2.2, 10.5, 2.2), offset = Vector3.new(0.0, 5.25, 0.0) },
		Glow = { mesh = "Pillar__Glow", size = Vector3.new(0.15, 6.0, 2.32), offset = Vector3.new(0.0, 5.25, 0.0) },
		Steel = { mesh = "Pillar__Steel", size = Vector3.new(2.6, 10.5, 2.6), offset = Vector3.new(0.0, 5.25, 0.0) },
	},
	PipeBeam = {
		Dark = { mesh = "PipeBeam__Dark", size = Vector3.new(11.8, 2.36, 2.36), offset = Vector3.new(0.0, 1.0, 0.0) },
		Hazard = { mesh = "PipeBeam__Hazard", size = Vector3.new(1.2, 0.1, 2.2), offset = Vector3.new(0.0, 2.02, 0.0) },
		Steel = {
			mesh = "PipeBeam__Steel",
			size = Vector3.new(12.0, 2.056, 2.351),
			offset = Vector3.new(0.0, 1.0, 0.0),
		},
	},
	RobotBase = {
		Dark = { mesh = "RobotBase__Dark", size = Vector3.new(4.0, 1.2, 4.0), offset = Vector3.new(0.0, 0.6, 0.0) },
		Frame = {
			mesh = "RobotBase__Frame",
			size = Vector3.new(3.687, 4.669, 1.0),
			offset = Vector3.new(0.0, 6.6, 0.0),
		},
		Hazard = { mesh = "RobotBase__Hazard", size = Vector3.new(2.2, 2.2, 2.2), offset = Vector3.new(0.0, 4.3, 0.0) },
		Steel = {
			mesh = "RobotBase__Steel",
			size = Vector3.new(3.55, 8.3, 2.6),
			offset = Vector3.new(0.475, 5.25, 0.0),
		},
	},
	Shelf = {
		Dark = { mesh = "Shelf__Dark", size = Vector3.new(5.5, 11.4, 0.15), offset = Vector3.new(0.0, 6.0, 1.4) },
		Frame = { mesh = "Shelf__Frame", size = Vector3.new(4.0, 7.0, 1.2), offset = Vector3.new(0.5, 6.55, 0.6) },
		Glass = { mesh = "Shelf__Glass", size = Vector3.new(4.9, 7.3, 0.9), offset = Vector3.new(0.0, 6.7, 0.6) },
		Hazard = { mesh = "Shelf__Hazard", size = Vector3.new(3.8, 6.25, 0.05), offset = Vector3.new(0.5, 6.7, 0.0) },
		Rubber = { mesh = "Shelf__Rubber", size = Vector3.new(5.4, 11.78, 2.5), offset = Vector3.new(0.0, 6.18, 0.0) },
		Slime = { mesh = "Shelf__Slime", size = Vector3.new(4.76, 6.8, 0.76), offset = Vector3.new(0.0, 6.45, 0.6) },
		Steel = { mesh = "Shelf__Steel", size = Vector3.new(6.0, 12.0, 3.0), offset = Vector3.new(0.0, 6.0, 0.0) },
	},
	Tank = {
		Dark = { mesh = "Tank__Dark", size = Vector3.new(5.2, 0.4, 5.2), offset = Vector3.new(0.0, 1.4, 0.0) },
		Glass = { mesh = "Tank__Glass", size = Vector3.new(5.0, 6.4, 5.0), offset = Vector3.new(0.0, 4.4, 0.0) },
		Hazard = { mesh = "Tank__Hazard", size = Vector3.new(5.56, 0.2, 5.56), offset = Vector3.new(0.0, 8.7, 0.0) },
		Rubber = { mesh = "Tank__Rubber", size = Vector3.new(5.1, 0.15, 5.1), offset = Vector3.new(0.0, 8.67, 0.0) },
		Slime = { mesh = "Tank__Slime", size = Vector3.new(4.5, 4.48, 4.5), offset = Vector3.new(0.0, 3.54, 0.0) },
		Steel = { mesh = "Tank__Steel", size = Vector3.new(5.728, 8.65, 6.27), offset = Vector3.new(0.0, 4.325, 0.265) },
	},
	WallPipes = {
		Dark = { mesh = "WallPipes__Dark", size = Vector3.new(6.4, 7.2, 0.6), offset = Vector3.new(0.0, 6.075, -0.25) },
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
		Glow = { mesh = "WallPipes__Glow", size = Vector3.new(6.1, 0.14, 0.12), offset = Vector3.new(0.0, 9.5, -0.48) },
		Hazard = {
			mesh = "WallPipes__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = { mesh = "WallPipes__Inset", size = Vector3.new(7.6, 10.1, 0.7), offset = Vector3.new(0.0, 5.25, 0.1) },
		Slime = { mesh = "WallPipes__Slime", size = Vector3.new(0.9, 7.9, 0.9), offset = Vector3.new(0.0, 5.6, -0.75) },
		Steel = {
			mesh = "WallPipes__Steel",
			size = Vector3.new(5.84, 8.1, 1.48),
			offset = Vector3.new(0.53, 5.6, -0.75),
		},
	},
	WallPlain = {
		Dark = { mesh = "WallPlain__Dark", size = Vector3.new(6.4, 0.35, 0.5), offset = Vector3.new(0.0, 9.5, -0.25) },
		Frame = {
			mesh = "WallPlain__Frame",
			size = Vector3.new(8.0, 10.5, 1.38),
			offset = Vector3.new(0.0, 5.25, -0.05),
		},
		Glow = { mesh = "WallPlain__Glow", size = Vector3.new(6.1, 0.14, 0.12), offset = Vector3.new(0.0, 9.5, -0.48) },
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
		Glow = { mesh = "WallVent__Glow", size = Vector3.new(6.1, 0.14, 0.12), offset = Vector3.new(0.0, 9.5, -0.48) },
		Hazard = {
			mesh = "WallVent__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = { mesh = "WallVent__Inset", size = Vector3.new(7.6, 10.1, 0.5), offset = Vector3.new(0.0, 5.25, 0.2) },
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
		Glass = { mesh = "WallWindow__Glass", size = Vector3.new(5.3, 4.9, 0.1), offset = Vector3.new(0.0, 5.3, -0.3) },
		Glow = { mesh = "WallWindow__Glow", size = Vector3.new(6.1, 0.14, 0.12), offset = Vector3.new(0.0, 9.5, -0.48) },
		Hazard = {
			mesh = "WallWindow__Hazard",
			size = Vector3.new(7.0, 0.35, 0.1),
			offset = Vector3.new(0.0, 0.85, -0.66),
		},
		Inset = { mesh = "WallWindow__Inset", size = Vector3.new(7.6, 10.1, 0.5), offset = Vector3.new(0.0, 5.25, 0.2) },
		Slime = { mesh = "WallWindow__Slime", size = Vector3.new(5.2, 2.2, 0.2), offset = Vector3.new(0.0, 3.9, 0.05) },
		Steel = {
			mesh = "WallWindow__Steel",
			size = Vector3.new(6.4, 6.0, 0.69),
			offset = Vector3.new(0.0, 5.3, -0.195),
		},
	},
}

return KitManifest
