-- coi_railway | Phase 1: ambient passenger train
-- Single looping passenger consist on the rails + live entity blip.
-- Loco is locked (doors locked for all players) and the pilot/conductor
-- is invincible + undraggable, same pattern as coi_train_rob robbery train.

Config = {}

-- Where the consist is created. Must be ON rails; the engine snaps to the
-- nearest track on spawn. Reuses the test-proven robbery spawn.
Config.TrainSpawn = {
    coords = vector3(-1250.7053, 533.2345, 93.3124),
    heading = 316.2449,
}

Config.Train = {
    model = 0xCD2C7CA1, -- passenger consist (engine + coaches)
    direction = true,    -- flip to false if it runs the wrong way round the loop
    cruiseSpeed = 12.0,
    maxSpeed = 12.0,
}

-- Live blip: attached to the train ENTITY so it moves with it on every client.
Config.TrainBlip = {
    name = "Passenger Train",
    blipHash = 1664425300,
    sprite = -250506368, -- train icon
    scale = 1.0,
}

-- If the train entity goes missing (deleted / desync), respawn after this.
Config.RespawnDelay = 10000 -- ms

-- Suppress Rockstar ambient trains so only our Phase 1 consist runs.
Config.DisableRandomTrains = true

Config.Notify = {
    title = "Railway",
    dict = "generic_textures",
    icon = "tick",
    duration = 4000,
    color = "COLOR_WHITE",
}

-- Admin ACE for /railway_reset. Set in server.cfg:
-- add_ace group.admin coi_railway.admin allow
Config.AdminAce = "coi_railway.admin"

Config.Debug = false
