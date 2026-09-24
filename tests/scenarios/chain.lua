-- Every epoch 1 building does its job with real prototypes, then the revival chamber goes through three
-- waves: charged (spent, force wakes), no charge (thaws on its own), no charge (the chamber's next charge
-- wakes the force). Also: a second chamber is refused, a full chamber stops instead of stockpiling.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end

local O = {x = 400, y = 400}
local function at(x, y) return {O.x + x, O.y + y} end
local E = {}
local force = "player"

local function input(e) return e.get_inventory(defines.inventory.crafter_input) end
local function output(e) return e.get_output_inventory() end
local function count(inv, name) return inv.get_item_count(name) end

local function setup()
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks(O, 3); s.force_generate_chunk_requests()
  local tiles = {}
  for x = -30, 40 do for y = -30, 50 do tiles[#tiles + 1] = {name = "grass-1", position = at(x, y)} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {at(-30, -30), at(40, 50)}}) do e.destroy() end
  -- Unlock every recipe without researching: machines refuse locked recipes.
  for name, r in pairs(game.forces[force].recipes) do
    if name:find("^sd%-") then r.enabled = true end
  end
  local function make(name, x, y, recipe)
    return s.create_entity{name = name, position = at(x, y), force = force, recipe = recipe}
  end

  E.campfire = make("sd-campfire", 0, 0, "sd-charcoal")
  E.campfire.get_fuel_inventory().insert{name = "wood", count = 10}
  input(E.campfire).insert{name = "wood", count = 30}

  E.kiln = make("sd-kiln", 4, 0, "sd-brick")
  E.kiln_wood = E.kiln.get_fuel_inventory().insert{name = "wood", count = 5}
  E.kiln.get_fuel_inventory().insert{name = "sd-charcoal", count = 10}
  input(E.kiln).insert{name = "sd-clay", count = 20}

  E.bench = make("sd-workbench", 8, 0, "sd-clay-tablet")
  input(E.bench).insert{name = "sd-clay", count = 20}
  input(E.bench).insert{name = "sd-charcoal", count = 10}

  E.desk = make("sd-scholar-desk", 13, 0)
  E.desk.get_fuel_inventory().insert{name = "wood", count = 20}
  E.desk.get_inventory(defines.inventory.lab_input).insert{name = "sd-clay-tablet", count = 20}
  game.forces[force].add_research("sd-pottery")

  E.garden = make("sd-garden", 0, 8, "sd-grow-fruit")
  input(E.garden).insert{name = "sd-fruit", count = 4}
  E.vat = make("sd-fermentation-vat", 5, 8, "sd-mash")
  input(E.vat).insert{name = "sd-jug", count = 2}
  input(E.vat).insert{name = "sd-fruit", count = 8}
  E.acid = make("sd-alembic", 10, 8, "sd-nitric-acid")
  E.acid.get_fuel_inventory().insert{name = "sd-charcoal", count = 10}
  input(E.acid).insert{name = "sd-jug", count = 2}
  input(E.acid).insert{name = "sd-saltpeter", count = 8}
  input(E.acid).insert{name = "sd-charcoal", count = 2}
  E.spirit = make("sd-alembic", 15, 8, "sd-spirit")
  E.spirit.get_fuel_inventory().insert{name = "sd-charcoal", count = 10}
  input(E.spirit).insert{name = "sd-mash-jug", count = 4}

  for x = -1, 0 do for y = 15, 16 do s.create_entity{name = "sd-clay", position = at(x + 0.5, y + 0.5), amount = 500} end end
  E.digger = make("sd-digger", 0, 16)
  E.digger.get_fuel_inventory().insert{name = "wood", count = 10}
  E.digger_chest = s.create_entity{name = "wooden-chest", position = E.digger.drop_position, force = force}

  E.lever = make("sd-lever-arm", 8, 16)
  E.lever.get_fuel_inventory().insert{name = "wood", count = 5}
  E.from = s.create_entity{name = "wooden-chest", position = E.lever.pickup_position, force = force}
  E.to = s.create_entity{name = "wooden-chest", position = E.lever.drop_position, force = force}
  E.from.insert{name = "stone", count = 10}

  E.chamber = s.create_entity{name = "sd-revival-chamber", position = at(0, 30), force = force, recipe = "sd-revival-charge-1", raise_built = true}
  E.chamber.get_fuel_inventory().insert{name = "sd-charcoal", count = 50}
  input(E.chamber).insert{name = "sd-acid-jug", count = 20}
  input(E.chamber).insert{name = "sd-spirit-jug", count = 20}
  local second = s.create_entity{name = "sd-revival-chamber", position = at(12, 30), force = force, raise_built = true}
  check("second chamber refused", not (second and second.valid))
  check("refused chamber dropped as item", s.count_entities_filtered{name = "item-on-ground", position = at(12, 30), radius = 3} > 0)
end

local function state() return remote.call("second-dawn", "state") end
local function forces_state() return state().forces[game.forces[force].index] end
local function tank() local fb = E.chamber.fluidbox[1]; return fb and fb.amount or 0 end

local steps = {
  [2] = setup,
  [1200] = function()
    check("campfire makes charcoal", count(output(E.campfire), "sd-charcoal") >= 2, count(output(E.campfire), "sd-charcoal") .. "")
    check("kiln refuses wood", E.kiln_wood == 0)
    check("kiln fires bricks on charcoal", count(output(E.kiln), "sd-brick") >= 5, count(output(E.kiln), "sd-brick") .. "")
    check("workbench makes tablets without power", count(output(E.bench), "sd-clay-tablet") >= 2, count(output(E.bench), "sd-clay-tablet") .. "")
    check("scholar desk researches on wood", game.forces[force].research_progress > 0, string.format("%.2f", game.forces[force].research_progress))
    check("digger mines clay", count(E.digger_chest.get_inventory(defines.inventory.chest), "sd-clay") >= 3,
      count(E.digger_chest.get_inventory(defines.inventory.chest), "sd-clay") .. "")
    check("lever arm moves items", E.to.get_item_count("stone") > 0, E.to.get_item_count("stone") .. "")
  end,
  [4000] = function()
    check("garden grows fruit", count(output(E.garden), "sd-fruit") >= 6, count(output(E.garden), "sd-fruit") .. "")
    check("vat makes mash", count(output(E.vat), "sd-mash-jug") >= 1, count(output(E.vat), "sd-mash-jug") .. "")
    check("alembic makes nitric acid", count(output(E.acid), "sd-acid-jug") >= 2, count(output(E.acid), "sd-acid-jug") .. "")
    check("alembic makes spirit and returns a jug", count(output(E.spirit), "sd-spirit-jug") >= 1 and count(output(E.spirit), "sd-jug") >= 1,
      count(output(E.spirit), "sd-spirit-jug") .. " spirit, " .. count(output(E.spirit), "sd-jug") .. " jugs")
  end,
  [35900] = function()
    check("no charge before 10 min", remote.call("second-dawn", "charge_tier", force) == nil, "tank " .. tank())
  end,
  [36300] = function()
    check("charge I after 10 min", remote.call("second-dawn", "charge_tier", force) == 1, "tank " .. tank())
    check("jugs come back", count(output(E.chamber), "sd-jug") == 20, count(output(E.chamber), "sd-jug") .. "")
    check("full chamber stops", E.chamber.disabled_by_script and E.chamber.crafting_progress < 0.05,
      string.format("disabled=%s next craft %.3f, tank %s", tostring(E.chamber.disabled_by_script), E.chamber.crafting_progress, tank()))
    remote.call("second-dawn", "wave_in", 60)
  end,
  [36420] = function()
    local f = forces_state()
    check("wave 1 spends the charge", f and f.revive_tick and remote.call("second-dawn", "charge_tier", force) == nil, serpent.line(f))
    check("chamber runs again after the wave", not E.chamber.disabled_by_script)
    E.chamber.get_fuel_inventory().insert{name = "sd-charcoal", count = 50} -- a charge burns 30
  end,
  [36700] = function()
    check("force awake 3 s after a charged wave", forces_state() == nil)
    remote.call("second-dawn", "wave_in", 60)
  end,
  [36800] = function()
    local f = forces_state()
    check("wave 2 without charge petrifies", f and f.thaw_tick == 36780 + 5 * 3600, serpent.line(f))
  end,
  [54990] = function()
    check("wave 2 statues thaw after 5 min", forces_state() == nil)
    remote.call("second-dawn", "wave_in", 30)
  end,
  [55100] = function()
    local f = forces_state()
    check("wave 3 without charge: thaw in 15 min", f and f.thaw_tick == 55020 + 15 * 3600, serpent.line(f))
  end,
  [73000] = function()
    local st = state()
    check("chamber's next charge wakes the force", forces_state() == nil and remote.call("second-dawn", "charge_tier", force) == nil,
      "tank " .. tank())
    check("release 0.1 stops after wave 3", st.waves.finished and st.waves.next_tick == nil, serpent.line(st.waves))
    L("failures: " .. failures)
  end,
}

script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
