local spawned = false

local players = {}
local GraceUntil = 0
local pending = { east = 0, west = 0, tram = 0 }

local eastTrain
local eastConductor
local westTrain
local westConductor
local tram
local tramConductor

local switchBackup = {}

if Config.UseManualJunctions then
	for i = 1, #Config.SwitchObjects do
		switchBackup[i] = Config.SwitchObjects[i]
	end
end

RegisterServerEvent("BGS_Trains:server:CanSpawnTrain", function ()
	local src = source
	local canSpawn = false

	local known = false
	for _, p in ipairs(players) do
		if p == src then known = true break end
	end
	if not known then table.insert(players, src) end

	if not spawned then
		spawned = true
		canSpawn = true
		GraceUntil = GetGameTimer() + 60000 -- first spawn takes a while, don't watchdog it yet
	end

	Wait(1000)

	TriggerClientEvent("BGS_Trains:client:CanSpawnTrain", src, canSpawn)
end)

RegisterServerEvent("BGS_Trains:server:StoreNetIndex", function (trainNetIndex, driverNetIndex, trainArea)
	if trainArea == "east" then
		eastTrain = trainNetIndex
		eastConductor = driverNetIndex
	elseif trainArea == "west" then
		westTrain = trainNetIndex
		westConductor = driverNetIndex
	else
		tram = trainNetIndex
		tramConductor = driverNetIndex
	end
end)

RegisterServerEvent("BGS_Trains:server:GetTrainsFromServer", function ()
	local src = source
	TriggerClientEvent("BGS_Trains:client:GetTrainsFromServer", src, eastTrain, westTrain, tram, eastConductor, westConductor, tramConductor)
end)

RegisterServerEvent("BGS_Trains:server:AllPlayersGetTrainsFromServer", function ()
	for index, player in ipairs(players) do
		TriggerClientEvent("BGS_Trains:client:GetTrainsFromServer", player, eastTrain, westTrain, tram, eastConductor, westConductor, tramConductor)
	end
end)

AddEventHandler("playerDropped", function(reason)
	local _source = source
	for index, player in ipairs(players) do
		if player == _source then
			table.remove(players, index)
			break
		end
	end
	if #players < 1 then
		spawned = false
		if Config.UseEastTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(eastTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(eastConductor))
		end
		if Config.UseWestTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(westTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(westConductor))
		end
		if Config.UseTram then
			DeleteEntity(NetworkGetEntityFromNetworkId(tram))
			DeleteEntity(NetworkGetEntityFromNetworkId(tramConductor))
		end
		eastTrain, eastConductor, westTrain, westConductor, tram, tramConductor = nil, nil, nil, nil, nil, nil
		if Config.UseManualJunctions then
			for index, value in ipairs(Config.SwitchObjects) do
				value.enabled = switchBackup.enable
				value.pushed = false
				DeleteEntity(NetworkGetEntityFromNetworkId(value.switchObject))
			end
			for index, value in ipairs(Config.EastJunctions) do
				for index2, value2 in ipairs(switchBackup) do
					if value.junctionIndex == value2.junctionIndex and value.trainTrack == value2.trainTrack then
						value.enabled = value2.enabled
					end
				end
			end
		end
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
        spawned = false
		if Config.UseEastTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(eastTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(eastConductor))
		end
		if Config.UseWestTrain then
			DeleteEntity(NetworkGetEntityFromNetworkId(westTrain))
			DeleteEntity(NetworkGetEntityFromNetworkId(westConductor))
		end
		if Config.UseTram then
			DeleteEntity(NetworkGetEntityFromNetworkId(tram))
			DeleteEntity(NetworkGetEntityFromNetworkId(tramConductor))
		end
		eastTrain, eastConductor, westTrain, westConductor, tram, tramConductor = nil, nil, nil, nil, nil, nil
		players = {}
		if Config.UseManualJunctions then
			for index, value in ipairs(Config.SwitchObjects) do
				DeleteEntity(NetworkGetEntityFromNetworkId(value.switchObject))
			end
		end
	end
end)

-- Despawn stuck trains
CreateThread(function ()
	if not Config.UseWestTrain and not Config.UseEastTrain then
		return
	end
	local lastCoordsEast = vec3(0,0,0)
	local lastCoordsWest = vec3(0,0,0)
	local countEast = 0
	local countWest = 0
	while true do
		local coordsEast
		local coordsWest
		Wait(10000)
		if eastTrain and #players > 0 then
			coordsEast = GetEntityCoords(NetworkGetEntityFromNetworkId(eastTrain))
			if lastCoordsEast ~= coordsEast then
				lastCoordsEast = coordsEast
				countEast = 0
			else
				countEast = countEast + 1
			end
			if countEast == Config.TrainDespawnTimer*6 then
				countEast = 0
				DeleteEntity(NetworkGetEntityFromNetworkId(eastTrain))
				DeleteEntity(NetworkGetEntityFromNetworkId(eastConductor))
				eastTrain, eastConductor = nil, nil
				pending.east = GetGameTimer() + 30000
				TriggerClientEvent("BGS_Trains:client:ResetTrain", players[#players], "east")
			end
		else
			lastCoordsEast = vec3(0,0,0)
			countEast = 0
		end
		if westTrain and #players > 0 then
			coordsWest = GetEntityCoords(NetworkGetEntityFromNetworkId(westTrain))
			if lastCoordsWest ~= coordsWest then
				lastCoordsWest = coordsWest
				countWest = 0
			else
				countWest = countWest + 1
			end
			if countWest == Config.TrainDespawnTimer*6 then
				countWest = 0
				DeleteEntity(NetworkGetEntityFromNetworkId(westTrain))
				DeleteEntity(NetworkGetEntityFromNetworkId(westConductor))
				westTrain, westConductor = nil, nil
				pending.west = GetGameTimer() + 30000
				TriggerClientEvent("BGS_Trains:client:ResetTrain", players[#players], "west")
			end
		else
			lastCoordsWest = vec3(0,0,0)
			countWest = 0
		end
	end
end)

-- Watchdog + blip sync: keeps every train alive 24/7 while players are online and
-- gives all clients the same train positions for their blips.
local function liveEntity(net)
	if not net then return nil end
	local ent = NetworkGetEntityFromNetworkId(net)
	if ent and ent ~= 0 and DoesEntityExist(ent) then return ent end
	return nil
end

CreateThread(function ()
	while true do
		Wait(2000)

		-- drop players that are gone
		for i = #players, 1, -1 do
			if not GetPlayerName(players[i]) then table.remove(players, i) end
		end

		if #players > 0 and spawned then
			local areas = {
				{ name = "east", use = Config.UseEastTrain, net = eastTrain },
				{ name = "west", use = Config.UseWestTrain, net = westTrain },
				{ name = "tram", use = Config.UseTram,      net = tram },
			}
			local payload = {}
			local now = GetGameTimer()
			for _, a in ipairs(areas) do
				if a.use then
					local ent = liveEntity(a.net)
					if ent then
						local c = GetEntityCoords(ent)
						payload[a.name] = { net = a.net, x = c.x, y = c.y, z = c.z }
					elseif now > GraceUntil and now > pending[a.name] then
						-- train vanished: have one online player respawn it
						pending[a.name] = now + 30000
						if a.name == "east" then eastTrain, eastConductor = nil, nil
						elseif a.name == "west" then westTrain, westConductor = nil, nil
						else tram, tramConductor = nil, nil end
						TriggerClientEvent("BGS_Trains:client:ResetTrain", players[#players], a.name)
					end
				end
			end
			for _, p in ipairs(players) do
				TriggerClientEvent("BGS_Trains:client:SyncBlips", p, payload)
			end
		end
	end
end)

-- used by server/rob.lua
function GetTrainNets()
	return { eastTrain, westTrain, tram }
end
