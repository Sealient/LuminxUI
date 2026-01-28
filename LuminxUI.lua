local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local lib = {}

-- global accent color used by various UI elements (modifiable from Settings)
local accentColor = Color3.fromRGB(0,170,255)

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
	TabHolder.Parent = Sidebar
	Instance.new("UIListLayout", TabHolder).Padding = UDim.new(0, 2)

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
		Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0,3)

		local titleLbl = Instance.new("TextLabel", nf)
		titleLbl.Position = UDim2.new(0, 14, 0, 6)
		titleLbl.Size = UDim2.new(1, -40, 0, 16)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = title or "Notification"
		titleLbl.TextColor3 = Color3.fromRGB(235,235,235)
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

		local closeBtn = Instance.new("TextButton", nf)
		closeBtn.Size = UDim2.new(0,20,0,20)
		closeBtn.Position = UDim2.new(1, -30, 0, 8)
		closeBtn.BackgroundTransparency = 1
		closeBtn.Text = "✕"
		closeBtn.Font = Enum.Font.RobotoMono
		closeBtn.TextSize = 14
		closeBtn.TextColor3 = Color3.fromRGB(160,160,160)
		closeBtn.AutoButtonColor = true

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

	-- track any open dropdown so we can close others when needed
	local openDropdown = nil

	function windowFunctions:CreateTab(tabName)
		local Page = Instance.new("ScrollingFrame")
		Page.Name = tabName .. "_Page"
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.BackgroundTransparency = 1
		Page.Visible = firstPage
		Page.ScrollBarThickness = 0
		Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		Page.Parent = PageContainer
		Instance.new("UIListLayout", Page).Padding = UDim.new(0, 10)

		local TabBtn = Instance.new("TextButton")
		TabBtn.Size = UDim2.new(0.9, 0, 0, 36)
		TabBtn.BackgroundTransparency = 1
		TabBtn.Text = "      " .. string.upper(tabName)
		TabBtn.TextColor3 = firstPage and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(120, 120, 120)
		TabBtn.Font = Enum.Font.RobotoMono
		TabBtn.TextSize = 12
		TabBtn.TextXAlignment = Enum.TextXAlignment.Left
		TabBtn.Parent = TabHolder

		if firstPage then
			Indicator.Visible = true
			task.defer(function()
				Indicator.Position = UDim2.new(0, 0, 0, TabBtn.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y + 8)
			end)
		end

		TabBtn.MouseButton1Click:Connect(function()
			for _, p in pairs(PageContainer:GetChildren()) do p.Visible = false end
			for _, t in pairs(TabHolder:GetChildren()) do
				if t:IsA("TextButton") then t.TextColor3 = Color3.fromRGB(120, 120, 120) end
			end
			Page.Visible = true
			TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			local targetY = TabBtn.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y + 8
			TweenService:Create(Indicator, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
				Position = UDim2.new(0, 0, 0, targetY)
			}):Play()
		end)

		firstPage = false
		local pageFunctions = {}

		function pageFunctions:CreateSection(text)
			local Label = Instance.new("TextLabel", Page)
			Label.Name = text
			Label.Size = UDim2.new(1, 0, 0, 20)
			Label.BackgroundTransparency = 1
			Label.Text = string.upper(text)
			Label.TextColor3 = Color3.fromRGB(100, 100, 100)
			Label.Font = Enum.Font.RobotoMono
			Label.TextSize = 11
			Label.TextXAlignment = Enum.TextXAlignment.Left
		end

		-- Updatable single-line label (left name, right value). Returns API {Set, Get, Instance}
		function pageFunctions:CreateLabel(name, defaultValue)
			local f = Instance.new("Frame", Page)
			f.Name = name
			f.Size = UDim2.new(1, -10, 0, 26)
			f.BackgroundTransparency = 1

			local nameLbl = Instance.new("TextLabel", f)
			nameLbl.Size = UDim2.new(0.6, 0, 1, 0)
			nameLbl.Position = UDim2.new(0, 6, 0, 0)
			nameLbl.BackgroundTransparency = 1
			nameLbl.Text = name
			nameLbl.TextColor3 = Color3.fromRGB(200,200,200)
			nameLbl.Font = Enum.Font.SourceSans
			nameLbl.TextSize = 14
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left

			local valLbl = Instance.new("TextLabel", f)
			valLbl.Size = UDim2.new(0.4, -12, 1, 0)
			valLbl.Position = UDim2.new(1, - (0.4 * f.AbsoluteSize.X) - 6, 0, 0)
			valLbl.AnchorPoint = Vector2.new(1, 0)
			valLbl.BackgroundTransparency = 1
			valLbl.Text = tostring(defaultValue or "")
			valLbl.TextColor3 = Color3.fromRGB(180,180,180)
			valLbl.Font = Enum.Font.RobotoMono
			valLbl.TextSize = 13
			valLbl.TextXAlignment = Enum.TextXAlignment.Right

			-- layout safety: update on render to keep right label anchored
			local conn
			conn = RunService.Heartbeat:Connect(function()
				if not f or not f.Parent then if conn then conn:Disconnect(); conn = nil end; return end
				valLbl.Position = UDim2.new(1, -12, 0, 0)
			end)

			local api = {}
			function api:Set(text)
				valLbl.Text = tostring(text)
			end
			function api:Get()
				return valLbl.Text
			end
			api.Instance = f
			return api
		end

		-- Section divider: thin horizontal rule with optional centered label
		function pageFunctions:CreateDivider(text)
			local d = Instance.new("Frame", Page)
			d.Size = UDim2.new(1, -10, 0, 18)
			d.BackgroundTransparency = 1

			local line = Instance.new("Frame", d)
			line.Size = UDim2.new(1, -20, 0, 1)
			line.Position = UDim2.new(0, 10, 0, 9)
			line.BackgroundColor3 = Color3.fromRGB(60,60,60)
			line.BorderSizePixel = 0
			Instance.new("UICorner", line).CornerRadius = UDim.new(0,1)

			if text and text ~= "" then
				local t = Instance.new("TextLabel", d)
				t.Size = UDim2.new(0, 120, 0, 16)
				t.Position = UDim2.new(0.5, -60, 0, 1)
				t.BackgroundTransparency = 1
				t.Text = text
				t.TextColor3 = Color3.fromRGB(140,140,140)
				t.Font = Enum.Font.RobotoMono
				t.TextSize = 12
				t.TextXAlignment = Enum.TextXAlignment.Center
			end
			return d
		end

		function pageFunctions:CreateButton(text, callback)
			local bFrame = Instance.new("Frame", Page)
			bFrame.Name = text
			bFrame.Size = UDim2.new(1, -10, 0, 38)
			bFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			bFrame.BackgroundTransparency = 0.97
			Instance.new("UICorner", bFrame).CornerRadius = UDim.new(0, 4)
			local s = Instance.new("UIStroke", bFrame)
			s.Color, s.Transparency = Color3.fromRGB(255,255,255), 0.92

			local btn = Instance.new("TextButton", bFrame)
			btn.Size = UDim2.new(1,0,1,0)
			btn.BackgroundTransparency = 1
			btn.Text = "  " .. text
			btn.TextColor3 = Color3.fromRGB(180,180,180)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.Font = Enum.Font.SourceSans
			btn.TextSize = 15

			btn.MouseEnter:Connect(function() TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.7}):Play() end)
			btn.MouseLeave:Connect(function() TweenService:Create(s, TweenInfo.new(0.2), {Transparency = 0.92}):Play() end)
			btn.MouseButton1Down:Connect(callback)
		end

		function pageFunctions:CreateToggle(text, default, callback, toggleType)
			local state = default or false
			local tFrame = Instance.new("Frame", Page)
			tFrame.Name = text
			tFrame.Size = UDim2.new(1, -10, 0, 40)
			tFrame.BackgroundColor3, tFrame.BackgroundTransparency = Color3.fromRGB(255,255,255), 0.96
			Instance.new("UICorner", tFrame).CornerRadius = UDim.new(0,4)

			local l = Instance.new("TextLabel", tFrame)
			l.Size, l.Position = UDim2.new(1,-60,1,0), UDim2.new(0,12,0,0)
			l.BackgroundTransparency, l.Text, l.TextColor3 = 1, text, Color3.fromRGB(200,200,200)
			l.Font, l.TextSize, l.TextXAlignment = Enum.Font.SourceSans, 16, Enum.TextXAlignment.Left

			local tType = toggleType or "switch"

			if tType == "switch" then
				local sw = Instance.new("TextButton", tFrame)
				sw.Size, sw.Position = UDim2.new(0,34,0,18), UDim2.new(1,-45,0.5,-9)
				sw.BackgroundColor3 = state and Color3.fromRGB(0,170,255) or Color3.fromRGB(50,50,50)
				sw.Text = ""
				Instance.new("UICorner", sw).CornerRadius = UDim.new(1,0)

				local c = Instance.new("Frame", sw)
				c.Size = UDim2.new(0,12,0,12)
				c.Position = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)
				c.BackgroundColor3 = Color3.fromRGB(255,255,255)
				Instance.new("UICorner", c).CornerRadius = UDim.new(1,0)

				sw.MouseButton1Click:Connect(function()
					state = not state
					TweenService:Create(c, TweenInfo.new(0.2), {Position = state and UDim2.new(1,-15,0.5,-6) or UDim2.new(0,3,0.5,-6)}):Play()
					TweenService:Create(sw, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(0,170,255) or Color3.fromRGB(50,50,50)}):Play()
					callback(state)
				end)

			elseif tType == "checkbox" then
				local box = Instance.new("TextButton", tFrame)
				box.Size, box.Position = UDim2.new(0,20,0,20), UDim2.new(1,-45,0.5,-10)
				box.BackgroundColor3 = state and Color3.fromRGB(0,170,255) or Color3.fromRGB(40,40,40)
				box.Text = state and "✓" or ""
				box.TextColor3 = Color3.fromRGB(255,255,255)
				box.Font = Enum.Font.SourceSansBold
				box.TextSize = 18
				Instance.new("UICorner", box).CornerRadius = UDim.new(0,4)

				box.MouseButton1Click:Connect(function()
					state = not state
					TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = state and Color3.fromRGB(0,170,255) or Color3.fromRGB(40,40,40)}):Play()
					box.Text = state and "✓" or ""
					callback(state)
				end)

			elseif tType == "button" then
				local btn = Instance.new("TextButton", tFrame)
				btn.Size, btn.Position = UDim2.new(0,60,0,22), UDim2.new(1,-72,0.5,-11)
				btn.BackgroundColor3 = state and Color3.fromRGB(0,170,255) or Color3.fromRGB(30,30,30)
				btn.Text = state and "ON" or "OFF"
				btn.TextColor3 = Color3.fromRGB(255,255,255)
				btn.Font, btn.TextSize = Enum.Font.RobotoMono, 12
				Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)

				btn.MouseButton1Click:Connect(function()
					state = not state
					TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = state and Color3.fromRGB(0,170,255) or Color3.fromRGB(30,30,30)}):Play()
					btn.Text = state and "ON" or "OFF"
					callback(state)
				end)
			end
		end

		function pageFunctions:CreateSlider(text, min, max, default, callback)
			local draggingSlider = false
			local val = default or min
			local sFrame = Instance.new("Frame", Page)
			sFrame.Name, sFrame.Size, sFrame.BackgroundTransparency = text, UDim2.new(1,-10,0,55), 1

			local l = Instance.new("TextLabel", sFrame)
			l.Size, l.Text, l.TextColor3, l.BackgroundTransparency = UDim2.new(1,0,0,20), text..": "..val, Color3.fromRGB(200,200,200), 1
			l.Font, l.TextSize, l.TextXAlignment = Enum.Font.SourceSans, 14, Enum.TextXAlignment.Left

			local bg = Instance.new("Frame", sFrame)
			bg.Size, bg.Position, bg.BackgroundColor3 = UDim2.new(1,-10,0,4), UDim2.new(0,5,0,35), Color3.fromRGB(40,40,40)
			Instance.new("UICorner", bg).CornerRadius = UDim.new(1,0)

			local fill = Instance.new("Frame", bg)
			fill.Size, fill.BackgroundColor3 = UDim2.new((val-min)/(max-min),0,1,0), Color3.fromRGB(0,170,255)
			Instance.new("UICorner", fill).CornerRadius = UDim.new(1,0)

			local handle = Instance.new("Frame", bg)
			handle.Size, handle.AnchorPoint = UDim2.new(0,12,0,12), Vector2.new(0.5,0.5)
			handle.Position, handle.BackgroundColor3 = UDim2.new((val-min)/(max-min),0,0.5,0), Color3.fromRGB(255,255,255)
			Instance.new("UICorner", handle).CornerRadius = UDim.new(1,0)

			local function updateSlider(input)
				local pos = math.clamp((input.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
				val = math.floor(min + ((max - min) * pos))
				handle.Position = UDim2.new(pos, 0, 0.5, 0)
				fill.Size = UDim2.new(pos, 0, 1, 0)
				l.Text = text .. ": " .. val
				callback(val)
			end

			handle.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then 
					draggingSlider = true 
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingSlider = false end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then updateSlider(input) end
			end)
		end

		function pageFunctions:CreateDropdown(text, options, defaultIndex, callback)
			local idx = defaultIndex or 1
			local selected = options and options[idx] or ""
			local dFrame = Instance.new("Frame", Page)
			dFrame.Name = text
			dFrame.Size = UDim2.new(1, -10, 0, 40)
			dFrame.BackgroundColor3, dFrame.BackgroundTransparency = Color3.fromRGB(255,255,255), 0.96
			Instance.new("UICorner", dFrame).CornerRadius = UDim.new(0,4)

			local l = Instance.new("TextLabel", dFrame)
			l.Size, l.Position = UDim2.new(1,-160,1,0), UDim2.new(0,12,0,0)
			l.BackgroundTransparency, l.Text, l.TextColor3 = 1, text, Color3.fromRGB(200,200,200)
			l.Font, l.TextSize, l.TextXAlignment = Enum.Font.SourceSans, 16, Enum.TextXAlignment.Left

			local main = Instance.new("TextButton", dFrame)
			main.Size, main.Position = UDim2.new(0,160,0,22), UDim2.new(1,-170,0.5,-11)
			main.BackgroundColor3 = Color3.fromRGB(30,30,30)
			main.TextColor3 = Color3.fromRGB(200,200,200)
			main.Font, main.TextSize = Enum.Font.RobotoMono, 12
			main.Text = selected or "Select"
			Instance.new("UICorner", main).CornerRadius = UDim.new(0,4)

			local arrow = Instance.new("TextLabel", main)
			arrow.Size = UDim2.new(0,18,1,0)
			arrow.Position = UDim2.new(1,-20,0,0)
			arrow.BackgroundTransparency = 1
			arrow.Text = "▾"
			arrow.TextColor3 = Color3.fromRGB(150,150,150)
			arrow.Font = Enum.Font.RobotoMono
			arrow.TextSize = 14

			-- create list in ScreenGui so we can position freely and handle viewport edge cases
			local list = Instance.new("ScrollingFrame")
			list.Name = text .. "_DropdownList"
			list.Parent = ScreenGui
			list.Size = UDim2.new(0,160,0,0)
			list.Position = UDim2.fromOffset(0,0)
			list.BackgroundColor3 = Color3.fromRGB(20,20,20)
			list.BorderSizePixel = 0
			list.Visible = false
			list.ScrollBarThickness = 6
			list.ClipsDescendants = true
			Instance.new("UICorner", list).CornerRadius = UDim.new(0,6)
			local layout = Instance.new("UIListLayout", list)
			layout.Padding = UDim.new(0,2)

			local items = {}
			for i, opt in ipairs(options or {}) do
				local item = Instance.new("TextButton", list)
				item.Size = UDim2.new(1, -8, 0, 28)
				item.Position = UDim2.new(0,4,0, (i-1) * 30)
				item.AnchorPoint = Vector2.new(0,0)
				item.BackgroundColor3 = Color3.fromRGB(20,20,20)
				item.BorderSizePixel = 0
				item.Text = opt
				item.TextColor3 = Color3.fromRGB(200,200,200)
				item.Font = Enum.Font.SourceSans
				item.TextSize = 14
				Instance.new("UICorner", item).CornerRadius = UDim.new(0,4)
				items[#items+1] = item
			end

			-- compute responsive width based on longest text
			local function computeWidth()
				local pad = 40
				local maxW = 100
				for _, it in ipairs(items) do
					local size = TextService:GetTextSize(it.Text, it.TextSize, it.Font, Vector2.new(2000, 100)).X
					if size > maxW then maxW = size end
				end
				local labelW = TextService:GetTextSize(l.Text, l.TextSize, l.Font, Vector2.new(2000,100)).X
				if labelW + 20 > maxW then maxW = labelW + 20 end
				local w = math.clamp(maxW + pad, 120, 360)
				return math.floor(w)
			end

			local highlightIdx = idx
			local renderConn, outsideConn, keyConn

			local function updateHighlight()
				for i, it in ipairs(items) do
					if i == highlightIdx then
						it.BackgroundColor3 = Color3.fromRGB(0,170,255)
						it.TextColor3 = Color3.fromRGB(255,255,255)
					else
						it.BackgroundColor3 = Color3.fromRGB(20,20,20)
						it.TextColor3 = Color3.fromRGB(200,200,200)
					end
				end
				if list and list.Visible then
					list.CanvasPosition = Vector2.new(0, math.max(0, (highlightIdx-1) * 30 - 30))
				end
			end

			for i, item in ipairs(items) do
				item.MouseEnter:Connect(function()
					if highlightIdx ~= i then
						item.BackgroundColor3 = Color3.fromRGB(30,30,30)
					end
				end)
				item.MouseLeave:Connect(function()
					if highlightIdx ~= i then
						item.BackgroundColor3 = Color3.fromRGB(20,20,20)
					end
				end)
				item.MouseButton1Click:Connect(function()
					highlightIdx = i
					updateHighlight()
					selected = item.Text
					idx = i
					main.Text = selected
					-- animate close
					TweenService:Create(list, TweenInfo.new(0.12), {Size = UDim2.new(0, list.AbsoluteSize.X, 0, 0)}):Play()
					task.delay(0.12, function() list.Visible = false; if renderConn then renderConn:Disconnect(); renderConn = nil end end)
					if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
					if keyConn then keyConn:Disconnect(); keyConn = nil end
					if openDropdown == list then openDropdown = nil end
					callback(selected, idx)
				end)
			end

			local function closeList()
				if outsideConn then outsideConn:Disconnect(); outsideConn = nil end
				if keyConn then keyConn:Disconnect(); keyConn = nil end
				if renderConn then renderConn:Disconnect(); renderConn = nil end
				TweenService:Create(list, TweenInfo.new(0.12), {Size = UDim2.new(0, list.AbsoluteSize.X, 0, 0)}):Play()
				task.delay(0.12, function() list.Visible = false end)
				if openDropdown == list then openDropdown = nil end
			end

			local function isInside(frame, pos)
				local ap = frame.AbsolutePosition
				local asz = frame.AbsoluteSize
				return pos.X >= ap.X and pos.X <= ap.X + asz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y
			end

			main.MouseButton1Click:Connect(function()
				if list.Visible then closeList(); return end
				if openDropdown and openDropdown ~= list then
					openDropdown.Visible = false
					openDropdown = nil
				end

				-- set sizes
				local w = computeWidth()
				local h = math.clamp(#items * 30, 0, 200)
				list.Size = UDim2.new(0, w, 0, 0)

				-- position list under main, flip above if necessary
				local absX = main.AbsolutePosition.X
				local absY = main.AbsolutePosition.Y + main.AbsoluteSize.Y
				local vpY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080
				if absY + h > vpY - 10 then
					-- open above
					list.Position = UDim2.fromOffset(absX, main.AbsolutePosition.Y - h - 6)
				else
					list.Position = UDim2.fromOffset(absX, absY + 4)
				end

				list.Visible = true
				TweenService:Create(list, TweenInfo.new(0.14), {Size = UDim2.new(0, w, 0, h)}):Play()
				openDropdown = list

				-- ensure highlight reflects current selection
				highlightIdx = idx
				updateHighlight()

				-- track movement so list follows main while dragging
				renderConn = RunService.RenderStepped:Connect(function()
					if list.Visible then
						local ax = main.AbsolutePosition.X
						local ay = main.AbsolutePosition.Y + main.AbsoluteSize.Y
						if ay + h > (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 1080) - 10 then
							list.Position = UDim2.fromOffset(ax, main.AbsolutePosition.Y - h - 6)
						else
							list.Position = UDim2.fromOffset(ax, ay + 4)
						end
					end
				end)

				-- close when clicking outside
				outsideConn = UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local pos = input.Position
						if not (isInside(list, pos) or isInside(main, pos)) then
							closeList()
						end
					end
				end)

				-- keyboard navigation
				keyConn = UserInputService.InputBegan:Connect(function(input, gp)
					if gp then return end
					if not list.Visible then return end
					if input.KeyCode == Enum.KeyCode.Down then
						highlightIdx = math.min(#items, highlightIdx + 1)
						updateHighlight()
					elseif input.KeyCode == Enum.KeyCode.Up then
						highlightIdx = math.max(1, highlightIdx - 1)
						updateHighlight()
					elseif input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
						if items[highlightIdx] then
							items[highlightIdx]:CaptureFocus()
							items[highlightIdx].MouseButton1Click:Fire()
						end
					elseif input.KeyCode == Enum.KeyCode.Escape then
						closeList()
					end
				end)
			end)

			-- initial selected look
			for i, it in ipairs(items) do
				if i == idx then
					it.BackgroundColor3 = Color3.fromRGB(0,170,255)
					it.TextColor3 = Color3.fromRGB(255,255,255)
				end
			end

		end

		function pageFunctions:CreateColorPicker(text, defaultColor, callback)
			local color = defaultColor or Color3.fromRGB(255,255,255)
			local cpFrame = Instance.new("Frame", Page)
			cpFrame.Name = text
			cpFrame.Size = UDim2.new(1, -10, 0, 44)
			cpFrame.BackgroundColor3 = Color3.fromRGB(255,255,255)
			cpFrame.BackgroundTransparency = 0.96
			Instance.new("UICorner", cpFrame).CornerRadius = UDim.new(0,4)

			local label = Instance.new("TextLabel", cpFrame)
			label.Size, label.Position = UDim2.new(1,-160,1,0), UDim2.new(0,12,0,0)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Color3.fromRGB(200,200,200)
			label.Font = Enum.Font.SourceSans
			label.TextSize = 16
			label.TextXAlignment = Enum.TextXAlignment.Left

			local preview = Instance.new("TextButton", cpFrame)
			preview.Size = UDim2.new(0,88,0,28)
			preview.Position = UDim2.new(1,-100,0.5,-14)
			preview.BackgroundColor3 = color
			preview.Text = ""
			Instance.new("UICorner", preview).CornerRadius = UDim.new(0,4)

			local popup = nil
			local conns = {}

			local function disconnectAll()
				for _, c in ipairs(conns) do
					if c and c.Disconnect then pcall(function() c:Disconnect() end) end
				end
				conns = {}
			end

			local function hsvToColor(h, s, v)
				return Color3.fromHSV(h, s, v)
			end

			local function colorToHSV(c)
				local h,s,v = Color3.toHSV(c)
				return h,s,v
			end

			preview.MouseButton1Click:Connect(function()
				if popup and popup.Visible then return end
				disconnectAll()
				popup = Instance.new("Frame", ScreenGui)
				popup.Size = UDim2.new(0,360,0,220)
				popup.Position = UDim2.fromOffset(preview.AbsolutePosition.X, preview.AbsolutePosition.Y + preview.AbsoluteSize.Y + 6)
				popup.BackgroundColor3 = Color3.fromRGB(24,24,24)
				popup.BorderSizePixel = 0
				Instance.new("UICorner", popup).CornerRadius = UDim.new(0,6)
				local popStroke = Instance.new("UIStroke", popup)
				popStroke.Color = Color3.fromRGB(40,40,40)
				popStroke.Transparency = 0.6

				local function isInside(frame, pos)
					local ap = frame.AbsolutePosition
					local asz = frame.AbsoluteSize
					return pos.X >= ap.X and pos.X <= ap.X + asz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y
				end

				-- SV square
				local sv = Instance.new("Frame", popup)
				sv.Size = UDim2.new(0,180,0,180)
				sv.Position = UDim2.new(0,12,0,12)
				sv.BackgroundColor3 = hsvToColor(colorToHSV(color))
				Instance.new("UICorner", sv).CornerRadius = UDim.new(0,4)

				-- white overlay (left -> right)
				local white = Instance.new("Frame", sv)
				white.Size = UDim2.new(1,0,1,0)
				white.BackgroundColor3 = Color3.fromRGB(255,255,255)
				local wg = Instance.new("UIGradient", white)
				wg.Rotation = 0
				wg.Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
				wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})

				-- black overlay (top -> bottom)
				local black = Instance.new("Frame", sv)
				black.Size = UDim2.new(1,0,1,0)
				black.BackgroundColor3 = Color3.fromRGB(0,0,0)
				local bg = Instance.new("UIGradient", black)
				bg.Rotation = 90
				bg.Color = ColorSequence.new(Color3.fromRGB(0,0,0), Color3.fromRGB(0,0,0))
				bg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})

				local svHandle = Instance.new("Frame", sv)
				svHandle.Size = UDim2.new(0,14,0,14)
				svHandle.AnchorPoint = Vector2.new(0.5,0.5)
				svHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)
				Instance.new("UICorner", svHandle).CornerRadius = UDim.new(1,0)

				-- hue slider
				local hue = Instance.new("Frame", popup)
				hue.Size = UDim2.new(0,22,0,180)
				hue.Position = UDim2.new(0,204,0,12)
				hue.BorderSizePixel = 0
				local hg = Instance.new("UIGradient", hue)
				hg.Rotation = 90
				hg.Color = ColorSequence.new(
					Color3.fromHSV(0,1,1), Color3.fromHSV(0.166,1,1), Color3.fromHSV(0.333,1,1),
					Color3.fromHSV(0.5,1,1), Color3.fromHSV(0.666,1,1), Color3.fromHSV(0.833,1,1), Color3.fromHSV(1,1,1)
				)
				local hueHandle = Instance.new("Frame", hue)
				hueHandle.Size = UDim2.new(1, -4, 0, 6)
				hueHandle.Position = UDim2.new(0,2,0,0)
				hueHandle.AnchorPoint = Vector2.new(0,0)
				hueHandle.BackgroundColor3 = Color3.fromRGB(255,255,255)
				Instance.new("UICorner", hueHandle).CornerRadius = UDim.new(0,3)

				-- preview box & hex input
				local previewBox = Instance.new("Frame", popup)
				previewBox.Size = UDim2.new(0,120,0,40)
				previewBox.Position = UDim2.new(0,236,0,14)
				previewBox.BackgroundColor3 = color
				Instance.new("UICorner", previewBox).CornerRadius = UDim.new(0,6)

				local hexBox = Instance.new("TextBox", popup)
				hexBox.Size = UDim2.new(0,120,0,26)
				hexBox.Position = UDim2.new(0,236,0,62)
				hexBox.BackgroundColor3 = Color3.fromRGB(36,36,36)
				hexBox.TextColor3 = Color3.fromRGB(200,200,200)
				hexBox.Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
				hexBox.Font = Enum.Font.RobotoMono
				hexBox.TextSize = 14
				Instance.new("UICorner", hexBox).CornerRadius = UDim.new(0,4)

				-- presets
				local presets = {Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0), Color3.fromRGB(0,170,255), Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(255,255,0)}
				for i, pc in ipairs(presets) do
					local sw = Instance.new("TextButton", popup)
					sw.Size = UDim2.new(0,28,0,28)
					sw.Position = UDim2.new(0,236 + ((i-1)%2)*36, 0, 96 + math.floor((i-1)/2)*36)
					sw.BackgroundColor3 = pc
					sw.Text = ""
					Instance.new("UICorner", sw).CornerRadius = UDim.new(0,4)
					sw.MouseButton1Click:Connect(function()
						color = pc
						preview.BackgroundColor3 = color
						previewBox.BackgroundColor3 = color
						hexBox.Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
						pcall(callback, color)
					end)
				end

				-- internal state
				local h,s,v = colorToHSV(color)
				local function applyAll()
					local col = hsvToColor(h,s,v)
					color = col
					preview.BackgroundColor3 = color
					previewBox.BackgroundColor3 = color
					hexBox.Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
					pcall(callback, color)
				end

				-- position handles based on initial color
				hueHandle.Position = UDim2.new(0,2, h, 0)
				svHandle.Position = UDim2.new(s, 0, 1-v, 0)

				-- interactions
				local draggingSV, draggingHue = false, false

				local function onSVInput(pos)
					local relX = math.clamp((pos.X - sv.AbsolutePosition.X)/sv.AbsoluteSize.X, 0, 1)
					local relY = math.clamp((pos.Y - sv.AbsolutePosition.Y)/sv.AbsoluteSize.Y, 0, 1)
					s = relX
					v = 1 - relY
					sv.BackgroundColor3 = hsvToColor(h,1,1)
					svHandle.Position = UDim2.new(s,0,1-v,0)
					applyAll()
				end

				local function onHueInput(pos)
					local relY = math.clamp((pos.Y - hue.AbsolutePosition.Y)/hue.AbsoluteSize.Y, 0, 1)
					h = relY
					hueHandle.Position = UDim2.new(0,2,relY,0)
					sv.BackgroundColor3 = hsvToColor(h,1,1)
					applyAll()
				end

				sv.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						draggingSV = true
						onSVInput(inp.Position)
					end
				end)
				sv.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = false end
				end)
				conns[#conns+1] = UserInputService.InputChanged:Connect(function(inp)
					if draggingSV and inp.UserInputType == Enum.UserInputType.MouseMovement then onSVInput(inp.Position) end
					if draggingHue and inp.UserInputType == Enum.UserInputType.MouseMovement then onHueInput(inp.Position) end
				end)

				hue.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true; onHueInput(inp.Position) end
				end)
				hue.InputEnded:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false end
				end)

				-- hex input
				hexBox.FocusLost:Connect(function(enterPressed)
					local txt = hexBox.Text:gsub("#","")
					if #txt == 6 then
						local r = tonumber(txt:sub(1,2),16)
						local g = tonumber(txt:sub(3,4),16)
						local b = tonumber(txt:sub(5,6),16)
						if r and g and b then
							color = Color3.fromRGB(r,g,b)
							h,s,v = colorToHSV(color)
							sv.BackgroundColor3 = hsvToColor(h,1,1)
							hueHandle.Position = UDim2.new(0,2,h,0)
							svHandle.Position = UDim2.new(s,0,1-v,0)
							preview.BackgroundColor3 = color
							previewBox.BackgroundColor3 = color
							pcall(callback, color)
						end
					end
				end)

				-- close button
				local closeBtn = Instance.new("TextButton", popup)
				closeBtn.Size = UDim2.new(0,72,0,28)
				closeBtn.Position = UDim2.new(1,-86,1,-40)
				closeBtn.Text = "Close"
				closeBtn.Font = Enum.Font.RobotoMono
				closeBtn.TextSize = 14
				closeBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
				closeBtn.TextColor3 = Color3.fromRGB(200,200,200)
				Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,4)
				closeBtn.MouseButton1Click:Connect(function()
					disconnectAll()
					if popup then popup:Destroy(); popup = nil end
				end)

				-- outside click
				conns[#conns+1] = UserInputService.InputBegan:Connect(function(inp)
					if inp.UserInputType == Enum.UserInputType.MouseButton1 then
						local pos = inp.Position
						if not (isInside(popup, pos) or isInside(preview, pos)) then
							disconnectAll()
							if popup then popup:Destroy(); popup = nil end
						end
					end
				end)

			end)

		end

		function pageFunctions:CreateKeybind(text, default, callback)
			local key = default or Enum.KeyCode.F
			local listening = false
			local kFrame = Instance.new("Frame", Page)
			kFrame.Name, kFrame.Size = text, UDim2.new(1,-10,0,40)
			kFrame.BackgroundColor3, kFrame.BackgroundTransparency = Color3.fromRGB(255,255,255), 0.96
			Instance.new("UICorner", kFrame).CornerRadius = UDim.new(0,4)

			local l = Instance.new("TextLabel", kFrame)
			l.Size, l.Position, l.BackgroundTransparency = UDim2.new(1,-60,1,0), UDim2.new(0,12,0,0), 1
			l.Text, l.TextColor3, l.Font = text, Color3.fromRGB(200,200,200), Enum.Font.SourceSans
			l.TextSize, l.TextXAlignment = 16, Enum.TextXAlignment.Left

			local kb = Instance.new("TextButton", kFrame)
			kb.Size, kb.Position = UDim2.new(0,60,0,22), UDim2.new(1,-72,0.5,-11)
			kb.BackgroundColor3, kb.Text, kb.TextColor3 = Color3.fromRGB(30,30,30), key.Name, Color3.fromRGB(0,170,255)
			kb.Font, kb.TextSize = Enum.Font.RobotoMono, 12
			Instance.new("UICorner", kb).CornerRadius = UDim.new(0,4)

			kb.MouseButton1Click:Connect(function() listening = true; kb.Text = "..." end)
			UserInputService.InputBegan:Connect(function(input)
				if listening and input.UserInputType == Enum.UserInputType.Keyboard then
					key = input.KeyCode
					listening = false
					kb.Text = key.Name
				elseif not listening and input.KeyCode == key then
					callback()
				end
			end)
		end

		return pageFunctions
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
		MainFrame.BackgroundColor3 = Color3.fromRGB(10,10,10)
	end)

	SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = SearchInput.Text:lower()
		for _, page in pairs(PageContainer:GetChildren()) do
			if page:IsA("ScrollingFrame") then
				for _, element in pairs(page:GetChildren()) do
					if element:IsA("Frame") or element:IsA("TextButton") or element:IsA("TextLabel") then
						element.Visible = element.Name:lower():find(query) ~= nil
					end
				end
			end
		end
	end)

	return windowFunctions
end

return lib
