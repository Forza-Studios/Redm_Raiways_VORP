-- coi_railway | Phase 1 client: looping passenger train + live blip
-- Pattern taken from coi_train_rob robbery train (proven on this server):
-- CreateMissionTrain spawn, wagon model preload, invincible locked-in
-- conductor, doors locked for all players, entity-attached blip per client.

local passengerTrain = nil
local conductor = nil
local trainBlip = nil
local spawnInProgress = false
local stateRequested = false

local function Dbg(msg)
    if Config.Debug then print("[coi_railway] " .. msg) end
end

RegisterNetEvent("coi_railway:client:notify", function(msg)
    if GetResourceState("vorp_core") == "started" then
        pcall(function()
            TriggerEvent("vorp:NotifyLeft",
                Config.Notify.title, msg,
                Config.Notify.dict, Config.Notify.icon,
                Config.Notify.duration, Config.Notify.color)
        end)
    end
    Dbg(msg)
end)

local function Notify(msg)
    TriggerEvent("coi_railway:client:notify", msg)
end

-- Suppress Rockstar ambient trains so only our consist runs.
CreateThread(function()
    Wait(2000)
    if Config.DisableRandomTrains and SetRandomTrains then
        pcall(SetRandomTrains, false)
    end
end)

-- ---------------------------------------------------------------- blips --

-- Blip helpers: prefer game globals (house style), fall back to raw hashes.
local function BlipForEntity(style, entity)
    if BlipAddForEntity then
        return BlipAddForEntity(style, entity)
    end
    return Citizen.InvokeNative(0x23F74C2FDA6E7C61, style, entity)
end

local function BlipName(blip, name)
    if SetBlipName then
        SetBlipName(blip, name)
    else
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, name)
    end
end

local function BlipSprite(blip, sprite)
    if SetBlipSprite then
        SetBlipSprite(blip, sprite, true)
    else
        Citizen.InvokeNative(0x74F74D3207ED525C, blip, sprite, true)
    end
end

local function BlipScale(blip, scale)
    if not blip or blip == 0 or not DoesBlipExist(blip) then return end
    if SetBlipScale then
        SetBlipScale(blip, scale)
    else
        Citizen.InvokeNative(0xD387445136465429, blip, scale)
    end
end

-- Live blip: entity-attached, so it tracks the moving train automatically.
local function AttachTrainBlip(train)
    if trainBlip and DoesBlipExist(trainBlip) then RemoveBlip(trainBlip) end
    local B = Config.TrainBlip
    trainBlip = BlipForEntity(B.blipHash, train)
    BlipSprite(trainBlip, B.sprite)
    BlipName(trainBlip, B.name)
    BlipScale(trainBlip, B.scale)
    Dbg("live train blip attached")
end

-- ---------------------------------------------------------------- spawn --

local function RequestWagonModels(trainHash)
    local wagons = Citizen.InvokeNative(0x635423D55CA84FC8, trainHash)
    for i = 0, wagons - 1 do
        local model = Citizen.InvokeNative(0x8DF5F6A19F99F0D5, trainHash, i)
        RequestModel(model)
        local timeout = 0
        while not HasModelLoaded(model) and timeout < 10000 do
            Wait(50)
            timeout = timeout + 50
        end
    end
end

local function LockConductor(driver, train)
    if not DoesEntityExist(driver) then return end
    conductor = driver
    SetEntityAsMissionEntity(driver, true, true)
    SetEntityInvincible(driver, true)
    SetEntityCanBeDamaged(driver, false)
    SetPedCanBeTargetted(driver, false)
    SetPedCanRagdoll(driver, false)
    SetBlockingOfNonTemporaryEvents(driver, true)
    pcall(SetPedCanBeDraggedOut, driver, false)
    pcall(SetPedStayInVehicleWhenJacked, driver, true)
    pcall(SetPedCanBeKnockedOffVehicle, driver, 1) -- KNOCKOFFVEHICLE_NEVER
    pcall(SetEntityProofs, driver, true, true, true, true, true, true, true, true)
    pcall(SetPedConfigFlag, driver, 26, true) -- cannot be dragged out
    NetworkRegisterEntityAsNetworked(driver)
    Dbg("conductor locked in cab")
end

local function StartTrainRolling(train)
    local T = Config.Train
    SetTrainSpeed(train, T.maxSpeed)
    SetTrainCruiseSpeed(train, T.cruiseSpeed)
    Citizen.InvokeNative(0x9F29999DFDF2AEB8, train, T.maxSpeed)
    Citizen.InvokeNative(0x4182C037AA1F0091, train, false)
    Citizen.InvokeNative(0x8EC47DD4300BF063, train, 0.0)
end

function SpawnPassengerTrain()
    if spawnInProgress then return end
    if passengerTrain and DoesEntityExist(passengerTrain) then return end
    spawnInProgress = true

    local T = Config.Train
    local spawn = Config.TrainSpawn
    RequestWagonModels(T.model)

    -- Snapped to nearest rail, no ambient passengers (param 6 = false).
    -- Same native + flags as the robbery train.
    local train = Citizen.InvokeNative(0xC239DBD9A57D2A71, T.model,
        spawn.coords.x, spawn.coords.y, spawn.coords.z, T.direction, false, true, true)

    local timeout = 0
    while (not DoesEntityExist(train) or train == 0) and timeout < 15000 do
        Wait(500)
        timeout = timeout + 500
    end

    if not DoesEntityExist(train) then
        spawnInProgress = false
        Notify("Train failed to spawn.")
        Dbg("CreateMissionTrain failed")
        return
    end

    passengerTrain = train

    -- Hold still during setup so carriages settle.
    SetTrainSpeed(train, 0.0)
    SetTrainCruiseSpeed(train, 0.0)

    -- Loco pilot: invincible, undraggable, locked in driver seat.
    local driver = GetPedInVehicleSeat(train, -1)
    timeout = 0
    while (not DoesEntityExist(driver)) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
        driver = GetPedInVehicleSeat(train, -1)
    end
    LockConductor(driver, train)

    -- Locked loco: nobody can enter / drive / hijack.
    SetVehicleDoorsLocked(train, 4)
    SetVehicleDoorsLockedForAllPlayers(train, true)

    NetworkRegisterEntityAsNetworked(train)
    local netId = NetworkGetNetworkIdFromEntity(train)
    local nTimeout = 0
    while (not NetworkDoesNetworkIdExist(netId)) and nTimeout < 5000 do
        Wait(100)
        nTimeout = nTimeout + 100
        netId = NetworkGetNetworkIdFromEntity(train)
    end
    if not NetworkDoesNetworkIdExist(netId) then
        spawnInProgress = false
        Notify("Train sync failed. Retry /railway_spawn.")
        Dbg("train net id never registered")
        return
    end
    SetNetworkIdExistsOnAllMachines(netId, true)
    if conductor and NetworkDoesNetworkIdExist(NetworkGetNetworkIdFromEntity(conductor)) then
        SetNetworkIdExistsOnAllMachines(NetworkGetNetworkIdFromEntity(conductor), true)
    end

    AttachTrainBlip(train)

    -- Roll: no endpoint in Phase 1, the consist loops the track circuit.
    StartTrainRolling(train)

    spawnInProgress = false
    TriggerServerEvent("coi_railway:server:registerTrain", netId)
    Notify("Passenger service running. Follow the train blip!")
    Dbg("passenger train spawned, looping, net=" .. tostring(netId))
end

local function DeleteLocalTrain()
    if trainBlip and DoesBlipExist(trainBlip) then RemoveBlip(trainBlip) end
    trainBlip = nil
    if conductor and conductor ~= 0 and DoesEntityExist(conductor) then
        SetEntityAsMissionEntity(conductor, true, true)
        DeletePed(conductor)
    end
    conductor = nil
    if passengerTrain and passengerTrain ~= 0 and DoesEntityExist(passengerTrain) then
        SetEntityAsMissionEntity(passengerTrain, true, true)
        DeleteVehicle(passengerTrain)
    end
    passengerTrain = nil
end

-- ---------------------------------------------------------------- protect --

-- Protect loco pilot + prevent driving / hijacking (robbery pattern).
CreateThread(function()
    while true do
        Wait(0)
        if passengerTrain and DoesEntityExist(passengerTrain) then
            local playerPed = PlayerPedId()

            SetVehicleDoorsLocked(passengerTrain, 4)
            SetVehicleDoorsLockedForAllPlayers(passengerTrain, true)

            -- Kick the player out if they somehow land in the driver seat.
            if GetPedInVehicleSeat(passengerTrain, -1) == playerPed then
                ClearPedTasksImmediately(playerPed)
                TaskLeaveVehicle(playerPed, passengerTrain, 16)
            end

            -- Near the cab: block enter/drive controls.
            local tCoords = GetEntityCoords(passengerTrain)
            if #(GetEntityCoords(playerPed) - tCoords) < 7.0 then
                DisableControlAction(0, 0xD9D0E1C0, true) -- INPUT_VEH_ENTER
                DisableControlAction(0, 0xCEEA424B, true) -- INPUT_VEH_DRIVE
                DisableControlAction(0, 0x7F8D09B8, true) -- INPUT_ENTER
            end

            -- Keep the pilot healthy, invincible and seated.
            if conductor and DoesEntityExist(conductor) then
                SetEntityInvincible(conductor, true)
                SetEntityCanBeDamaged(conductor, false)
                SetPedCanBeTargetted(conductor, false)
                SetPedCanRagdoll(conductor, false)
                SetBlockingOfNonTemporaryEvents(conductor, true)
                pcall(SetPedCanBeDraggedOut, conductor, false)
                pcall(SetPedStayInVehicleWhenJacked, conductor, true)
                pcall(SetPedCanBeKnockedOffVehicle, conductor, 1)

                if IsEntityDead(conductor) then
                    ResurrectPed(conductor)
                    SetEntityHealth(conductor, 1000)
                    ClearPedTasksImmediately(conductor)
                    SetPedIntoVehicle(conductor, passengerTrain, -1)
                end
            end
        else
            Wait(1000)
        end
    end
end)

-- Watchdog: train deleted / desynced -> ask server for a respawn slot.
CreateThread(function()
    while true do
        Wait(5000)
        if not spawnInProgress and (not passengerTrain or not DoesEntityExist(passengerTrain)) then
            -- Late-join sync first; server tells us to spawn only if no train exists.
            TriggerServerEvent("coi_railway:server:requestTrain")
            Wait(Config.RespawnDelay or 10000)
        end
    end
end)

-- ---------------------------------------------------------------- events --

-- Server confirms we are the spawner.
RegisterNetEvent("coi_railway:client:spawnTrain", function()
    SpawnPassengerTrain()
end)

-- Server says a train already runs: attach to it via net id.
RegisterNetEvent("coi_railway:client:syncTrain", function(trainNetId)
    if not trainNetId then return end
    if passengerTrain and DoesEntityExist(passengerTrain) then
        if not trainBlip or not DoesBlipExist(trainBlip) then
            AttachTrainBlip(passengerTrain)
        end
        return
    end
    local train = NetworkGetEntityFromNetworkId(trainNetId)
    local tries = 0
    while (not DoesEntityExist(train)) and tries < 30 do
        Wait(500)
        tries = tries + 1
        train = NetworkGetEntityFromNetworkId(trainNetId)
    end
    if DoesEntityExist(train) then
        passengerTrain = train
        AttachTrainBlip(train)
        Dbg("synced to passenger train net=" .. tostring(trainNetId))
    end
end)

RegisterNetEvent("coi_railway:client:clearTrain", function()
    DeleteLocalTrain()
    Dbg("train cleared by server")
end)

-- ---------------------------------------------------------------- boot --

local function RequestTrain()
    if stateRequested then
        TriggerServerEvent("coi_railway:server:requestTrain")
        return
    end
    stateRequested = true
    TriggerServerEvent("coi_railway:server:requestTrain")
end

RegisterNetEvent("vorp:SelectedCharacter", function()
    Wait(3000)
    RequestTrain()
end)

RegisterNetEvent("RSGCore:Client:OnPlayerLoaded", function()
    Wait(3000)
    RequestTrain()
end)

CreateThread(function()
    Wait(8000)
    RequestTrain()
end)

-- ---------------------------------------------------------------- debug --

RegisterCommand("railway_spawn", function()
    if passengerTrain and DoesEntityExist(passengerTrain) then
        Notify("Train already running.")
        return
    end
    TriggerServerEvent("coi_railway:server:requestTrain")
end, false)

RegisterCommand("railway_delete", function()
    DeleteLocalTrain()
    TriggerServerEvent("coi_railway:server:deleteTrain")
    Notify("Local train removed.")
end, false)

RegisterCommand("railway_tp", function()
    local target = passengerTrain
    if (not target or not DoesEntityExist(target)) and Config.TrainSpawn then
        SetEntityCoords(PlayerPedId(),
            Config.TrainSpawn.coords.x, Config.TrainSpawn.coords.y,
            Config.TrainSpawn.coords.z + 1.0, true, true, true, false)
        return
    end
    local c = GetEntityCoords(target)
    SetEntityCoords(PlayerPedId(), c.x + 5.0, c.y, c.z + 1.0, true, true, true, false)
end, false)

RegisterCommand("railway_state", function()
    local has = passengerTrain ~= nil and DoesEntityExist(passengerTrain)
    Notify("Train active: " .. tostring(has))
end, false)

RegisterCommand("railway_reset", function()
    TriggerServerEvent("coi_railway:server:resetTrain")
end, false)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    DeleteLocalTrain()
end)
