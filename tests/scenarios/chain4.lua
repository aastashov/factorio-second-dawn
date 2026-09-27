-- Epoch 4: sulfuric acid, rubber, reagent; oil processing, cracking, fuel oil; tungsten in the electric
-- furnace, sea chart; ether; charge IV against wave 11; a plantation is refused at home and grows
-- latex in the south; a pumpjack pumps southern oil.
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
  local p = s.create_entity{name = "electric-energy-interface", position = {cx, cy}, force = force}
  p.power_production = 1e7
  p.electric_buffer_size = 1e8
  for x = -r + 4, r - 4, 6 do for y = -r + 4, r - 4, 6 do
    s.create_entity{name = "medium-electric-pole", position = {cx + x + 0.5, cy + y + 0.5}, force = force}
  end end
end

local function make(name, x, y, recipe)
  return game.surfaces.nauvis.create_entity{name = name, position = {x, y}, force = force, recipe = recipe, raise_built = true}
end
local function put(e, items, fluids)
  local inv = e.get_inventory(defines.inventory.crafter_input) or e.get_inventory(defines.inventory.furnace_source)
  for _, it in pairs(items or {}) do inv.insert{name = it[1], count = it[2]} end
  for _, f in pairs(fluids or {}) do e.insert_fluid{name = f[1], amount = f[2]} end
end
local function out(e, name) return e.get_output_inventory().get_item_count(name) end

local steps = {
  [2] = function()
    local s, T = game.surfaces.nauvis, storage.t
    local f = game.forces[force]
    for name, r in pairs(f.recipes) do if name:find("^sd%-") then r.enabled = true end end
    for _, t in pairs(f.technologies) do if t.name:find("^sd%-") then t.researched = true end end
    local X, Y = 300, -300
    ground(s, X, Y, 40)
    T.acid = make("chemical-plant", X - 30, Y - 30, "sd-sulfuric-acid")
    put(T.acid, {{"sulfur", 50}, {"iron-plate", 10}}, {{"water", 1000}})
    T.rubber = make("chemical-plant", X - 24, Y - 30, "sd-rubber")
    put(T.rubber, {{"sd-latex", 20}, {"sulfur", 5}})
    T.reactive = make("chemical-plant", X - 18, Y - 30, "sd-reactive")
    put(T.reactive, {{"sd-bottle", 5}, {"sd-rubber", 5}}, {{"sulfuric-acid", 200}})
    T.refinery = make("oil-refinery", X - 8, Y - 28, "sd-oil-processing")
    put(T.refinery, nil, {{"crude-oil", 1000}, {"water", 500}})
    T.basic = make("oil-refinery", X + 16, Y - 28, "sd-basic-oil-processing")
    put(T.basic, nil, {{"crude-oil", 1000}})
    T.crack = make("chemical-plant", X + 2, Y - 30, "sd-heavy-cracking")
    put(T.crack, nil, {{"heavy-oil", 200}, {"water", 200}})
    T.fuel = make("chemical-plant", X + 8, Y - 30, "sd-fuel-oil")
    put(T.fuel, nil, {{"light-oil", 200}})
    T.furnace = make("electric-furnace", X - 30, Y - 18)
    put(T.furnace, {{"sd-tungsten-ore", 20}})
    T.nav = make("assembling-machine-2", X - 24, Y - 18, "sd-navigation")
    put(T.nav, {{"sd-tungsten", 5}, {"sd-glass", 10}, {"sd-mechanism", 5}})
    T.ether = make("chemical-plant", X - 18, Y - 18, "sd-ether")
    put(T.ether, {{"sd-spirit-jug", 10}, {"sd-bottle", 5}}, {{"sulfuric-acid", 100}})
    T.home_plantation = make("sd-plantation", X + 20, Y + 20)
    check("plantation refused outside the hot belt", not (T.home_plantation and T.home_plantation.valid))

    T.chamber = make("sd-revival-chamber-2", X + 20, Y - 10, "sd-revival-charge-4")
    put(T.chamber, {{"sd-rectified-bottle", 20}, {"sd-conc-acid-bottle", 20}, {"sd-ether-bottle", 10}, {"sd-tungsten-electrode", 5}})
    remote.call("second-dawn", "set_wave_count", 10)
    remote.call("second-dawn", "wave_in", 120)

    -- the south: a plantation and a pumpjack next to a cooler
    local HY = D + 400
    ground(s, 0, HY, 30)
    T.plantation = make("sd-plantation", -10, HY)
    if T.plantation and T.plantation.valid then put(T.plantation, nil, {{"water", 1000}}) end
    for x = 8, 10 do for y = -1, 1 do s.create_entity{name = "crude-oil", position = {x + 0.5, HY + y + 0.5}, amount = 300000} end end
    T.jack = make("pumpjack", 9.5, HY + 0.5)
  end,
  [1500] = function()
    local T = storage.t
    check("chemical plant makes sulfuric acid", T.acid.get_fluid_count("sulfuric-acid") > 0, tostring(T.acid.get_fluid_count("sulfuric-acid")))
    check("latex and sulfur make rubber", out(T.rubber, "sd-rubber") >= 4, out(T.rubber, "sd-rubber") .. "")
    check("reagent from bottle, acid and rubber", out(T.reactive, "sd-reactive") >= 2, out(T.reactive, "sd-reactive") .. "")
    local h, l, g = T.refinery.get_fluid_count("heavy-oil"), T.refinery.get_fluid_count("light-oil"), T.refinery.get_fluid_count("petroleum-gas")
    check("refinery gives heavy, light oil and gas", h > 0 and l > 0 and g > 0, string.format("%d / %d / %d", h, l, g))
    local bh, bg = T.basic.get_fluid_count("heavy-oil"), T.basic.get_fluid_count("petroleum-gas")
    check("basic oil processing: only gas", bg > 0 and bh == 0, string.format("gas %d, heavy %d", bg, bh))
    local tech = game.forces.player.technologies
    check("the three-product recipe comes with advanced processing, not before",
      not tech["sd-oil-processing"].prototype.effects[2] or tech["sd-oil-processing"].prototype.effects[2].recipe ~= "sd-oil-processing",
      serpent.line(tech["sd-oil-processing"].prototype.effects))
    check("heavy oil cracks into light", T.crack.get_fluid_count("light-oil") > 0, tostring(T.crack.get_fluid_count("light-oil")))
    -- the input box takes only part of the inserted oil: 2 crafts are enough to prove the recipe
    check("fuel oil from light oil", out(T.fuel, "sd-fuel-oil") >= 2, out(T.fuel, "sd-fuel-oil") .. "")
    check("electric furnace smelts tungsten", T.furnace.get_output_inventory().get_item_count("sd-tungsten") >= 3,
      T.furnace.get_output_inventory().get_item_count("sd-tungsten") .. "")
    check("sea chart", out(T.nav, "sd-navigation") >= 1, out(T.nav, "sd-navigation") .. "")
    check("ether from spirit and acid, jugs back", out(T.ether, "sd-ether-bottle") >= 2 and out(T.ether, "sd-jug") >= 4,
      out(T.ether, "sd-ether-bottle") .. " ether, " .. out(T.ether, "sd-jug") .. " jugs")
    local st = remote.call("second-dawn", "state").forces[game.forces[force].index]
    check("wave 11 needs charge IV", st and st.required == 4, serpent.line(st))
    check("plantation accepted in the south", T.plantation and T.plantation.valid)
    check("pumpjack pumps southern oil", T.jack and T.jack.valid and T.jack.get_fluid_count("crude-oil") > 0,
      T.jack and tostring(T.jack.get_fluid_count("crude-oil")))
    check("screw steamer is faster than the tug", prototypes.entity["sd-screw-steamer"].speed > prototypes.entity["sd-tug"].speed,
      prototypes.entity["sd-screw-steamer"].speed .. " > " .. prototypes.entity["sd-tug"].speed)
  end,
  [3700] = function()
    local T = storage.t
    check("plantation grows latex", T.plantation.get_output_inventory().get_item_count("sd-latex") >= 6,
      T.plantation.get_output_inventory().get_item_count("sd-latex") .. "")
  end,
  [90300] = function()
    local st = remote.call("second-dawn", "state").forces[game.forces[force].index]
    check("charge IV wakes the team", st == nil, serpent.line(st))
    check("bottles back from charge IV", out(storage.t.chamber, "sd-bottle") == 50, out(storage.t.chamber, "sd-bottle") .. "")
    L("failures: " .. failures)
  end,
}
script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
