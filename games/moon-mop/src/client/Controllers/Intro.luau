--!strict
-- The opening, built like the original's (P1 f_001, f_002; dense frames d_0001 to d_0014):
--   1. Black starfield, three short story cards fade in and out. SKIP INTRO in the corner.
--   2. The employment contract on a clipboard: four pages (A / D or the arrows to turn), your
--      name and avatar photo on page one, numbered clauses, and on the last page a signature
--      line you sign with the mouse or a finger. SIGN & CLOCK IN, Clear, REFUSE & CLOCK IN
--      (refusing also hires you). Our own wording throughout; only the flow follows the original.
--   3. A HIRED stamp slams down, the screen fades, and you start the shift in first person in
--      front of the North Station supply wall with the Field Manual open.
-- Only new players see it (save flag `hired`). All text is our own; the layout follows the
-- reference frames. Reduced Motion: no slides or slams, plain fades.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local Juice = require(script.Parent.Juice)
local Menus = require(script.Parent.Menus)
local Movement = require(script.Parent.Movement)
local State = require(script.Parent.State)
local Theme = require(script.Parent.Theme)

local Intro = {}

local player = Players.LocalPlayer
local INK = Color3.fromRGB(38, 40, 46)
local GREY = Color3.fromRGB(120, 124, 132)
local BLUE_INK = Color3.fromRGB(28, 44, 140)
local PAPER = Color3.fromRGB(246, 244, 238)
local STAMP = Color3.fromRGB(200, 40, 50)

local STORY = {
	{ "Somebody looked up and noticed the Moon was covered in dust.", "Management decided this could not stand." },
	{
		"Moon Mop Co. was founded for one job: clean the entire Moon.",
		"The budget came to roughly one toothbrush.",
	},
	{ "Somehow, you applied.", "Before we hand you that toothbrush, we need a signature." },
}

local function reduced(): boolean
	return GuiService.ReducedMotionEnabled
end

local function tween(obj: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?): Tween
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(if reduced() then math.min(t, 0.2) else t, style or Enum.EasingStyle.Quad),
		props
	)
	tw:Play()
	return tw
end

---------------------------------------------------------------------------- paper helpers
local function para(parent: Instance, order: number, text: string, opts: { bold: boolean?, size: number? }?): TextLabel
	local o: { bold: boolean?, size: number? } = opts or {}
	local l = Theme.label(text, o.size or 11, INK, if o.bold then Theme.F.serifBold else Theme.F.serif)
	l.Size = UDim2.new(1, 0, 0, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextWrapped = true
	l.RichText = true
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.LayoutOrder = order
	l.LineHeight = 1.1
	l.Parent = parent
	return l
end

local function clause(parent: Instance, order: number, n: number?, title: string)
	local row = Theme.frame(UDim2.new(1, 0, 0, 20), nil, PAPER, 1)
	row.LayoutOrder = order
	local x = 0
	if n then
		local dot = Theme.frame(UDim2.fromOffset(15, 15), UDim2.fromOffset(0, 3), Theme.ORANGE)
		Theme.corner(dot, 8)
		local d = Theme.label(tostring(n), 9, Theme.WHITE, Theme.F.bold, UDim2.fromScale(1, 1))
		d.TextXAlignment = Enum.TextXAlignment.Center
		d.Parent = dot
		dot.Parent = row
		x = 21
	end
	local t = Theme.label(string.upper(title), 11, INK, Theme.F.bold, UDim2.new(1, -x, 1, 0), UDim2.fromOffset(x, 1))
	t.Parent = row
	row.Parent = parent
end

local function small(parent: Instance, order: number, text: string)
	local l = Theme.label(string.upper(text), 8, GREY, Theme.F.bold, UDim2.new(1, 0, 0, 12))
	l.LayoutOrder = order
	l.Parent = parent
end

local function hand(parent: Instance, text: string, px: number, size: UDim2, pos: UDim2, color: Color3?): TextLabel
	local l = Theme.label(text, px, color or BLUE_INK, Theme.F.hand, size, pos)
	l.Parent = parent
	return l
end

local function gap(parent: Instance, order: number, h: number)
	local g = Theme.frame(UDim2.new(1, 0, 0, h), nil, PAPER, 1)
	g.LayoutOrder = order
	g.Parent = parent
end

---------------------------------------------------------------------------- the pages
local function pageOne(page: Frame)
	local head = Theme.frame(UDim2.new(1, 0, 0, 56), nil, PAPER, 1)
	head.LayoutOrder = 1
	local logo = Theme.frame(UDim2.fromOffset(40, 40), UDim2.fromOffset(0, 4), Color3.fromRGB(26, 28, 32))
	Theme.corner(logo, 4)
	local moon = Theme.frame(UDim2.fromOffset(20, 20), UDim2.fromOffset(6, 6), Color3.fromRGB(230, 230, 236))
	Theme.corner(moon, 10)
	moon.Parent = logo
	local stick = Theme.frame(UDim2.fromOffset(3, 22), UDim2.fromOffset(28, 14), Theme.ORANGE)
	stick.Rotation = 30
	stick.Parent = logo
	logo.Parent = head
	local name =
		Theme.label("MOON MOP\nCOMPANY", 15, INK, Theme.F.black, UDim2.fromOffset(110, 40), UDim2.fromOffset(46, 4))
	name.LineHeight = 0.9
	name.Parent = head
	local m = Theme.label("MANDATORY", 11, STAMP, Theme.F.heavy, UDim2.fromOffset(200, 14), UDim2.new(1, -200, 0, 4))
	m.TextXAlignment = Enum.TextXAlignment.Right
	m.Parent = head
	local e = Theme.label(
		"EMPLOYMENT AGREEMENT",
		11,
		INK,
		Theme.F.heavy,
		UDim2.fromOffset(200, 14),
		UDim2.new(1, -200, 0, 18)
	)
	e.TextXAlignment = Enum.TextXAlignment.Right
	e.Parent = head
	local note = Theme.label(
		"Employee copy. Time spent reading is unpaid.",
		7,
		GREY,
		Theme.F.serif,
		UDim2.fromOffset(200, 12),
		UDim2.new(1, -200, 0, 33)
	)
	note.TextXAlignment = Enum.TextXAlignment.Right
	note.Parent = head
	local rule = Theme.frame(UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -3), INK)
	rule.Parent = head
	head.Parent = page

	local who = Theme.frame(UDim2.new(1, 0, 0, 92), nil, PAPER, 1)
	who.LayoutOrder = 2
	local l1 = Theme.label("EMPLOYEE", 8, GREY, Theme.F.bold, UDim2.fromOffset(180, 12), UDim2.fromOffset(0, 8))
	l1.Parent = who
	hand(who, player.DisplayName, 20, UDim2.fromOffset(190, 26), UDim2.fromOffset(2, 18))
	local line = Theme.frame(UDim2.fromOffset(190, 1), UDim2.fromOffset(0, 44), GREY)
	line.Parent = who
	local l2 = Theme.label("POSITION", 8, GREY, Theme.F.bold, UDim2.fromOffset(180, 12), UDim2.fromOffset(0, 52))
	l2.Parent = who
	local pos = Theme.label(
		"Junior Lunar Surface Hygiene Associate,\nEntry Level (Replaceable)",
		10,
		INK,
		Theme.F.serif,
		UDim2.fromOffset(200, 28),
		UDim2.fromOffset(0, 64)
	)
	pos.TextYAlignment = Enum.TextYAlignment.Top
	pos.Parent = who
	-- taped photo with a caption, like a staff file
	local photo = Theme.frame(UDim2.fromOffset(104, 92), UDim2.new(1, -110, 0, 2), Color3.fromRGB(252, 252, 250))
	photo.Rotation = 3
	Theme.stroke(photo, Color3.fromRGB(210, 208, 200), 1)
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromOffset(94, 64)
	img.Position = UDim2.fromOffset(5, 5)
	img.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
	img.BorderSizePixel = 0
	img.ScaleType = Enum.ScaleType.Crop
	img.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", player.UserId)
	img.Parent = photo
	hand(photo, "First day. Still smiling.", 12, UDim2.fromOffset(104, 16), UDim2.fromOffset(4, 72), INK)
	local tape = Theme.frame(UDim2.fromOffset(34, 10), UDim2.fromOffset(36, -5), Color3.fromRGB(240, 226, 170), 0.3)
	tape.Rotation = -4
	tape.Parent = photo
	photo.Parent = who
	who.Parent = page

	para(page, 3, "Congratulations. Your application was the only one we received.")
	para(
		page,
		4,
		'By signing below you accept employment with Moon Mop Co. ("the Company") as a '
			.. "<b>Junior Lunar Surface Hygiene Associate</b>."
	)
	gap(page, 5, 2)
	clause(page, 6, 1, "Length of employment")
	para(page, 7, "Your shift ends when the Moon is clean.")
	para(
		page,
		8,
		'"The Moon" means every surface you can see, every surface you can\'t, and any surface '
			.. "management finds after you finish."
	)
	gap(page, 9, 2)
	clause(page, 10, 2, "Equipment")
	para(page, 11, "You will be issued one (1) toothbrush.")
	para(page, 12, "This is a complete cleaning system. Requests for bigger tools will be filed under ambition.")
	para(page, 13, "You will also receive the Field Manual. Press <b>H</b> to read it at any time.")
end

local function pageTwo(page: Frame)
	clause(page, 1, 3, "Pay")
	para(page, 2, "You are paid for every kilogram of dust delivered to a station Dust Drum.")
	para(page, 3, "Pay is not adjusted for effort, feelings or the size of the Moon.")
	gap(page, 4, 4)
	clause(page, 5, 4, "Working hours")
	para(page, 6, "Your shift runs until the Moon is clean (see clause 1).")
	para(page, 7, "Breaks may be taken while walking.")
	gap(page, 8, 4)
	clause(page, 9, 5, "Safety")
	para(page, 10, "Keep your helmet on. Taking it off ends this agreement, and you.")
	para(page, 11, "Do not stand behind the Pod Cannon. Do not ask why.")
	gap(page, 12, 4)
	clause(page, 13, 6, "Travel home")
	para(page, 14, "A seat back to Earth is included once the Moon is clean.")
	para(page, 15, 'The seat is not included in the meaning of "included".')
end

local function pageThree(page: Frame)
	clause(page, 1, 7, "Property")
	para(page, 2, "All dust belongs to the Company, including dust on you.")
	para(page, 3, "Tools bought with your wages remain yours, but we will be watching.")
	gap(page, 4, 4)
	clause(page, 5, 8, "Complaints")
	para(page, 6, "Complaints may be posted to the Complaints Department, a bin near the airlock.")
	gap(page, 7, 4)
	clause(page, 8, 9, "Colleagues")
	para(page, 9, "Robots you buy are your colleagues. They are also unpaid. Please be kind to them.")
	gap(page, 10, 4)
	clause(page, 11, 10, "Gravity")
	para(page, 12, "Moon gravity is one sixth of Earth's. Jumping is allowed but not encouraged.")
	para(page, 13, "Falling off the Moon is not covered.")
end

type Signature = { pad: Frame, strokes: { Frame }, typed: TextLabel }

local function pageFour(page: Frame): Signature
	clause(page, 1, 11, "Changes to this agreement")
	para(page, 2, "The Company may change these terms at any time, including before you finish reading them.")
	gap(page, 3, 4)
	clause(page, 4, nil, "Employee declaration")
	para(page, 5, "By signing, I confirm that:")
	local checks = {
		"I have read this agreement, or have decided to trust it.",
		"I applied of my own free will. The locked airlock is a coincidence.",
		'I understand "we are one big team" means the team is me.',
		"I knew the Moon was big when I applied.",
	}
	for i, c in checks do
		local row = Theme.frame(UDim2.new(1, 0, 0, 0), nil, PAPER, 1)
		row.AutomaticSize = Enum.AutomaticSize.Y
		row.LayoutOrder = 5 + i
		local tick = Theme.label("✓", 12, STAMP, Theme.F.bold, UDim2.fromOffset(14, 14))
		tick.Parent = row
		local t = para(row, 0, c, { size = 10 })
		t.Size = UDim2.new(1, -18, 0, 0)
		t.Position = UDim2.fromOffset(18, 0)
		row.Parent = page
	end
	gap(page, 11, 6)
	small(page, 12, "Employee signature")
	local pad = Theme.frame(UDim2.new(1, 0, 0, 70), nil, PAPER, 1)
	pad.Name = "SignaturePad"
	pad.LayoutOrder = 13
	pad.Active = true
	pad.ClipsDescendants = true
	local line = Theme.frame(UDim2.new(1, -60, 0, 1), UDim2.new(0, 0, 1, -6), GREY)
	line.Parent = pad
	local typed = hand(pad, "", 36, UDim2.new(1, -60, 1, -6), UDim2.fromOffset(16, 0))
	pad.Parent = page
	local foot = Theme.frame(UDim2.new(1, 0, 0, 40), nil, PAPER, 1)
	foot.LayoutOrder = 14
	local d1 = Theme.label("DATE", 8, GREY, Theme.F.bold, UDim2.fromOffset(150, 12), UDim2.fromOffset(0, 4))
	d1.Parent = foot
	hand(foot, "Day one of the rest of your shift", 15, UDim2.fromOffset(176, 22), UDim2.fromOffset(0, 18))
	local d2 =
		Theme.label("COMPANY SIGNATURE", 8, GREY, Theme.F.bold, UDim2.fromOffset(150, 12), UDim2.fromOffset(176, 4))
	d2.Parent = foot
	hand(foot, "Not needed. We agree with us.", 15, UDim2.fromOffset(170, 22), UDim2.fromOffset(176, 18))
	-- faint company stamp
	local seal = Theme.frame(UDim2.fromOffset(46, 46), UDim2.new(1, -46, 0, -6), PAPER, 1)
	seal.Rotation = -12
	Theme.corner(seal, 23)
	Theme.stroke(seal, STAMP, 2, 0.45)
	local sl = Theme.label("MMC", 12, STAMP, Theme.F.black, UDim2.fromScale(1, 1))
	sl.TextXAlignment = Enum.TextXAlignment.Center
	sl.TextTransparency = 0.45
	sl.Parent = seal
	seal.Parent = foot
	foot.Parent = page
	gap(page, 15, 6)
	local note = hand(
		page,
		"Your wellbeing is important to our statistics.\n                    - Management",
		16,
		UDim2.new(1, 0, 0, 46),
		UDim2.new(),
		INK
	)
	note.LayoutOrder = 16
	return { pad = pad, strokes = {}, typed = typed }
end

---------------------------------------------------------------------------- build and run
local running = false

function Intro.play()
	if running then
		return
	end
	running = true
	Movement.setFrozen(true)
	Movement.freeCursor("intro", true)
	local gui = Instance.new("ScreenGui")
	gui.Name = "Intro"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 100
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local sky = Theme.frame(UDim2.fromScale(1, 1), nil, Color3.fromRGB(12, 14, 19))
	sky.Parent = gui
	local rng = Random.new(7)
	for _ = 1, 260 do
		local d = rng:NextNumber(1, 2.4)
		local star = Theme.frame(
			UDim2.fromOffset(d, d),
			UDim2.fromScale(rng:NextNumber(), rng:NextNumber()),
			Color3.new(1, 1, 1),
			rng:NextNumber(0.2, 0.85)
		)
		Theme.corner(star, 2)
		star.Parent = sky
	end
	local holder = Theme.frame(UDim2.fromScale(1, 1), nil, Theme.PANEL, 1)
	holder.Parent = gui
	local canvas = Theme.canvas(holder)

	-- 1. story cards
	local skipped = false
	-- pinned to the real screen corner, not the 16:9 canvas, so it stays put on tall windows
	local skip = Theme.button("SKIP INTRO  ›", UDim2.fromOffset(124, 32), "Dark")
	skip.AnchorPoint = Vector2.new(1, 0)
	skip.Position = UDim2.new(1, -24, 0, 24)
	skip.BackgroundTransparency = 0.3
	skip.TextScaled = false
	skip.TextSize = 12
	skip.FontFace = Theme.F.bold
	Theme.stroke(skip, Color3.fromRGB(150, 156, 166), 1, 0.2)
	skip.Parent = holder
	skip.Activated:Connect(function()
		skipped = true
	end)
	local line1 = Theme.label("", 21, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(1000, 30), UDim2.fromOffset(140, 326))
	line1.TextXAlignment = Enum.TextXAlignment.Center
	line1.TextTransparency = 1
	line1.Parent = canvas
	local line2 = Theme.label(
		"",
		19,
		Color3.fromRGB(176, 172, 164),
		Theme.F.semi,
		UDim2.fromOffset(1000, 28),
		UDim2.fromOffset(140, 364)
	)
	line2.TextXAlignment = Enum.TextXAlignment.Center
	line2.TextTransparency = 1
	line2.Parent = canvas
	local function waitOrSkip(t: number)
		local t0 = os.clock()
		while os.clock() - t0 < t and not skipped do
			task.wait()
		end
	end
	for _, card in STORY do
		if skipped then
			break
		end
		line1.Text, line2.Text = card[1], card[2]
		tween(line1, 0.8, { TextTransparency = 0 })
		waitOrSkip(1.1)
		tween(line2, 0.8, { TextTransparency = 0 })
		waitOrSkip(2.6)
		tween(line1, 0.6, { TextTransparency = 1 })
		tween(line2, 0.6, { TextTransparency = 1 })
		waitOrSkip(0.8)
	end
	line1:Destroy()
	line2:Destroy()
	skip:Destroy()

	-- 2. the clipboard
	local board = Theme.frame(UDim2.fromOffset(446, 596), UDim2.fromOffset(417, 42), Color3.fromRGB(64, 70, 79))
	Theme.corner(board, 18)
	Theme.stroke(board, Color3.fromRGB(110, 118, 128), 1, 0.3)
	board.Parent = canvas
	local paper = Theme.frame(UDim2.fromOffset(390, 506), UDim2.fromOffset(28, 40), PAPER)
	Theme.corner(paper, 2)
	paper.Parent = board
	local band = Theme.frame(UDim2.fromOffset(446, 46), UDim2.fromOffset(0, 550), Theme.ORANGE)
	Theme.corner(band, 18)
	band.Parent = board
	local bandTop = Theme.frame(UDim2.fromOffset(446, 20), UDim2.fromOffset(0, 0), Theme.ORANGE)
	bandTop.Parent = band
	local stripes = Instance.new("CanvasGroup")
	stripes.Size = UDim2.fromOffset(110, 46)
	stripes.Position = UDim2.fromOffset(36, 0)
	stripes.BackgroundTransparency = 1
	for i = 0, 2 do
		local s =
			Theme.frame(UDim2.fromOffset(12, 70), UDim2.fromOffset(22 + i * 26, -12), Color3.fromRGB(255, 236, 220))
		s.Rotation = 30
		s.Parent = stripes
	end
	stripes.Parent = band
	local formName = Theme.label(
		"FORM MMC-01  ·  EMPLOYMENT",
		12,
		Theme.WHITE,
		Theme.F.bold,
		UDim2.fromOffset(240, 46),
		UDim2.fromOffset(186, 0)
	)
	formName.TextXAlignment = Enum.TextXAlignment.Right
	formName.Parent = band
	-- metal clip with the company name
	local clip = Theme.frame(UDim2.fromOffset(170, 64), UDim2.fromOffset(138, -8), Color3.fromRGB(184, 188, 196))
	Theme.corner(clip, 10)
	local cg = Instance.new("UIGradient")
	cg.Color = ColorSequence.new(Color3.fromRGB(236, 238, 242), Color3.fromRGB(150, 154, 162))
	cg.Rotation = 90
	cg.Parent = clip
	local clipText = Theme.label(
		"MOON MOP CO.",
		9,
		Color3.fromRGB(70, 74, 82),
		Theme.F.black,
		UDim2.new(1, 0, 0, 20),
		UDim2.fromOffset(0, 36)
	)
	clipText.TextXAlignment = Enum.TextXAlignment.Center
	clipText.Parent = clip
	local hole = Theme.frame(UDim2.fromOffset(16, 10), UDim2.fromOffset(77, 8), Color3.fromRGB(64, 70, 79))
	Theme.corner(hole, 5)
	hole.Parent = clip
	clip.Parent = board
	-- barcode sticker
	local code = Theme.frame(UDim2.fromOffset(60, 22), UDim2.fromOffset(40, 8), Theme.WHITE)
	for i = 0, 18 do
		local bar = Theme.frame(
			UDim2.fromOffset(if i % 3 == 0 then 2 else 1, 14),
			UDim2.fromOffset(4 + i * 2.8, 3),
			Theme.BLACK
		)
		bar.Parent = code
	end
	code.Parent = board
	-- pen clipped to the right edge
	local pen = Theme.frame(UDim2.fromOffset(12, 230), UDim2.fromOffset(410, 28), Theme.WHITE)
	Theme.corner(pen, 6)
	local grip = Theme.frame(UDim2.fromOffset(12, 40), UDim2.fromOffset(0, 150), Theme.ORANGE)
	grip.Parent = pen
	local cap = Theme.frame(UDim2.fromOffset(12, 14), UDim2.fromOffset(0, 0), Theme.ORANGE)
	Theme.corner(cap, 6)
	cap.Parent = pen
	pen.Parent = board

	local pages: { Frame } = {}
	local sig: Signature
	for i = 1, 4 do
		local page = Theme.frame(UDim2.fromOffset(330, 436), UDim2.fromOffset(30, 24), PAPER, 1)
		page.Visible = i == 1
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 5)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = page
		if i == 1 then
			pageOne(page)
		elseif i == 2 then
			pageTwo(page)
		elseif i == 3 then
			pageThree(page)
		else
			sig = pageFour(page)
		end
		page.Parent = paper
		table.insert(pages, page)
	end
	local formFoot = Theme.label(
		"FORM MMC-01  ·  EMPLOYEE COPY",
		8,
		GREY,
		Theme.F.bold,
		UDim2.fromOffset(220, 12),
		UDim2.fromOffset(30, 478)
	)
	formFoot.Parent = paper
	local pageNo = Theme.label("1 / 4", 9, INK, Theme.F.bold, UDim2.fromOffset(60, 12), UDim2.fromOffset(300, 478))
	pageNo.TextXAlignment = Enum.TextXAlignment.Right
	pageNo.Parent = paper
	local footRule = Theme.frame(UDim2.fromOffset(330, 1), UDim2.fromOffset(30, 470), Color3.fromRGB(214, 212, 204))
	footRule.Parent = paper

	-- "SIGN HERE" arrow tag sticking out of the paper's left edge on page 4
	local signHere = Theme.frame(UDim2.fromOffset(84, 22), UDim2.fromOffset(14, 0), Theme.ORANGE)
	signHere.Visible = false
	local sh = Theme.label("SIGN HERE", 10, Theme.WHITE, Theme.F.bold, UDim2.fromOffset(74, 22), UDim2.fromOffset(6, 0))
	sh.Parent = signHere
	local tip = Theme.frame(UDim2.fromOffset(16, 16), UDim2.fromOffset(84, 11), Theme.ORANGE)
	tip.AnchorPoint = Vector2.new(0.5, 0.5)
	tip.Rotation = 45
	tip.Parent = signHere
	signHere.Parent = board

	-- buttons and page hint to the right (P1 d_0010)
	local side = Theme.frame(UDim2.fromOffset(184, 220), UDim2.fromOffset(898, 340), Theme.PANEL, 1)
	side.Parent = canvas
	Theme.hints(side, { { "A", "D", "Flip pages" }, { "Enter", "Sign" } }, 18, 92)
	local nextPage = Theme.button("NEXT PAGE  ›", UDim2.fromOffset(184, 42), "Dark")
	nextPage.Position = UDim2.fromOffset(0, 51)
	nextPage.Parent = side
	local prevPage = Theme.button("‹  BACK", UDim2.fromOffset(184, 42), "Dark")
	prevPage.Position = UDim2.fromOffset(0, 103)
	prevPage.Parent = side
	local signBtn = Theme.button("SIGN & CLOCK IN", UDim2.fromOffset(184, 42), "Orange")
	signBtn.Position = UDim2.fromOffset(0, 51)
	signBtn.Parent = side
	local clearBtn = Theme.button("Clear", UDim2.fromOffset(184, 42), "Dark")
	clearBtn.Position = UDim2.fromOffset(0, 103)
	clearBtn.Parent = side
	local declineBtn = Theme.button("REFUSE & CLOCK IN", UDim2.fromOffset(184, 42), "Dark")
	declineBtn.Position = UDim2.fromOffset(0, 155)
	declineBtn.Parent = side
	for _, b in { nextPage, prevPage, signBtn, clearBtn, declineBtn } do
		b.TextXAlignment = Enum.TextXAlignment.Left
		local p = b:FindFirstChildOfClass("UIPadding")
		if p then
			p.PaddingLeft = UDim.new(0, 14)
		end
		local limit = b:FindFirstChildOfClass("UITextSizeConstraint")
		if limit then
			limit.MaxTextSize = 13
		end
	end

	local current = 1
	local function showPage(n: number)
		current = math.clamp(n, 1, 4)
		for i, p in pages do
			p.Visible = i == current
		end
		pageNo.Text = string.format("%d / 4", current)
		local last = current == 4
		signHere.Visible = last
		nextPage.Visible = not last
		prevPage.Visible = current > 1 and not last
		signBtn.Visible = last
		clearBtn.Visible = last
		declineBtn.Visible = last
		if last then
			-- line the tag up with the signature pad
			task.defer(function()
				local y = (sig.pad.AbsolutePosition.Y - board.AbsolutePosition.Y)
					/ math.max(board.AbsoluteSize.Y / 596, 0.01)
				signHere.Position = UDim2.fromOffset(-6, y + 20)
			end)
		end
		Juice.playSound("rbxasset://sounds/electronicpingshort.wav", 0.15)
	end
	showPage(1)
	if not reduced() then
		board.Position = UDim2.fromOffset(417, 760)
		tween(board, 0.6, { Position = UDim2.fromOffset(417, 42) }, Enum.EasingStyle.Back)
	end
	nextPage.Activated:Connect(function()
		showPage(current + 1)
	end)
	prevPage.Activated:Connect(function()
		showPage(current - 1)
	end)

	-- signing: drag on the pad to draw ink
	local drawing = false
	local last: Vector2? = nil
	local inkLength = 0
	-- InputObject.Position and AbsolutePosition share the same space (both below the top bar,
	-- checked in a playtest), so no inset correction
	local function toPad(screen: Vector2): Vector2
		local k = board.AbsoluteSize.X / 446
		return (screen - sig.pad.AbsolutePosition) / math.max(k, 0.01)
	end
	local function ink(a: Vector2, b: Vector2)
		local d = b - a
		local len = d.Magnitude
		if len < 0.5 then
			return
		end
		local seg =
			Theme.frame(UDim2.fromOffset(len + 2.4, 2.4), UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2), BLUE_INK)
		seg.AnchorPoint = Vector2.new(0.5, 0.5)
		seg.Rotation = math.deg(math.atan2(d.Y, d.X))
		Theme.corner(seg, 2)
		seg.Parent = sig.pad
		table.insert(sig.strokes, seg)
		inkLength += len
	end
	sig.pad.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			drawing = true
			last = toPad(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	local moveConn = UserInputService.InputChanged:Connect(function(input)
		if
			drawing
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local p = toPad(Vector2.new(input.Position.X, input.Position.Y))
			if last then
				ink(last, p)
			end
			last = p
		end
	end)
	local upConn = UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			drawing = false
			last = nil
		end
	end)
	clearBtn.Activated:Connect(function()
		for _, s in sig.strokes do
			s:Destroy()
		end
		table.clear(sig.strokes)
		inkLength = 0
		sig.typed.Text = ""
	end)

	local done = false
	local function finish(declined: boolean)
		if done then
			return
		end
		done = true
		-- no ink drawn: the pen signs your name for you
		if inkLength < 30 and not declined then
			sig.typed.Text = player.DisplayName
		end
		for _, b in { signBtn, clearBtn, declineBtn } do
			b.Active = false
			tween(b, 0.3, { BackgroundTransparency = 0.6, TextTransparency = 0.6 })
		end
		-- the stamp slams down on the signature
		local stamp = Theme.frame(UDim2.fromOffset(150, 46), UDim2.fromOffset(250, 380), PAPER, 1)
		stamp.AnchorPoint = Vector2.new(0.5, 0.5)
		stamp.Rotation = -8
		Theme.stroke(stamp, STAMP, 3)
		Theme.corner(stamp, 4)
		local st = Theme.label(
			if declined then "HIRED ANYWAY" else "HIRED",
			if declined then 18 else 26,
			STAMP,
			Theme.F.black,
			UDim2.fromScale(1, 1)
		)
		st.TextXAlignment = Enum.TextXAlignment.Center
		st.Parent = stamp
		local s = Instance.new("UIScale")
		s.Scale = if reduced() then 1 else 2.4
		s.Parent = stamp
		stamp.Parent = paper
		tween(s, 0.18, { Scale = 1 }, Enum.EasingStyle.Quad)
		task.delay(0.18, function()
			Juice.playSound("rbxasset://sounds/collide.wav", 0.6)
		end)
		task.wait(1.4)
		-- fade to black, start the shift
		local black = Theme.frame(UDim2.fromScale(1, 1), nil, Color3.new(0, 0, 0), 1)
		black.ZIndex = 50
		black.Parent = gui
		tween(black, 0.7, { BackgroundTransparency = 0 })
		task.wait(0.75)
		Remotes.get("Story"):FireServer("hired")
		sky:Destroy()
		holder:Destroy()
		task.wait(0.6)
		moveConn:Disconnect()
		upConn:Disconnect()
		Movement.setFrozen(false)
		Movement.freeCursor("intro", false)
		tween(black, 1.1, { BackgroundTransparency = 1 })
		task.wait(1.15)
		gui:Destroy()
		running = false
		Menus.open("manual")
	end
	signBtn.Activated:Connect(function()
		task.spawn(finish, false)
	end)
	declineBtn.Activated:Connect(function()
		task.spawn(finish, true)
	end)
	local keyConn = UserInputService.InputBegan:Connect(function(input)
		if done then
			return
		end
		if
			input.KeyCode == Enum.KeyCode.D
			or input.KeyCode == Enum.KeyCode.Right
			or input.KeyCode == Enum.KeyCode.DPadRight
		then
			showPage(current + 1)
		elseif
			input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.Left
			or input.KeyCode == Enum.KeyCode.DPadLeft
		then
			showPage(current - 1)
		elseif current == 4 and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA) then
			-- Enter / gamepad A signs (the pen signs your name if you drew nothing)
			task.spawn(finish, false)
		end
	end)
	gui.Destroying:Once(function()
		keyConn:Disconnect()
	end)
end

function Intro.start()
	local seen = false
	State.changed(function(s)
		if s.hired == false and not seen then
			seen = true
			task.spawn(Intro.play)
		elseif s.hired then
			seen = true
		end
	end)
end

return Intro
