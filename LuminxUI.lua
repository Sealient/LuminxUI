local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local lib = {}

-- global accent color used by various UI elements (modifiable from Settings)
local accentColor = Color3.fromRGB(0,170,255)
local LIB_VERSION = "1.0.0"

function lib:CreateWindow(titleText)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "LuminxUI"
	ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	ScreenGui.ResetOnSpawn = false

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 650, 0, 420)
	MainFrame.Position = UDim2.new(0.5, -325, 0.5, -210)
	MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	MainFrame.BackgroundTransparency = 0.1
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	local MainCorner = Instance.new("UICorner", MainFrame)
	MainCorner.CornerRadius = UDim.new(0, 4)

	local MainStroke = Instance.new("UIStroke", MainFrame)
	MainStroke.Color = Color3.fromRGB(255, 255, 255)
	MainStroke.Transparency = 0.9
	MainStroke.Thickness = 1

	-- SIDEBAR (Used as the Drag Handle)
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 170, 1, 0)
	Sidebar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Sidebar.BackgroundTransparency = 0.4
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame
	Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 4)

	-- DRAGGING LOGIC (Sidebar Only)
	local dragging, dragInput, dragStart, startPos
	Sidebar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 60)
	Title.BackgroundTransparency = 1
	Title.Text = string.upper(titleText)
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.Font = Enum.Font.RobotoMono
	Title.TextSize = 15
	Title.Parent = Sidebar

	local Separator = Instance.new("Frame")
	Separator.Size = UDim2.new(0.7, 0, 0, 1)
	Separator.Position = UDim2.new(0.15, 0, 0, 60)
	Separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Separator.BackgroundTransparency = 0.9
	Separator.Parent = Sidebar

	local Indicator = Instance.new("Frame")
	Indicator.Size = UDim2.new(0, 2, 0, 20)
	Indicator.BackgroundColor3 = accentColor
	Indicator.BorderSizePixel = 0
	Indicator.Visible = false
	Indicator.ZIndex = 5
	Indicator.Parent = Sidebar

	local TabHolder = Instance.new("ScrollingFrame")
	TabHolder.Size = UDim2.new(1, 0, 1, -70)
	TabHolder.Position = UDim2.new(0, 0, 0, 70)
	TabHolder.BackgroundTransparency = 1
	TabHolder.BorderSizePixel = 0
	TabHolder.ScrollBarThickness = 0
	TabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y -- Allows the list to grow 
	TabHolder.Parent = Sidebar
	
	local Layout = Instance.new("UIListLayout", TabHolder)
	Layout.Padding = UDim.new(0, 2)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Floating profile in the bottom-left of the sidebar
	local profileFrame = Instance.new("Frame", Sidebar)
	profileFrame.Name = "Profile"
	profileFrame.Size = UDim2.new(0, 150, 0, 48)
	profileFrame.Position = UDim2.new(0, 10, 1, -62)
	profileFrame.BackgroundColor3 = Color3.fromRGB(40,42,46)
	profileFrame.BackgroundTransparency = 0
	profileFrame.BorderSizePixel = 0
	profileFrame.ZIndex = 20
	profileFrame.ClipsDescendants = false
	Instance.new("UICorner", profileFrame).CornerRadius = UDim.new(0,6)
	local profileStroke = Instance.new("UIStroke", profileFrame)
	profileStroke.Color = Color3.fromRGB(35,35,35)
	profileStroke.Transparency = 0.7
	profileStroke.Thickness = 1

	-- avatar background (circular) to ensure we always have a visible circle behind the image
	local avatarBG = Instance.new("Frame", profileFrame)
	avatarBG.Name = "AvatarBG"
	avatarBG.Size = UDim2.new(0,36,0,36)
	avatarBG.Position = UDim2.new(0,8,0,6)
	avatarBG.BackgroundColor3 = Color3.fromRGB(96,96,96)
	avatarBG.BorderSizePixel = 0
	-- ensure the avatar background sits behind text
	avatarBG.ZIndex = 21
	Instance.new("UICorner", avatarBG).CornerRadius = UDim.new(1,0)

	local avatar = Instance.new("ImageLabel", avatarBG)
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(1,0,1,0)
	avatar.Position = UDim2.new(0,0,0,0)
	avatar.BackgroundTransparency = 1
	avatar.ScaleType = Enum.ScaleType.Fit
	avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(game.Players.LocalPlayer.UserId) .. "&w=48&h=48"
	avatar.ZIndex = 22
	Instance.new("UICorner", avatar).CornerRadius = UDim.new(1,0)

	-- info container to avoid overlap with avatar (centered name + stats)
	local infoFrame = Instance.new("Frame", profileFrame)
	infoFrame.Name = "Info"
	infoFrame.Position = UDim2.new(0,52,0,6)
	infoFrame.Size = UDim2.new(1,-64,1,-12)
	infoFrame.BackgroundTransparency = 1
	-- keep info above avatar
	infoFrame.ZIndex = 23

	local nameLbl = Instance.new("TextLabel", infoFrame)
	nameLbl.Name = "Name"
	nameLbl.Position = UDim2.new(0,0,0,0)
	nameLbl.Size = UDim2.new(1,0,0,14)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = game.Players.LocalPlayer.Name
	nameLbl.Font = Enum.Font.RobotoMono
	nameLbl.TextSize = 12
	nameLbl.TextColor3 = Color3.fromRGB(255,255,255)
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextScaled = false
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.ZIndex = 24
	nameLbl.TextTransparency = 0
	if not nameLbl.Text or nameLbl.Text == "" then nameLbl.Text = game.Players.LocalPlayer.Name or "Player" end
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left

	-- stats row (fps / ping / version)
	local statsFrame = Instance.new("Frame", infoFrame)
	statsFrame.Name = "Stats"
	statsFrame.Position = UDim2.new(0,0,0,18)
	statsFrame.Size = UDim2.new(1,0,0,12)
	statsFrame.BackgroundTransparency = 1
	statsFrame.ZIndex = 23

	local fpsLbl = Instance.new("TextLabel", statsFrame)
	fpsLbl.Name = "FPS"
	fpsLbl.Size = UDim2.new(0.33, -6, 1, 0)
	fpsLbl.Position = UDim2.new(0, 0, 0, 0)
	fpsLbl.BackgroundTransparency = 1
	fpsLbl.Text = "-- FPS"
	fpsLbl.Font = Enum.Font.RobotoMono
	fpsLbl.TextSize = 10
	fpsLbl.TextColor3 = Color3.fromRGB(200,200,200)
	fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
	fpsLbl.ZIndex = 24
	fpsLbl.TextTransparency = 0

	local pingLbl = Instance.new("TextLabel", statsFrame)
	pingLbl.Name = "Ping"
	pingLbl.Size = UDim2.new(0.34, -6, 1, 0)
	pingLbl.Position = UDim2.new(0.33, 3, 0, 0)
	pingLbl.BackgroundTransparency = 1
	pingLbl.Text = "-- ms"
	pingLbl.Font = Enum.Font.RobotoMono
	pingLbl.TextSize = 10
	pingLbl.TextColor3 = Color3.fromRGB(200,200,200)
	pingLbl.TextXAlignment = Enum.TextXAlignment.Center
	pingLbl.ZIndex = 24
	pingLbl.TextTransparency = 0

	local verLbl = Instance.new("TextLabel", statsFrame)
	verLbl.Name = "Version"
	verLbl.Size = UDim2.new(0.33, 0, 1, 0)
	verLbl.Position = UDim2.new(0.67, 0, 0, 0)
	verLbl.BackgroundTransparency = 1
	verLbl.Text = LIB_VERSION
	verLbl.Font = Enum.Font.RobotoMono
	verLbl.TextSize = 10
	verLbl.TextColor3 = Color3.fromRGB(190,190,190)
	verLbl.TextXAlignment = Enum.TextXAlignment.Right
	verLbl.ZIndex = 24
	verLbl.TextTransparency = 0

	local accentDot = Instance.new("Frame", profileFrame)
	accentDot.Name = "AccentDot"
	accentDot.Size = UDim2.new(0,8,0,8)
	accentDot.Position = UDim2.new(1,-12,0,8)
	accentDot.BackgroundColor3 = accentColor
	accentDot.BorderSizePixel = 0
	Instance.new("UICorner", accentDot).CornerRadius = UDim.new(1,0)

	-- subtle hover effect
	profileFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			pcall(function()
				TweenService:Create(profileFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(48,50,54)}):Play()
			end)
		end
	end)
	profileFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			pcall(function()
				TweenService:Create(profileFrame, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40,42,46)}):Play()
			end)
		end
	end)

	-- update FPS / Ping periodically
	local fpsAcc, fpsCount, fpsTimer = 0, 0, 0
	local statsConn
	statsConn = RunService.Heartbeat:Connect(function(dt)
		-- FPS averaging
		if dt and dt > 0 then
			fpsAcc = fpsAcc + (1 / dt)
			fpsCount = fpsCount + 1
			fpsTimer = fpsTimer + dt
		end
		if fpsTimer >= 0.6 then
			local avg = math.floor((fpsAcc / math.max(1, fpsCount)) + 0.5)
			if fpsLbl and fpsLbl.Text then fpsLbl.Text = tostring(avg) .. " FPS" end
			fpsAcc, fpsCount, fpsTimer = 0, 0, 0
		end
		-- ping (try to read Stats service safely)
		local pingVal = 0
		pcall(function()
			local net = game:GetService("Stats").Network
			if net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"] and net.ServerStatsItem["Data Ping"].GetValue then
				pingVal = math.floor(net.ServerStatsItem["Data Ping"]:GetValue())
			end
		end)
		if pingLbl and pingLbl.Text then pingLbl.Text = tostring(pingVal) .. " ms" end
		-- cleanup if profile removed
		if not profileFrame or not profileFrame.Parent then if statsConn then statsConn:Disconnect(); statsConn = nil end end
	end)

	-- SEARCH BAR
	local SearchFrame = Instance.new("Frame")
	SearchFrame.Size = UDim2.new(1, -210, 0, 32)
	SearchFrame.Position = UDim2.new(0, 185, 0, 15)
	SearchFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SearchFrame.BackgroundTransparency = 0.96
	SearchFrame.Parent = MainFrame
	Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(1, 0)

	local SearchStroke = Instance.new("UIStroke", SearchFrame)
	SearchStroke.Color = accentColor
	SearchStroke.Transparency = 1

	local SearchInput = Instance.new("TextBox")
	SearchInput.Size = UDim2.new(1, -30, 1, 0)
	SearchInput.Position = UDim2.new(0, 15, 0, 0)
	SearchInput.BackgroundTransparency = 1
	SearchInput.PlaceholderText = "SEARCH..."
	SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchInput.Font = Enum.Font.RobotoMono
	SearchInput.TextSize = 12
	SearchInput.TextXAlignment = Enum.TextXAlignment.Left
	SearchInput.Parent = SearchFrame

	SearchInput.Focused:Connect(function() TweenService:Create(SearchStroke, TweenInfo.new(0.3), {Transparency = 0.6}):Play() end)
	SearchInput.FocusLost:Connect(function() TweenService:Create(SearchStroke, TweenInfo.new(0.3), {Transparency = 1}):Play() end)

	local PageContainer = Instance.new("Frame")
	PageContainer.Size = UDim2.new(1, -210, 1, -70)
	PageContainer.Position = UDim2.new(0, 185, 0, 60)
	PageContainer.BackgroundTransparency = 1
	PageContainer.Parent = MainFrame

	local windowFunctions = {}

	-- Notifications: sleek, minimal, semi-transparent stacked toasts
	local notifContainer = Instance.new("Frame", ScreenGui)
	notifContainer.Name = "Notifications"
	notifContainer.Size = UDim2.new(0, 320, 1, 0)
	notifContainer.Position = UDim2.new(1, -20, 0, 20)
	notifContainer.AnchorPoint = Vector2.new(1, 0)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ClipsDescendants = false
	notifContainer.ZIndex = 50

	local activeNotifs = {}

	local function shiftNotifs()
		for i, nf in ipairs(activeNotifs) do
			local targetY = (i-1) * 66
			if nf and nf.Frame then
				TweenService:Create(nf.Frame, TweenInfo.new(0.24, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -16, 0, targetY)}):Play()
			end
		end
	end

	local function makeNotification(title, body, duration, ntype)
		duration = duration or 4
		ntype = ntype or "info"
		local accents = {
			info = accentColor,
			success = Color3.fromRGB(0,200,120),
			warn = Color3.fromRGB(255,180,0),
			error = Color3.fromRGB(255,80,80)
		}
		local accent = accents[ntype] or accents.info

		local nf = Instance.new("Frame", notifContainer)
		nf.Size = UDim2.new(0, 320, 0, 56)
		nf.Position = UDim2.new(1, 380, 0, (#activeNotifs) * 66)
		nf.AnchorPoint = Vector2.new(1,0)
		nf.BackgroundColor3 = Color3.fromRGB(18,18,18)
		nf.BackgroundTransparency = 0.2
		nf.BorderSizePixel = 0
		nf.ZIndex = 51
		Instance.new("UICorner", nf).CornerRadius = UDim.new(0,6)
		local stroke = Instance.new("UIStroke", nf)
		stroke.Color = Color3.fromRGB(35,35,35)
		stroke.Transparency = 0.75
		stroke.Thickness = 1

		local accentBar = Instance.new("Frame", nf)
		accentBar.Size = UDim2.new(0,4,1,0)
		accentBar.Position = UDim2.new(0,0,0,0)
		accentBar.BackgroundColor3 = accent
		accentBar.ZIndex = nf.ZIndex
		Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0,3)

		local titleLbl = Instance.new("TextLabel", nf)
		titleLbl.Position = UDim2.new(0, 14, 0, 6)
		titleLbl.Size = UDim2.new(1, -40, 0, 16)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title or "Notification"
		titleLbl.TextColor3 = accent
		titleLbl.ZIndex = nf.ZIndex + 1
		titleLbl.Font = Enum.Font.RobotoMono
		titleLbl.TextSize = 13
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left

		local bodyLbl = Instance.new("TextLabel", nf)
		bodyLbl.Position = UDim2.new(0, 14, 0, 24)
		bodyLbl.Size = UDim2.new(1, -40, 0, 28)
		bodyLbl.BackgroundTransparency = 1
		bodyLbl.Text = body or ""
		bodyLbl.TextColor3 = Color3.fromRGB(190,190,190)
		bodyLbl.Font = Enum.Font.SourceSans
		bodyLbl.TextSize = 12
		bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
		bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
		bodyLbl.TextWrapped = true
		bodyLbl.ZIndex = nf.ZIndex + 1

		local closeBtn = Instance.new("TextButton", nf)
		closeBtn.Size = UDim2.new(0,20,0,20)
		closeBtn.Position = UDim2.new(1, -30, 0, 8)
		closeBtn.BackgroundTransparency = 1
		closeBtn.Text = "✕"
		closeBtn.Font = Enum.Font.RobotoMono
		closeBtn.TextSize = 14
		closeBtn.TextColor3 = Color3.fromRGB(160,160,160)
		closeBtn.AutoButtonColor = true
		closeBtn.ZIndex = nf.ZIndex + 1

		local data = {Frame = nf, Alive = true}
		table.insert(activeNotifs, data)
		shiftNotifs()

		-- entrance animation
		TweenService:Create(nf, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0, (#activeNotifs-1) * 66), BackgroundTransparency = 0.2}):Play()

		local alive = true
		local elapsed = 0
		local paused = false

		local function cleanup()
			if not data.Alive then return end
			data.Alive = false
			-- remove from activeNotifs
			for i, v in ipairs(activeNotifs) do if v == data then table.remove(activeNotifs, i); break end end
			-- exit animation (slide right and fade)
			TweenService:Create(nf, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {Position = UDim2.new(1, 380, 0, nf.Position.Y.Offset), BackgroundTransparency = 1}):Play()
			task.delay(0.18, function() pcall(function() nf:Destroy() end) end)
			shiftNotifs()
		end

		-- hover to pause
		nf.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement then paused = true end
		end)
		nf.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseMovement then paused = false end
		end)

		closeBtn.MouseButton1Click:Connect(function() if alive then alive = false; cleanup() end end)

		-- auto-dismiss loop
		spawn(function()
			while alive do
				if not paused then
					task.wait(0.2)
					elapsed = elapsed + 0.2
					if elapsed >= duration then alive = false; cleanup(); break end
				else
					task.wait(0.2)
				end
			end
		end)

		return data
	end

	function windowFunctions:Notify(title, body, duration, ntype)
		pcall(function() makeNotification(title, body, duration, ntype) end)
	end
	local firstPage = true
	
	local Tooltip = Instance.new("TextLabel")
	Tooltip.Name = "GlobalTooltip"
	Tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Tooltip.BorderColor3 = Color3.fromRGB(60, 60, 60)
	Tooltip.BorderSizePixel = 1
	Tooltip.Size = UDim2.new(0, 100, 0, 20)
	Tooltip.Visible = false
	Tooltip.ZIndex = 100 -- Ensure it's on top
	Tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
	Tooltip.Font = Enum.Font.SourceSans
	Tooltip.TextSize = 12
	Tooltip.Parent = game.CoreGui:FindFirstChildOfClass("ScreenGui") or TabHolder.Parent -- Use the main UI parent

	local UICorner = Instance.new("UICorner", Tooltip)
	UICorner.CornerRadius = UDim.new(0, 4)

	-- Logic to make it follow the mouse
	game:GetService("RunService").RenderStepped:Connect(function()
		if Tooltip.Visible then
			local mousePos = UserInputService:GetMouseLocation()
			Tooltip.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y + 15)
		end
	end)

	-- track any open dropdown so we can close others when needed
	local openDropdown = nil
	local TweenService = game:GetService("TweenService")

	function lib:CreateTab(name, parentTab)
		local tab = {}
		tab.IsExpanded = false

		-- Main Container for this tab and its children 
		local TabContainer = Instance.new("Frame")
		TabContainer.Name = name .. "_Container"
		TabContainer.Size = UDim2.new(1, 0, 0, 32) -- Initial height of one tab
		TabContainer.BackgroundTransparency = 1
		TabContainer.ClipsDescendants = true -- Essential for accordion effect
		-- If a parentTab is provided, nest it; otherwise, put it in the main TabHolder 
		TabContainer.Parent = parentTab and parentTab.SubContainer or TabHolder

		-- The Button that triggers the tab/accordion
		local TabButton = Instance.new("TextButton")
		TabButton.Size = UDim2.new(1, 0, 0, 32)
		TabButton.BackgroundTransparency = 1
		TabButton.Text = (parentTab and "    " or "  ") .. name -- Indent text if it's a sub-tab
		TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		TabButton.Font = Enum.Font.RobotoMono
		TabButton.TextSize = 14
		TabButton.TextXAlignment = Enum.TextXAlignment.Left
		TabButton.Parent = TabContainer

		-- The Container for nested sub-tabs (the "Tree" part)
		local SubContainer = Instance.new("Frame")
		SubContainer.Name = "SubContainer"
		SubContainer.Position = UDim2.new(0, 0, 0, 32)
		SubContainer.Size = UDim2.new(1, 0, 0, 0)
		SubContainer.BackgroundTransparency = 1
		SubContainer.Parent = TabContainer

		local SubLayout = Instance.new("UIListLayout", SubContainer)
		SubLayout.Padding = UDim.new(0, 2)
		tab.SubContainer = SubContainer

		-- The Page where actual content (buttons/toggles) will go
		local Page = Instance.new("ScrollingFrame")
		Page.Name = name .. "_Page"
		Page.Size = UDim2.new(1, -20, 1, -20)
		Page.Position = UDim2.new(0, 10, 0, 10)
		Page.BackgroundTransparency = 1
		Page.Visible = false
		Page.Parent = PageContainer -- Assumed global from CreateWindow 

		-- Logic to update heights recursively for the accordion effect
		local function updateTreeHeight()
			if tab.IsExpanded then
				local childrenHeight = SubLayout.AbsoluteContentSize.Y
				TabContainer.Size = UDim2.new(1, 0, 0, 32 + childrenHeight)
			else
				TabContainer.Size = UDim2.new(1, 0, 0, 32)
			end

			-- If this tab itself is inside another tab, tell the parent to resize too
			if parentTab and parentTab.UpdateHeight then
				parentTab.UpdateHeight()
			end
		end
		tab.UpdateHeight = updateTreeHeight

		-- Accordion Animation Toggle
		local function toggleAccordion()
			tab.IsExpanded = not tab.IsExpanded
			local targetHeight = tab.IsExpanded and (32 + SubLayout.AbsoluteContentSize.Y) or 32

			local tween = TweenService:Create(TabContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(1, 0, 0, targetHeight)
			})

			tween:Play()
			tween.Completed:Connect(function()
				if parentTab then parentTab.UpdateHeight() end
			end)
		end

		TabButton.MouseButton1Click:Connect(function()
			-- If it has children sub-tabs, act as an accordion
			if #SubContainer:GetChildren() > 1 then -- >1 because of UIListLayout
				toggleAccordion()
			end

			-- Logic to switch to this tab's page
			for _, p in pairs(PageContainer:GetChildren()) do
				p.Visible = false
			end
			Page.Visible = true
		end)

		function tab:CreateButton(btnName, callback)
			callback = callback or function() end

			-- 1. Ensure the Page has a layout if it doesn't already
			if not Page:FindFirstChildOfClass("UIListLayout") then
				local layout = Instance.new("UIListLayout", Page)
				layout.Padding = UDim.new(0, 5)
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				layout.SortOrder = Enum.SortOrder.LayoutOrder
			end

			-- 2. Create the Button UI
			local Button = Instance.new("TextButton")
			Button.Name = btnName .. "_Btn"
			Button.Size = UDim2.new(1, -10, 0, 30) -- Full width minus padding
			Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
			Button.BorderSizePixel = 0
			Button.Text = btnName
			Button.TextColor3 = Color3.fromRGB(255, 255, 255)
			Button.Font = Enum.Font.SourceSans
			Button.TextSize = 14
			Button.AutoButtonColor = true
			Button.Parent = Page

			-- 3. Rounded Corners (Optional but looks better)
			local UICorner = Instance.new("UICorner", Button)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 4. Functionality
			Button.MouseButton1Click:Connect(function()
				-- Brief visual feedback
				local originalColor = Button.BackgroundColor3
				Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
				task.wait(0.1)
				Button.BackgroundColor3 = originalColor

				callback()
			end)

			return Button
		end

		function tab:CreateLabel(labelText)
			-- 1. Ensure the Page has a layout (Consistency check)
			if not Page:FindFirstChildOfClass("UIListLayout") then
				local layout = Instance.new("UIListLayout", Page)
				layout.Padding = UDim.new(0, 5)
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				layout.SortOrder = Enum.SortOrder.LayoutOrder
			end

			-- 2. Create Label Container
			local Label = Instance.new("TextLabel")
			Label.Name = "Label_" .. labelText
			Label.Size = UDim2.new(1, -10, 0, 20) -- Slimmer than a button
			Label.BackgroundTransparency = 1 -- Keep it clean
			Label.Text = labelText
			Label.TextColor3 = Color3.fromRGB(150, 150, 150) -- Dimmer than buttons
			Label.Font = Enum.Font.SourceSansItalic
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left -- Usually looks better aligned left
			Label.Parent = Page

			-- 3. Add some left padding to the text so it's not glued to the edge
			local UIPadding = Instance.new("UIPadding", Label)
			UIPadding.PaddingLeft = UDim.new(0, 5)

			return Label
		end

		function tab:CreateDivider()
			-- 1. Create a container frame to handle padding
			local DividerContainer = Instance.new("Frame")
			DividerContainer.Name = "Divider"
			DividerContainer.Size = UDim2.new(1, -10, 0, 10) -- 10 pixels of vertical space
			DividerContainer.BackgroundTransparency = 1
			DividerContainer.Parent = Page

			-- 2. The actual line
			local Line = Instance.new("Frame")
			Line.Name = "Line"
			Line.Size = UDim2.new(0.9, 0, 0, 1) -- Slightly shorter than full width
			Line.Position = UDim2.new(0.05, 0, 0.5, 0) -- Centered
			Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60) -- Subtle grey
			Line.BorderSizePixel = 0
			Line.Parent = DividerContainer

			-- 3. Add a slight gradient for a "fading" look (Optional)
			local Gradient = Instance.new("UIGradient")
			Gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1)
			})
			Gradient.Parent = Line

			return DividerContainer
		end

		function tab:CreateToggle(tglName, default, callback)
			local toggleState = default or false
			callback = callback or function() end

			-- 1. Main Background Frame
			local ToggleBase = Instance.new("Frame")
			ToggleBase.Name = tglName .. "_Toggle"
			ToggleBase.Size = UDim2.new(1, -10, 0, 35)
			ToggleBase.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			ToggleBase.BorderSizePixel = 0
			ToggleBase.Parent = Page

			local UICorner = Instance.new("UICorner", ToggleBase)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 2. Toggle Label
			local Text = Instance.new("TextLabel")
			Text.Size = UDim2.new(1, -50, 1, 0)
			Text.Position = UDim2.new(0, 10, 0, 0)
			Text.BackgroundTransparency = 1
			Text.Text = tglName
			Text.TextColor3 = Color3.fromRGB(255, 255, 255)
			Text.Font = Enum.Font.SourceSans
			Text.TextSize = 14
			Text.TextXAlignment = Enum.TextXAlignment.Left
			Text.Parent = ToggleBase

			-- 3. The Switch (Outer)
			local Switch = Instance.new("Frame")
			Switch.Size = UDim2.new(0, 34, 0, 18)
			Switch.Position = UDim2.new(1, -44, 0.5, -9)
			Switch.BackgroundColor3 = toggleState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
			Switch.BorderSizePixel = 0
			Switch.Parent = ToggleBase

			local SwitchCorner = Instance.new("UICorner", Switch)
			SwitchCorner.CornerRadius = UDim.new(1, 0)

			-- 4. The Knob (Inner Circle)
			local Knob = Instance.new("Frame")
			Knob.Size = UDim2.new(0, 14, 0, 14)
			Knob.Position = toggleState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Knob.BorderSizePixel = 0
			Knob.Parent = Switch

			Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

			-- 5. Interaction Logic
			local ToggleBtn = Instance.new("TextButton") -- Invisible button for clicking
			ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
			ToggleBtn.BackgroundTransparency = 1
			ToggleBtn.Text = ""
			ToggleBtn.Parent = ToggleBase

			ToggleBtn.MouseButton1Click:Connect(function()
				toggleState = not toggleState

				-- Animation
				local targetPos = toggleState and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
				local targetColor = toggleState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)

				TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Position = targetPos}):Play()
				TweenService:Create(Switch, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()

				callback(toggleState)
			end)

			return ToggleBase
		end

		function tab:CreateSlider(sldName, min, max, default, callback)
			local sliderValue = default or min
			callback = callback or function() end

			-- 1. Main Background Frame
			local SliderBase = Instance.new("Frame")
			SliderBase.Name = sldName .. "_Slider"
			SliderBase.Size = UDim2.new(1, -10, 0, 45) -- Slightly taller for label + bar
			SliderBase.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			SliderBase.BorderSizePixel = 0
			SliderBase.Parent = Page

			local UICorner = Instance.new("UICorner", SliderBase)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 2. Slider Label & Value Display
			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -20, 0, 20)
			Title.Position = UDim2.new(0, 10, 0, 5)
			Title.BackgroundTransparency = 1
			Title.Text = sldName .. ": " .. sliderValue
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.Font = Enum.Font.SourceSans
			Title.TextSize = 14
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = SliderBase

			-- 3. The Bar (Background)
			local BarBack = Instance.new("Frame")
			BarBack.Name = "BarBack"
			BarBack.Size = UDim2.new(1, -20, 0, 6)
			BarBack.Position = UDim2.new(0, 10, 0, 30)
			BarBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			BarBack.BorderSizePixel = 0
			BarBack.Parent = SliderBase

			Instance.new("UICorner", BarBack)

			-- 4. The Fill (Visual progress)
			local Fill = Instance.new("Frame")
			Fill.Name = "Fill"
			Fill.Size = UDim2.fromScale((sliderValue - min) / (max - min), 1)
			Fill.BackgroundColor3 = Color3.fromRGB(0, 120, 255) -- Blue accent
			Fill.BorderSizePixel = 0
			Fill.Parent = BarBack

			Instance.new("UICorner", Fill)

			-- 5. Sliding Logic
			local dragging = false

			local function update(input)
				local pos = math.clamp((input.Position.X - BarBack.AbsolutePosition.X) / BarBack.AbsoluteSize.X, 0, 1)
				sliderValue = math.floor(min + (max - min) * pos)

				-- Update UI
				Fill.Size = UDim2.fromScale(pos, 1)
				Title.Text = sldName .. ": " .. sliderValue

				callback(sliderValue)
			end

			SliderBase.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					update(input) -- Update immediately on click
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					update(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)

			return SliderBase
		end

		function tab:CreateDropdown(dropName, options, callback)
			local isDropped = false
			options = options or {}
			callback = callback or function() end

			-- 1. Main Container
			local DropContainer = Instance.new("Frame")
			DropContainer.Name = dropName .. "_Dropdown"
			DropContainer.Size = UDim2.new(1, -10, 0, 35) -- Closed height
			DropContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			DropContainer.ClipsDescendants = true
			DropContainer.Parent = Page

			local UICorner = Instance.new("UICorner", DropContainer)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 2. The Header (The part you click)
			local Header = Instance.new("TextButton")
			Header.Size = UDim2.new(1, 0, 0, 35)
			Header.BackgroundTransparency = 1
			Header.Text = dropName .. " : Select..."
			Header.TextColor3 = Color3.fromRGB(200, 200, 200)
			Header.Font = Enum.Font.SourceSans
			Header.TextSize = 14
			Header.Parent = DropContainer

			-- 3. The Options Holder (where buttons go)
			local OptionHolder = Instance.new("Frame")
			OptionHolder.Name = "OptionHolder"
			OptionHolder.Position = UDim2.new(0, 0, 0, 35)
			OptionHolder.Size = UDim2.new(1, 0, 0, 0)
			OptionHolder.BackgroundTransparency = 1
			OptionHolder.Parent = DropContainer

			local Layout = Instance.new("UIListLayout", OptionHolder)
			Layout.Padding = UDim.new(0, 2)

			-- 4. Logic to Toggle Dropdown
			Header.MouseButton1Click:Connect(function()
				isDropped = not isDropped
				local targetSize = isDropped and UDim2.new(1, -10, 0, 35 + Layout.AbsoluteContentSize.Y + 5) or UDim2.new(1, -10, 0, 35)

				TweenService:Create(DropContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Size = targetSize
				}):Play()
			end)

			-- 5. Function to populate options
			for _, option in pairs(options) do
				local OptBtn = Instance.new("TextButton")
				OptBtn.Size = UDim2.new(1, 0, 0, 25)
				OptBtn.BackgroundTransparency = 1
				OptBtn.Text = tostring(option)
				OptBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
				OptBtn.Font = Enum.Font.SourceSans
				OptBtn.TextSize = 13
				OptBtn.Parent = OptionHolder

				OptBtn.MouseButton1Click:Connect(function()
					Header.Text = dropName .. " : " .. tostring(option)
					isDropped = false
					TweenService:Create(DropContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
						Size = UDim2.new(1, -10, 0, 35)
					}):Play()
					callback(option)
				end)

				-- Hover effect for options
				OptBtn.MouseEnter:Connect(function() OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255) end)
				OptBtn.MouseLeave:Connect(function() OptBtn.TextColor3 = Color3.fromRGB(150, 150, 150) end)
			end

			return DropContainer
		end

		function tab:CreateMultiDropdown(dropName, options, default, callback)
			local isDropped = false
			local selectedOptions = default or {} -- Table of selected items
			options = options or {}
			callback = callback or function() end

			-- 1. Main Container
			local MultiDropContainer = Instance.new("Frame")
			MultiDropContainer.Name = dropName .. "_MultiDropdown"
			MultiDropContainer.Size = UDim2.new(1, -10, 0, 35)
			MultiDropContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			MultiDropContainer.ClipsDescendants = true
			MultiDropContainer.Parent = Page

			local UICorner = Instance.new("UICorner", MultiDropContainer)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 2. The Header
			local Header = Instance.new("TextButton")
			Header.Size = UDim2.new(1, 0, 0, 35)
			Header.BackgroundTransparency = 1
			Header.Text = dropName .. " (Multi)"
			Header.TextColor3 = Color3.fromRGB(200, 200, 200)
			Header.Font = Enum.Font.SourceSans
			Header.TextSize = 14
			Header.Parent = MultiDropContainer

			-- 3. Options Holder
			local OptionHolder = Instance.new("Frame")
			OptionHolder.Name = "OptionHolder"
			OptionHolder.Position = UDim2.new(0, 0, 0, 35)
			OptionHolder.Size = UDim2.new(1, 0, 0, 0)
			OptionHolder.BackgroundTransparency = 1
			OptionHolder.Parent = MultiDropContainer

			local Layout = Instance.new("UIListLayout", OptionHolder)
			Layout.Padding = UDim.new(0, 2)

			-- 4. Toggle Logic
			Header.MouseButton1Click:Connect(function()
				isDropped = not isDropped
				local targetHeight = isDropped and (35 + Layout.AbsoluteContentSize.Y + 5) or 35
				TweenService:Create(MultiDropContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, -10, 0, targetHeight)
				}):Play()
			end)

			-- 5. Helper function to check if item is selected
			local function isSelected(name)
				for _, v in pairs(selectedOptions) do
					if v == name then return true end
				end
				return false
			end

			-- 6. Populate Options
			for _, option in pairs(options) do
				local OptBtn = Instance.new("TextButton")
				OptBtn.Size = UDim2.new(1, 0, 0, 25)
				OptBtn.BackgroundTransparency = 1
				OptBtn.Text = tostring(option)
				OptBtn.TextColor3 = isSelected(option) and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(150, 150, 150)
				OptBtn.Font = Enum.Font.SourceSans
				OptBtn.TextSize = 13
				OptBtn.Parent = OptionHolder

				OptBtn.MouseButton1Click:Connect(function()
					if isSelected(option) then
						-- Remove from table
						for i, v in pairs(selectedOptions) do
							if v == option then table.remove(selectedOptions, i) end
						end
						OptBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
					else
						-- Add to table
						table.insert(selectedOptions, option)
						OptBtn.TextColor3 = Color3.fromRGB(0, 200, 100)
					end

					callback(selectedOptions)
				end)
			end

			return MultiDropContainer
		end

		function tab:CreateTextField(txtName, placeholder, callback)
			callback = callback or function() end

			-- 1. Main Background Frame
			local TextBase = Instance.new("Frame")
			TextBase.Name = txtName .. "_TextField"
			TextBase.Size = UDim2.new(1, -10, 0, 45) -- Slightly taller for label + input
			TextBase.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			TextBase.BorderSizePixel = 0
			TextBase.Parent = Page

			local UICorner = Instance.new("UICorner", TextBase)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 2. Label
			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -20, 0, 20)
			Title.Position = UDim2.new(0, 10, 0, 3)
			Title.BackgroundTransparency = 1
			Title.Text = txtName
			Title.TextColor3 = Color3.fromRGB(200, 200, 200)
			Title.Font = Enum.Font.SourceSans
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = TextBase

			-- 3. The Input Box
			local Input = Instance.new("TextBox")
			Input.Size = UDim2.new(1, -20, 0, 18)
			Input.Position = UDim2.new(0, 10, 0, 22)
			Input.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			Input.BorderSizePixel = 0
			Input.TextColor3 = Color3.fromRGB(255, 255, 255)
			Input.Font = Enum.Font.SourceSans
			Input.TextSize = 14
			Input.Text = ""
			Input.PlaceholderText = placeholder or "Type here..."
			Input.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
			Input.ClearTextOnFocus = false
			Input.Parent = TextBase

			local InputCorner = Instance.new("UICorner", Input)
			InputCorner.CornerRadius = UDim.new(0, 4)

			-- 4. Visual Feedback & Logic
			Input.Focused:Connect(function()
				TweenService:Create(Input, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}):Play()
			end)

			Input.FocusLost:Connect(function(enterPressed)
				TweenService:Create(Input, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}):Play()

				-- We trigger the callback even if they didn't press enter (clicked away)
				callback(Input.Text)
			end)

			return TextBase
		end

		function tab:CreateColorPicker(colName, default, callback)
			local selectedColor = default or Color3.fromRGB(255, 0, 0)
			callback = callback or function() end

			-- 1. Main Container
			local ColorBase = Instance.new("Frame")
			ColorBase.Name = colName .. "_ColorPicker"
			ColorBase.Size = UDim2.new(1, -10, 0, 75) -- Taller to fit the color bar
			ColorBase.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			ColorBase.BorderSizePixel = 0
			ColorBase.Parent = Page

			local UICorner = Instance.new("UICorner", ColorBase)
			UICorner.CornerRadius = UDim.new(0, 6)

			-- 2. Label & Preview
			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -50, 0, 25)
			Title.Position = UDim2.new(0, 10, 0, 0)
			Title.BackgroundTransparency = 1
			Title.Text = colName
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.Font = Enum.Font.SourceSans
			Title.TextSize = 14
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = ColorBase

			local Preview = Instance.new("Frame")
			Preview.Size = UDim2.new(0, 20, 0, 20)
			Preview.Position = UDim2.new(1, -30, 0, 5)
			Preview.BackgroundColor3 = selectedColor
			Preview.Parent = ColorBase
			Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 4)

			-- 3. The Color Gradient Bar (Hue)
			local ColorBar = Instance.new("ImageButton")
			ColorBar.Size = UDim2.new(1, -20, 0, 30)
			ColorBar.Position = UDim2.new(0, 10, 0, 35)
			ColorBar.Image = "rbxassetid://2329543533" -- Standard rainbow gradient asset
			ColorBar.Parent = ColorBase

			local PickerCircle = Instance.new("Frame")
			PickerCircle.Size = UDim2.new(0, 4, 1, 4)
			PickerCircle.Position = UDim2.new(0.5, 0, 0, -2)
			PickerCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			PickerCircle.BorderSizePixel = 0
			PickerCircle.Parent = ColorBar

			-- 4. Color Logic
			local function updateColor(input)
				local relativeX = math.clamp((input.Position.X - ColorBar.AbsolutePosition.X) / ColorBar.AbsoluteSize.X, 0, 1)
				PickerCircle.Position = UDim2.new(relativeX, -2, 0, -2)

				-- Calculate Hue (0 to 1)
				selectedColor = Color3.fromHSV(relativeX, 1, 1)
				Preview.BackgroundColor3 = selectedColor
				callback(selectedColor)
			end

			local dragging = false

			ColorBar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = true
					updateColor(input)
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					updateColor(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)

			return ColorBase
		end

		function tab:CreateDescriptionList(listName, data)
			data = data or {} -- Expected format: {{"Health", "100"}, {"Level", "5"}}

			-- 1. Main Container
			local ListBase = Instance.new("Frame")
			ListBase.Name = listName .. "_DescList"
			ListBase.Size = UDim2.new(1, -10, 0, 0) -- Height will be set by Layout
			ListBase.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			ListBase.BorderSizePixel = 0
			ListBase.Parent = Page

			local UICorner = Instance.new("UICorner", ListBase)
			UICorner.CornerRadius = UDim.new(0, 6)

			local Layout = Instance.new("UIListLayout", ListBase)
			Layout.Padding = UDim.new(0, 2)
			Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

			local Padding = Instance.new("UIPadding", ListBase)
			Padding.PaddingTop = UDim.new(0, 5)
			Padding.PaddingBottom = UDim.new(0, 5)

			-- 2. Function to add rows
			local function addRow(key, value)
				local Row = Instance.new("Frame")
				Row.Size = UDim2.new(1, -20, 0, 20)
				Row.BackgroundTransparency = 1
				Row.Parent = ListBase

				local KeyLabel = Instance.new("TextLabel")
				KeyLabel.Size = UDim2.new(0.5, 0, 1, 0)
				KeyLabel.Text = tostring(key)
				KeyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
				KeyLabel.Font = Enum.Font.SourceSans
				KeyLabel.TextSize = 13
				KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
				KeyLabel.BackgroundTransparency = 1
				KeyLabel.Parent = Row

				local ValueLabel = Instance.new("TextLabel")
				ValueLabel.Size = UDim2.new(0.5, 0, 1, 0)
				ValueLabel.Position = UDim2.new(0.5, 0, 0, 0)
				ValueLabel.Text = tostring(value)
				ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				ValueLabel.Font = Enum.Font.SourceSansBold
				ValueLabel.TextSize = 13
				ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
				ValueLabel.BackgroundTransparency = 1
				ValueLabel.Parent = Row
			end

			-- 3. Populate and Update height
			for _, item in pairs(data) do
				addRow(item[1], item[2])
			end

			ListBase.Size = UDim2.new(1, -10, 0, Layout.AbsoluteContentSize.Y + 10)

			-- Return a table so the user can update values later
			local listFunctions = {}
			function listFunctions:Update(newData)
				for _, child in pairs(ListBase:GetChildren()) do
					if child:IsA("Frame") then child:Destroy() end
				end
				for _, item in pairs(newData) do
					addRow(item[1], item[2])
				end
				ListBase.Size = UDim2.new(1, -10, 0, Layout.AbsoluteContentSize.Y + 10)
			end

			return listFunctions
		end

		function lib:CreatePopUp(title, message, callback)
			-- 1. Dark Overlay (Dimming the background)
			local Overlay = Instance.new("Frame")
			Overlay.Name = "PopUpOverlay"
			Overlay.Size = UDim2.new(1, 0, 1, 0)
			Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Overlay.BackgroundTransparency = 1 -- Start invisible for animation
			Overlay.BorderSizePixel = 0
			Overlay.ZIndex = 500
			Overlay.Parent = TabHolder.Parent -- Attach to the main ScreenGui

			-- 2. Pop-Up Window
			local Window = Instance.new("Frame")
			Window.Name = "PopupWindow"
			Window.Size = UDim2.new(0, 300, 0, 150)
			Window.Position = UDim2.new(0.5, 0, 0.5, 0)
			Window.AnchorPoint = Vector2.new(0.5, 0.5)
			Window.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			Window.ClipsDescendants = true
			Window.Parent = Overlay

			local WindowCorner = Instance.new("UICorner", Window)
			WindowCorner.CornerRadius = UDim.new(0, 8)

			local Stroke = Instance.new("UIStroke", Window)
			Stroke.Color = Color3.fromRGB(60, 60, 60)
			Stroke.Thickness = 1

			-- 3. Title & Description
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, 0, 0, 40)
			TitleLabel.Text = title
			TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TitleLabel.Font = Enum.Font.SourceSansBold
			TitleLabel.TextSize = 18
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Parent = Window

			local DescLabel = Instance.new("TextLabel")
			DescLabel.Size = UDim2.new(1, -20, 0, 60)
			DescLabel.Position = UDim2.new(0, 10, 0, 40)
			DescLabel.Text = message
			DescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
			DescLabel.Font = Enum.Font.SourceSans
			DescLabel.TextSize = 14
			DescLabel.TextWrapped = true
			DescLabel.BackgroundTransparency = 1
			DescLabel.Parent = Window

			-- 4. Buttons (Confirm / Cancel)
			local function createPopBtn(name, color, pos, isConfirm)
				local Btn = Instance.new("TextButton")
				Btn.Size = UDim2.new(0.4, 0, 0, 30)
				Btn.Position = pos
				Btn.BackgroundColor3 = color
				Btn.Text = name
				Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
				Btn.Font = Enum.Font.SourceSansBold
				Btn.Parent = Window
				Instance.new("UICorner", Btn)

				Btn.MouseButton1Click:Connect(function()
					-- Fade out animation
					TweenService:Create(Overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
					local exit = TweenService:Create(Window, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 0)})
					exit:Play()
					exit.Completed:Connect(function() 
						Overlay:Destroy() 
						if isConfirm then callback() end
					end)
				end)
			end

			createPopBtn("Cancel", Color3.fromRGB(50, 50, 50), UDim2.new(0.08, 0, 1, -40), false)
			createPopBtn("Confirm", Color3.fromRGB(0, 120, 255), UDim2.new(0.52, 0, 1, -40), true)

			-- 5. Entrance Animation
			TweenService:Create(Overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
			Window.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(Window, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 300, 0, 150)}):Play()
		end
		
		function lib:AddTooltip(element, text)
			element.MouseEnter:Connect(function()
				Tooltip.Text = " " .. text .. " " -- Add padding
				Tooltip.Size = UDim2.new(0, Tooltip.TextBounds.X + 10, 0, 25)
				Tooltip.Visible = true
			end)

			element.MouseLeave:Connect(function()
				Tooltip.Visible = false
			end)
		end

		return tab
	end


	-- Create a mandatory Settings tab with a few theme and notification options
	local SettingsTab = windowFunctions:CreateTab("Settings")
	SettingsTab:CreateSection("Appearance")
	SettingsTab:CreateToggle("Dark Mode", true, function(state)
		if state then
			MainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
			MainFrame.BackgroundTransparency = 0.1
		else
			MainFrame.BackgroundColor3 = Color3.fromRGB(245,245,245)
			MainFrame.BackgroundTransparency = 0
		end
	end, "switch")

	SettingsTab:CreateColorPicker("Accent Color", accentColor, function(col)
		accentColor = col
		Indicator.BackgroundColor3 = accentColor
		SearchStroke.Color = accentColor
		if accentDot then accentDot.BackgroundColor3 = accentColor end
	end)

	SettingsTab:CreateSlider("UI Scale (%)", 50, 150, 100, function(value)
		local scale = value / 100
		MainFrame.Size = UDim2.new(0, math.floor(650 * scale), 0, math.floor(420 * scale))
		MainFrame.Position = UDim2.new(0.5, -math.floor(325 * scale), 0.5, -math.floor(210 * scale))
	end)

	SettingsTab:CreateSection("Notifications")
	SettingsTab:CreateToggle("Enable Notifications", true, function(state)
		notifContainer.Visible = state
	end, "switch")

	SettingsTab:CreateButton("Clear Notifications", function()
		for i = #activeNotifs, 1, -1 do
			if activeNotifs[i] and activeNotifs[i].Frame then
				pcall(function() activeNotifs[i].Frame:Destroy() end)
			end
			table.remove(activeNotifs, i)
		end
	end)

	SettingsTab:CreateButton("Reset Theme", function()
		accentColor = Color3.fromRGB(0,170,255)
		Indicator.BackgroundColor3 = accentColor
		SearchStroke.Color = accentColor
		if accentDot then accentDot.BackgroundColor3 = accentColor end
		MainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
	end)

	-- Unload / uninstall the UI and optional mods folder
	local unloadConfirm = false
	SettingsTab:CreateButton("Unload UI", function()
		if not unloadConfirm then
			unloadConfirm = true
			windowFunctions:Notify("LuminxUI", "Click 'Unload UI' again within 5s to confirm.", 4, "warn")
			task.delay(5, function() unloadConfirm = false end)
			return
		end
		-- proceed to cleanup
		pcall(function()
			if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
		end)
		-- remove installed mods folder if present
		pcall(function()
			local rs = game:GetService("ReplicatedStorage")
			local mf = rs:FindFirstChild("LuminxMods")
			if mf then mf:Destroy() end
		end)
		windowFunctions:Notify("LuminxUI", "Library unloaded. Re-run to reinitialize.", 4, "info")
	end)



	return windowFunctions
end

return lib
