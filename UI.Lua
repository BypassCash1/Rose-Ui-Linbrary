local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local Library = {}

Library.Name = "Rose"
Library.Font = Enum.Font.Code
Library.Accent = Color3.fromRGB(0, 170, 255) -- cyan-blue
Library.flags = Library.flags or {}
Library.notifications = Library.notifications or {}

if getgenv then
	local env = getgenv()
	env.Rose = Library
	env.RoseLibrary = Library
end

local function protectGui(gui)
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
		gui.Parent = CoreGui
	elseif getgenv and getgenv().gethui then
		gui.Parent = getgenv().gethui()
	else
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

local function isPhone()
	local camera = workspace.CurrentCamera
	if not camera then
		return false
	end
	local vp = camera.ViewportSize
	return vp.X <= 650
end

local function viewportSize()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.ViewportSize
	end
	return Vector2.new(1920, 1080)
end

local function addCorner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, 6)
	c.Parent = inst
	return c
end

local function addStroke(inst, color)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = inst
	return s
end

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function hsvToColor(h, s, v)
	return Color3.fromHSV(h, s, v)
end

local function safeToHSV(c)
	if Color3.toHSV then
		return Color3.toHSV(c)
	end
	if typeof(c) == "Color3" and c.ToHSV then
		return c:ToHSV()
	end
	return 0, 0, 0
end

local function colorToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

function Library:CreateWindow(options)
	options = options or {}
	local titleText = options.Title or Library.Name
	local displayName = options.name or options.Name or titleText
	local suffix = options.suffix or options.Suffix
	local gameInfo = options.gameInfo or options.GameInfo
	local requestedSize = options.Size or options.size

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "Rose_UI_V1"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	protectGui(ScreenGui)

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Parent = ScreenGui
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Visible = true

	local baseSize = requestedSize or UDim2.new(0, 550, 0, 500)
	local vp = viewportSize()
	if isPhone() then
		local targetW = math.max(320, math.min(420, math.floor(vp.X - 32)))
		local targetH = math.max(320, math.min(460, math.floor(vp.Y - 96)))
		MainFrame.Size = UDim2.new(0, targetW, 0, targetH)
	else
		-- Keep desktop/tablet consistent, but clamp to viewport so it never goes off-screen.
		if baseSize.X.Offset > 0 and baseSize.Y.Offset > 0 then
			local targetW = math.min(baseSize.X.Offset, math.floor(vp.X - 64))
			local targetH = math.min(baseSize.Y.Offset, math.floor(vp.Y - 96))
			MainFrame.Size = UDim2.new(0, targetW, 0, targetH)
		else
			MainFrame.Size = baseSize
		end
	end

	addCorner(MainFrame, UDim.new(0, 8))
	addStroke(MainFrame, Color3.fromRGB(50, 50, 50))

	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Parent = MainFrame
	TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	TopBar.BorderSizePixel = 0
	TopBar.Size = UDim2.new(1, 0, 0, 42)
	addStroke(TopBar, Color3.fromRGB(35, 35, 35))

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Name = "Title"
	TitleLabel.Parent = TopBar
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.new(0, 14, 0, 0)
	TitleLabel.Size = UDim2.new(0, 0, 1, 0)
	TitleLabel.AutomaticSize = Enum.AutomaticSize.X
	TitleLabel.Font = Library.Font
	local left = tostring(displayName)
	if suffix and tostring(suffix) ~= "" then
		left = left .. " " .. tostring(suffix)
	end
	local right = gameInfo and tostring(gameInfo) or ""
	TitleLabel.Text = right ~= "" and (left .. " | " .. right) or (left .. " |")
	TitleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	TitleLabel.TextSize = 15
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.RichText = false

	local TitlePad = Instance.new("UIPadding")
	TitlePad.Parent = TitleLabel
	TitlePad.PaddingRight = UDim.new(0, 0)

	local TabContainer = Instance.new("Frame")
	TabContainer.Name = "TabContainer"
	TabContainer.Parent = TopBar
	TabContainer.BackgroundTransparency = 1
	TabContainer.Position = UDim2.new(0, 160, 0, 0)
	TabContainer.Size = UDim2.new(1, -170, 1, 0)

	local TabLayout = Instance.new("UIListLayout")
	TabLayout.Parent = TabContainer
	TabLayout.FillDirection = Enum.FillDirection.Horizontal
	TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabLayout.Padding = UDim.new(0, 12)
	TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

	local function updateTabPosition()
		local pad = 14
		local x = TitleLabel.Position.X.Offset + TitleLabel.AbsoluteSize.X + pad
		TabContainer.Position = UDim2.new(0, x, 0, 0)
		TabContainer.Size = UDim2.new(1, -(x + 14), 1, 0)
	end
	TitleLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTabPosition)
	TitleLabel:GetPropertyChangedSignal("Text"):Connect(updateTabPosition)
	task.defer(updateTabPosition)

	local ContentScroll = Instance.new("ScrollingFrame")
	ContentScroll.Name = "ContentScroll"
	ContentScroll.Parent = MainFrame
	ContentScroll.BackgroundTransparency = 1
	ContentScroll.Position = UDim2.new(0, 0, 0, 46)
	ContentScroll.Size = UDim2.new(1, 0, 1, -52)
	ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ContentScroll.ScrollBarThickness = 2
	ContentScroll.ScrollBarImageColor3 = Library.Accent
	ContentScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local ContentHolder = Instance.new("Frame")
	ContentHolder.Name = "ContentHolder"
	ContentHolder.Parent = ContentScroll
	ContentHolder.BackgroundTransparency = 1
	ContentHolder.Size = UDim2.new(1, 0, 1, 0)

	local holderPadding = Instance.new("UIPadding")
	holderPadding.Parent = ContentHolder
	holderPadding.PaddingTop = UDim.new(0, 10)
	holderPadding.PaddingBottom = UDim.new(0, 10)
	holderPadding.PaddingLeft = UDim.new(0, 12)
	holderPadding.PaddingRight = UDim.new(0, 12)

	local OpenCloseButton = Instance.new("TextButton")
	OpenCloseButton.Name = "OpenClose"
	OpenCloseButton.Parent = ScreenGui
	OpenCloseButton.AnchorPoint = Vector2.new(1, 0)
	OpenCloseButton.Position = UDim2.new(1, -14, 0, 14)
	OpenCloseButton.Size = UDim2.new(0, 44, 0, 44)
	OpenCloseButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	OpenCloseButton.BorderSizePixel = 0
	OpenCloseButton.Text = "×"
	OpenCloseButton.TextColor3 = Color3.fromRGB(230, 230, 230)
	OpenCloseButton.Font = Library.Font
	OpenCloseButton.TextSize = 20
	OpenCloseButton.AutoButtonColor = true
	OpenCloseButton.ZIndex = 50
	addCorner(OpenCloseButton, UDim.new(0, 10))
	addStroke(OpenCloseButton, Color3.fromRGB(45, 45, 45))

	-- Notifications holder
	local NotifHolder = Instance.new("Frame")
	NotifHolder.Name = "Notifications"
	NotifHolder.Parent = ScreenGui
	NotifHolder.BackgroundTransparency = 1
	NotifHolder.AnchorPoint = Vector2.new(1, 0)
	NotifHolder.Position = UDim2.new(1, -14, 0, 66)
	NotifHolder.Size = UDim2.new(0, 280, 1, -80)
	NotifHolder.ZIndex = 60

	local NotifLayout = Instance.new("UIListLayout")
	NotifLayout.Parent = NotifHolder
	NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NotifLayout.Padding = UDim.new(0, 8)
	NotifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

	local function setOpen(isOpen)
		MainFrame.Visible = isOpen
		OpenCloseButton.Text = isOpen and "×" or "≡"
	end

	OpenCloseButton.MouseButton1Click:Connect(function()
		setOpen(not MainFrame.Visible)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.RightControl then
			setOpen(not MainFrame.Visible)
		end
	end)

	-- Dragging: mouse + touch, only when window is open
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function beginDrag(input)
		if not MainFrame.Visible then
			return
		end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end

	local function updateDrag(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		local t = input.UserInputType
		if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	local function endDrag(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = false
			dragStart = nil
			startPos = nil
		end
	end

	TopBar.InputBegan:Connect(beginDrag)
	UserInputService.InputChanged:Connect(updateDrag)
	UserInputService.InputEnded:Connect(endDrag)

	local function newColumnContainer(parent)
		local ColumnContainer = Instance.new("Frame")
		ColumnContainer.Parent = parent
		ColumnContainer.BackgroundTransparency = 1
		ColumnContainer.Size = UDim2.new(1, 0, 1, 0)

		local LeftCol = Instance.new("Frame")
		LeftCol.Parent = ColumnContainer
		LeftCol.BackgroundTransparency = 1
		LeftCol.Position = UDim2.new(0, 0, 0, 0)
		LeftCol.Size = UDim2.new(0.5, -9, 1, 0)

		local RightCol = Instance.new("Frame")
		RightCol.Parent = ColumnContainer
		RightCol.BackgroundTransparency = 1
		RightCol.Position = UDim2.new(0.5, 9, 0, 0)
		RightCol.Size = UDim2.new(0.5, -9, 1, 0)

		local function SetupLayout(p)
			local l = Instance.new("UIListLayout")
			l.Parent = p
			l.SortOrder = Enum.SortOrder.LayoutOrder
			l.Padding = UDim.new(0, 12)
		end
		SetupLayout(LeftCol)
		SetupLayout(RightCol)

		return ColumnContainer, LeftCol, RightCol
	end

	local Window = {}
	Window._screenGui = ScreenGui
	Window._main = MainFrame
	Window._tabs = {}
	Window._activeTab = nil
	Window._notifHolder = NotifHolder

	local function setActiveTab(tab)
		Window._activeTab = tab
		for _, t in pairs(Window._tabs) do
			local isActive = (t == tab)
			t.Button.TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
			t.Underline.Visible = isActive
			t.Container.Visible = isActive
		end
	end

	function Window:CreateTab(name)
		local TabBtn = Instance.new("TextButton")
		TabBtn.Name = name
		TabBtn.Parent = TabContainer
		TabBtn.BackgroundTransparency = 1
		TabBtn.BorderSizePixel = 0
		TabBtn.Font = Library.Font
		TabBtn.Text = name
		TabBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
		TabBtn.TextSize = 14
		TabBtn.TextYAlignment = Enum.TextYAlignment.Center
		TabBtn.AutomaticSize = Enum.AutomaticSize.X
		TabBtn.Size = UDim2.new(0, 0, 1, 0)
		TabBtn.ClipsDescendants = false

		local underlinePad = Instance.new("UIPadding")
		underlinePad.Parent = TabBtn
		underlinePad.PaddingBottom = UDim.new(0, 6)

		local Underline = Instance.new("Frame")
		Underline.Name = "Underline"
		Underline.Parent = TabBtn
		Underline.BackgroundColor3 = Library.Accent
		Underline.BorderSizePixel = 0
		Underline.AnchorPoint = Vector2.new(0, 1)
		Underline.Position = UDim2.new(0, 0, 1, 2)
		Underline.Size = UDim2.new(1, 0, 0, 2)
		Underline.Visible = false
		Underline.ZIndex = 5

		local TabContent = Instance.new("Frame")
		TabContent.Name = name .. "_Content"
		TabContent.Parent = ContentHolder
		TabContent.BackgroundTransparency = 1
		TabContent.Size = UDim2.new(1, 0, 1, 0)
		TabContent.Visible = false

		local _, LeftCol, RightCol = newColumnContainer(TabContent)

		local Tab = {}
		Tab._left = LeftCol
		Tab._right = RightCol
		Tab._container = TabContent
		Tab._columnIndex = 0

		function Tab:column(opts)
			Tab._columnIndex += 1
			local side = (Tab._columnIndex == 1) and "Left" or "Right"
			local Column = {}
			Column._side = side
			function Column:section(sopts)
				sopts = sopts or {}
				local sectionName = sopts.name or sopts.Name or sopts.title or "Section"
				return Tab:CreateSection(sectionName, side)
			end
			return Column
		end

		function Tab:CreateSection(sectionName, side)
			local parent = (side == "Right" and RightCol) or LeftCol

			local SectionBox = Instance.new("Frame")
			SectionBox.Name = sectionName
			SectionBox.Parent = parent
			SectionBox.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			SectionBox.BorderSizePixel = 0
			SectionBox.AutomaticSize = Enum.AutomaticSize.Y
			SectionBox.Size = UDim2.new(1, 0, 0, 0)
			addCorner(SectionBox, UDim.new(0, 6))
			addStroke(SectionBox, Color3.fromRGB(45, 45, 45))

			local SectionLabel = Instance.new("TextLabel")
			SectionLabel.Parent = SectionBox
			SectionLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			SectionLabel.Position = UDim2.new(0, 10, 0, -8)
			SectionLabel.Size = UDim2.new(0, 0, 0, 16)
			SectionLabel.Font = Library.Font
			SectionLabel.Text = " " .. sectionName .. " "
			SectionLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
			SectionLabel.TextSize = 13
			SectionLabel.AutomaticSize = Enum.AutomaticSize.X
			addCorner(SectionLabel, UDim.new(0, 4))

			local Container = Instance.new("Frame")
			Container.Parent = SectionBox
			Container.BackgroundTransparency = 1
			Container.AutomaticSize = Enum.AutomaticSize.Y
			Container.Size = UDim2.new(1, 0, 0, 0)

			local Padding = Instance.new("UIPadding")
			Padding.Parent = Container
			Padding.PaddingTop = UDim.new(0, 14)
			Padding.PaddingBottom = UDim.new(0, 10)
			Padding.PaddingLeft = UDim.new(0, 10)
			Padding.PaddingRight = UDim.new(0, 10)

			local UIList = Instance.new("UIListLayout")
			UIList.Parent = Container
			UIList.SortOrder = Enum.SortOrder.LayoutOrder
			UIList.Padding = UDim.new(0, 8)

			local Section = {}

			function Section:AddToggle(opts)
				opts = opts or {}
				local text = opts.Text or "Toggle"
				local default = opts.Default == true
				local callback = opts.Callback or function() end

				local TFrame = Instance.new("Frame")
				TFrame.Parent = Container
				TFrame.BackgroundTransparency = 1
				TFrame.Size = UDim2.new(1, 0, 0, 22)

				local Box = Instance.new("TextButton")
				Box.Parent = TFrame
				Box.Size = UDim2.new(0, 16, 0, 16)
				Box.Position = UDim2.new(0, 0, 0.5, -8)
				Box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				Box.BorderSizePixel = 0
				Box.Text = ""
				addCorner(Box, UDim.new(0, 4))
				addStroke(Box, Color3.fromRGB(60, 60, 60))

				local Fill = Instance.new("Frame")
				Fill.Parent = Box
				Fill.BackgroundColor3 = Library.Accent
				Fill.BorderSizePixel = 0
				Fill.Size = default and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0)
				Fill.Position = UDim2.new(0, 0, 0, 0)
				addCorner(Fill, UDim.new(0, 4))

				local Label = Instance.new("TextButton")
				Label.Parent = TFrame
				Label.BackgroundTransparency = 1
				Label.Position = UDim2.new(0, 24, 0, 0)
				Label.Size = UDim2.new(1, -24, 1, 0)
				Label.Font = Library.Font
				Label.Text = text
				Label.TextColor3 = Color3.fromRGB(150, 150, 150)
				Label.TextSize = 13
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.BorderSizePixel = 0
				Label.AutoButtonColor = false

				local state = default

				local function setState(v)
					state = v
					TweenService:Create(Fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = state and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 0, 1, 0),
					}):Play()
					pcall(callback, state)
				end

				local function toggle()
					setState(not state)
				end

				Box.MouseButton1Click:Connect(toggle)
				Label.MouseButton1Click:Connect(toggle)

				return {
					Set = setState,
					Get = function() return state end,
				}
			end

			function Section:AddButton(opts)
				opts = opts or {}
				local text = opts.Text or opts.name or opts.Name or "Button"
				local callback = opts.Callback or opts.callback or function() end

				local Btn = Instance.new("TextButton")
				Btn.Parent = Container
				Btn.Size = UDim2.new(1, 0, 0, 26)
				Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
				Btn.BorderSizePixel = 0
				Btn.Font = Library.Font
				Btn.Text = text
				Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
				Btn.TextSize = 13
				Btn.AutoButtonColor = true
				addCorner(Btn, UDim.new(0, 6))
				addStroke(Btn, Color3.fromRGB(55, 55, 55))

				Btn.MouseButton1Click:Connect(function()
					pcall(callback)
				end)

				return Btn
			end

			function Section:AddDropdown(opts)
				opts = opts or {}
				local text = opts.Text or opts.name or opts.Name or "Dropdown"
				local items = opts.Items or opts.items or {}
				local default = opts.Default or opts.default or items[1]
				local callback = opts.Callback or opts.callback or function() end

				local DFrame = Instance.new("Frame")
				DFrame.Parent = Container
				DFrame.BackgroundTransparency = 1
				DFrame.Size = UDim2.new(1, 0, 0, 30)

				local Btn = Instance.new("TextButton")
				Btn.Parent = DFrame
				Btn.Size = UDim2.new(1, 0, 0, 26)
				Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
				Btn.BorderSizePixel = 0
				Btn.Font = Library.Font
				Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
				Btn.TextSize = 13
				Btn.TextXAlignment = Enum.TextXAlignment.Left
				Btn.AutoButtonColor = true
				addCorner(Btn, UDim.new(0, 6))
				addStroke(Btn, Color3.fromRGB(55, 55, 55))

				local pad = Instance.new("UIPadding")
				pad.Parent = Btn
				pad.PaddingLeft = UDim.new(0, 10)
				pad.PaddingRight = UDim.new(0, 10)

				local List = Instance.new("Frame")
				List.Parent = Container
				List.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
				List.BorderSizePixel = 0
				List.Visible = false
				List.Size = UDim2.new(1, 0, 0, 0)
				List.AutomaticSize = Enum.AutomaticSize.Y
				addCorner(List, UDim.new(0, 6))
				addStroke(List, Color3.fromRGB(45, 45, 45))

				local lpad = Instance.new("UIPadding")
				lpad.Parent = List
				lpad.PaddingTop = UDim.new(0, 8)
				lpad.PaddingBottom = UDim.new(0, 8)
				lpad.PaddingLeft = UDim.new(0, 8)
				lpad.PaddingRight = UDim.new(0, 8)

				local ll = Instance.new("UIListLayout")
				ll.Parent = List
				ll.SortOrder = Enum.SortOrder.LayoutOrder
				ll.Padding = UDim.new(0, 6)

				local current = default
				local function setValue(v)
					current = v
					Btn.Text = text .. ": " .. tostring(current)
					pcall(callback, current)
				end

				for _, it in ipairs(items) do
					local ItemBtn = Instance.new("TextButton")
					ItemBtn.Parent = List
					ItemBtn.Size = UDim2.new(1, 0, 0, 24)
					ItemBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
					ItemBtn.BorderSizePixel = 0
					ItemBtn.Font = Library.Font
					ItemBtn.Text = tostring(it)
					ItemBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
					ItemBtn.TextSize = 13
					ItemBtn.AutoButtonColor = true
					addCorner(ItemBtn, UDim.new(0, 6))
					addStroke(ItemBtn, Color3.fromRGB(55, 55, 55))

					ItemBtn.MouseButton1Click:Connect(function()
						setValue(it)
						List.Visible = false
					end)
				end

				Btn.MouseButton1Click:Connect(function()
					List.Visible = not List.Visible
				end)

				setValue(current)

				return {
					Set = setValue,
					Get = function() return current end,
				}
			end

			function Section:AddTextBox(opts)
				opts = opts or {}
				local text = opts.Text or opts.name or opts.Name or "Text"
				local placeholder = opts.Placeholder or opts.placeholder or "Type here..."
				local default = opts.Default or opts.default or ""
				local callback = opts.Callback or opts.callback or function() end

				local TFrame = Instance.new("Frame")
				TFrame.Parent = Container
				TFrame.BackgroundTransparency = 1
				TFrame.Size = UDim2.new(1, 0, 0, 46)

				local Label = Instance.new("TextLabel")
				Label.Parent = TFrame
				Label.BackgroundTransparency = 1
				Label.Size = UDim2.new(1, 0, 0, 16)
				Label.Font = Library.Font
				Label.Text = text
				Label.TextColor3 = Color3.fromRGB(150, 150, 150)
				Label.TextSize = 12
				Label.TextXAlignment = Enum.TextXAlignment.Left

				local Box = Instance.new("TextBox")
				Box.Parent = TFrame
				Box.Position = UDim2.new(0, 0, 0, 22)
				Box.Size = UDim2.new(1, 0, 0, 24)
				Box.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
				Box.BorderSizePixel = 0
				Box.Font = Library.Font
				Box.Text = tostring(default)
				Box.PlaceholderText = placeholder
				Box.TextColor3 = Color3.fromRGB(220, 220, 220)
				Box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
				Box.TextSize = 13
				Box.ClearTextOnFocus = false
				Box.TextXAlignment = Enum.TextXAlignment.Left
				addCorner(Box, UDim.new(0, 6))
				addStroke(Box, Color3.fromRGB(55, 55, 55))

				local pad = Instance.new("UIPadding")
				pad.Parent = Box
				pad.PaddingLeft = UDim.new(0, 10)
				pad.PaddingRight = UDim.new(0, 10)

				local function fire()
					pcall(callback, Box.Text)
				end
				Box.FocusLost:Connect(function(enterPressed)
					fire()
				end)

				return {
					Set = function(v) Box.Text = tostring(v) end,
					Get = function() return Box.Text end,
					Box = Box,
				}
			end

			function Section:AddSlider(opts)
				opts = opts or {}
				local text = opts.Text or "Slider"
				local min = tonumber(opts.Min) or 0
				local max = tonumber(opts.Max) or 100
				local default = tonumber(opts.Default) or min
				local interval = tonumber(opts.Interval or opts.interval)
				local suffix = opts.Suffix or ""
				local callback = opts.Callback or function() end

				default = math.clamp(default, min, max)

				local SFrame = Instance.new("Frame")
				SFrame.Parent = Container
				SFrame.BackgroundTransparency = 1
				SFrame.Size = UDim2.new(1, 0, 0, 42)

				local Top = Instance.new("TextLabel")
				Top.Parent = SFrame
				Top.BackgroundTransparency = 1
				Top.Size = UDim2.new(1, 0, 0, 16)
				Top.Font = Library.Font
				Top.TextXAlignment = Enum.TextXAlignment.Left
				Top.TextColor3 = Color3.fromRGB(150, 150, 150)
				Top.TextSize = 12
				Top.Text = text

				local ValueLabel = Instance.new("TextLabel")
				ValueLabel.Parent = SFrame
				ValueLabel.BackgroundTransparency = 1
				ValueLabel.Size = UDim2.new(1, 0, 0, 16)
				ValueLabel.Font = Library.Font
				ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
				ValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				ValueLabel.TextSize = 12

				local Bar = Instance.new("Frame")
				Bar.Parent = SFrame
				Bar.Position = UDim2.new(0, 0, 0, 22)
				Bar.Size = UDim2.new(1, 0, 0, 12)
				Bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				Bar.BorderSizePixel = 0
				addCorner(Bar, UDim.new(0, 4))
				addStroke(Bar, Color3.fromRGB(55, 55, 55))

				local Fill = Instance.new("Frame")
				Fill.Parent = Bar
				Fill.BackgroundColor3 = Library.Accent
				Fill.BorderSizePixel = 0
				Fill.Size = UDim2.new(0, 0, 1, 0)
				addCorner(Fill, UDim.new(0, 4))

				local hitbox = Instance.new("TextButton")
				hitbox.Parent = Bar
				hitbox.BackgroundTransparency = 1
				hitbox.Size = UDim2.new(1, 0, 1, 0)
				hitbox.Text = ""
				hitbox.ZIndex = 5

				local value = default
				local draggingSlider = false

				local function snap(v)
					if interval and interval > 0 then
						local steps = math.floor(((v - min) / interval) + 0.5)
						return min + (steps * interval)
					end
					return v
				end

				local function setValue(v)
					value = math.clamp(snap(v), min, max)
					local pct = (value - min) / (max - min)
					Fill.Size = UDim2.new(pct, 0, 1, 0)
					ValueLabel.Text = tostring(math.floor(value + 0.5)) .. suffix
					pcall(callback, value)
				end

				local function updateFromX(x)
					local rel = clamp01((x - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X)
					local v = min + (max - min) * rel
					setValue(v)
				end

				hitbox.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingSlider = true
						updateFromX(input.Position.X)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if not draggingSlider then
						return
					end
					if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
						updateFromX(input.Position.X)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						draggingSlider = false
					end
				end)

				setValue(default)

				return {
					Set = setValue,
					Get = function() return value end,
				}
			end

			function Section:AddColorPicker(opts)
				opts = opts or {}
				local text = opts.Text or "Color"
				local default = opts.Default or Library.Accent
				local callback = opts.Callback or function() end

				local h, s, v = safeToHSV(default)

				local PFrame = Instance.new("Frame")
				PFrame.Parent = Container
				PFrame.BackgroundTransparency = 1
				PFrame.Size = UDim2.new(1, 0, 0, 26)

				local Label = Instance.new("TextButton")
				Label.Parent = PFrame
				Label.BackgroundTransparency = 1
				Label.Position = UDim2.new(0, 0, 0, 0)
				Label.Size = UDim2.new(1, -56, 1, 0)
				Label.Font = Library.Font
				Label.Text = text
				Label.TextColor3 = Color3.fromRGB(150, 150, 150)
				Label.TextSize = 13
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.BorderSizePixel = 0
				Label.AutoButtonColor = false

				local Preview = Instance.new("TextButton")
				Preview.Parent = PFrame
				Preview.AnchorPoint = Vector2.new(1, 0)
				Preview.Position = UDim2.new(1, 0, 0, 0)
				Preview.Size = UDim2.new(0, 46, 0, 20)
				Preview.BackgroundColor3 = default
				Preview.BorderSizePixel = 0
				Preview.Text = ""
				addCorner(Preview, UDim.new(0, 4))
				addStroke(Preview, Color3.fromRGB(60, 60, 60))

				local Picker = Instance.new("Frame")
				Picker.Parent = Container
				Picker.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
				Picker.BorderSizePixel = 0
				Picker.Visible = false
				Picker.Size = UDim2.new(1, 0, 0, 156)
				addCorner(Picker, UDim.new(0, 6))
				addStroke(Picker, Color3.fromRGB(45, 45, 45))

				local pad = Instance.new("UIPadding")
				pad.Parent = Picker
				pad.PaddingTop = UDim.new(0, 8)
				pad.PaddingBottom = UDim.new(0, 8)
				pad.PaddingLeft = UDim.new(0, 8)
				pad.PaddingRight = UDim.new(0, 8)

				local SV = Instance.new("ImageButton")
				SV.Parent = Picker
				SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				SV.BorderSizePixel = 0
				SV.Size = UDim2.new(1, -22, 1, -34)
				SV.Image = "rbxassetid://4155801252" -- sat/val square
				SV.AutoButtonColor = false
				addCorner(SV, UDim.new(0, 4))
				addStroke(SV, Color3.fromRGB(55, 55, 55))

				local SVPicker = Instance.new("Frame")
				SVPicker.Parent = SV
				SVPicker.Size = UDim2.new(0, 10, 0, 10)
				SVPicker.AnchorPoint = Vector2.new(0.5, 0.5)
				SVPicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				SVPicker.BorderSizePixel = 0
				addCorner(SVPicker, UDim.new(0, 10))
				addStroke(SVPicker, Color3.fromRGB(0, 0, 0))

				local Hue = Instance.new("ImageButton")
				Hue.Parent = Picker
				Hue.AnchorPoint = Vector2.new(1, 0)
				Hue.Position = UDim2.new(1, 0, 0, 0)
				Hue.Size = UDim2.new(0, 14, 1, -34)
				Hue.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Hue.BorderSizePixel = 0
				Hue.Image = "rbxassetid://3641079629" -- hue gradient
				Hue.AutoButtonColor = false
				addCorner(Hue, UDim.new(0, 4))
				addStroke(Hue, Color3.fromRGB(55, 55, 55))

				local HuePicker = Instance.new("Frame")
				HuePicker.Parent = Hue
				HuePicker.Size = UDim2.new(1, 0, 0, 3)
				HuePicker.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HuePicker.BorderSizePixel = 0
				addCorner(HuePicker, UDim.new(0, 4))

				local HexLabel = Instance.new("TextLabel")
				HexLabel.Parent = Picker
				HexLabel.BackgroundTransparency = 1
				HexLabel.Position = UDim2.new(0, 0, 1, -22)
				HexLabel.Size = UDim2.new(1, 0, 0, 14)
				HexLabel.Font = Library.Font
				HexLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
				HexLabel.TextSize = 12
				HexLabel.TextXAlignment = Enum.TextXAlignment.Left

				local function setPickerPositions()
					SVPicker.Position = UDim2.new(s, 0, 1 - v, 0)
					HuePicker.Position = UDim2.new(0, 0, h, 0)
				end

				local function applyColor()
					local c = hsvToColor(h, s, v)
					Preview.BackgroundColor3 = c
					SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
					HexLabel.Text = colorToHex(c)
					pcall(callback, c)
				end

				local pickingSV = false
				local pickingHue = false

				local function updateSVFromPos(pos)
					local relX = clamp01((pos.X - SV.AbsolutePosition.X) / SV.AbsoluteSize.X)
					local relY = clamp01((pos.Y - SV.AbsolutePosition.Y) / SV.AbsoluteSize.Y)
					s = relX
					v = 1 - relY
					setPickerPositions()
					applyColor()
				end

				local function updateHueFromPos(pos)
					local relY = clamp01((pos.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y)
					h = relY
					setPickerPositions()
					applyColor()
				end

				SV.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						pickingSV = true
						updateSVFromPos(input.Position)
					end
				end)
				Hue.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						pickingHue = true
						updateHueFromPos(input.Position)
					end
				end)

				UserInputService.InputChanged:Connect(function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
						return
					end
					if pickingSV then
						updateSVFromPos(input.Position)
					elseif pickingHue then
						updateHueFromPos(input.Position)
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						pickingSV = false
						pickingHue = false
					end
				end)

				local function togglePicker()
					Picker.Visible = not Picker.Visible
				end
				Label.MouseButton1Click:Connect(togglePicker)
				Preview.MouseButton1Click:Connect(togglePicker)

				setPickerPositions()
				applyColor()

				return {
					Set = function(color)
						local nh, ns, nv = safeToHSV(color)
						h, s, v = nh, ns, nv
						setPickerPositions()
						applyColor()
					end,
					Get = function() return hsvToColor(h, s, v) end,
				}
			end

			-- v2-style names + flags
			function Section:toggle(opts)
				opts = opts or {}
				local flag = opts.flag
				local control = self:AddToggle({
					Text = opts.name or opts.Text or "Toggle",
					Default = opts.default == true or opts.Default == true,
					Callback = function(v)
						if flag then
							Library.flags[flag] = v
						end
						local cb = opts.callback or opts.Callback
						if cb then
							cb(v)
						end
					end,
				})
				if flag then
					Library.flags[flag] = control.Get()
				end
				return control
			end

			function Section:slider(opts)
				opts = opts or {}
				local flag = opts.flag
				local control = self:AddSlider({
					Text = opts.name or opts.Text or "Slider",
					Min = opts.min or opts.Min,
					Max = opts.max or opts.Max,
					Default = opts.default or opts.Default,
					Interval = opts.interval or opts.Interval,
					Suffix = opts.suffix or opts.Suffix or "",
					Callback = function(v)
						if flag then
							Library.flags[flag] = v
						end
						local cb = opts.callback or opts.Callback
						if cb then
							cb(v)
						end
					end,
				})
				if flag then
					Library.flags[flag] = control.Get()
				end
				return control
			end

			function Section:dropdown(opts)
				opts = opts or {}
				local flag = opts.flag
				local control = self:AddDropdown({
					Text = opts.name or opts.Text or "Dropdown",
					Items = opts.items or opts.Items or {},
					Default = opts.default or opts.Default,
					Callback = function(v)
						if flag then
							Library.flags[flag] = v
						end
						local cb = opts.callback or opts.Callback
						if cb then
							cb(v)
						end
					end,
				})
				if flag then
					Library.flags[flag] = control.Get()
				end
				return control
			end

			function Section:colorpicker(opts)
				opts = opts or {}
				local flag = opts.flag
				local alpha = tonumber(opts.alpha) or 0
				local cb = opts.callback or opts.Callback
				local control = self:AddColorPicker({
					Text = opts.name or opts.Text or "Color",
					Default = opts.color or opts.Default or Library.Accent,
					Callback = function(c)
						if flag then
							Library.flags[flag] = c
						end
						if cb then
							cb(c, alpha)
						end
					end,
				})
				if flag then
					Library.flags[flag] = control.Get()
				end
				return control
			end

			function Section:button(opts)
				opts = opts or {}
				return self:AddButton({
					Text = opts.name or opts.Text or "Button",
					Callback = opts.callback or opts.Callback,
				})
			end

			function Section:textbox(opts)
				opts = opts or {}
				local flag = opts.flag
				local control = self:AddTextBox({
					Text = opts.name or opts.Text or "Text",
					Placeholder = opts.placeholder or opts.Placeholder,
					Default = opts.default or opts.Default,
					Callback = function(v)
						if flag then
							Library.flags[flag] = v
						end
						local cb = opts.callback or opts.Callback
						if cb then
							cb(v)
						end
					end,
				})
				if flag then
					Library.flags[flag] = control.Get()
				end
				return control
			end

			return Section
		end

		local tabObj = {
			Button = TabBtn,
			Underline = Underline,
			Container = TabContent,
			Tab = Tab,
		}
		table.insert(Window._tabs, tabObj)

		TabBtn.MouseButton1Click:Connect(function()
			setActiveTab(tabObj)
		end)

		if not Window._activeTab then
			setActiveTab(tabObj)
		end

		return Tab
	end

	-- Backward-compatible helpers (v1 scripts):
	-- - Window:Section(name, side)
	-- - Window:Tab(name)
	local compatDefaultTab = nil
	function Window:Tab(name)
		return self:CreateTab(name)
	end
	function Window:Section(name, side)
		if not compatDefaultTab then
			compatDefaultTab = self:CreateTab("General")
		end
		return compatDefaultTab:CreateSection(name, side)
	end

	function Window:SetOpen(isOpen)
		setOpen(isOpen)
	end

	function Window:Destroy()
		if ScreenGui then
			ScreenGui:Destroy()
		end
	end

	-- v2-style API wrappers
	function Window:tab(opts)
		opts = opts or {}
		return self:CreateTab(opts.name or opts.Name or "Tab")
	end

	return Window
end

-- Backward-compatible constructor name (v1 scripts): Library:Create()
function Library:Create(options)
	return self:CreateWindow(options)
end

-- v2-style constructor: library:window({ ... })
function Library:window(opts)
	return self:CreateWindow(opts)
end

-- Basic notifications API (v2-style)
function Library.notifications:create_notification(opts)
	opts = opts or {}
	local title = opts.name or opts.Name or Library.Name
	local info = opts.info or opts.Info or ""
	local lifetime = tonumber(opts.lifetime) or 3

	local holder = nil
	if Library and Library._lastWindow and Library._lastWindow._notifHolder then
		holder = Library._lastWindow._notifHolder
	end
	if not holder then
		return
	end

	local Card = Instance.new("Frame")
	Card.Parent = holder
	Card.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Card.BorderSizePixel = 0
	Card.Size = UDim2.new(1, 0, 0, 52)
	Card.ZIndex = 61
	addCorner(Card, UDim.new(0, 8))
	addStroke(Card, Color3.fromRGB(45, 45, 45))

	local T = Instance.new("TextLabel")
	T.Parent = Card
	T.BackgroundTransparency = 1
	T.Position = UDim2.new(0, 10, 0, 6)
	T.Size = UDim2.new(1, -20, 0, 16)
	T.Font = Library.Font
	T.Text = tostring(title)
	T.TextColor3 = Color3.fromRGB(230, 230, 230)
	T.TextSize = 13
	T.TextXAlignment = Enum.TextXAlignment.Left
	T.ZIndex = 62

	local I = Instance.new("TextLabel")
	I.Parent = Card
	I.BackgroundTransparency = 1
	I.Position = UDim2.new(0, 10, 0, 24)
	I.Size = UDim2.new(1, -20, 0, 22)
	I.Font = Library.Font
	I.Text = tostring(info)
	I.TextColor3 = Color3.fromRGB(170, 170, 170)
	I.TextSize = 12
	I.TextXAlignment = Enum.TextXAlignment.Left
	I.TextWrapped = true
	I.ZIndex = 62

	task.delay(lifetime, function()
		if Card and Card.Parent then
			TweenService:Create(Card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
			task.delay(0.22, function()
				if Card and Card.Parent then
					Card:Destroy()
				end
			end)
		end
	end)
end

-- Track the most recent window for notifications
local _oldCreateWindow = Library.CreateWindow
function Library:CreateWindow(options)
	local w = _oldCreateWindow(self, options)
	Library._lastWindow = w
	return w
end

return Library
