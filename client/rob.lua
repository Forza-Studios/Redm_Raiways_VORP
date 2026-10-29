-- Rob train passengers: stand next to a passenger and press ENTER.
-- The payout is rolled and validated on the server (server/rob.lua), never by the client.

local ENTER = 0xC7B5340A -- INPUT_FRONTEND_ACCEPT (Enter / Numpad Enter)

local passengerModels = {}
for _, name in ipairs(Config.Rob.PassengerModels) do
	passengerModels[joaat(name)] = true
end

local robbed = {}       -- local ped handle -> true
local robbedNet = {}    -- net id -> true (synced from the server so nobody can rob the same ped twice)
local promptGroup = GetRandomIntInRange(0, 0xffffff)
local robPrompt
local busy = false

local function createPrompt()
	robPrompt = PromptRegisterBegin()
	PromptSetControlAction(robPrompt, ENTER)
	PromptSetText(robPrompt, CreateVarString(10, "LITERAL_STRING", Config.Rob.PromptText))
	PromptSetEnabled(robPrompt, true)
	PromptSetVisible(robPrompt, true)
	PromptSetStandardMode(robPrompt, true)
	PromptSetGroup(robPrompt, promptGroup)
	PromptRegisterEnd(robPrompt)
end

local function pedNetId(ped)
	if NetworkGetEntityIsNetworked(ped) then
		return NetworkGetNetworkIdFromEntity(ped)
	end
end

local function isRobbed(ped)
	if robbed[ped] then return true end
	local net = pedNetId(ped)
	return net ~= nil and robbedNet[net] == true
end

-- closest robbable passenger within reach, or nil
local function findTarget(playerPed, coords)
	local best, bestDist
	local handle, ped = FindFirstPed()
	local ok = handle ~= -1
	while ok do
		if ped ~= playerPed and DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true)
			and passengerModels[GetEntityModel(ped)] and not isRobbed(ped) then
			local dist = #(GetEntityCoords(ped) - coords)
			if dist <= Config.Rob.Distance and (not bestDist or dist < bestDist) then
				best, bestDist = ped, dist
			end
		end
		ok, ped = FindNextPed(handle)
	end
	EndFindPed(handle)
	return best
end

-- scared reaction: cower + a line of dialog shown on screen
local function scarePassenger(ped)
	if not DoesEntityExist(ped) then return end
	local scenario = joaat(Config.Rob.ScareScenario)
	TaskStartScenarioInPlace(ped, scenario, -1, true, false, false, false)
	if Config.Rob.SpeechLines and #Config.Rob.SpeechLines > 0 and Config.Rob.SpeechVoice then
		-- optional audio line, only used when you fill Config.Rob.SpeechLines / SpeechVoice
		local line = Config.Rob.SpeechLines[math.random(#Config.Rob.SpeechLines)]
		PlayPedAmbientSpeechNative(ped, line, Config.Rob.SpeechVoice, "SPEECH_PARAMS_FORCE", 0, 0)
	end
	local text = Config.Rob.ScaredLines[math.random(#Config.Rob.ScaredLines)]
	TriggerEvent("vorp:TipRight", text, 3500)
end

CreateThread(function ()
	createPrompt()
	while true do
		local wait = 500
		if not busy then
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)
			local target = findTarget(playerPed, coords)
			if target then
				wait = 0
				PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, "LITERAL_STRING", Config.Rob.GroupText))
				if PromptHasStandardModeCompleted(robPrompt, 0) then
					busy = true
					robbed[target] = true
					scarePassenger(target)
					TriggerServerEvent("coi_railway:server:RobPassenger", pedNetId(target))
					Wait(Config.Rob.Cooldown)
					busy = false
				end
			end
		end
		Wait(wait)
	end
end)

RegisterNetEvent("coi_railway:client:Robbed", function (net)
	robbedNet[net] = true
end)

RegisterNetEvent("coi_railway:client:ClearRobbed", function ()
	robbedNet = {}
end)

AddEventHandler("onResourceStop", function (resourceName)
	if GetCurrentResourceName() == resourceName and robPrompt then
		PromptDelete(robPrompt)
	end
end)
