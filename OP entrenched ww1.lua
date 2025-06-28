-- 📦 Final Script: Auto-Lock Aimbot + ESP + HealthBar + Dynamic FOV + Directional Line (Mobile Friendly)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local AimPart = "Head"
local TeamCheck = true
_G = {}
_G.AimRadius = 50

local ESPTable = {}
local LineTable = {}
local Target = nil

-- UI FOV Circle (Dynamic)
local circleGui = Instance.new("ScreenGui", game.CoreGui)
circleGui.IgnoreGuiInset = true
circleGui.Name = "FOV_Circle_GUI"

local circle = Instance.new("Frame", circleGui)
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.new(0.5, 0, 0.5, 0)
circle.Size = UDim2.new(0, _G.AimRadius * 2, 0, _G.AimRadius * 2)
circle.BackgroundTransparency = 1

local uicorner = Instance.new("UICorner", circle)
uicorner.CornerRadius = UDim.new(1, 0)

local circleStroke = Instance.new("UIStroke", circle)
circleStroke.Thickness = 2
circleStroke.Color = Color3.fromRGB(255, 0, 0)

-- Get Closest Target
local function IsVisible(part)
	local origin = Camera.CFrame.Position
	local direction = (part.Position - origin)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local result = workspace:Raycast(origin, direction, raycastParams)
	return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function GetClosestVisibleAliveTarget()
	local closest = nil
	local shortestDistance = _G.AimRadius
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(AimPart) then
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then continue end
			if TeamCheck and player.Team == LocalPlayer.Team then continue end

			local part = player.Character[AimPart]
			local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

			if onScreen then
				local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				if distance < shortestDistance and IsVisible(part) then
					shortestDistance = distance
					closest = part
				end
			end
		end
	end
	return closest
end

-- ESP
local function CreateESP(player)
	if ESPTable[player] then return end
	local box = Drawing.new("Square")
	box.Thickness = 1
	box.Filled = false
	box.Transparency = 1
	box.Visible = false

	local distanceText = Drawing.new("Text")
	distanceText.Size = 14
	distanceText.Center = true
	distanceText.Outline = true
	distanceText.Color = Color3.new(1, 1, 1)
	distanceText.Visible = false

	local healthBar = Drawing.new("Square")
	healthBar.Filled = true
	healthBar.Thickness = 0
	healthBar.Transparency = 1
	healthBar.Visible = false

	local healthText = Drawing.new("Text")
	healthText.Size = 8
	healthText.Center = true
	healthText.Outline = true
	healthText.Color = Color3.new(1, 1, 1)
	healthText.Visible = false

	ESPTable[player] = {
		box = box,
		distance = distanceText,
		healthBar = healthBar,
		healthText = healthText
	}
end

local function RemoveESP(player)
	if ESPTable[player] then
		for _, v in pairs(ESPTable[player]) do v:Remove() end
		ESPTable[player] = nil
	end
end

for _, player in pairs(Players:GetPlayers()) do
	if player ~= LocalPlayer then CreateESP(player) end
end
Players.PlayerAdded:Connect(function(p)
	if p ~= LocalPlayer then CreateESP(p) end
end)
Players.PlayerRemoving:Connect(RemoveESP)

-- Update
RunService.RenderStepped:Connect(function()
	Target = GetClosestVisibleAliveTarget()
	if Target then
		Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
		circleStroke.Color = Color3.fromRGB(0, 255, 0)
	else
		circleStroke.Color = Color3.fromRGB(255, 0, 0)
	end

	for _, player in pairs(Players:GetPlayers()) do
		local esp = ESPTable[player]
		if player ~= LocalPlayer and esp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
			local root = player.Character.HumanoidRootPart
			local human = player.Character:FindFirstChildOfClass("Humanoid")
			if human and human.Health > 0 and (not TeamCheck or player.Team ~= LocalPlayer.Team) then
				local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
				if onScreen then
					local sizeY = Camera:WorldToViewportPoint(root.Position + Vector3.new(2, 3, 0)).Y - Camera:WorldToViewportPoint(root.Position - Vector3.new(2, 3, 0)).Y
					local boxSize = Vector2.new(sizeY * 0.6, sizeY)
					local boxPos = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)
					esp.box.Size = boxSize
					esp.box.Position = boxPos
					esp.box.Color = IsVisible(player.Character[AimPart]) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					esp.box.Visible = true

					local dist = math.floor((root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
					esp.distance.Text = tostring(dist) .. " studs"
					esp.distance.Position = Vector2.new(pos.X, pos.Y + (boxSize.Y / 2) + 10)
					esp.distance.Visible = true

					local hpPercent = math.clamp(human.Health / human.MaxHealth, 0, 1)
					esp.healthBar.Size = Vector2.new(13 * hpPercent, 3)
					esp.healthBar.Position = Vector2.new(pos.X - 6.5, boxPos.Y - 7)
					esp.healthBar.Color = hpPercent > 0.7 and Color3.fromRGB(0,255,0) or (hpPercent > 0.4 and Color3.fromRGB(255,255,0) or Color3.fromRGB(255,0,0))
					esp.healthBar.Visible = true

					esp.healthText.Text = tostring(math.floor(hpPercent * 100)) .. "%"
					esp.healthText.Position = Vector2.new(pos.X, boxPos.Y - 7)
					esp.healthText.Visible = true
				else
					esp.box.Visible = false
					esp.distance.Visible = false
					esp.healthBar.Visible = false
					esp.healthText.Visible = false
				end
			else
				esp.box.Visible = false
				esp.distance.Visible = false
				esp.healthBar.Visible = false
				esp.healthText.Visible = false
			end
		end
	end

	-- Dynamic FOV
	if Target then
		local targetSize = Target.Size.Magnitude
		local distance = (Target.Position - Camera.CFrame.Position).Magnitude
		local newRadius = math.clamp((targetSize / distance) * 800, 5, 300)
		circle.Size = UDim2.new(0, newRadius * 2, 0, newRadius * 2)
	else
		circle.Size = UDim2.new(0, _G.AimRadius * 2, 0, _G.AimRadius * 2)
	end

	-- Directional Line
	for _, line in pairs(LineTable) do line:Remove() end
	table.clear(LineTable)
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
			local human = player.Character:FindFirstChildOfClass("Humanoid")
			if human.Health > 0 and (not TeamCheck or player.Team ~= LocalPlayer.Team) then
				local root = player.Character.HumanoidRootPart
				local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
				if onScreen then
					local line = Drawing.new("Line")
					line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
					line.To = Vector2.new(pos.X, pos.Y)
					line.Color = Color3.fromRGB(0, 255, 0)
					line.Thickness = 1
					line.Visible = true
					table.insert(LineTable, line)
				end
			end
		end
	end
end)
