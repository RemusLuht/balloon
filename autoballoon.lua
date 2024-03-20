getgenv().MoneyPrinter = {
    toolName = "Slingshot",
    autoBalloons = true,

    sendWeb = true,
    webURL = "https://discord.com/api/webhooks/1219664843712495646/R8GVD7AkvB_eZZOcVIX6yjIRyX9QT6DtTyZ3S5xyDTe9mI5eBQD7bRXL50PDq6-OEmAJ",

	maybeCPUReducer = true,
}
repeat task.wait(1) until game.PlaceId ~= nil
repeat task.wait(1) until game:GetService("Players") and game:GetService("Players").LocalPlayer
repeat task.wait(1) until not game.Players.LocalPlayer.PlayerGui:FindFirstChild("__INTRO")

local LargeRAP = 11000; local SmallRAP = 2800
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = game:GetService("Players").LocalPlayer
local RepStor = game:GetService("ReplicatedStorage")
local Library = require(RepStor.Library)
local HRP = Player.Character.HumanoidRootPart
local saveMod = require(RepStor.Library.Client.Save)
local BreakMod = require(RepStor.Library.Client.BreakableCmds)
local Slingshot = getsenv(Player.PlayerScripts.Scripts.Game.Misc.Slingshot)
local RAPValues = getupvalues(require(RepStor.Library).DevRAPCmds.Get)[1]
hookfunction(require(game.ReplicatedStorage.Library.Client.PlayerPet).CalculateSpeedMultiplier, function() return 250 end)
function getInfo(name) return saveMod.Get()[name] end 
function getTool() return Player.Character:FindFirstChild("WEAPON_"..Player.Name, true) end
function equipTool(toolName) return Library.Network.Invoke(toolName.."_Toggle") end
function getCurrentZone() return Library["MapCmds"].GetCurrentZone() end
if game:IsLoaded() and getgenv().MoneyPrinter.maybeCPUReducer then
	local Lib = require(game.ReplicatedStorage.Library)

	function xTab(TABLE)
		for i,v in pairs(TABLE) do
			if type(v) == "function" then
				TABLE[i] = function(...) return end
			end
			if type(v) == "table" then
				xTab(v)
			end
		end
	end
	xTab(Lib.WorldFX)
	xTab(Lib.NotificationCmds.Item)

	for i,v in pairs(game:GetDescendants()) do
		if v:IsA("MeshPart") then
			v.MeshId = ""
		end
		if v:IsA("BasePart") or v:IsA("MeshPart") then
			v.Transparency = 1
		end
		if v:IsA("Texture") or v:IsA("Decal") then
			v.Texture = ""
		end
		if v:IsA("ParticleEmitter") then
			v.Lifetime = NumberRange.new(0)
			v.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,0)})
			v.Enabled = false
		end
		if v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("Trail") or v:IsA("Beam") then
			v.Enabled = false
		end
		if v:IsA("Highlight") then
			v.OutlineTransparency = 1
			v.FillTransparency = 1
		end
	end
end
function sendNotif(msg)
	local message = {content = msg}
	local jsonMessage = HttpService:JSONEncode(message)
	local success, webMessage = pcall(function() 
		HttpService:PostAsync(getgenv().MoneyPrinter.webURL, jsonMessage) 
	end)
	if not success then 
		local response = request({Url = getgenv().MoneyPrinter.webURL,Method = "POST",Headers = {["Content-Type"] = "application/json"},Body = jsonMessage})
	end
end
function getBalloonUID(zoneName) 
	for i,v in pairs(BreakMod.AllByZoneAndClass(zoneName, "Chest")) do
		if v:GetAttribute("OwnerUsername") == Player.Name and string.find(v:GetAttribute("BreakableID"), "Balloon Gift") then
			return v:GetAttribute("BreakableUID")
		elseif v:GetAttribute("OwnerUserName") ~= Player.Name and string.find(v:GetAttribute("BreakableID"), "Balloon Gift") then
			return "Skip"
		end
	end
end

function getTotalRAP(num)
	local suffixes = {"", "k", "m", "b"}
	local suffixInd = 1
	while num >= 1000 and suffixInd < #suffixes do
		num = num / 1000
		suffixInd = suffixInd + 1
	end
	local formattedNum
	if num % 1 == 0 then
		formattedNum = string.format("%d", num)
	else
		formattedNum = string.format("%.1f", num):gsub("%.?0+$", "")
	end
	return formattedNum .. suffixes[suffixInd]
end
-- AUTO ORB
local autoOrbConnection = nil
local autoLootBagConnection = nil
for i, v in workspace.__THINGS.Orbs:GetChildren() do
	Library.Network.Fire("Orbs: Collect",{tonumber(v.Name)})
	Library.Network.Fire("Orbs_ClaimMultiple",{[1]={[1]=v.Name}})
	task.wait()
	v:Destroy()
end
for i, v in workspace.__THINGS.Lootbags:GetChildren() do
	Library.Network.Fire("Lootbags_Claim",{v.Name})
	task.wait()
	v:Destroy()
end
autoOrbConnection = workspace.__THINGS.Orbs.ChildAdded:Connect(function(v)
	Library.Network.Fire("Orbs: Collect",{tonumber(v.Name)})
	Library.Network.Fire("Orbs_ClaimMultiple",{[1]={[1]=v.Name}})
	task.wait()
	v:Destroy()
end)
autoLootBagConnection = workspace.__THINGS.Lootbags.ChildAdded:Connect(function(v)
	Library.Network.Fire("Lootbags_Claim",{v.Name})
	task.wait()
	v:Destroy()
end)
local startBalloons = #workspace.__THINGS.BalloonGifts:GetChildren()
local startGifts = 0
local startLarge = 0
for i,v in pairs(getInfo("Inventory").Misc) do
	if startGifts ~= 0 and startLarge ~= 0 then break end
	if v.id == "Gift Bag" then
		startGifts = (v._am or 1)
	elseif v.id == "Large Gift Bag" then
		startLarge = (v._am or 1)
	end
end
local startTime = os.time()
while getgenv().MoneyPrinter.autoBalloons do task.wait()
	for _,Balloon in pairs(Library.Network.Invoke("BalloonGifts_GetActiveBalloons")) do task.wait(0.03)
		if Balloon.Id then
			while Library.Network.Invoke("BalloonGifts_GetActiveBalloons")[Balloon.Id] do task.wait(0.03)
				if not getTool() then equipTool(getgenv().MoneyPrinter.toolName) end
				local breakableId = getBalloonUID(getCurrentZone())
				if breakableId == "Skip" then break end
				if breakableId then
					HRP.CFrame = CFrame.new(Balloon.LandPosition)
					Library.Network.Fire("Breakables_PlayerDealDamage", breakableId)
				elseif not Balloon.Popped then
					HRP.CFrame = CFrame.new(Balloon.Position + Vector3.new(0,30,0))
					Slingshot.fireWeapon()
					Library.Network.Fire("BalloonGifts_BalloonHit", Balloon.Id)
				end
			end
		end
	end
	local currentTime = os.time()
	if getgenv().MoneyPrinter.sendWeb then
		sendNotif("```asciidoc\n[ "..Player.Name.." Earned ]\n‐ "..tostring(endGifts - startGifts).." Small :: "..tostring(getTotalRAP((endGifts - startGifts) * SmallRAP)).." \n‐ "..tostring(endLarge - startLarge).." Large :: "..tostring(getTotalRAP((endLarge - startLarge) * LargeRAP)).." \n\n[ Total / Server ]\n‐ "..tostring(endGifts).." Small :: "..tostring(getTotalRAP(endGifts * SmallRAP)).." \n‐ "..tostring(endLarge).." Large :: "..tostring(getTotalRAP(endLarge * LargeRAP)).." \n- took "..tostring(currentTime - startTime).." seconds \n- had "..tostring(startBalloons).." balloons\n```")
	end
	if #workspace.__THINGS.BalloonGifts:GetChildren() <= 1 then
		repeat
	end
end