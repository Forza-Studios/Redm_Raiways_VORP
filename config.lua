-- Simple passenger train spawner
-- Spawn point: 2727.1458, -1448.6500, 45.7874, 295.0960 (Saint Denis yard)

Config = {}

-- x, y, z + heading (heading kept for reference / tp command,
-- the train itself snaps to the nearest rail)
Config.Spawn = vector4(2727.1458, -1448.65, 45.7874, 295.0960)

Config.Train = {
    model = 0xCD2C7CA1, -- passenger consist (engine + coaches)
    direction = false,   -- flipped: runs opposite way along track
    cruiseSpeed = 15.0,
    maxSpeed = 20.0,
}

-- false = no one can drive / hijack the train (ride only), true = drivable
Config.AllowDrive = false

-- true = stop Rockstar ambient trains so only this one runs
-- keep true or an ambient train can block the line and force an "unscripted" halt
Config.DisableRandomTrains = true

-- Station where the train halts, then resumes after dwellTime
-- 1529.4327, 449.6300, 90.2318, 2.0233
Config.Station = {
    coords = vector3(1529.4327, 449.63, 90.2318),    --Emerald station
    slowRadius = 120.0, -- start slowing when within this distance
    slowSpeed = 4.0,    -- approach speed (was stopping late at 15-20 m/s and overshooting)
    stopRadius = 10.0,  -- halt when train nose is within this distance
    dwellTime = 15000,  -- ms to wait at platform before rolling again
    spawnClearRadius = 300.0, -- ignore station until this far from spawn (proves early halt is NOT station code)
}

Config.Debug = true

-- Live moving blip that follows the train on the map / minimap
Config.Blip = {
    name = "Passenger Train",
    blipHash = 1664425300,
    sprite = -250506368, -- train icon
    scale = 1.0,
}
