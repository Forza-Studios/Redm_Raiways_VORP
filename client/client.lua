--######################### edit for VORP by: outsider ########################
local prompts = GetRandomIntInRange(0, 0xffffff)
local openmenu
local inmenu = false
local stops = Config.Stops
CURRENT_TRAIN = nil
local trainspawned = false
local trainrunning = false
local npcs = {}
local MenuData = exports.vorp_menu:GetMenuData()
local PlayerJob

AddEventHandler('vorp_menu:closemenu', function()
	if inmenu then
		inmenu = false
	end
end)

function InsertNpcs()
	for z, x in pairs(Config.RailroadNpc) do
		while not HasModelLoaded(GetHashKey(Config.RailroadNpc[z]["Model"])) do
			Wait(500)
			Modelrequest(GetHashKey(Config.RailroadNpc[z]["Model"]))
		end
		local npc = CreatePed(GetHashKey(Config.RailroadNpc[z]["Model"]), Config.RailroadNpc[z]["Pos"].x, Config.RailroadNpc[z]["Pos"].y, Config.RailroadNpc[z]["Pos"].z, Config.RailroadNpc[z]["Heading"], false, false, 0, 0)
		while not DoesEntityExist(npc) do
			Wait(300)
		end
		Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
		FreezeEntityPosition(npc, false)
		SetEntityInvincible(npc, true)
		TaskStandStill(npc, -1)
		Wait(100)
		SET_PED_RELATIONSHIP_GROUP_HASH(npc, GetHashKey(Config.RailroadNpc[z]["Model"]))
		SetEntityCanBeDamagedByRelationshipGroup(npc, false, GetHashKey("PLAYER"))
		SetEntityAsMissionEntity(npc, true, true)
		SetModelAsNoLongerNeeded(GetHashKey(Config.RailroadNpc[z]["Model"]))
		table.insert(npcs, { npc = npc, coords = x.Pos })
	end
end

Citizen.CreateThread(function()
	Citizen.Wait(5000)
	local str = Press
	openmenu = PromptRegisterBegin()
	PromptSetControlAction(openmenu, 0x760A9C6F) -- G
	str = CreateVarString(10, 'LITERAL_STRING', str)
	PromptSetText(openmenu, str)
	PromptSetEnabled(openmenu, 1)
	PromptSetVisible(openmenu, 1)
	PromptSetStandardMode(openmenu, 1)
	PromptSetHoldMode(openmenu, 1)
	PromptSetGroup(openmenu, prompts)
	Citizen.InvokeNative(0xC5F428EE08FA7F2C, openmenu, true)
	PromptRegisterEnd(openmenu)
end)



Citizen.CreateThread(function()
	InsertNpcs()
	while true do
		Citizen.Wait(0)

		local player = PlayerPedId()
		local sleep = true
		local playercoords = GetEntityCoords(player)


		if not inmenu then
		
				local dist = Vdist2(playercoords, Config.Location, true) --location
				if 2.0 > dist then
					sleep = false
					local label = CreateVarString(10, 'LITERAL_STRING', TrainPrompt)
					PromptSetActiveGroupThisFrame(prompts, label)
					if Citizen.InvokeNative(0xC92AC953F0A982AE, openmenu) then
						 TriggerServerEvent("get:PlayerJob") 
                                                 Wait(200)
						if PlayerJob == Config.Job then
						   inmenu = true
						   TrainMenu()
						end
					end
				end
			
		end
		if sleep then
			Citizen.Wait(500)
		end
	end
end)

function DeleteCurrentTrain()
	if CURRENT_TRAIN and DoesEntityExist(CURRENT_TRAIN) then
		DeleteEntity(CURRENT_TRAIN)
	end
	CURRENT_TRAIN = nil
	trainspawned = false
	trainrunning = false
end

function TrainMenu()
	MenuData.CloseAll()
	local elements = {}
	for _, e in ipairs(Config.Elements) do
		elements[#elements + 1] = e
	end
	-- always offer a stop/delete entry so you can remove the current train and spawn the next one
	elements[#elements + 1] = { label = "DELETE current train", value = 'delete', desc = "stop + delete train to spawn next" }

	MenuData.Open('default', GetCurrentResourceName(), 'railway_main',
		{
			title    = MenuTittle,
			subtext  = MenuSubTittle,
			align    = 'top-left',
			elements = elements,
		},

			function(data, menu)
			if (data.current.value == 'delete') then
				DeleteCurrentTrain()
				menu.close()
				TriggerEvent("vorp:TipRight", "train deleted, you can spawn next!", 3000)
			elseif data.current.info then
				-- generic: works for any number of trains (train_X, exp, legacy hashX)
				StartTrain(data.current.info)
			end
		
		end,


		function(data, menu)
			menu.close()

		end)
end

function StartTrain(hash)

	if trainspawned == false then
		SetRandomTrains(false)
		--requestmodel--
		local trainWagons = N_0x635423d55ca84fc8(hash)
		for wagonIndex = 0, trainWagons - 1 do
			local trainWagonModel = N_0x8df5f6a19f99f0d5(hash, wagonIndex)
			while not HasModelLoaded(trainWagonModel) do
				Citizen.InvokeNative(0xFA28FE3A6246FC30, trainWagonModel, 1)
				Citizen.Wait(100)
			end
		end
		--spawn train--
		local train = N_0xc239dbd9a57d2a71(hash, GetEntityCoords(PlayerPedId()), 0, 1, 1, 1)
		SetTrainSpeed(train, 0.0)
		local coords = GetEntityCoords(train)
		local trainV = vector3(coords.x, coords.y, coords.z)
		-- warp ped into train (valentine)
		DoScreenFadeOut(500)
		Wait(1000)
		Citizen.InvokeNative(0x203BEFFDBE12E96A, PlayerPedId(), -167.4587, 622.33398, 114.6397 - 1, 141.77737)
		Wait(1000)
		DoScreenFadeIn(500)
		SetModelAsNoLongerNeeded(train)
		--blip--
		local bliphash = -399496385
		local blip = Citizen.InvokeNative(0x23f74c2fda6e7c61, bliphash, train) -- blip for train
		SetBlipScale(blip, 1.5)
		CURRENT_TRAIN = train
		trainspawned = true
		trainrunning = true
		-- Lock driver seat when driving is disabled in config
		if Config.AllowDriving == false then
			SetVehicleDoorsLocked(train, 4)
			SetVehicleDoorsLockedForAllPlayers(train, true)
		end
	else
		TriggerEvent("vorp:TipRight", "train is already out, check map!", 3000)
	end

end

Citizen.CreateThread(function()
	while true do
		Wait(0)
		if trainrunning == true then
			for i = 1, #stops do
				local coords = GetEntityCoords(CURRENT_TRAIN)
				local trainV = vector3(coords.x, coords.y, coords.z)
				local distance = #(vector3(stops[i]["x"], stops[i]["y"], stops[i]["z"]) - trainV)

				--speed--
				local stopspeed = 0.0
				local cruisespeed = 5.0
				local fullspeed = 15.0

				if distance < stops[i]["dst"] then
					SetTrainCruiseSpeed(CURRENT_TRAIN, cruisespeed)
					Wait(200)
					if distance < stops[i]["dst2"] then
						SetTrainCruiseSpeed(CURRENT_TRAIN, stopspeed)
						Wait(stops[i]["time"])
						TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 10, 'allaboard', 1.0)
						Wait(10000)
						SetTrainCruiseSpeed(CURRENT_TRAIN, cruisespeed)
						Wait(10000)
					end
				elseif distance > stops[i]["dst"] then
					SetTrainCruiseSpeed(CURRENT_TRAIN, fullspeed)
					Wait(25)
				end
			end
		end
	end
end)

RegisterNetEvent("send:PlayerJob")
AddEventHandler("send:PlayerJob", function(Job)
	PlayerJob = Job

end)
-- Protect driver seat when Config.AllowDriving == false (same pattern as coi_train_rob)
Citizen.CreateThread(function()
	while true do
		Wait(0)
		if Config.AllowDriving == false and trainspawned and CURRENT_TRAIN and DoesEntityExist(CURRENT_TRAIN) then
			local playerPed = PlayerPedId()
			-- keep locked for all players
			SetVehicleDoorsLocked(CURRENT_TRAIN, 4)
			SetVehicleDoorsLockedForAllPlayers(CURRENT_TRAIN, true)
			-- kick out of driver seat (-1) immediately, passengers still allowed
			if GetPedInVehicleSeat(CURRENT_TRAIN, -1) == playerPed then
				ClearPedTasksImmediately(playerPed)
				TaskLeaveVehicle(playerPed, CURRENT_TRAIN, 16)
			end
			-- block enter/drive prompts near the locomotive cab
			local tCoords = GetEntityCoords(CURRENT_TRAIN)
			if #(GetEntityCoords(playerPed) - tCoords) < 7.0 then
				DisableControlAction(0, 0xD9D0E1C0, true) -- INPUT_VEH_ENTER
				DisableControlAction(0, 0xCEEA424B, true) -- INPUT_VEH_DRIVE
				DisableControlAction(0, 0x7F8D09B8, true) -- INPUT_ENTER
			end
		else
			Wait(1000)
		end
	end
end)
-- delete all
AddEventHandler("onResourceStop", function(resourceName)
	if resourceName == GetCurrentResourceName() then
		if inmenu == true then
			PromptDelete(openmenu) -- delete prompt
			MenuData.CloseAll() --close menu
		end

		for _, v in pairs(npcs) do
			DeleteEntity(v.npc)
			DeletePed(v.npc)
			SetEntityAsNoLongerNeeded(v.npc)
		end

		DeleteEntity(CURRENT_TRAIN) --delete train
		trainspawned = false
		trainrunning = false
	end
end)

-- delete train
RegisterCommand('deletetrain', function()
	if PlayerJob == Config.Job then
		DeleteCurrentTrain()
	else
		TriggerEvent("vorp:TipRight", "no permission / open train menu first!", 3000)
	end
end)

-- reset train
RegisterCommand('resettrain', function()
	if PlayerJob == Config.Job then
		DeleteCurrentTrain()
		DoScreenFadeOut(500)
		Wait(1000)
		Citizen.InvokeNative(0x203BEFFDBE12E96A, PlayerPedId(), -163.1477, 637.15832, 114.03209 - 1, 337.03866) --tp back to valentine
		Wait(1000)
		DoScreenFadeIn(500)
	end
end)
