-- coi_passenger_train | spawns one passenger train and keeps it running
local passengerTrain = nil
local trainBlip = nil
local spawnTime = 0
local stationHold = false -- true only while we intentionally hold at the platform

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

    -- Lock drive seat at spawn when driving is disabled
    if not Config.AllowDrive then
        SetVehicleDoorsLocked(train, 4)
        SetVehicleDoorsLockedForAllPlayers(train, true)
        local driver = GetPedInVehicleSeat(train, -1)
        if driver and DoesEntityExist(driver) then
            SetEntityAsMissionEntity(driver, true, true)
            SetEntityInvincible(driver, true)
            SetBlockingOfNonTemporaryEvents(driver, true)
            pcall(SetPedCanBeDraggedOut, driver, false)
        end
    end

    SetTrainSpeed(train, T.maxSpeed)
    SetTrainCruiseSpeed(train, T.cruiseSpeed)
    Citizen.InvokeNative(0x9F29999DFDF2AEB8, train, T.maxSpeed) -- _SET_TRAIN_MAX_SPEED
    Citizen.InvokeNative(0x4182C037AA1F0091, train, false) -- _SET_TRAIN_STOPS_FOR_STATIONS (false = keep running)
    Citizen.InvokeNative(0x8EC47DD4300BF063, train, 0.0) -- _SET_TRAIN_ACCELERATION

    spawnTime = GetGameTimer()
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

-- Prevent driving / hijacking when Config.AllowDrive = false
CreateThread(function()
    while true do
        Wait(0)
        if not Config.AllowDrive and passengerTrain and DoesEntityExist(passengerTrain) then
            SetVehicleDoorsLocked(passengerTrain, 4)
            SetVehicleDoorsLockedForAllPlayers(passengerTrain, true)

            local playerPed = PlayerPedId()
            if GetPedInVehicleSeat(passengerTrain, -1) == playerPed then
                ClearPedTasksImmediately(playerPed)
                TaskLeaveVehicle(playerPed, passengerTrain, 16)
            end

            if #(GetEntityCoords(playerPed) - GetEntityCoords(passengerTrain)) < 7.0 then
                DisableControlAction(0, 0xD9D0E1C0, true) -- INPUT_VEH_ENTER
                DisableControlAction(0, 0xCEEA424B, true) -- INPUT_VEH_DRIVE
                DisableControlAction(0, 0x7F8D09B8, true) -- INPUT_ENTER
            end
        else
            Wait(1000)
        end
    end
end)

-- Station stop: slow early, halt at Config.Station, wait, then roll again
-- NOTE: spawn is ~2.2km from Emerald, so any halt in the first ~300m is
-- native AI (dead-end / ambient block / off-rail snap), NOT this thread.
CreateThread(function()
    local slowing = false
    local departing = false
    while true do
        Wait(500)
        if passengerTrain and DoesEntityExist(passengerTrain) and Config.Station then
            local S = Config.Station
            local T = Config.Train
            local slowRadius = S.slowRadius or 120.0
            local stopRadius = S.stopRadius or 10.0
            local slowSpeed = S.slowSpeed or 4.0
            local trainCoords = GetEntityCoords(passengerTrain)
            local d = #(trainCoords - S.coords)
            local spawnDist = #(trainCoords - vector3(Config.Spawn.x, Config.Spawn.y, Config.Spawn.z))

            -- guard: ignore station until clear of the yard
            if spawnDist >= (S.spawnClearRadius or 300.0) then
                if departing then
                -- ignore station until fully clear so we don't re-slow on pull-out
                if d > (slowRadius + 30.0) then
                    departing = false
                    slowing = false
                end
            elseif d < stopRadius then
                -- full halt at platform
                slowing = false
                stationHold = true
                if Config.Debug then print(("[coi_passenger_train] STATION hold at %.1fm"):format(d)) end
                SetTrainCruiseSpeed(passengerTrain, 0.0)
                SetTrainSpeed(passengerTrain, 0.0)
                Citizen.InvokeNative(0x3660BCAB3A6BB734, passengerTrain) -- stop
                Wait(S.dwellTime or 15000)
                if passengerTrain and DoesEntityExist(passengerTrain) then
                    SetTrainSpeed(passengerTrain, T.maxSpeed)
                    SetTrainCruiseSpeed(passengerTrain, T.cruiseSpeed)
                    Citizen.InvokeNative(0x9F29999DFDF2AEB8, passengerTrain, T.maxSpeed)
                    Citizen.InvokeNative(0x4182C037AA1F0091, passengerTrain, false)
                end
                stationHold = false
                departing = true
            elseif d < slowRadius then
                -- approach zone: ease down once, don't spam the native
                if not slowing then
                    slowing = true
                    if Config.Debug then print(("[coi_passenger_train] slowing for station at %.1fm"):format(d)) end
                    SetTrainCruiseSpeed(passengerTrain, slowSpeed)
                    Citizen.InvokeNative(0x9F29999DFDF2AEB8, passengerTrain, slowSpeed)
                end
            else
                -- outside approach: ensure full line speed
                if slowing then
                    slowing = false
                    SetTrainSpeed(passengerTrain, T.maxSpeed)
                    SetTrainCruiseSpeed(passengerTrain, T.cruiseSpeed)
                    Citizen.InvokeNative(0x9F29999DFDF2AEB8, passengerTrain, T.maxSpeed)
                end
                end
            end
        else
            Wait(2000)
        end
    end
end)

-- Watchdog: catches NATIVE (unscripted) halts and rolls again.
-- If speed is ~0 outside the station and we are NOT in stationHold, the game
-- stopped it (end-of-track / ambient block / obstacle) -> re-apply speed.
CreateThread(function()
    while true do
        Wait(5000)
        if passengerTrain and DoesEntityExist(passengerTrain) and not stationHold then
            local speed = GetEntitySpeed(passengerTrain)
            if speed < 0.5 then
                local d = #(GetEntityCoords(passengerTrain) - Config.Station.coords)
                if d > ((Config.Station and Config.Station.stopRadius or 10.0) + 20.0) then
                    if Config.Debug then print(("[coi_passenger_train] UNSCRIPTED halt detected (speed %.2f, %.0fm from station) - re-rolling"):format(speed, d)) end
                    local T = Config.Train
                    SetTrainSpeed(passengerTrain, T.maxSpeed)
                    SetTrainCruiseSpeed(passengerTrain, T.cruiseSpeed)
                    Citizen.InvokeNative(0x9F29999DFDF2AEB8, passengerTrain, T.maxSpeed)
                    Citizen.InvokeNative(0x4182C037AA1F0091, passengerTrain, false)
                end
            end
        else
            Wait(5000)
        end
    end
end)

-- Debug: live distance + speed readout
RegisterCommand("ptrain_dist", function()
    if not passengerTrain or not DoesEntityExist(passengerTrain) then
        print("[coi_passenger_train] no train")
        return
    end
    local tc = GetEntityCoords(passengerTrain)
    local dStation = #(tc - Config.Station.coords)
    local dSpawn = #(tc - vector3(Config.Spawn.x, Config.Spawn.y, Config.Spawn.z))
    print(("[coi_passenger_train] speed=%.2f stationDist=%.1f spawnDist=%.1f hold=%s"):format(
        GetEntitySpeed(passengerTrain), dStation, dSpawn, tostring(stationHold)))
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
