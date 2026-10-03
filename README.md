# coi_railway — Railway (VORP / RedM)

## Phase 1 (current): ambient passenger train
- One passenger consist (`0xCD2C7CA1`, engine + coaches) spawns on the rails
  and loops the track circuit continuously.
- **Live blip**: entity-attached "Passenger Train" blip, created per client,
  so it tracks the moving train on radar + pause map.
- **Locked loco + pilot**: doors locked for all players, enter/drive controls
  blocked near the cab, driver kicked out of seat `-1`, conductor invincible +
  undraggable (same pattern as `coi_train_rob` robbery train).
- Server elects a single spawner (first requester, 30s pending guard);
  late joiners sync to the running train via net id. Spawner drop frees the
  slot; watchdog respawns after `Config.RespawnDelay`.
- `SetRandomTrains(false)` suppresses Rockstar ambient trains.

## Install
1. Copy `coi_railway` into `resources/`.
2. In `server.cfg` / `resources.cfg` (after VORP):
   ```
   ensure coi_railway
   ```
3. Optional admin ACE for reset:
   ```
   add_ace group.admin coi_railway.admin allow
   ```

## Test
1. Start server, join, wait ~8s → "Passenger service running."
2. Check radar/map for the moving **Passenger Train** blip.
3. `/railway_tp` → teleport to the train, confirm it is rolling.
4. Try to enter/drive it → blocked, doors locked.
5. `/railway_state` → train active true/false.
6. `/railway_delete` → removes local train (testing).
7. `/railway_reset` (needs ACE) → wipes service, next requester respawns.
8. Server console: `railway_state`, `railway_reset`.

## Tune (`config.lua`)
- `TrainSpawn.coords` / `Train.direction` — flip `direction` if it loops wrong way.
- `Train.cruiseSpeed` / `maxSpeed`.
- `TrainBlip` name/sprite/scale, `RespawnDelay`, `DisableRandomTrains`.

## Later phases (not in Phase 1)
- Stations, stops, boarding, tickets, driver jobs, freight, robbery hooks.
