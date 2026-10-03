-- coi_railway | Phase 1 server: single-train registry + late-join sync
-- First requester becomes the spawner (RedM trains must spawn client-side).
-- Everyone else receives the train net id and attaches their own live blip.

local trainNetId = nil
local spawner = nil
local spawnGrantedAt = 0

local function Dbg(msg)
    if Config.Debug then print("[coi_railway] " .. msg) end
end

-- A client wants the train: spawn slot or sync to the running one.
RegisterNetEvent("coi_railway:server:requestTrain", function()
    local src = source
    if trainNetId then
        TriggerClientEvent("coi_railway:client:syncTrain", src, trainNetId)
        Dbg(("sent sync net=%s to %d"):format(tostring(trainNetId), src))
    elseif spawner and (os.time() - spawnGrantedAt) < 30 then
        -- Spawn already granted, waiting on registration. Hold; the
        -- watchdog will retry and pick up the sync once registered.
        Dbg(("spawn pending (holder %d), holding request from %d"):format(spawner, src))
    else
        spawner = src
        spawnGrantedAt = os.time()
        TriggerClientEvent("coi_railway:client:spawnTrain", src)
        Dbg("granted spawn slot to " .. tostring(src))
    end
end)

-- Spawner reports the networked train entity.
RegisterNetEvent("coi_railway:server:registerTrain", function(netId)
    local src = source
    if trainNetId then return end -- first registration wins
    trainNetId = tonumber(netId)
    spawner = src
    Dbg(("train registered net=%s by %d"):format(tostring(trainNetId), src))
end)

-- Manual delete (testing): clear registry, spawner re-spawns via watchdog.
RegisterNetEvent("coi_railway:server:deleteTrain", function()
    trainNetId = nil
    spawner = nil
    spawnGrantedAt = 0
    Dbg("train registry cleared (delete)")
end)

-- Admin / debug reset: clear local trains everywhere, next requester spawns.
RegisterNetEvent("coi_railway:server:resetTrain", function()
    local src = source
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then
        -- Non-admins just re-request; only ACE holders wipe the service.
        TriggerClientEvent("coi_railway:client:syncTrain", src, trainNetId)
        return
    end
    trainNetId = nil
    spawner = nil
    spawnGrantedAt = 0
    TriggerClientEvent("coi_railway:client:clearTrain", -1)
    print("[coi_railway] service reset, next requester will spawn the train")
end)

-- Spawner dropped before anyone re-registered: free the slot so the next
-- watchdog tick elects a new spawner instead of soft-locking.
AddEventHandler("playerDropped", function()
    local src = source
    if src == spawner then
        trainNetId = nil
        spawner = nil
        spawnGrantedAt = 0
        print("[coi_railway] spawner dropped, slot freed")
    end
end)

RegisterCommand("railway_reset", function(source)
    if source ~= 0 and not IsPlayerAceAllowed(source, Config.AdminAce) then return end
    trainNetId = nil
    spawner = nil
    spawnGrantedAt = 0
    TriggerClientEvent("coi_railway:client:clearTrain", -1)
    print("[coi_railway] service reset via console/ACE")
end, false)

RegisterCommand("railway_state", function(source)
    if source == 0 then
        print(("[coi_railway] trainNet=%s spawner=%s"):format(tostring(trainNetId), tostring(spawner)))
    end
end, false)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        trainNetId = nil
        spawner = nil
        spawnGrantedAt = 0
    end
end)
