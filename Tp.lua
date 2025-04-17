local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local root = chr:WaitForChild("HumanoidRootPart")
local humanoid = chr:WaitForChild("Humanoid")

-- Config
local teleportPosition = Vector3.new(-589, 3, 21961)
local seatSearchTime = 0.5
local seatScanMoment = 0.35
local seatRange = 2000 

-- Find closest seat in range
local function findClosestSeat(centerPos, range)
	local items = workspace:FindFirstChild("RuntimeItems")
	if not items then return nil end

	local closestSeat, closestDist = nil, math.huge
	for _, part in ipairs(items:GetChildren()) do
		local seat = part:FindFirstChild("Seat")
		if seat and seat:IsA("Seat") then
			local dist = (seat.Position - centerPos).Magnitude
			if dist < closestDist and dist <= range then
				closestSeat = seat
				closestDist = dist
			end
		end
	end
	return closestSeat
end

-- Step 1: Teleport to the fixed position
root.CFrame = CFrame.new(teleportPosition)
root.Anchored = true

-- Step 2: Wait and scan for seats nearby
task.wait(0.1)

-- Create a temporary invisible anchor part at the teleport position
local anchorPart = Instance.new("Part")
anchorPart.Size = Vector3.new(1, 1, 1)
anchorPart.Anchored = true
anchorPart.Transparency = 1
anchorPart.CanCollide = false
anchorPart.CFrame = CFrame.new(teleportPosition)
anchorPart.Parent = workspace

-- Step 3: Constant teleport loop to load RuntimeItems
local t0 = tick()
local closestSeat
while tick() - t0 < seatSearchTime do
	root.CFrame = anchorPart.CFrame

	if tick() - t0 >= seatScanMoment then
		closestSeat = findClosestSeat(teleportPosition, seatRange)
		if closestSeat then break end
	end

	RunService.Heartbeat:Wait()
end

anchorPart:Destroy()

-- Always unanchor after the loop, no matter what
root.Anchored = false

if not closestSeat then
	warn("No valid seat found near position.")
	return
end

-- Step 4: Sit logic
local seated = false
local timeout = 5
local startSit = tick()

while tick() - startSit < timeout and not seated do
	pcall(function()
		local seatPos = closestSeat.CFrame + Vector3.new(0, 5, 0)

		root.CFrame = seatPos
		chr:PivotTo(seatPos)

		if humanoid.SeatPart ~= closestSeat then
			closestSeat:Sit(humanoid)
		else
			seated = true
		end
	end)
	RunService.Heartbeat:Wait()
end
