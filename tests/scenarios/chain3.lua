-- Epoch 3: offshore pump pumps, boiler makes steam, steam engine powers a grid that runs an electric
-- drill, an assembler and the laboratory on three sciences; the blast furnace makes iron and steel;
-- the electric chamber replaces the old one, is unique, and makes charge III.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end
local O = {x = 0, y = 800}
local function at(x, y) return {O.x + x, O.y + y} end
local force = "player"

script.on_init(function() storage.t = {} end)
local function input(e) return e.get_inventory(defines.inventory.crafter_input) end
local function out(e, name) return e.get_output_inventory().get_item_count(name) end
local function fluid(e, i) local f = e.fluidbox[i or 1]; return f and f.name .. "=" .. math.floor(f.amount) or "empty" end

local function setup()
  local T = storage.t
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks(O, 3); s.force_generate_chunk_requests()
  local tiles = {}
  for x = -40, 40 do for y = -40, 40 do
    tiles[#tiles + 1] = {name = (x < -30) and "water" or "grass-1", position = at(x, y)}
  end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {at(-40, -40), at(40, 40)}}) do e.destroy() end
  local f = game.forces[force]
  for name, r in pairs(f.recipes) do if name:find("^sd%-") then r.enabled = true end end
  local function make(name, x, y, recipe, dir)
    return s.create_entity{name = name, position = at(x, y), force = force, recipe = recipe, direction = dir}
  end

  -- offshore pump: the first shore position and direction the game accepts
  for y = -10, 10 do
    for _, dir in pairs{defines.direction.north, defines.direction.east, defines.direction.south, defines.direction.west} do
      if not T.pump and s.can_place_entity{name = "offshore-pump", position = at(-30.5, y + 0.5), direction = dir, force = force} then
        T.pump = make("offshore-pump", -30.5, y + 0.5, nil, dir)
      end
    end
  end

  if T.pump then
    local conn = T.pump.fluidbox.get_pipe_connections(1)[1]
    T.pipe = s.create_entity{name = "pipe", position = conn.target_position, force = force}
  end

  T.boiler = make("boiler", -10, -20)
  T.boiler.fluidbox[1] = {name = "water", amount = 200}
  T.boiler_wood = T.boiler.get_fuel_inventory().insert{name = "wood", count = 5}
  T.boiler.get_fuel_inventory().insert{name = "coal", count = 5}

  T.engine = make("steam-engine", 0, 0)
  T.engine.fluidbox[1] = {name = "steam", amount = 200, temperature = 165}
  make("small-electric-pole", 3, 3)
  make("small-electric-pole", 8, 3)
  make("small-electric-pole", 13, 3)
  T.asm = make("assembling-machine-1", 8, 6, "sd-iron-gear")
  input(T.asm).insert{name = "iron-plate", count = 40}
  T.lab = make("sd-lab", 13, 6)
  local labin = T.lab.get_inventory(defines.inventory.lab_input)
  T.lab_mech = labin.insert{name = "sd-mechanism", count = 10}
  labin.insert{name = "sd-clay-tablet", count = 10}
  labin.insert{name = "sd-glass-flask", count = 10}
  for _, t in pairs(f.technologies) do
    if t.name:find("^sd%-") and t.name ~= "sd-logistics-3" then t.researched = true end
  end
  f.add_research("sd-logistics-3")
  for x = 5, 7 do for y = 11, 13 do s.create_entity{name = "iron-ore", position = at(x + 0.5, y + 0.5), amount = 500} end end
  T.drill = make("electric-mining-drill", 6.5, 12.5)
  T.drill_chest = s.create_entity{name = "wooden-chest", position = T.drill.drop_position, force = force}
  make("small-electric-pole", 8, 10)

  T.blast = make("steel-furnace", 20, -20)
  T.blast_wood = T.blast.get_fuel_inventory().insert{name = "wood", count = 5}
  T.blast.get_fuel_inventory().insert{name = "coal", count = 20}
  T.blast.get_inventory(defines.inventory.furnace_source).insert{name = "iron-ore", count = 10}
  T.steel = make("steel-furnace", 24, -20)
  T.steel.get_fuel_inventory().insert{name = "coal", count = 20}
  T.steel.get_inventory(defines.inventory.furnace_source).insert{name = "iron-plate", count = 10}

  -- chambers: the old one, then a second electric one elsewhere (refused), then the upgrade in place
  T.old = s.create_entity{name = "sd-revival-chamber", position = at(20, 20), force = force, raise_built = true}
  local second = s.create_entity{name = "sd-revival-chamber-2", position = at(-10, 25), force = force, raise_built = true}
  check("an electric chamber next to the old one is refused", not (second and second.valid))
  T.new = s.create_entity{name = "sd-revival-chamber-2", position = at(20, 20), force = force, fast_replace = true,
    spill = true, raise_built = true, recipe = "sd-revival-charge-3"}
  check("electric chamber replaces the old one in place", T.new and T.new.valid and not T.old.valid)
  check("the replacement is the force's chamber", remote.call("second-dawn", "chamber", force) == T.new)
  T.power = s.create_entity{name = "electric-energy-interface", position = at(26, 20), force = force}
  T.power.power_production = 1e6
  T.power.electric_buffer_size = 1e7
  T.new.set_recipe("sd-revival-charge-3")
  make("small-electric-pole", 24, 20)
  local inp = input(T.new)
  inp.insert{name = "sd-rectified-bottle", count = 15}
  inp.insert{name = "sd-conc-acid-bottle", count = 15}
  inp.insert{name = "sd-electrode", count = 5}
end

local steps = {
  [2] = setup,
  [1200] = function()
    local T = storage.t
    local names = {}
    for k, v in pairs(defines.entity_status) do names[v] = k end
    L("       chamber status " .. tostring(names[T.new.status]))
    check("offshore pump fills a pipe with water", T.pipe and fluid(T.pipe):find("water") ~= nil, T.pipe and fluid(T.pipe) or "no spot")
    check("boiler takes coal (and wood)", T.boiler_wood > 0)
    check("boiler makes steam", fluid(T.boiler, 2):find("steam") ~= nil, fluid(T.boiler, 2))
    check("steam engine powers the grid: assembler makes gears", out(T.asm, "iron-gear-wheel") >= 5, out(T.asm, "iron-gear-wheel") .. "")
    check("laboratory takes mechanisms", T.lab_mech == 10)
    check("laboratory researches on three sciences", game.forces[force].research_progress > 0, string.format("%.3f", game.forces[force].research_progress))
    check("electric drill mines iron ore", T.drill_chest.get_item_count("iron-ore") >= 5, T.drill_chest.get_item_count("iron-ore") .. "")
    check("blast furnace refuses wood", T.blast_wood == 0)
    check("blast furnace smelts iron", T.blast.get_output_inventory().get_item_count("iron-plate") >= 5,
      T.blast.get_output_inventory().get_item_count("iron-plate") .. "")
    check("blast furnace makes steel", T.steel.get_output_inventory().get_item_count("steel-plate") >= 1,
      T.steel.get_output_inventory().get_item_count("steel-plate") .. "")
  end,
  [72300] = function()
    local T = storage.t
    check("electric chamber makes charge III", remote.call("second-dawn", "charge_tier", force) == 3, fluid(T.new))
    check("bottles come back", out(T.new, "sd-bottle") == 30, out(T.new, "sd-bottle") .. "")
    L("failures: " .. failures)
  end,
}

script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
