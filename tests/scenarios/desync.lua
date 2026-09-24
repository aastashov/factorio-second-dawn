-- Short wave cycle for heavy mode (tests/run-heavy.sh): the game is saved, loaded and compared every tick,
-- so all test state lives in storage. Charges are written straight into the chamber's tank.
local function L(s) log("SD-TEST " .. s) end
local function charge() storage.t.chamber.fluidbox[1] = {name = "sd-revival-charge-1", amount = 1} end
local function forces() return remote.call("second-dawn", "state").forces[game.forces.player.index] end

script.on_init(function()
  storage.t = {}
end)

script.on_event(defines.events.on_tick, function(e)
  local t = e.tick
  if t == 300 then
    local s = game.surfaces.nauvis
    storage.t.chamber = s.create_entity{name = "sd-revival-chamber", position = {300, 300}, force = "player", raise_built = true}
    charge()
    remote.call("second-dawn", "wave_in", 50)
  elseif t == 400 then
    L("charged wave: " .. serpent.line(forces()))
  elseif t == 600 then
    L("after wake: " .. serpent.line(forces()))
    remote.call("second-dawn", "wave_in", 50)
  elseif t == 700 then
    L("uncharged wave: " .. serpent.line(forces()))
    charge()
  elseif t == 800 then
    L("woken by chamber: " .. serpent.line(forces()))
  elseif t == 900 then
    local s = game.surfaces.nauvis
    s.request_to_generate_chunks({0, 0}, 10)
    s.force_generate_chunk_requests()
  elseif t == 1000 then
    -- read the first two notes found: ruins, recipes and caches go through save/load too
    local n = 0
    for unit in pairs(remote.call("second-dawn", "notes").entities) do
      remote.call("second-dawn", "read_note", unit, "player")
      n = n + 1
      if n == 12 then break end
    end
    local st = remote.call("second-dawn", "notes")
    L("notes: ruins " .. st.ruins .. ", caches " .. st.caches .. ", diary " .. #st.read[game.forces.player.index])
    charge()
  elseif t == 1100 then
    -- switching the chamber to charge II pours the tier I charge out
    game.forces.player.recipes["sd-revival-charge-2"].enabled = true
    storage.t.chamber.set_recipe("sd-revival-charge-2")
  elseif t == 1200 then
    L("tank after switching to charge II: " .. tostring(storage.t.chamber.fluidbox[1]))
    -- a wolf lair next to a chest; its wolves get provoked, then sent on a raid
    local s = game.surfaces.nauvis
    storage.t.lair = s.create_entity{name = "sd-wolf-lair", position = {300, 360}, force = "sd-wildlife"}
    storage.t.box = s.create_entity{name = "wooden-chest", position = {300, 400}, force = "player"}
    storage.t.char = s.create_entity{name = "character", position = {300, 345}, force = "player"}
  elseif t == 2600 then
    L("provoked lairs: " .. tostring(remote.call("second-dawn", "provoke", storage.t.char.position)))
    L("raids sent: " .. remote.call("second-dawn", "raid", "player", 1))
  elseif t == 3000 then
    L("chest after raid: " .. (storage.t.box.valid and storage.t.box.health or "destroyed"))
    remote.call("second-dawn", "wave_in", 30)
  elseif t == 3100 then
    L("lair frozen by the wave: " .. tostring(storage.t.lair.valid and storage.t.lair.disabled_by_script))
    -- a net thrown at the frozen lair
    local s = game.surfaces.nauvis
    s.create_entity{name = "sd-net-projectile", position = {300, 348}, target = storage.t.lair.position, speed = 0.3,
      source = storage.t.char.valid and storage.t.char or nil, force = "player"}
  elseif t == 3300 then
    L("kennel after the net: " .. game.surfaces.nauvis.count_entities_filtered{name = "sd-wolf-kennel"})
    -- climate: a kiln in the cold with a brazier, a workbench in the heat
    local s, D = game.surfaces.nauvis, settings.startup["sd-climate-distance"].value
    s.request_to_generate_chunks({0, -(D + 100)}, 1); s.request_to_generate_chunks({0, D + 100}, 1)
    s.force_generate_chunk_requests()
    local kiln = s.create_entity{name = "sd-kiln", position = {0, -(D + 100)}, force = "player", recipe = "sd-charcoal", raise_built = true}
    local brazier = s.create_entity{name = "sd-brazier", position = {3, -(D + 100)}, force = "player", raise_built = true}
    brazier.get_fuel_inventory().insert{name = "wood", count = 2}
    s.create_entity{name = "sd-workbench", position = {0, D + 100}, force = "player", recipe = "sd-clay-tablet", raise_built = true}
    storage.t.kiln = kiln
  elseif t == 3500 then
    L("cold kiln with a burning brazier disabled: " .. tostring(storage.t.kiln.disabled_by_script))
    -- a ship sailing to a pier
    local s, Y = game.surfaces.nauvis, -1100
    s.request_to_generate_chunks({0, Y}, 2); s.force_generate_chunk_requests()
    local tiles = {}
    for x = -60, 60 do for y = -3, 1 do tiles[#tiles + 1] = {name = "deepwater", position = {x, Y + y}} end end
    s.set_tiles(tiles)
    for x = -51, 51, 2 do s.create_entity{name = "sd-waterway-straight-rail", position = {x, Y + 1}, direction = defines.direction.east, force = "player"} end
    local pier = s.create_entity{name = "sd-pier", position = {45, Y + 3}, direction = defines.direction.east, force = "player"}
    pier.backer_name = "Pier"
    local tug = s.create_entity{name = "sd-tug", position = {-40, Y + 1}, direction = defines.direction.east, force = "player"}
    tug.get_fuel_inventory().insert{name = "coal", count = 10}
    tug.train.schedule = {current = 1, records = {{station = "Pier", wait_conditions = {{type = "time", ticks = 60}}}}}
    tug.train.manual_mode = false
    storage.t.tug = tug
  elseif t == 3900 then
    L("ship at the pier: " .. tostring(storage.t.tug.train.station and storage.t.tug.train.station.backer_name))
  end
end)
