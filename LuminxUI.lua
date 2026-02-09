local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CollectionService = game:GetService("CollectionService")

local RunningMods = {}
local lib = {}

-- global accent color used by various UI elements (modifiable from Settings)
local accentColor = Color3.fromRGB(0,170,255)
local LIB_VERSION = "1.0.0"

local function SetAccent(object)
	CollectionService:AddTag(object, "LuminxAccent")
end

local function CreateDefaultSettings(lib, Window)
	local SettingsTab = lib:CreateTab("Settings")

	-- Appearance
	SettingsTab:CreateLabel("Appearance Settings")

	SettingsTab:CreateToggle("Dark Mode", true, function(state)
		-- Reference the MainFrame from the Window object
		local MainFrame = Window.MainFrame
		if state then
			MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			MainFrame.BackgroundTransparency = 0.1
		else
			MainFrame.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
			MainFrame.BackgroundTransparency = 0
		end
	end)

	SettingsTab:CreateColorPicker("Accent Color", Color3.fromRGB(0, 170, 255), function(col)
		-- Update the global accent logic
		if Window.UpdateAccent then
			Window:UpdateAccent(col)
		end
	end)

	SettingsTab:CreateSlider("UI Scale (%)", 50, 150, 100, function(value)
		local scale = value / 100
		Window.MainFrame.Size = UDim2.new(0, math.floor(650 * scale), 0, math.floor(420 * scale))
	end)

	SettingsTab:CreateDivider()

	-- Notifications
	SettingsTab:CreateLabel("Notifications & Alerts")
	SettingsTab:CreateToggle("Enable Notifications", true, function(state)
		if lib.NotifContainer then lib.NotifContainer.Visible = state end
	end)

	SettingsTab:CreateButton("Clear Notifications", function()
		lib:ClearAllNotifications() -- We'll define this helper method
	end)

	SettingsTab:CreateDivider()

	-- System
	SettingsTab:CreateLabel("System")
	SettingsTab:CreateTextField("Custom UI Title", "Enter text...", function(text)
		if Window.TitleLabel then
			Window.TitleLabel.Text = string.upper(text)
		end
	end)

	SettingsTab:CreateButton("Unload UI", function()
		lib:CreatePopUp("Unload", "Are you sure you want to remove the UI?", function()
			if lib.MainGui then lib.MainGui:Destroy() end
		end)
	end)
end

function lib:CreateWindow(titleText)
	local Window = {}
	Window.AccentElements = {}
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "LuminxUI"
	ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	ScreenGui.ResetOnSpawn = false
	self.MainGui = ScreenGui

	function Window:UpdateAccent(newColor)
		-- 1. Store the new color globally so new elements spawn with it
		self.CurrentAccent = newColor
		local TS = game:GetService("TweenService")
		local tInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

		-- 2. Iterate through every tagged element in the UI
		for _, element in ipairs(game:GetService("CollectionService"):GetTagged("LuminxAccent")) do
			if not element or not element.Parent then continue end

			-- HANDLE STROKES (Borders)
			if element:IsA("UIStroke") then
				if element.Name == "DropdownStroke" or element.Name == "TextFieldStroke" then
					-- Only update if the stroke isn't the "Inactive" White color
					if element.Color ~= Color3.fromRGB(255, 255, 255) then
						TS:Create(element, tInfo, {Color = newColor}):Play()
					end
				else
					-- Standard themed strokes (Keybinds, PopUps)
					TS:Create(element, tInfo, {Color = newColor}):Play()
				end

				-- HANDLE GRADIENTS (Dividers/Section Headers)
			elseif element:IsA("UIGradient") then
				element.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, newColor),
					ColorSequenceKeypoint.new(0.5, newColor),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
				})

				-- HANDLE TEXT (Titles, Icons, Multi-Dropdown Counters)
			elseif element:IsA("TextLabel") or element:IsA("TextButton") then
				-- If it's a TextButton acting as a Fill (like the PopUp Dismiss button)
				if element.BackgroundTransparency < 0.5 then
					TS:Create(element, tInfo, {BackgroundColor3 = newColor}):Play()
				else
					-- Otherwise, it's a label (Title, TextField Label)
					if element.Name == "TextFieldLabel" then
						-- Only update if focused (shrunken size) and not the "Inactive" Gray
						if element.TextSize == 10 and element.TextColor3 ~= Color3.fromRGB(150, 150, 150) then
							TS:Create(element, tInfo, {TextColor3 = newColor}):Play()
						end
					else
						TS:Create(element, tInfo, {TextColor3 = newColor}):Play()
					end
				end

				-- HANDLE IMAGES (Arrows and Icons)
			elseif element:IsA("ImageLabel") then
				TS:Create(element, tInfo, {ImageColor3 = newColor}):Play()

				-- HANDLE FRAMES (Slider Fills, Toggles, Multi-Indicators)
			elseif element:IsA("Frame") then
				if element.Name == "MultiIndicator" then
					-- Only update color if it's currently selected (visible)
					if element.BackgroundTransparency < 1 then
						TS:Create(element, tInfo, {BackgroundColor3 = newColor}):Play()
					else
						element.BackgroundColor3 = newColor -- Update silently
					end
				else
					-- Standard fills (Slider, Toggle Knob)
					TS:Create(element, tInfo, {BackgroundColor3 = newColor}):Play()
				end
			end
		end
	end

	-- MAIN FRAME
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 650, 0, 420)
	MainFrame.Position = UDim2.new(0.5, -325, 0.5, -210)
	MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	MainFrame.BackgroundTransparency = 0.1
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	Window.MainFrame = MainFrame

	local MainCorner = Instance.new("UICorner", MainFrame)
	MainCorner.CornerRadius = UDim.new(0, 4)

	local MainStroke = Instance.new("UIStroke", MainFrame)
	MainStroke.Color = Color3.fromRGB(255, 255, 255)
	MainStroke.Transparency = 0.9
	MainStroke.Thickness = 1

	-- SIDEBAR
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 170, 1, 0)
	Sidebar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Sidebar.BackgroundTransparency = 0.4
	Sidebar.BorderSizePixel = 0
	Sidebar.ClipsDescendants = true -- Crucial: hides tabs that scroll out of view
	Sidebar.Parent = MainFrame
	Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 4)

	-- DRAGGING LOGIC (Sidebar)
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

	-- 1. CREATE PAGE CONTAINER FIRST (Crucial for the search to work)
	local PageContainer = Instance.new("Frame")
	PageContainer.Name = "PageContainer"
	PageContainer.Size = UDim2.new(1, -170, 1, -60)
	PageContainer.Position = UDim2.new(0, 170, 0, 60)
	PageContainer.BackgroundTransparency = 1
	PageContainer.Parent = MainFrame
	Window.PageContainer = PageContainer

	-- --- POLISHED SEARCH BAR ---
	local SearchContainer = Instance.new("Frame")
	SearchContainer.Name = "SearchContainer"
	SearchContainer.Size = UDim2.new(1, -170, 0, 60)
	SearchContainer.Position = UDim2.new(0, 170, 0, 0)
	SearchContainer.BackgroundTransparency = 1
	SearchContainer.Parent = MainFrame

	local SearchFrame = Instance.new("Frame")
	SearchFrame.Name = "SearchWrapper"
	SearchFrame.Size = UDim2.new(1, -40, 0, 36) -- Slightly taller
	SearchFrame.Position = UDim2.new(0, 20, 0, 12)
	SearchFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	SearchFrame.Parent = SearchContainer

	local SCorner = Instance.new("UICorner", SearchFrame)
	SCorner.CornerRadius = UDim.new(0, 8)

	local SStroke = Instance.new("UIStroke", SearchFrame)
	SStroke.Thickness = 1.2
	SStroke.Color = Color3.fromRGB(255, 255, 255)
	SStroke.Transparency = 0.9 -- Subtle border

	-- Magnifying Glass Icon (Using a UTF-8 character or TextLabel)
	local SearchIcon = Instance.new("TextLabel", SearchFrame)
	SearchIcon.Size = UDim2.new(0, 30, 1, 0)
	SearchIcon.Position = UDim2.new(0, 10, 0, 0)
	SearchIcon.BackgroundTransparency = 1
	SearchIcon.Text = "🔍" -- You can replace with an ImageLabel if you have an asset ID
	SearchIcon.TextSize = 14
	SearchIcon.TextColor3 = Color3.fromRGB(150, 150, 150)
	SearchIcon.Font = Enum.Font.Gotham

	local FeatureSearch = Instance.new("TextBox", SearchFrame)
	FeatureSearch.Name = "FeatureSearch"
	FeatureSearch.Size = UDim2.new(1, -50, 1, 0)
	FeatureSearch.Position = UDim2.new(0, 40, 0, 0)
	FeatureSearch.BackgroundTransparency = 1
	FeatureSearch.PlaceholderText = "Search for features..."
	FeatureSearch.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	FeatureSearch.TextColor3 = Color3.fromRGB(255, 255, 255)
	FeatureSearch.Font = Enum.Font.GothamMedium
	FeatureSearch.TextSize = 13
	FeatureSearch.Text = ""
	FeatureSearch.ClipsDescendants = true

	-- --- INTERACTION ANIMS ---
	FeatureSearch.Focused:Connect(function()
		TweenService:Create(SStroke, TweenInfo.new(0.3), {Transparency = 0.5, Color = Color3.fromRGB(0, 170, 255)}):Play()
		TweenService:Create(SearchFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(35, 35, 35)}):Play()
	end)

	FeatureSearch.FocusLost:Connect(function()
		TweenService:Create(SStroke, TweenInfo.new(0.3), {Transparency = 0.9, Color = Color3.fromRGB(255, 255, 255)}):Play()
		TweenService:Create(SearchFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
	end)

	-- --- ADVANCED FEEDBACK UI ---
	local NoResults = Instance.new("Frame")
	NoResults.Name = "NoResults"
	NoResults.Size = UDim2.new(1, 0, 1, 0)
	NoResults.BackgroundTransparency = 1
	NoResults.Visible = false

	local NoResultsLabel = Instance.new("TextLabel", NoResults)
	NoResultsLabel.Size = UDim2.new(1, 0, 0, 50)
	NoResultsLabel.Position = UDim2.new(0, 0, 0.4, 0)
	NoResultsLabel.BackgroundTransparency = 1
	NoResultsLabel.Text = "No results found for your search"
	NoResultsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	NoResultsLabel.Font = Enum.Font.GothamMedium
	NoResultsLabel.TextSize = 16

	-- --- ADVANCED UNIVERSAL SEARCH ENGINE ---
	FeatureSearch:GetPropertyChangedSignal("Text"):Connect(function()
		local RawInput = FeatureSearch.Text:lower()
		local CleanInput = RawInput:gsub("%s+", "")

		local ActivePage = nil
		for _, p in ipairs(PageContainer:GetChildren()) do
			if p:IsA("ScrollingFrame") and p.Visible == true then
				ActivePage = p
				break
			end
		end

		if not ActivePage then return end

		NoResults.Parent = ActivePage
		local resultsFound = 0

		-- These classes should NEVER be hidden by search
		local Blacklist = {
			["UIListLayout"] = true,
			["UIGridLayout"] = true,
			["UIPadding"] = true,
			["NoResults"] = true -- Your custom frame name
		}

		for _, item in ipairs(ActivePage:GetChildren()) do
			-- Skip layouts and technical objects
			if not Blacklist[item.ClassName] and item.Name ~= "NoResults" then
				if RawInput == "" then
					item.Visible = true
					resultsFound = resultsFound + 1
				else
					local isMatch = false

					-- Check the item itself if it's a Button or Label
					if (item:IsA("TextButton") or item:IsA("TextLabel")) and item.Visible then
						local txt = item.Text:lower()
						if txt:find(RawInput) or txt:gsub("%s+", ""):find(CleanInput) then
							isMatch = true
						end
					end

					-- Also scan descendants (for Frames that contain Labels/Buttons)
					if not isMatch then
						for _, desc in ipairs(item:GetDescendants()) do
							if (desc:IsA("TextLabel") or desc:IsA("TextButton")) and desc.Visible then
								local txt = desc.Text:lower()
								if txt:find(RawInput) or txt:gsub("%s+", ""):find(CleanInput) then
									isMatch = true
									break
								end
							end
						end
					end

					-- FORCE visibility based on match
					item.Visible = isMatch
					if isMatch then resultsFound = resultsFound + 1 end
				end
			end
		end

		-- Toggle "No Results" and Border Feedback
		if RawInput ~= "" and resultsFound == 0 then
			NoResults.Visible = true
			TweenService:Create(SStroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(200, 80, 80)}):Play()
		else
			NoResults.Visible = false
			local targetColor = FeatureSearch:IsFocused() and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(255, 255, 255)
			TweenService:Create(SStroke, TweenInfo.new(0.2), {Color = targetColor}):Play()
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

	local Layout = Instance.new("UIListLayout", TabHolder)
	Layout.Padding = UDim.new(0, 2)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder

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

	local TabHolder = Instance.new("ScrollingFrame")
	TabHolder.Name = "TabHolder"
	-- POSITION: Push it down (e.g., 40 pixels) so it doesn't hit the top
	TabHolder.Position = UDim2.new(0, 0, 0, 60) 
	-- SIZE: Subtract that offset from the height so it doesn't go off the bottom
	TabHolder.Size = UDim2.new(1, 0, 1, -135) 
	TabHolder.BackgroundTransparency = 1
	TabHolder.BorderSizePixel = 0
	TabHolder.ScrollBarThickness = 2
	TabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TabHolder.Parent = Sidebar

	local SidebarLayout = Instance.new("UIListLayout", TabHolder)
	SidebarLayout.Padding = UDim.new(0, 2)
	SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

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

	-- Inside lib:CreateWindow
	local SelectionIndicator = Instance.new("Frame")
	SelectionIndicator.Name = "SelectionIndicator"
	SelectionIndicator.ZIndex = 10 
	SelectionIndicator.Size = UDim2.new(0, 2, 0, 22)
	SelectionIndicator.BackgroundColor3 = accentColor
	SelectionIndicator.BorderSizePixel = 0
	-- IMPORTANT: This prevents UIListLayout from moving it
	if SelectionIndicator:IsA("GuiObject") then
		local layoutConstraint = Instance.new("UICorner") -- Just a dummy or use a specific property
		-- If your Roblox version supports it:
		-- SelectionIndicator.LayoutOrder = -1 
	end

	SelectionIndicator.Parent = Sidebar -- Parent it to the Sidebar, NOT the TabHolder (ScrollingFrame)

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

	local windowFunctions = {}

	-- Add these to your library's main properties
	lib.ActiveNotifs = {}
	lib.NotifContainer = nil

	local function CreateNotifContainer(ScreenGui)
		local container = Instance.new("Frame")
		container.Name = "Notifications"
		container.Size = UDim2.new(0, 320, 1, -40)
		container.Position = UDim2.new(1, -20, 0, 20)
		container.AnchorPoint = Vector2.new(1, 0)
		container.BackgroundTransparency = 1
		container.ZIndex = 100
		container.Parent = ScreenGui
		return container
	end

	function lib:Notify(title, body, duration, ntype)
		if not self.NotifContainer then 
			self.NotifContainer = CreateNotifContainer(self.MainGui)
		end

		duration = duration or 4
		ntype = ntype or "info"

		local accents = {
			info = Color3.fromRGB(0, 170, 255),
			success = Color3.fromRGB(0, 255, 150),
			warn = Color3.fromRGB(255, 180, 0),
			error = Color3.fromRGB(255, 80, 80)
		}
		local accent = accents[ntype] or accents.info

		-- Main Toast Frame
		local nf = Instance.new("Frame")
		nf.Name = "Toast"
		nf.Size = UDim2.new(1, 0, 0, 60)
		-- Start off-screen to the right
		nf.Position = UDim2.new(1, 350, 0, #self.ActiveNotifs * 70) 
		nf.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		nf.BackgroundTransparency = 0.1
		nf.Parent = self.NotifContainer

		local Corner = Instance.new("UICorner", nf)
		Corner.CornerRadius = UDim.new(0, 8)

		local Stroke = Instance.new("UIStroke", nf)
		Stroke.Color = Color3.fromRGB(255, 255, 255)
		Stroke.Transparency = 0.9

		-- Progress Bar Background
		local ProgressBG = Instance.new("Frame", nf)
		ProgressBG.Size = UDim2.new(1, 0, 0, 2)
		ProgressBG.Position = UDim2.new(0, 0, 1, -2)
		ProgressBG.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ProgressBG.BackgroundTransparency = 0.95
		ProgressBG.BorderSizePixel = 0

		local ProgressBar = Instance.new("Frame", ProgressBG)
		ProgressBar.Size = UDim2.new(1, 0, 1, 0)
		ProgressBar.BackgroundColor3 = accent
		ProgressBar.BorderSizePixel = 0

		-- Text Elements
		local Title = Instance.new("TextLabel", nf)
		Title.Text = title:upper()
		Title.Font = Enum.Font.GothamBold
		Title.TextSize = 12
		Title.TextColor3 = accent
		Title.Position = UDim2.new(0, 12, 0, 10)
		Title.Size = UDim2.new(1, -40, 0, 15)
		Title.BackgroundTransparency = 1
		Title.TextXAlignment = Enum.TextXAlignment.Left

		local Description = Instance.new("TextLabel", nf)
		Description.Text = body
		Description.Font = Enum.Font.Gotham
		Description.TextSize = 12
		Description.TextColor3 = Color3.fromRGB(200, 200, 200)
		Description.Position = UDim2.new(0, 12, 0, 28)
		Description.Size = UDim2.new(1, -40, 0, 25)
		Description.BackgroundTransparency = 1
		Description.TextXAlignment = Enum.TextXAlignment.Left
		Description.TextWrapped = true

		-- Logic & Animation
		local data = {Frame = nf}
		table.insert(self.ActiveNotifs, data)

		local function shift()
			for i, item in ipairs(self.ActiveNotifs) do
				game:GetService("TweenService"):Create(item.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
					Position = UDim2.new(0, 0, 0, (i-1) * 70)
				}):Play()
			end
		end

		local function dismiss()
			local idx = table.find(self.ActiveNotifs, data)
			if idx then table.remove(self.ActiveNotifs, idx) end

			game:GetService("TweenService"):Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Position = UDim2.new(1.2, 0, 0, nf.Position.Y.Offset),
				BackgroundTransparency = 1
			}):Play()

			task.delay(0.3, function() 
				nf:Destroy() 
				shift()
			end)
		end

		-- Entrance
		shift()

		-- Progress bar tween (matches duration)
		local progressTween = game:GetService("TweenService"):Create(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0)
		})
		progressTween:Play()

		-- Close on Finish
		task.delay(duration, function()
			dismiss()
		end)

		-- Close on Click
		nf.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				progressTween:Cancel()
				dismiss()
			end
		end)
	end

	local firstPage = true

	-- track any open dropdown so we can close others when needed
	local openDropdown = nil
	local TweenService = game:GetService("TweenService")

	-- We'll store this in windowFunctions so tabs can access it
	windowFunctions.Indicator = SelectionIndicator

	-- Add this so Window:CreateTab() works in your LocalScript
	function windowFunctions:CreateTab(name, parentTab)
		return lib:CreateTab(name, parentTab)
	end

	function lib:CreateTab(name, parentTab)
		local tab = {}
		tab.IsExpanded = false

		-- 1. Main Container with AutomaticSize for smooth expansion
		local TabContainer = Instance.new("Frame")
		TabContainer.Name = name .. "_Container"
		TabContainer.Size = UDim2.new(1, 0, 0, 32)
		TabContainer.BackgroundTransparency = 1
		TabContainer.ClipsDescendants = true
		TabContainer.Parent = parentTab and parentTab.SubContainer or TabHolder

		-- 2. The Tab Button
		local TabButton = Instance.new("TextButton")
		TabButton.Size = UDim2.new(1, 0, 0, 32)
		TabButton.BackgroundTransparency = 1
		TabButton.Text = (parentTab and "      " or "  ") .. name 
		TabButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		TabButton.Font = Enum.Font.SourceSansSemibold
		TabButton.TextSize = 14
		TabButton.TextXAlignment = Enum.TextXAlignment.Left
		TabButton.AutoButtonColor = false
		TabButton.Parent = TabContainer

		-- 3. The Expand Arrow (Icon)
		local Arrow = Instance.new("TextLabel")
		Arrow.Size = UDim2.new(0, 20, 0, 32)
		Arrow.Position = UDim2.new(1, -25, 0, 0)
		Arrow.BackgroundTransparency = 1
		Arrow.Text = "→" -- Modern arrow
		Arrow.TextColor3 = Color3.fromRGB(80, 80, 80)
		Arrow.TextSize = 12
		Arrow.Visible = false
		Arrow.Parent = TabButton

		-- 4. Sub-Tab Container
		local SubContainer = Instance.new("Frame")
		SubContainer.Name = "SubContainer"
		SubContainer.Position = UDim2.new(0, 0, 0, 32)
		SubContainer.Size = UDim2.new(1, 0, 0, 0)
		SubContainer.BackgroundTransparency = 1
		SubContainer.Parent = TabContainer

		local SubLayout = Instance.new("UIListLayout", SubContainer)
		SubLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tab.SubContainer = SubContainer

		-- Inside lib:CreateTab, find the Page creation:
		local Page = Instance.new("ScrollingFrame")
		Page.Name = name .. "_Page"
		Page.Size = UDim2.new(1, -20, 1, -20)
		Page.Position = UDim2.new(0, 10, 0, 10)
		Page.BackgroundTransparency = 1
		Page.Visible = false
		Page.BorderSizePixel = 0
		Page.ClipsDescendants = true -- THIS prevents elements from going off the UI background
		Page.Parent = PageContainer
		Page.AutomaticCanvasSize = Enum.AutomaticSize.Y 
		Page.CanvasSize = UDim2.new(0, 0, 0, 0)
		Page.ScrollBarThickness = 2

		-- You MUST add a layout for AutomaticCanvasSize to work
		local ContentLayout = Instance.new("UIListLayout", Page)
		ContentLayout.Padding = UDim.new(0, 5) -- Space between your elements
		ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

		-- Add padding so elements aren't touching the very top/bottom
		local ContentPadding = Instance.new("UIPadding", Page)
		ContentPadding.PaddingTop = UDim.new(0, 5)
		ContentPadding.PaddingBottom = UDim.new(0, 5)

		-- RECURSIVE HEIGHT UPDATE: Animates parent containers too
		tab.UpdateHeight = function()
			-- 1. Calculate the final target height
			local finalHeight = tab.IsExpanded and (32 + SubLayout.AbsoluteContentSize.Y) or 32

			-- 2. "Smear" Effect Logic: 
			-- We'll use a specific EasingStyle (Back or Quart) to give it that elastic stretch.
			-- If opening, we slightly "overshoot" the stretch to create the smear look.
			local info = TweenService:Create(TabContainer, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, finalHeight)
			})

			-- 3. The "Elastic Stretch" (The Smear)
			-- We temporarily disable ClipsDescendants or adjust transparency to sell the effect
			TabContainer.ClipsDescendants = true 

			info:Play()

			-- 4. Recursive "Bubble" with a smoother delay
			if parentTab and parentTab.UpdateHeight then
				-- We trigger the parent update almost immediately for a synchronized "sliding" effect
				task.spawn(function()
					local start = tick()
					while tick() - start < 0.5 do -- While the tween is running
						parentTab.UpdateHeight()
						RunService.RenderStepped:Wait()
					end
				end)
			end
		end

		-- TAB CLICK LOGIC
		TabButton.MouseButton1Click:Connect(function()
			-- 1. SWITCH PAGE
			for _, p in pairs(PageContainer:GetChildren()) do
				if p:IsA("ScrollingFrame") then p.Visible = false end
			end
			Page.Visible = true

			-- 2. MOVE THE INDICATOR (The Fix)
			if windowFunctions.Indicator then
				-- We calculate the Y position relative to the Sidebar frame
				-- This works even if the tab is deep inside a sub-menu
				local relativeY = TabButton.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y

				TweenService:Create(windowFunctions.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Position = UDim2.new(0, 2, 0, relativeY + (TabButton.AbsoluteSize.Y / 2) - 11) -- Center it
				}):Play()
			end

			-- 3. TEXT HIGHLIGHTING
			for _, otherBtn in pairs(Sidebar:GetDescendants()) do
				if otherBtn:IsA("TextButton") then
					TweenService:Create(otherBtn, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(150, 150, 150)}):Play()
				end
			end
			TweenService:Create(TabButton, TweenInfo.new(0.3), {TextColor3 = accentColor}):Play()

			-- 4. ACCORDION LOGIC
			local hasChildren = #SubContainer:GetChildren() > 1
			if hasChildren then
				tab.IsExpanded = not tab.IsExpanded
				if Arrow then
					TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = tab.IsExpanded and 90 or 0}):Play()
				end
				tab.UpdateHeight()
			end
		end)

		-- Hover Effect
		TabButton.MouseEnter:Connect(function()
			if Page.Visible == false then
				TweenService:Create(TabButton, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
			end
		end)

		-- Auto-detect children to show arrow
		SubContainer.ChildAdded:Connect(function() Arrow.Visible = true end)

		function tab:CreateButton(btnText, callback)
			local ButtonBase = Instance.new("TextButton")
			ButtonBase.Size = UDim2.new(1, -12, 0, 38)
			ButtonBase.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Slightly deeper
			ButtonBase.AutoButtonColor = false
			ButtonBase.Text = ""
			ButtonBase.Parent = Page

			local Corner = Instance.new("UICorner", ButtonBase)
			Corner.CornerRadius = UDim.new(0, 5)

			-- 1. The Main Glow Stroke
			local Stroke = Instance.new("UIStroke", ButtonBase)
			SetAccent(Stroke)
			Stroke.Thickness = 1.2
			Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.95 -- Ghostly at rest

			-- 2. The Gradient Stroke (Adds "character" to the glow)
			local StrokeGrad = Instance.new("UIGradient")
			StrokeGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 170, 255)), -- Subtle Blue tint
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
			})
			StrokeGrad.Parent = Stroke

			-- 3. The Inner Bloom (A faint light inside the button)
			local InnerBloom = Instance.new("Frame")
			InnerBloom.Size = UDim2.new(1, 0, 1, 0)
			InnerBloom.BackgroundTransparency = 1
			InnerBloom.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			InnerBloom.Parent = ButtonBase

			local BloomGrad = Instance.new("UIGradient")
			BloomGrad.Rotation = 90
			BloomGrad.Transparency = NumberSequence.new(0.9, 1) -- Very faint
			BloomGrad.Parent = InnerBloom
			Instance.new("UICorner", InnerBloom).CornerRadius = UDim.new(0, 5)

			-- 4. The Label
			local Text = Instance.new("TextLabel")
			Text.Size = UDim2.new(1, 0, 1, 0)
			Text.Text = btnText
			Text.Font = Enum.Font.GothamMedium
			Text.TextColor3 = Color3.fromRGB(140, 140, 140)
			Text.TextSize = 13
			Text.BackgroundTransparency = 1
			Text.ZIndex = 2
			Text.Parent = ButtonBase

			-- REFINED ANIMATIONS
			ButtonBase.MouseEnter:Connect(function()
				TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0.7, Thickness = 1.5}):Play()
				TweenService:Create(InnerBloom, TweenInfo.new(0.3), {BackgroundTransparency = 0.96}):Play()
				TweenService:Create(Text, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()

				-- Subtle "Pulse" of the gradient
				TweenService:Create(StrokeGrad, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(1, 0)}):Play()
			end)

			ButtonBase.MouseLeave:Connect(function()
				TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0.95, Thickness = 1.2}):Play()
				TweenService:Create(InnerBloom, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
				TweenService:Create(Text, TweenInfo.new(0.3), {TextColor3 = Color3.fromRGB(140, 140, 140)}):Play()
			end)

			ButtonBase.MouseButton1Down:Connect(function()
				TweenService:Create(ButtonBase, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
				TweenService:Create(Stroke, TweenInfo.new(0.1), {Color = Color3.fromRGB(0, 170, 255)}):Play()
			end)

			ButtonBase.MouseButton1Up:Connect(function()
				TweenService:Create(ButtonBase, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 20)}):Play()
				TweenService:Create(Stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(255, 255, 255)}):Play()
				callback()
			end)

			return ButtonBase
		end

		function tab:CreateLabel(labelText)
			-- 1. Ensure Layout exists
			local layout = Page:FindFirstChildOfClass("UIListLayout")
			if not layout then
				layout = Instance.new("UIListLayout", Page)
				layout.Padding = UDim.new(0, 8)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			end

			-- 2. The Container
			local LabelContainer = Instance.new("Frame")
			LabelContainer.Name = "Label_" .. labelText
			LabelContainer.Size = UDim2.new(1, -12, 0, 30)
			LabelContainer.BackgroundTransparency = 1
			LabelContainer.BorderSizePixel = 0
			LabelContainer.Parent = Page

			-- 3. The Text
			local Text = Instance.new("TextLabel")
			Text.Size = UDim2.new(1, 0, 1, 0)
			Text.Position = UDim2.new(0, 4, 0, 0)
			Text.BackgroundTransparency = 1
			Text.Text = labelText:upper()
			Text.TextColor3 = Color3.fromRGB(150, 150, 150)
			Text.Font = Enum.Font.GothamBold
			Text.TextSize = 11
			Text.TextXAlignment = Enum.TextXAlignment.Left
			Text.Parent = LabelContainer

			-- 4. The Underline
			local Underline = Instance.new("Frame")
			Underline.Size = UDim2.new(1, 0, 0, 1)
			Underline.Position = UDim2.new(0, 0, 1, 0)
			Underline.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Underline.BackgroundTransparency = 0.92
			Underline.BorderSizePixel = 0
			Underline.Parent = LabelContainer
			SetAccent(Underline)

			-- 5. RETURN METHODS (The Fix)
			local Methods = {}

			-- This allows you to call label:UpdateText("New Name")
			function Methods:UpdateText(newText)
				Text.Text = newText:upper()
				LabelContainer.Name = "Label_" .. newText
			end

			-- Optional: Allow scripts to still access the actual Frame if needed
			Methods.Instance = LabelContainer

			return Methods
		end

		function tab:CreateDivider()
			-- 1. Setup Layout
			local layout = Page:FindFirstChildOfClass("UIListLayout")
			if not layout then
				layout = Instance.new("UIListLayout", Page)
				layout.Padding = UDim.new(0, 8)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
			end

			-- 2. Container
			local DividerContainer = Instance.new("Frame")
			DividerContainer.Name = "Divider"
			DividerContainer.Size = UDim2.new(1, -20, 0, 16) -- Slightly taller for the glow
			DividerContainer.BackgroundTransparency = 1
			DividerContainer.Parent = Page

			-- 3. The Line
			local Line = Instance.new("Frame")
			Line.Size = UDim2.new(1, 0, 0, 1)
			Line.Position = UDim2.new(0, 0, 0.5, 0)
			Line.AnchorPoint = Vector2.new(0, 0.5)
			Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Line.BorderSizePixel = 0
			Line.Parent = DividerContainer

			-- 4. Color & Transparency Gradient
			-- This creates a blue "hotspot" in the middle that fades to dark gray/transparent
			local ColorGrad = Instance.new("UIGradient")
			ColorGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 40)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 170, 255)), -- Accent Blue
				ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 40))
			})
			ColorGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.4), -- Most visible in center
				NumberSequenceKeypoint.new(1, 1)
			})
			ColorGrad.Parent = Line
			SetAccent(ColorGrad)

			-- 5. The "Glow" (A soft flare behind the line)
			local Flare = Instance.new("Frame")
			Flare.Size = UDim2.new(0, 60, 0, 10)
			Flare.Position = UDim2.new(0.5, 0, 0.5, 0)
			Flare.AnchorPoint = Vector2.new(0.5, 0.5)
			Flare.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			Flare.BackgroundTransparency = 0.9 -- Very faint
			Flare.BorderSizePixel = 0
			Flare.Parent = DividerContainer

			local FlareGrad = Instance.new("UIGradient")
			FlareGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1)
			})
			FlareGrad.Parent = Flare
			SetAccent(Flare)

			return DividerContainer
		end

		function tab:CreateToggle(toggleText, default, callback)
			local Toggled = default or false

			local ToggleFrame = Instance.new("Frame")
			ToggleFrame.Size = UDim2.new(1, -12, 0, 38)
			ToggleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			ToggleFrame.Parent = Page
			Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 5)

			local Stroke = Instance.new("UIStroke", ToggleFrame)
			Stroke.Thickness = 1
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.95

			local Text = Instance.new("TextLabel")
			Text.Size = UDim2.new(1, -60, 1, 0)
			Text.Position = UDim2.new(0, 12, 0, 0)
			Text.BackgroundTransparency = 1
			Text.Text = toggleText
			Text.Font = Enum.Font.GothamMedium
			Text.TextColor3 = Color3.fromRGB(160, 160, 160)
			Text.TextSize = 13
			Text.TextXAlignment = Enum.TextXAlignment.Left
			Text.Parent = ToggleFrame

			local Track = Instance.new("Frame")
			Track.Size = UDim2.new(0, 36, 0, 16)
			Track.Position = UDim2.new(1, -12, 0.5, 0)
			Track.AnchorPoint = Vector2.new(1, 0.5)
			Track.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
			Track.Parent = ToggleFrame
			Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

			-- The Liquid Knob (This handles the smear and the knob as one unit)
			local Knob = Instance.new("Frame")
			Knob.Name = "AccentKnob"
			Knob.Size = UDim2.new(0, 10, 0, 10)
			Knob.Position = Toggled and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
			Knob.AnchorPoint = Vector2.new(Toggled and 1 or 0, 0.5) -- Dynamic anchoring
			Knob.BackgroundColor3 = Toggled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(70, 70, 70)
			Knob.Parent = Track
			Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)
			SetAccent(Knob)

			-- The Blur Gradient (Always synced)
			local Gradient = Instance.new("UIGradient", Knob)
			Gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 0.8) -- Soft blur tail
			})
			Gradient.Rotation = Toggled and 180 or 0

			local function UpdateToggle()
				local accentColor = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
				-- Sync Info: All parts move together over 0.6 seconds
				local info = TweenInfo.new(0.6, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

				if Toggled then
					-- 1. Flip Anchor to the LEFT so it stretches to the RIGHT
					Knob.AnchorPoint = Vector2.new(0, 0.5)
					Knob.Position = UDim2.new(0, 4, 0.5, 0)
					Gradient.Rotation = 180

					-- 2. Single Sync Tween: Stretch, Slide, and Change Color
					TweenService:Create(Knob, info, {
						Size = UDim2.new(0, 28, 0, 10),
						BackgroundColor3 = accentColor -- Use variable here
					}):Play()

					-- 3. Halfway through, we pull the tail in (Cleanly synced)
					task.delay(0.25, function()
						TweenService:Create(Knob, info, {
							Size = UDim2.new(0, 10, 0, 10),
							Position = UDim2.new(1, -14, 0.5, 0)
						}):Play()
					end)
				else
					-- 1. Flip Anchor to the RIGHT so it stretches to the LEFT
					Knob.AnchorPoint = Vector2.new(1, 0.5)
					Knob.Position = UDim2.new(1, -14, 0.5, 0)
					Gradient.Rotation = 0

					TweenService:Create(Knob, info, {
						Size = UDim2.new(0, 28, 0, 10),
						BackgroundColor3 = Color3.fromRGB(70, 70, 70)
					}):Play()

					task.delay(0.25, function()
						TweenService:Create(Knob, info, {
							Size = UDim2.new(0, 10, 0, 10),
							Position = UDim2.new(0, 4, 0.5, 0)
						}):Play()
					end)
				end

				TweenService:Create(Text, info, {TextColor3 = Toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 160)}):Play()
			end

			-- Interaction
			local ClickBtn = Instance.new("TextButton", ToggleFrame)
			ClickBtn.Size = UDim2.new(1, 0, 1, 0)
			ClickBtn.BackgroundTransparency = 1
			ClickBtn.Text = ""

			ClickBtn.MouseButton1Click:Connect(function()
				Toggled = not Toggled
				UpdateToggle()
				callback(Toggled)
			end)

			return ToggleFrame
		end

		function tab:CreateSlider(sliderText, min, max, default, callback)
			local Value = default or min
			local Dragging = false

			-- 1. Container
			local SliderFrame = Instance.new("Frame")
			SliderFrame.Size = UDim2.new(1, -12, 0, 45)
			SliderFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			SliderFrame.Parent = Page
			Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 5)

			local Stroke = Instance.new("UIStroke", SliderFrame)
			Stroke.Thickness = 1
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.95

			-- 2. Labels
			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -20, 0, 20)
			Title.Position = UDim2.new(0, 12, 0, 6)
			Title.BackgroundTransparency = 1
			Title.Text = sliderText
			Title.Font = Enum.Font.GothamMedium
			Title.TextColor3 = Color3.fromRGB(160, 160, 160)
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = SliderFrame

			local ValueText = Instance.new("TextLabel")
			ValueText.Size = UDim2.new(0, 40, 0, 20)
			ValueText.Position = UDim2.new(1, -52, 0, 6)
			ValueText.BackgroundTransparency = 1
			ValueText.Text = tostring(Value)
			ValueText.Font = Enum.Font.GothamBold
			ValueText.TextColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
			ValueText.TextSize = 13
			ValueText.TextXAlignment = Enum.TextXAlignment.Right
			ValueText.Parent = SliderFrame

			SetAccent(ValueText)

			-- 3. The Track
			local Track = Instance.new("Frame")
			Track.Size = UDim2.new(1, -24, 0, 4)
			Track.Position = UDim2.new(0.5, 0, 1, -12)
			Track.AnchorPoint = Vector2.new(0.5, 0.5)
			Track.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
			Track.Parent = SliderFrame
			Instance.new("UICorner", Track)

			-- 4. The Smear Fill (The actual "Liquid" bar)
			local Fill = Instance.new("Frame")
			Fill.Size = UDim2.new((Value - min) / (max - min), 0, 1, 0)
			Fill.BackgroundColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
			Fill.BorderSizePixel = 0
			Fill.Parent = Track
			Instance.new("UICorner", Fill)

			SetAccent(Fill)

			-- Glow/Blur Gradient (Synced to the move direction)
			local Gradient = Instance.new("UIGradient", Fill)
			Gradient.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.85, 0),
				NumberSequenceKeypoint.new(1, 0.4) -- Subtle blur at the leading edge
			})

			-- 5. The "Momentum" Logic
			local function Update(input)
				local pos = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				Value = math.floor(min + (max - min) * pos)
				ValueText.Text = tostring(Value)

				-- The "Smear" Timing
				-- We use a Circular Out for a heavy, smooth pull
				local info = TweenInfo.new(0.4, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

				-- Apply the stretch
				TweenService:Create(Fill, info, {
					Size = UDim2.new(pos, 0, 1, 0)
				}):Play()

				callback(Value)
			end

			-- 6. Interaction
			SliderFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					Dragging = true
					-- Visual feedback: Bar gets slightly thicker when active
					TweenService:Create(Track, TweenInfo.new(0.3), {Size = UDim2.new(1, -24, 0, 6)}):Play()
					TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0.8}):Play()
					Update(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					Dragging = false
					TweenService:Create(Track, TweenInfo.new(0.3), {Size = UDim2.new(1, -24, 0, 4)}):Play()
					TweenService:Create(Stroke, TweenInfo.new(0.3), {Transparency = 0.95}):Play()
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					Update(input)
				end
			end)

			return SliderFrame
		end

		function tab:CreateDropdown(name, list, callback)
			local Opened = false
			local Selected = name

			-- 1. Main Container (Styled exactly like your Button/Toggle)
			local DropdownFrame = Instance.new("Frame")
			DropdownFrame.Name = name .. "_Dropdown"
			DropdownFrame.Size = UDim2.new(1, -12, 0, 32) -- Matches button height
			DropdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			DropdownFrame.ClipsDescendants = true
			DropdownFrame.Parent = Page

			local Corner = Instance.new("UICorner", DropdownFrame)
			Corner.CornerRadius = UDim.new(0, 6)

			local Stroke = Instance.new("UIStroke", DropdownFrame)
			Stroke.Thickness = 1
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.95 -- The subtle "silk" border
			Stroke.Name = "DropdownStroke"
			SetAccent(Stroke)

			-- 2. Header (The "Button" Part)
			local Header = Instance.new("TextButton")
			Header.Size = UDim2.new(1, 0, 0, 32)
			Header.BackgroundTransparency = 1
			Header.Text = ""
			Header.Parent = DropdownFrame

			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -35, 1, 0)
			Title.Position = UDim2.new(0, 12, 0, 0)
			Title.BackgroundTransparency = 1
			Title.Text = name
			Title.Font = Enum.Font.GothamMedium
			Title.TextColor3 = Color3.fromRGB(200, 200, 200)
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = Header

			local Arrow = Instance.new("ImageLabel")
			Arrow.Size = UDim2.new(0, 14, 0, 14)
			Arrow.Position = UDim2.new(1, -10, 0.5, 0)
			Arrow.AnchorPoint = Vector2.new(1, 0.5)
			Arrow.BackgroundTransparency = 1
			Arrow.Image = "rbxassetid://6034818372"
			Arrow.ImageColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
			Arrow.Parent = Header

			SetAccent(Arrow)

			-- 3. Options Container
			local Container = Instance.new("Frame")
			Container.Size = UDim2.new(1, 0, 0, #list * 28)
			Container.Position = UDim2.new(0, 0, 0, 32)
			Container.BackgroundTransparency = 1
			Container.Parent = DropdownFrame

			local Layout = Instance.new("UIListLayout", Container)
			Layout.SortOrder = Enum.SortOrder.LayoutOrder

			-- 4. Options (Clean & Integrated)
			for i, v in pairs(list) do
				local Option = Instance.new("TextButton")
				Option.Size = UDim2.new(1, 0, 0, 28)
				Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Option.BackgroundTransparency = 1
				Option.Text = v
				Option.Font = Enum.Font.Gotham
				Option.TextColor3 = Color3.fromRGB(140, 140, 140)
				Option.TextSize = 12
				Option.Parent = Container

				-- Hover Effect
				Option.MouseEnter:Connect(function()
					TweenService:Create(Option, TweenInfo.new(0.2), {
						BackgroundTransparency = 0.96, -- Very subtle "Button" highlight
						TextColor3 = Color3.fromRGB(255, 255, 255)
					}):Play()
				end)

				Option.MouseLeave:Connect(function()
					TweenService:Create(Option, TweenInfo.new(0.2), {
						BackgroundTransparency = 1,
						TextColor3 = Color3.fromRGB(140, 140, 140)
					}):Play()
				end)

				Option.MouseButton1Click:Connect(function()
					Title.Text = v
					callback(v)
					Opened = false
					-- Close Animation
					TweenService:Create(DropdownFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
						Size = UDim2.new(1, -12, 0, 32)
					}):Play()
					TweenService:Create(Arrow, TweenInfo.new(0.25), {Rotation = 0}):Play()
					TweenService:Create(Stroke, TweenInfo.new(0.25), {Transparency = 0.95}):Play()
				end)
			end

			-- 5. Toggle Logic
			Header.MouseButton1Click:Connect(function()
				local targetColor = Opened and (Window.CurrentAccent or Color3.fromRGB(0, 170, 255)) or Color3.fromRGB(255, 255, 255)
				Opened = not Opened
				local info = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

				-- Animation matching Button/Toggle speed
				TweenService:Create(DropdownFrame, info, {
					Size = Opened and UDim2.new(1, -12, 0, 32 + (#list * 28) + 4) or UDim2.new(1, -12, 0, 32)
				}):Play()

				TweenService:Create(Arrow, info, {Rotation = Opened and 180 or 0}):Play()

				-- Make border glow slightly when open
				TweenService:Create(Stroke, info, {
					Transparency = Opened and 0.8 or 0.95,
					Color = targetColor -- Dynamic color!
				}):Play()
			end)

			return DropdownFrame
		end

		function tab:CreateMultiDropdown(name, list, default, callback)
			local list = type(list) == "table" and list or {}
			local Selected = type(default) == "table" and default or {}
			local Opened = false

			local MultiFrame = Instance.new("Frame")
			MultiFrame.Size = UDim2.new(1, -12, 0, 32)
			MultiFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			MultiFrame.ClipsDescendants = true
			MultiFrame.Parent = Page
			Instance.new("UICorner", MultiFrame).CornerRadius = UDim.new(0, 6)

			local Stroke = Instance.new("UIStroke", MultiFrame)
			Stroke.Thickness = 1
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.95

			local Header = Instance.new("TextButton")
			Header.Size = UDim2.new(1, 0, 0, 32)
			Header.BackgroundTransparency = 1
			Header.Text = ""
			Header.Parent = MultiFrame

			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -60, 1, 0)
			Title.Position = UDim2.new(0, 12, 0, 0)
			Title.BackgroundTransparency = 1
			Title.Text = name
			Title.Font = Enum.Font.GothamMedium
			Title.TextColor3 = Color3.fromRGB(180, 180, 180)
			Title.TextSize = 13
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = Header

			local CountText = Instance.new("TextLabel")
			CountText.Size = UDim2.new(0, 40, 1, 0)
			CountText.Position = UDim2.new(1, -35, 0, 0)
			CountText.BackgroundTransparency = 1
			CountText.Text = #Selected > 0 and #Selected or ""
			CountText.Font = Enum.Font.GothamBold
			CountText.TextColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
			CountText.TextSize = 11
			CountText.Parent = Header

			SetAccent(CountText)

			local Arrow = Instance.new("ImageLabel")
			Arrow.Size = UDim2.new(0, 14, 0, 14)
			Arrow.Position = UDim2.new(1, -10, 0.5, 0)
			Arrow.AnchorPoint = Vector2.new(1, 0.5)
			Arrow.BackgroundTransparency = 1
			Arrow.Image = "rbxassetid://6034818372"
			Arrow.ImageColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
			Arrow.Parent = Header

			SetAccent(Arrow)

			local Container = Instance.new("Frame")
			Container.Size = UDim2.new(1, 0, 0, #list * 28)
			Container.Position = UDim2.new(0, 0, 0, 32)
			Container.BackgroundTransparency = 1
			Container.Parent = MultiFrame
			Instance.new("UIListLayout", Container).SortOrder = Enum.SortOrder.LayoutOrder

			for i, v in pairs(list) do
				local isSelected = table.find(Selected, v)

				local Option = Instance.new("TextButton")
				Option.Size = UDim2.new(1, 0, 0, 28)
				Option.BackgroundTransparency = 1
				Option.Text = ""
				Option.Parent = Container

				-- The Subtle Indicator (Left Bar)
				local Indicator = Instance.new("Frame")
				Indicator.Size = UDim2.new(0, 2, 0, isSelected and 14 or 0)
				Indicator.Position = UDim2.new(0, 4, 0.5, 0)
				Indicator.AnchorPoint = Vector2.new(0, 0.5)
				Indicator.BackgroundColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
				Indicator.BorderSizePixel = 0
				Indicator.BackgroundTransparency = isSelected and 0 or 1
				Indicator.Parent = Option
				Indicator.Name = "MultiIndicator" -- Specific name for the updater
				Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
				SetAccent(Indicator)

				local OptTitle = Instance.new("TextLabel")
				OptTitle.Size = UDim2.new(1, -20, 1, 0)
				-- Shift text right if selected
				OptTitle.Position = UDim2.new(0, isSelected and 18 or 12, 0, 0)
				OptTitle.BackgroundTransparency = 1
				OptTitle.Text = v
				OptTitle.Font = Enum.Font.Gotham
				OptTitle.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
				OptTitle.TextSize = 12
				OptTitle.TextXAlignment = Enum.TextXAlignment.Left
				OptTitle.Parent = Option

				Option.MouseButton1Click:Connect(function()
					local index = table.find(Selected, v)
					if index then table.remove(Selected, index) else table.insert(Selected, v) end

					local active = table.find(Selected, v)
					local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart)

					-- Animate Subtle Shift
					TweenService:Create(Indicator, tInfo, {
						Size = UDim2.new(0, 2, 0, active and 14 or 0),
						BackgroundTransparency = active and 0 or 1,
						BackgroundColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255) -- Add this
					}):Play()

					TweenService:Create(OptTitle, tInfo, {
						Position = UDim2.new(0, active and 18 or 12, 0, 0),
						TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 130)
					}):Play()

					CountText.Text = #Selected > 0 and #Selected or ""
					if callback then callback(Selected) end
				end)
			end

			Header.MouseButton1Click:Connect(function()
				Opened = not Opened
				local info = TweenInfo.new(0.25, Enum.EasingStyle.Quart)

				TweenService:Create(MultiFrame, info, {
					Size = Opened and UDim2.new(1, -12, 0, 32 + (#list * 28) + 4) or UDim2.new(1, -12, 0, 32)
				}):Play()

				TweenService:Create(Arrow, info, {Rotation = Opened and 180 or 0}):Play()
			end)

			return MultiFrame
		end

		function tab:CreateTextField(name, placeholder, callback)
			local TextFieldFrame = Instance.new("Frame")
			TextFieldFrame.Size = UDim2.new(1, -12, 0, 38) -- Slightly taller for the float effect
			TextFieldFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			TextFieldFrame.Parent = Page

			local Corner = Instance.new("UICorner", TextFieldFrame)
			Corner.CornerRadius = UDim.new(0, 6)

			local Stroke = Instance.new("UIStroke", TextFieldFrame)
			Stroke.Thickness = 1
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.95
			Stroke.Name = "TextFieldStroke"
			SetAccent(Stroke)

			-- Floating Title Label
			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -24, 1, 0)
			Label.Position = UDim2.new(0, 12, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = name
			Label.Font = Enum.Font.GothamMedium
			Label.TextColor3 = Color3.fromRGB(120, 120, 120)
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.ZIndex = 2
			Label.Parent = TextFieldFrame
			Label.Name = "TextFieldLabel"
			SetAccent(Label)

			-- Input Field
			local Input = Instance.new("TextBox")
			Input.Size = UDim2.new(1, -24, 1, 0)
			Input.Position = UDim2.new(0, 12, 0, 0)
			Input.BackgroundTransparency = 1
			Input.Text = ""
			Input.PlaceholderText = ""
			Input.PlaceholderColor3 = Color3.fromRGB(50, 50, 50)
			Input.Font = Enum.Font.Gotham
			Input.TextColor3 = Color3.fromRGB(255, 255, 255)
			Input.TextSize = 13
			Input.TextXAlignment = Enum.TextXAlignment.Left
			Input.ClearTextOnFocus = false
			Input.ZIndex = 3
			Input.Parent = TextFieldFrame

			-- Animation Logic
			local function ToggleFocus(focused)
				local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
				-- Get the live accent color or fallback to default blue
				local accent = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)

				if focused or Input.Text ~= "" then
					TweenService:Create(Label, tInfo, {
						Position = UDim2.new(0, 12, 0, -10),
						TextSize = 10,
						-- If focused, use accent. If not focused but has text, use gray.
						TextColor3 = focused and accent or Color3.fromRGB(150, 150, 150)
					}):Play()

					TweenService:Create(Stroke, tInfo, {
						Transparency = focused and 0.8 or 0.95,
						Color = focused and accent or Color3.fromRGB(255, 255, 255)
					}):Play()
				else
					-- ... (Reset logic remains the same)
				end
			end

			Input.Focused:Connect(function() ToggleFocus(true) end)

			Input.FocusLost:Connect(function() 
				ToggleFocus(false) 
				callback(Input.Text)
			end)

			return TextFieldFrame
		end

		function tab:CreateColorPicker(name, default, callback)
			local Color = default or Color3.fromRGB(0, 170, 255)
			local H, S, V = Color:ToHSV()
			local Opened = false
			local UIS = game:GetService("UserInputService")

			local CPFrame = Instance.new("Frame")
			CPFrame.Size = UDim2.new(1, -12, 0, 32)
			CPFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			CPFrame.ClipsDescendants = true
			CPFrame.Parent = Page
			Instance.new("UICorner", CPFrame).CornerRadius = UDim.new(0, 6)

			local Stroke = Instance.new("UIStroke", CPFrame)
			Stroke.Thickness = 1; Stroke.Color = Color3.fromRGB(255, 255, 255); Stroke.Transparency = 0.96

			local Header = Instance.new("TextButton")
			Header.Size = UDim2.new(1, 0, 0, 32)
			Header.BackgroundTransparency = 1; Header.Text = ""
			Header.Parent = CPFrame

			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -60, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
			Title.BackgroundTransparency = 1; Title.Text = name
			Title.Font = Enum.Font.GothamMedium; Title.TextColor3 = Color3.fromRGB(180, 180, 180)
			Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = Header

			local Preview = Instance.new("Frame")
			Preview.Size = UDim2.new(0, 24, 0, 14)
			Preview.Position = UDim2.new(1, -12, 0.5, 0)
			Preview.AnchorPoint = Vector2.new(1, 0.5)
			Preview.BackgroundColor3 = Color
			Preview.Parent = Header
			Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 3)

			-- Picker Container
			local Container = Instance.new("Frame")
			Container.Size = UDim2.new(1, -24, 0, 140)
			Container.Position = UDim2.new(0, 12, 0, 38)
			Container.BackgroundTransparency = 1
			Container.Parent = CPFrame

			-- 1. Saturation/Value Box
			local SVBox = Instance.new("ImageLabel")
			SVBox.Size = UDim2.new(1, 0, 0, 100)
			SVBox.Image = "rbxassetid://4155801252"
			SVBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
			SVBox.Parent = Container
			Instance.new("UICorner", SVBox)

			local Cursor = Instance.new("Frame")
			Cursor.Size = UDim2.new(0, 8, 0, 8)
			Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
			Cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Cursor.Position = UDim2.new(S, 0, 1-V, 0)
			Cursor.Parent = SVBox
			Instance.new("UICorner", Cursor).CornerRadius = UDim.new(1, 0)
			local CStroke = Instance.new("UIStroke", Cursor)
			CStroke.Thickness = 1.5; CStroke.Color = Color3.fromRGB(0,0,0)

			-- 2. TRUE Rainbow Hue Slider
			local HueSlider = Instance.new("Frame")
			HueSlider.Size = UDim2.new(1, 0, 0, 12)
			HueSlider.Position = UDim2.new(0, 0, 0, 115)
			HueSlider.Parent = Container
			Instance.new("UICorner", HueSlider)

			local HueGradient = Instance.new("UIGradient", HueSlider)
			HueGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			})

			local HueCursor = Instance.new("Frame")
			HueCursor.Size = UDim2.new(0, 4, 1, 4)
			HueCursor.Position = UDim2.new(H, 0, 0.5, 0)
			HueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
			HueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			HueCursor.Parent = HueSlider
			Instance.new("UICorner", HueCursor)
			Instance.new("UIStroke", HueCursor).Thickness = 1

			local function Update()
				local realColor = Color3.fromHSV(H, S, V)
				Preview.BackgroundColor3 = realColor
				SVBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
				Cursor.Position = UDim2.new(S, 0, 1-V, 0)
				HueCursor.Position = UDim2.new(H, 0, 0.5, 0)
				callback(realColor)
			end

			-- Draggable Input Logic (Fixed)
			local function MakeDraggable(obj, callback)
				obj.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local function UpdatePos()
							local size = obj.AbsoluteSize
							local position = obj.AbsolutePosition
							local mPos = UIS:GetMouseLocation()
							-- Account for the 36px GUI inset
							local relX = math.clamp((mPos.X - position.X) / size.X, 0, 1)
							local relY = math.clamp((mPos.Y - (position.Y + 36)) / size.Y, 0, 1)
							callback(relX, relY)
						end

						local connection
						connection = UIS.InputChanged:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								UpdatePos()
							end
						end)

						UpdatePos() -- Update once on click

						UIS.InputEnded:Connect(function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								if connection then connection:Disconnect() end
							end
						end)
					end
				end)
			end

			MakeDraggable(SVBox, function(x, y)
				S = x
				V = 1 - y
				Update()
			end)

			MakeDraggable(HueSlider, function(x)
				H = x
				Update()
			end)

			Header.MouseButton1Click:Connect(function()
				Opened = not Opened
				TweenService:Create(CPFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
					Size = Opened and UDim2.new(1, -12, 0, 185) or UDim2.new(1, -12, 0, 32)
				}):Play()
			end)

			return CPFrame
		end

		function tab:CreateDescriptionList(name, items)
			local ListItems = items or {}
			local ListHeight = #ListItems * 24 -- Compact spacing

			local ListFrame = Instance.new("Frame")
			ListFrame.Name = name .. "_DescList"
			ListFrame.Size = UDim2.new(1, -12, 0, 36 + ListHeight)
			ListFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			ListFrame.Parent = Page

			local Corner = Instance.new("UICorner", ListFrame)
			Corner.CornerRadius = UDim.new(0, 6)

			local Stroke = Instance.new("UIStroke", ListFrame)
			Stroke.Thickness = 1
			Stroke.Color = Color3.fromRGB(255, 255, 255)
			Stroke.Transparency = 0.96

			-- Section Title
			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -24, 0, 30)
			Title.Position = UDim2.new(0, 12, 0, 0)
			Title.BackgroundTransparency = 1
			Title.Text = name:upper()
			Title.Font = Enum.Font.GothamBold
			Title.TextColor3 = Window.CurrentAccent or Color3.fromRGB(100, 100, 100)
			Title.TextSize = 10
			Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = ListFrame
			SetAccent(Title)

			-- Inside tab:CreateDescriptionList
			local AccentBar = Instance.new("Frame")
			AccentBar.Size = UDim2.new(0, 2, 0, 12)
			AccentBar.Position = UDim2.new(0, 0, 0, 9) -- Centered with the Title text
			AccentBar.BackgroundColor3 = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)
			AccentBar.BorderSizePixel = 0
			AccentBar.Parent = Title -- Parented to title for easy alignment

			local CornerBar = Instance.new("UICorner", AccentBar)
			CornerBar.CornerRadius = UDim.new(1, 0)

			SetAccent(AccentBar) -- Tag it!

			local Container = Instance.new("Frame")
			Container.Size = UDim2.new(1, -24, 1, -36)
			Container.Position = UDim2.new(0, 12, 0, 32)
			Container.BackgroundTransparency = 1
			Container.Parent = ListFrame

			local Layout = Instance.new("UIListLayout", Container)
			Layout.SortOrder = Enum.SortOrder.LayoutOrder
			Layout.Padding = UDim.new(0, 4)

			-- Item Generator
			for i, item in pairs(ListItems) do
				-- Detect format: Is it {Title = "X"} or is it just a string?
				local labelText = ""
				local valueText = ""

				if type(item) == "table" then
					-- Formal format: {Title = "Health", Description = "100"}
					-- Or simple array format: {"Health", "100"}
					labelText = item.Title or item[1] or "Key"
					valueText = item.Description or item[2] or "Value"
				else
					-- If it's a direct dictionary: {Health = "100"}
					-- i would be "Health", item would be "100"
					labelText = tostring(i)
					valueText = tostring(item)
				end

				local ItemFrame = Instance.new("Frame")
				ItemFrame.Size = UDim2.new(1, 0, 0, 20)
				ItemFrame.BackgroundTransparency = 1
				ItemFrame.Parent = Container

				local KeyLabel = Instance.new("TextLabel") -- Changed name to avoid confusion with loop 'i'
				KeyLabel.Size = UDim2.new(0.4, 0, 1, 0)
				KeyLabel.BackgroundTransparency = 1
				KeyLabel.Text = labelText -- Use our smart variable
				KeyLabel.Font = Enum.Font.GothamMedium
				KeyLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
				KeyLabel.TextSize = 12
				KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
				KeyLabel.Parent = ItemFrame

				local ValueLabel = Instance.new("TextLabel")
				ValueLabel.Size = UDim2.new(0.6, 0, 1, 0)
				ValueLabel.Position = UDim2.new(0.4, 0, 0, 0)
				ValueLabel.BackgroundTransparency = 1
				ValueLabel.Text = valueText -- Use our smart variable
				ValueLabel.Font = Enum.Font.Gotham
				ValueLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
				ValueLabel.TextSize = 12
				ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
				ValueLabel.Parent = ItemFrame

				-- Subtle Separator Dot
				if i < #ListItems then
					local Line = Instance.new("Frame")
					Line.Size = UDim2.new(1, 0, 0, 1)
					Line.Position = UDim2.new(0, 0, 1, 2)
					Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Line.BackgroundTransparency = 0.98
					Line.BorderSizePixel = 0
					Line.Parent = ItemFrame
				end
			end

			-- Methods to update the list live
			local Methods = {}
			function Methods:Update(newItems)
				-- Logic to clear and rebuild or update labels
			end

			return ListFrame, Methods
		end

		function lib:CreatePopUp(title, content, callback)
			local TargetGui = self.MainGui
			local currentAccent = self.CurrentAccent or Color3.fromRGB(0, 170, 255)

			-- 1. The Dimmer (Stays at the bottom)
			local Dimmer = Instance.new("Frame") -- Changed to Frame to prevent button-nesting bugs
			Dimmer.Name = "PopUpOverlay"
			Dimmer.Size = UDim2.new(1, 0, 1, 0)
			Dimmer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Dimmer.BackgroundTransparency = 1
			Dimmer.BorderSizePixel = 0
			Dimmer.ZIndex = 500 
			Dimmer.Parent = TargetGui

			-- Invisible button to capture background clicks (optional)
			local Blocker = Instance.new("TextButton")
			Blocker.Size = UDim2.new(1, 0, 1, 0)
			Blocker.BackgroundTransparency = 1
			Blocker.Text = ""
			Blocker.Parent = Dimmer

			-- 2. The PopUp Box (Higher ZIndex than Dimmer)
			local PopUpFrame = Instance.new("Frame")
			PopUpFrame.Size = UDim2.new(0, 280, 0, 0) -- Start flat
			PopUpFrame.Position = UDim2.new(0.5, 0, 0.5, 50)
			PopUpFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			PopUpFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			PopUpFrame.ZIndex = 501 -- Must be higher than Dimmer
			PopUpFrame.Parent = Dimmer

			Instance.new("UICorner", PopUpFrame).CornerRadius = UDim.new(0, 8)
			local Stroke = Instance.new("UIStroke", PopUpFrame)
			Stroke.Color = currentAccent
			Stroke.Thickness = 1.5
			SetAccent(Stroke)


			-- 3. Labels (Inherit ZIndex)
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, 0, 0, 45)
			TitleLabel.Text = title
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TitleLabel.TextSize = 16
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.ZIndex = 502
			TitleLabel.Parent = PopUpFrame

			local DescLabel = Instance.new("TextLabel")
			DescLabel.Size = UDim2.new(1, -30, 0, 60)
			DescLabel.Position = UDim2.new(0, 15, 0, 45)
			DescLabel.Text = content
			DescLabel.Font = Enum.Font.Gotham
			DescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
			DescLabel.TextSize = 13
			DescLabel.TextWrapped = true
			DescLabel.BackgroundTransparency = 1
			DescLabel.ZIndex = 502
			DescLabel.Parent = PopUpFrame

			-- 4. Interaction Button
			local CloseBtn = Instance.new("TextButton")
			CloseBtn.Size = UDim2.new(0.9, 0, 0, 32)
			CloseBtn.Position = UDim2.new(0.5, 0, 1, -12)
			CloseBtn.AnchorPoint = Vector2.new(0.5, 1)
			CloseBtn.BackgroundColor3 = currentAccent
			CloseBtn.Text = "Dismiss"
			CloseBtn.Font = Enum.Font.GothamBold
			CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			CloseBtn.TextSize = 12
			CloseBtn.ZIndex = 503 -- Highest priority
			CloseBtn.Parent = PopUpFrame
			Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)
			SetAccent(CloseBtn)

			-- Intro Animation
			local TS = game:GetService("TweenService")
			TS:Create(Dimmer, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()
			TS:Create(PopUpFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 280, 0, 150) -- Grow into place
			}):Play()

			-- Close Logic
			CloseBtn.MouseButton1Click:Connect(function()
				TS:Create(Dimmer, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
				TS:Create(PopUpFrame, TweenInfo.new(0.2), {Position = UDim2.new(0.5, 0, 0.5, 30)}):Play()
				task.wait(0.2)
				Dimmer:Destroy()
				if callback then callback() end
			end)
		end

		function tab:CreateKeybind(name, default, callback)
			local Key = default or Enum.KeyCode.F
			local Binding = false
			local UIS = game:GetService("UserInputService")
			local currentAccent = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)

			local KBFrame = Instance.new("Frame")
			KBFrame.Size = UDim2.new(1, -12, 0, 32)
			KBFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
			KBFrame.Parent = Page
			Instance.new("UICorner", KBFrame).CornerRadius = UDim.new(0, 6)

			local Stroke = Instance.new("UIStroke", KBFrame)
			Stroke.Thickness = 1; Stroke.Color = Color3.fromRGB(255, 255, 255); Stroke.Transparency = 0.96

			local Title = Instance.new("TextLabel")
			Title.Size = UDim2.new(1, -60, 1, 0); Title.Position = UDim2.new(0, 12, 0, 0)
			Title.BackgroundTransparency = 1; Title.Text = name
			Title.Font = Enum.Font.GothamMedium; Title.TextColor3 = Color3.fromRGB(180, 180, 180)
			Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left
			Title.Parent = KBFrame

			local BindButton = Instance.new("TextButton")
			BindButton.Size = UDim2.new(0, 60, 0, 20)
			BindButton.Position = UDim2.new(1, -12, 0.5, 0)
			BindButton.AnchorPoint = Vector2.new(1, 0.5)
			BindButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
			BindButton.Text = Key.Name
			BindButton.Font = Enum.Font.GothamBold; 
			BindButton.TextColor3 = currentAccent -- Key name shows in accent color
			BindButton.TextSize = 11
			BindButton.Parent = KBFrame
			Instance.new("UICorner", BindButton).CornerRadius = UDim.new(0, 4)

			local BStroke = Instance.new("UIStroke", BindButton)
			BStroke.Thickness = 1
			BStroke.Transparency = 0.8
			BStroke.Color = currentAccent
			BStroke.Name = "KeybindStroke"

			SetAccent(BStroke)
			SetAccent(BindButton)

			-- Logic for clicking the button to start binding
			BindButton.MouseButton1Click:Connect(function()
				Binding = true
				BindButton.Text = "..."
				BStroke.Transparency = 0.2 -- Make border bright while listening
			end)

			-- Global Input Listener
			UIS.InputBegan:Connect(function(input, gpe)
				if gpe then return end -- Don't trigger if typing in a Roblox chat/textbox

				if Binding then
					if input.UserInputType == Enum.UserInputType.Keyboard then
						-- Check for Escape to cancel/unbind
						if input.KeyCode == Enum.KeyCode.Escape then
							Key = nil
							BindButton.Text = "None"
						else
							Key = input.KeyCode
							BindButton.Text = Key.Name
						end

						Binding = false
						BStroke.Transparency = 0.8
						BStroke.Color = Window.CurrentAccent or Color3.fromRGB(0, 170, 255)

						-- Note: Usually we don't fire the callback when setting the key, 
						-- only when pressing it later. But you can if you want:
						-- if callback then callback(Key) end 
					end
				else
					-- TRIGGER MODE: Check if the pressed key matches our saved Key
					if Key and input.KeyCode == Key then
						if callback then callback() end
					end
				end
			end)

			return KBFrame
		end

		return tab
	end

	task.spawn(function()
		CreateDefaultSettings(lib, Window)
	end)
	
	function lib:InitializeMods(WindowObj)
		-- Configuration
		local ModSource = "https://raw.githubusercontent.com/Sealient/LuminxUI/main/Mods/"
		local ModList = {"testmod.lua"} 

		-- Local reference to the accent to prevent "nil" errors
		local AccentColor = self.CurrentAccent or Color3.fromRGB(0, 170, 255)

		-- Create the Tab
		local ModsTab = WindowObj:CreateTab("Mods", "rbxassetid://10734949856")

		local function SafeFetch(url)
			local success, result = pcall(function()
				if type(game.HttpGet) == "function" then
					return game:HttpGet(url)
				else
					return game:GetService("HttpService"):GetAsync(url, true)
				end
			end)
			return success, result
		end

		task.spawn(function()
			for _, fileName in pairs(ModList) do
				local success, result = SafeFetch(ModSource .. fileName)

				if success then
					local modDataFunc, parseErr = loadstring(result)
					if modDataFunc then
						local dataSuccess, modData = pcall(modDataFunc)

						if dataSuccess and type(modData) == "table" then
							-- 1. Create the Card via your library
							local Card, Methods = ModsTab:CreateDescriptionList(modData.Title or "Mod", {
								{Title = "Version", Description = modData.Version or "1.0.0"},
								{Title = "Status", Description = "Ready"}
							})

							-- 2. Create and Force the Action Button
							local ActionBtn = Instance.new("TextButton")
							ActionBtn.Name = "ModInstallButton"
							ActionBtn.Size = UDim2.new(0, 80, 0, 24)
							-- Positioned to be clearly visible on the right side of the card
							ActionBtn.Position = UDim2.new(1, -10, 0, 8)
							ActionBtn.AnchorPoint = Vector2.new(1, 0)
							ActionBtn.BackgroundColor3 = AccentColor -- Using the local safe variable
							ActionBtn.BorderSizePixel = 0
							ActionBtn.Text = "Install"
							ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
							ActionBtn.Font = Enum.Font.GothamBold
							ActionBtn.TextSize = 11
							ActionBtn.ZIndex = 50 
							ActionBtn.Parent = Card

							local Corner = Instance.new("UICorner")
							Corner.CornerRadius = UDim.new(0, 4)
							Corner.Parent = ActionBtn

							-- 3. UI Update Helper
							local function UpdateUI(status, btnText, color)
								ActionBtn.Text = btnText
								ActionBtn.BackgroundColor3 = color or AccentColor
								Methods:Update({
									{Title = "Version", Description = modData.Version},
									{Title = "Status", Description = status}
								})
							end

							-- 4. Set Initial State
							if RunningMods[modData.Title] then
								if RunningMods[modData.Title].Version ~= modData.Version then
									UpdateUI("Update", "Update", Color3.fromRGB(0, 180, 100))
								else
									UpdateUI("Active", "Disable", Color3.fromRGB(180, 50, 50))
								end
							end

							-- 5. Click Handling with nil-checks
							ActionBtn.MouseButton1Click:Connect(function()
								local Active = RunningMods[modData.Title]

								-- Handle Update cleanup
								if Active and Active.Version ~= modData.Version then
									if Active.Instance and Active.Instance.Stop then pcall(Active.Instance.Stop) end
									Active = nil
									RunningMods[modData.Title] = nil
								end

								if not RunningMods[modData.Title] then
									-- Try to Load
									local modCode, err = loadstring(modData.Script)
									if modCode then
										local s, instance = pcall(modCode)
										if s then
											RunningMods[modData.Title] = {Instance = instance, Version = modData.Version}
											UpdateUI("Active", "Disable", Color3.fromRGB(180, 50, 50))
										else
											warn("Mod Runtime Error: " .. tostring(instance))
										end
									else
										warn("Mod Syntax Error: " .. tostring(err))
									end
								else
									-- Disable
									if Active and Active.Instance and Active.Instance.Stop then 
										pcall(Active.Instance.Stop) 
									end
									RunningMods[modData.Title] = nil
									UpdateUI("Ready", "Install", AccentColor)
								end
							end)
						end
					end
				end
			end
		end)
	end

	task.defer(function()
		self:InitializeMods(Window)
	end)

	return windowFunctions
end

return lib

