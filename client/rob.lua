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

-- Real voice: the passenger screams / begs for help. Lines come from Config.Rob.SpeechLines
-- (names taken from the RDR2 speech-line database). A line is only used if the ped reports it can say it.
local function sayLine(ped)
	local lines = Config.Rob.SpeechLines
	local order = {}
	for i = 1, #lines do order[i] = lines[i] end
	for i = #order, 2, -1 do
		local k = math.random(i)
		order[i], order[k] = order[k], order[i]
	end
	local fallback = order[1]
	for _, line in ipairs(order) do
		-- 0x9D6DEC9791A4E501: can this ped say this speech line?
		local can = Citizen.InvokeNative(0x9D6DEC9791A4E501, ped, line, 0, 1, Citizen.ResultAsInteger())
		if can and can ~= 0 then
			fallback = line
			break
		end
	end
	if not fallback then return end
	-- PLAY_PED_AMBIENT_SPEECH_NATIVE(ped, speechName, speechParam): both are strings (citizenfx/natives)
	PlayPedAmbientSpeechNative(ped, fallback, Config.Rob.SpeechParam)
	if Config.Rob.Debug then
		print(("[coi_railway] passenger %d says %s"):format(ped, fallback))
	end
end

-- scared reaction: cower + scream / plead for help
local function scarePassenger(ped)
	if not DoesEntityExist(ped) then return end
	TaskStartScenarioInPlace(ped, joaat(Config.Rob.ScareScenario), -1, true, false, false, false)
	sayLine(ped)
	-- keep begging a couple of times while the ped is cowering
	CreateThread(function ()
		for _ = 1, Config.Rob.RepeatLines do
			Wait(Config.Rob.RepeatDelay)
			if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then return end
			sayLine(ped)
		end
	end)
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
					TriggerServerEvent("coi_railway:server:RobPassenger", pedNetId(target))
					local ok, err = pcall(scarePassenger, target)
					if not ok then print(("[coi_railway] scare reaction failed: %s"):format(err)) end
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
