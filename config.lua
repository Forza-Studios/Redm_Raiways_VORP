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
    maxSpeed = 15.0,
}

-- true = stop Rockstar ambient trains so only this one runs
Config.DisableRandomTrains = false

-- Live moving blip that follows the train on the map / minimap
Config.Blip = {
    name = "Passenger Train",
    blipHash = 1664425300,
    sprite = -250506368, -- train icon
    scale = 1.0,
}
