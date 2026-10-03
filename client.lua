-- coi_passenger_train | spawns one passenger train and keeps it running
local passengerTrain = nil

local function RequestWagonModels(trainHash)
    local count = Citizen.InvokeNative(0x635423D55CA84FC8, trainHash)
    for i = 0, count - 1 do
        local model = Citizen.InvokeNative(0x8DF5F6A19F99F0D5, trainHash, i)
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 10000 do
            Wait(50)
            timeout = timeout + 50
        end
    end
end

local function SpawnPassengerTrain()
    if passengerTrain and DoesEntityExist(passengerTrain) then
        SetEntityAsMissionEntity(passengerTrain, true, true)
        DeleteVehicle(passengerTrain)
        passengerTrain = nil
        Wait(500)
    end

    local T = Config.Train
    local s = Config.Spawn

    RequestWagonModels(T.model)

    local train = Citizen.InvokeNative(0xC239DBD9A57D2A71, T.model,
        s.x, s.y, s.z, T.direction, false, true, true)

    local timeout = 0
    while (not DoesEntityExist(train) or train == 0) and timeout < 15000 do
        Wait(500)
        timeout = timeout + 500
    end
    if not DoesEntityExist(train) then
        print("[coi_passenger_train] CreateMissionTrain failed")
        return
    end

    passengerTrain = train
    SetEntityAsMissionEntity(train, true, true)

    SetTrainSpeed(train, T.maxSpeed)
    SetTrainCruiseSpeed(train, T.cruiseSpeed)
    Citizen.InvokeNative(0x9F29999DFDF2AEB8, train, T.maxSpeed) -- _SET_TRAIN_MAX_SPEED
    Citizen.InvokeNative(0x4182C037AA1F0091, train, false) -- _SET_TRAIN_STOPS_FOR_STATIONS (false = keep running)
    Citizen.InvokeNative(0x8EC47DD4300BF063, train, 0.0) -- _SET_TRAIN_ACCELERATION

    print("[coi_passenger_train] passenger train running from " .. tostring(s))
end

CreateThread(function()
    Wait(2000)
    if Config.DisableRandomTrains and SetRandomTrains then
        pcall(SetRandomTrains, false)
    end
    SpawnPassengerTrain()

    -- Respawn if it gets deleted / despawned
    while true do
        Wait(10000)
        if not passengerTrain or not DoesEntityExist(passengerTrain) then
            SpawnPassengerTrain()
        end
    end
end)

-- /ptrain = respawn, /ptrain tp = respawn + teleport to start
RegisterCommand("ptrain", function(_, args)
    SpawnPassengerTrain()
    if args and args[1] == "tp" then
        local s = Config.Spawn
        SetEntityCoords(PlayerPedId(), s.x, s.y, s.z + 1.0, true, true, true, false)
    end
end, false)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if passengerTrain and DoesEntityExist(passengerTrain) then
        SetEntityAsMissionEntity(passengerTrain, true, true)
        DeleteVehicle(passengerTrain)
    end
    passengerTrain = nil
end)
