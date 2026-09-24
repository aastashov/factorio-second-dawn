-- Climate: belt tiles and resources by latitude; in the cold an unheated kiln stops, a burning brazier
-- keeps it going, a brazier out of fuel lets it freeze again; in the heat an uncooled workbench makes
-- about half of what a cooled one makes; a character loses health without the right clothing.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end
local D = settings.startup["sd-climate-distance"].value
local force = "player"
script.on_init(function() storage.t = {} end)

local function ground(s, cx, cy, r)
  s.request_to_generate_chunks({cx, cy}, math.ceil(r / 32) + 1); s.force_generate_chunk_requests()
  local tiles = {}
  for x = -r, r do for y = -r, r do tiles[#tiles + 1] = {name = "grass-1", position = {cx + x, cy + y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{cx - r, cy - r}, {cx + r, cy + r}}}) do e.destroy() end
end
local function make(name, pos, recipe)
  return game.surfaces.nauvis.create_entity{name = name, position = pos, force = force, recipe = recipe, raise_built = true}
end
local function input(e) return e.get_inventory(defines.inventory.crafter_input) end

local steps = {
  [2] = function()
    local s, T = game.surfaces.nauvis, storage.t
    for _, y in pairs{-(D + 500), 0, D + 500} do
      for _, x in pairs{-760, 0, 760} do s.request_to_generate_chunks({x, y}, 12) end
    end
    s.force_generate_chunk_requests()
    local function band(y) return {{-380, y - 380}, {380, y + 380}} end
    local snow_n, snow_s = s.count_tiles_filtered{name = "sd-snow", area = band(-(D + 500))}, s.count_tiles_filtered{name = "sd-snow", area = band(D + 500)}
    local dunes_s, dunes_n = s.count_tiles_filtered{name = "sd-dunes", area = band(D + 500)}, s.count_tiles_filtered{name = "sd-dunes", area = band(-(D + 500))}
    check("snow only in the north", snow_n > 100000 and snow_s == 0, snow_n .. " north, " .. snow_s .. " south")
    check("dunes only in the south", dunes_s > 100000 and dunes_n == 0, dunes_s .. " south, " .. dunes_n .. " north")
    check("no belt tiles at the camp", s.count_tiles_filtered{name = {"sd-snow", "sd-dunes"}, area = band(0)} == 0)
    local function count(name, y) return s.count_entities_filtered{name = name, area = {{-1140, y - 380}, {1140, y + 380}}} end
    check("tungsten only in the cold", count("sd-tungsten-ore", -(D + 500)) > 0 and count("sd-tungsten-ore", D + 500) == 0 and count("sd-tungsten-ore", 0) == 0,
      count("sd-tungsten-ore", -(D + 500)) .. " north")
    check("sulfur only in the heat", count("sd-sulfur-deposit", D + 500) > 0 and count("sd-sulfur-deposit", -(D + 500)) == 0,
      count("sd-sulfur-deposit", D + 500) .. " south")
    check("no oil outside the heat", count("crude-oil", 0) == 0 and count("crude-oil", -(D + 500)) == 0,
      count("crude-oil", D + 500) .. " oil wells in the south sample")
    check("bears only in the cold", s.count_entities_filtered{name = "sd-bear-den", area = {{-380, -D}, {380, D + 900}}} == 0)

    -- Cold test ground
    local cy = -(D + 200)
    ground(s, 0, cy, 30)
    T.kiln = make("sd-kiln", {0, cy}, "sd-charcoal")
    T.kiln.get_fuel_inventory().insert{name = "sd-charcoal", count = 20}
    input(T.kiln).insert{name = "wood", count = 100}
    T.brazier = make("sd-brazier", {4, cy})
    T.far = make("sd-kiln", {20, cy}, "sd-charcoal")
    -- Hot test ground: two workbenches, one next to a powered, watered cooler
    local hy = D + 200
    ground(s, 0, hy, 30)
    T.hot = make("sd-workbench", {-10, hy}, "sd-clay-tablet")
    T.cool = make("sd-workbench", {10, hy}, "sd-clay-tablet")
    for _, w in pairs{T.hot, T.cool} do
      input(w).insert{name = "sd-clay", count = 200}
      input(w).insert{name = "sd-charcoal", count = 100}
    end
    T.cooler = make("sd-cooler", {14, hy})
    T.cooler.fluidbox[1] = {name = "water", amount = 100}
    T.power = s.create_entity{name = "electric-energy-interface", position = {18, hy}, force = force}
    T.power.power_production = 1e5
    T.power.electric_buffer_size = 1e6
    make("small-electric-pole", {16, hy + 2})
    T.char = s.create_entity{name = "character", position = {-20, cy}, force = force}
  end,
  [200] = function()
    local T = storage.t
    local e = remote.call("second-dawn", "climate", T.kiln.unit_number)
    check("kiln in the cold is tracked and frozen", e and e.belt == "cold" and not e.covered and T.kiln.disabled_by_script, serpent.line(e))
    T.brazier.get_fuel_inventory().insert{name = "wood", count = 1}
    local r = remote.call("second-dawn", "expose", T.char.position)
    check("character without a coat loses health", r.belt == "cold" and not r.protected and r.health < 250, serpent.line(r))
    T.char.get_inventory(defines.inventory.character_armor).insert{name = "sd-fur-coat"}
    r = remote.call("second-dawn", "expose", T.char.position)
    check("character in a fur coat does not", r.protected and r.health == 248, serpent.line(r))
  end,
  [400] = function()
    local T = storage.t
    check("burning brazier keeps the kiln working", not T.kiln.disabled_by_script)
    check("kiln out of the brazier's reach stays frozen", T.far.disabled_by_script)
  end,
  [2200] = function()
    local T = storage.t
    check("brazier out of fuel: the kiln freezes again", T.kiln.disabled_by_script, "brazier status " .. tostring(T.brazier.status))
    T.cooler.fluidbox[1] = {name = "water", amount = 100}
  end,
  [2210] = function()
    local T = storage.t
    T.hot_start, T.cool_start = T.hot.products_finished, T.cool.products_finished
  end,
  [2210 + 18000] = function()
    local T = storage.t
    local hot, cool = T.hot.products_finished - T.hot_start, T.cool.products_finished - T.cool_start
    -- a workbench makes a tablet craft in 16 s: 18.75 crafts in 5 minutes at full speed
    check("cooled workbench runs full speed", cool >= 18, cool .. " crafts in 5 min")
    check("uncooled workbench runs about half", hot >= cool * 0.4 and hot <= cool * 0.6, hot .. " crafts in 5 min")
    L("failures: " .. failures)
  end,
}
script.on_event(defines.events.on_tick, function(e)
  local T = storage.t
  if T.cooler and T.cooler.valid and e.tick % 300 == 0 then T.cooler.fluidbox[1] = {name = "water", amount = 100} end
  local f = steps[e.tick]
  if f then f() end
end)
