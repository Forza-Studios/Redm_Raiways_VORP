-- coi_passenger_train | spawns one passenger train and keeps it running
local passengerTrain = nil
local trainBlip = nil

local function BlipForEntity(style, entity)
    if BlipAddForEntity then
        return BlipAddForEntity(style, entity)
    end
    return Citizen.InvokeNative(0x23F74C2FDA6E7C61, style, entity)
end

local function AttachTrainBlip(train)
    if trainBlip and DoesBlipExist(trainBlip) then RemoveBlip(trainBlip) end
    trainBlip = nil
    local B = Config.Blip
    if not B or not train or not DoesEntityExist(train) then return end
    trainBlip = BlipForEntity(B.blipHash or 1664425300, train)
    if trainBlip then
        if SetBlipSprite then
            SetBlipSprite(trainBlip, B.sprite, true)
        else
            Citizen.InvokeNative(0x74F74D3207ED525C, trainBlip, B.sprite, true)
        end
        if SetBlipName then
            SetBlipName(trainBlip, B.name or "Passenger Train")
        else
            Citizen.InvokeNative(0x9CB1A1623062F402, trainBlip, B.name or "Passenger Train")
        end
        if SetBlipScale then
            SetBlipScale(trainBlip, B.scale or 1.0)
        else
            Citizen.InvokeNative(0xD387445136465429, trainBlip, B.scale or 1.0)
        end
    end
end

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
    if trainBlip and DoesBlipExist(trainBlip) then RemoveBlip(trainBlip) end
    trainBlip = nil

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
    AttachTrainBlip(train)

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

    -- Respawn if it gets deleted / despawned, re-attach blip if lost
    while true do
        Wait(10000)
        if not passengerTrain or not DoesEntityExist(passengerTrain) then
            SpawnPassengerTrain()
        elseif not trainBlip or not DoesBlipExist(trainBlip) then
            AttachTrainBlip(passengerTrain)
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
    if trainBlip and DoesBlipExist(trainBlip) then RemoveBlip(trainBlip) end
    trainBlip = nil
    if passengerTrain and DoesEntityExist(passengerTrain) then
        SetEntityAsMissionEntity(passengerTrain, true, true)
        DeleteVehicle(passengerTrain)
    end
    passengerTrain = nil
end)
