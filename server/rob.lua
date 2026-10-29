-- Server side of passenger robbing. The server rolls the amount, so a client can never choose it.

local VORPcore = {}
TriggerEvent("getCore", function (core)
	VORPcore = core
end)

local lastRob = {}      -- source -> GetGameTimer() of their last rob
local robbedNet = {}    -- net id -> true

local function nearAnyTrain(src)
	local ped = GetPlayerPed(src)
	if not ped or ped == 0 then return false end
	local pcoords = GetEntityCoords(ped)
	local nets = GetTrainNets()
	for i = 1, 3 do
		local net = nets[i]
		if net then
			local ent = NetworkGetEntityFromNetworkId(net)
			if ent and ent ~= 0 and DoesEntityExist(ent) and #(GetEntityCoords(ent) - pcoords) <= Config.Rob.MaxTrainDistance then
				return true
			end
		end
	end
	return false
end

RegisterServerEvent("coi_railway:server:RobPassenger", function (pedNet)
	local src = source
	local now = GetGameTimer()
	if lastRob[src] and now - lastRob[src] < Config.Rob.Cooldown then return end
	if not nearAnyTrain(src) then return end
	if type(pedNet) == "number" then
		if robbedNet[pedNet] then return end
		robbedNet[pedNet] = true
		TriggerClientEvent("coi_railway:client:Robbed", -1, pedNet)
	end
	local user = VORPcore.getUser(src)
	if not user then return end
	local character = user.getUsedCharacter
	if not character then return end

	lastRob[src] = now
	local amount = math.random(Config.Rob.MinMoney, Config.Rob.MaxMoney)
	character.addCurrency(0, amount)
	TriggerClientEvent("vorp:TipRight", src, ("You robbed $%d from the passenger"):format(amount), 4000)
	print(("[coi_railway] %s robbed a passenger for $%d"):format(GetPlayerName(src), amount))
end)

AddEventHandler("playerDropped", function ()
	lastRob[source] = nil
end)

-- net ids get reused after peds despawn, so forget them regularly
CreateThread(function ()
	while true do
		Wait(10 * 60 * 1000)
		robbedNet = {}
		TriggerClientEvent("coi_railway:client:ClearRobbed", -1)
	end
end)
