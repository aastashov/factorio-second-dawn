-- Epoch 5 and the finale: plastic, circuits, instrument board, rocket fuel, low density structure, control
-- unit; charge V against wave 15; a rocket silo with 30 parts launches; the suited character by the silo
-- flies to the Moon, the unsuited one stays; air runs down and an oxygen tank refills it; the emitter's
-- pulse; dismantling the emitter wins, stops the waves, and the crew comes home.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end
local force = "player"
script.on_init(function() storage.t = {} end)
local function make(name, x, y, recipe)
  return game.surfaces.nauvis.create_entity{name = name, position = {x, y}, force = force, recipe = recipe, raise_built = true}
end
local function put(e, items, fluids)
  local inv = e.get_inventory(defines.inventory.crafter_input)
  for _, it in pairs(items or {}) do inv.insert{name = it[1], count = it[2]} end
  for _, f in pairs(fluids or {}) do e.insert_fluid{name = f[1], amount = f[2]} end
end
local function out(e, name) return e.get_output_inventory().get_item_count(name) end
local function moon() return remote.call("second-dawn", "moon") end

local steps = {
  [2] = function()
    local s, T = game.surfaces.nauvis, storage.t
    local f = game.forces[force]
    for name, r in pairs(f.recipes) do if name:find("^sd%-") then r.enabled = true end end
    for _, t in pairs(f.technologies) do if t.name:find("^sd%-") then t.researched = true end end
    local X, Y = -300, 300
    s.request_to_generate_chunks({X, Y}, 3); s.force_generate_chunk_requests()
    local tiles = {}
    for x = -45, 45 do for y = -45, 45 do tiles[#tiles + 1] = {name = "grass-1", position = {X + x, Y + y}} end end
    s.set_tiles(tiles)
    for _, e in pairs(s.find_entities_filtered{area = {{X - 45, Y - 45}, {X + 45, Y + 45}}}) do e.destroy() end
    local p = s.create_entity{name = "electric-energy-interface", position = {X, Y}, force = force}
    p.power_production = 1e8; p.electric_buffer_size = 1e9
    for x = -40, 40, 18 do for y = -40, 40, 18 do s.create_entity{name = "substation", position = {X + x, Y + y}, force = force} end end

    T.plastic = make("chemical-plant", X - 30, Y - 30, "sd-plastic");    put(T.plastic, {{"coal", 10}}, {{"petroleum-gas", 200}})
    T.circuit = make("assembling-machine-2", X - 24, Y - 30, "sd-circuit"); put(T.circuit, {{"plastic-bar", 10}, {"copper-cable", 30}, {"iron-plate", 10}})
    T.board = make("assembling-machine-2", X - 18, Y - 30, "sd-board");   put(T.board, {{"electronic-circuit", 6}, {"plastic-bar", 4}, {"sd-tungsten", 2}})
    T.fuel = make("chemical-plant", X - 12, Y - 30, "sd-rocket-fuel");    put(T.fuel, {{"sd-fuel-oil", 3}}, {{"light-oil", 100}})
    T.lds = make("assembling-machine-2", X - 6, Y - 30, "sd-low-density"); put(T.lds, {{"steel-plate", 4}, {"copper-plate", 10}, {"plastic-bar", 4}})
    T.cu = make("assembling-machine-2", X, Y - 30, "sd-control-unit");    put(T.cu, {{"electronic-circuit", 10}, {"sd-tungsten", 2}, {"plastic-bar", 2}})

    T.chamber = make("sd-revival-chamber-2", X + 25, Y - 25, "sd-revival-charge-5")
    put(T.chamber, {{"sd-rectified-bottle", 25}, {"sd-conc-acid-bottle", 25}, {"sd-ether-bottle", 15}, {"sd-control-unit", 5}})
    remote.call("second-dawn", "no_victory_screen")
    remote.call("second-dawn", "set_wave_count", 14)
    remote.call("second-dawn", "wave_in", 120)

    T.silo = make("rocket-silo", X, Y + 20)
    T.silo.rocket_parts = 30
    T.suited = s.create_entity{name = "character", position = {X + 6, Y + 28}, force = force}
    T.suited.get_inventory(defines.inventory.character_armor).insert{name = "sd-spacesuit"}
    T.suited.get_main_inventory().insert{name = "sd-oxygen-tank", count = 2}
    T.plain = s.create_entity{name = "character", position = {X - 6, Y + 28}, force = force}
  end,
  [1500] = function()
    local T = storage.t
    check("plastic from gas and coal", out(T.plastic, "plastic-bar") >= 4, out(T.plastic, "plastic-bar") .. "")
    check("electronic circuits", out(T.circuit, "electronic-circuit") >= 5, out(T.circuit, "electronic-circuit") .. "")
    check("instrument board", out(T.board, "sd-board") >= 2, out(T.board, "sd-board") .. "")
    check("rocket fuel", out(T.fuel, "rocket-fuel") >= 1, out(T.fuel, "rocket-fuel") .. "")
    check("low density structure", out(T.lds, "low-density-structure") >= 1, out(T.lds, "low-density-structure") .. "")
    check("control unit", out(T.cu, "sd-control-unit") >= 1, out(T.cu, "sd-control-unit") .. "")
    local st = remote.call("second-dawn", "state").forces[game.forces[force].index]
    check("wave 15 needs charge V", st and st.required == 5, serpent.line(st))
    check("rocket silo takes 30 parts", prototypes.entity["rocket-silo"].rocket_parts_required == 30)
  end,
  [108400] = function()
    local T = storage.t
    local st = remote.call("second-dawn", "state").forces[game.forces[force].index]
    check("charge V wakes the team", st == nil, serpent.line(st))
    check("the rocket is ready", T.silo.rocket_silo_status == defines.rocket_silo_status.rocket_ready)
    check("launch", T.silo.launch_rocket())
  end,
  [108400 + 1400] = function()
    local T = storage.t
    local m = moon()
    check("the suited character is on the Moon", T.suited.surface.name == "sd-moon", T.suited.surface.name)
    check("the unsuited one stayed home", T.plain.surface.name == "nauvis")
    check("the emitter stands 250-350 tiles away", m.emitter and math.sqrt(m.emitter.x ^ 2 + m.emitter.y ^ 2) >= 240, serpent.line(m.emitter))
    check("air is running down", m.crew[1] and m.crew[1].air < 300 and m.crew[1].air > 250, serpent.line(m.crew))
    remote.call("second-dawn", "set_air", T.suited.unit_number, 5)
  end,
  [108400 + 1600] = function()
    local T = storage.t
    local m = moon()
    check("an oxygen tank refills the air", m.crew[1] and m.crew[1].air > 100 and T.suited.get_main_inventory().get_item_count("sd-oxygen-tank") == 1,
      serpent.line(m.crew))
    T.suited.teleport({m.emitter.x + 6, m.emitter.y})
    T.pulses = m.pulses or 0
    remote.call("second-dawn", "moon_pulse_now")
  end,
  [108400 + 1700] = function()
    local T = storage.t
    local m = moon()
    check("the emitter pulses and hits whoever is near", (m.pulses or 0) > T.pulses and (m.hits or 0) >= 1, serpent.line({m.pulses, m.hits}))
    local emitter = game.surfaces["sd-moon"].find_entities_filtered{name = "sd-emitter"}[1]
    check("the emitter can't be damaged", emitter and not emitter.destructible)
    T.suited.mine_entity(emitter, true)
  end,
  [108400 + 1800] = function()
    local m = moon()
    check("dismantling the emitter wins", m.won, serpent.line({m.won}))
    check("no more waves", m.finished and remote.call("second-dawn", "state").waves.next_tick == nil)
  end,
  [108400 + 2500] = function()
    check("the crew is home", storage.t.suited.surface.name == "nauvis", storage.t.suited.surface.name)
    L("failures: " .. failures)
  end,
}
script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
