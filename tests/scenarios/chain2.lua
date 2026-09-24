-- Epoch 2: every building does its job, the desk takes flasks, then the tier II rules: a tier I charge
-- does not stop wave 4, switching the chamber to charge II pours the old charge out, charge II wakes the team.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end

local O = {x = -400, y = 400}
local function at(x, y) return {O.x + x, O.y + y} end
local E = {}
local force = "player"
local function input(e) return e.get_inventory(defines.inventory.crafter_input) end
local function out(e, name) return e.get_output_inventory().get_item_count(name) end

local function setup()
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks(O, 3); s.force_generate_chunk_requests()
  local tiles = {}
  for x = -30, 40 do for y = -30, 50 do tiles[#tiles + 1] = {name = "grass-1", position = at(x, y)} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {at(-30, -30), at(40, 50)}}) do e.destroy() end
  for name, r in pairs(game.forces[force].recipes) do
    if name:find("^sd%-") then r.enabled = true end
  end
  local function make(name, x, y, recipe)
    return s.create_entity{name = name, position = at(x, y), force = force, recipe = recipe}
  end

  E.bloomery = make("sd-bloomery", 0, 0, "sd-bronze")
  E.bloomery_wood = E.bloomery.get_fuel_inventory().insert{name = "wood", count = 5}
  E.bloomery.get_fuel_inventory().insert{name = "coal", count = 10}
  input(E.bloomery).insert{name = "copper-plate", count = 30}
  input(E.bloomery).insert{name = "sd-tin", count = 10}
  E.copper = make("sd-bloomery", 4, 0, "sd-copper")
  E.copper.get_fuel_inventory().insert{name = "sd-charcoal", count = 10}
  input(E.copper).insert{name = "copper-ore", count = 20}
  E.mill = make("sd-millstone", 8, 0, "sd-sand")
  input(E.mill).insert{name = "stone", count = 20}
  E.ash = make("sd-kiln", 12, 0, "sd-potash")
  E.ash.get_fuel_inventory().insert{name = "coal", count = 10}
  input(E.ash).insert{name = "sd-ash", count = 20}
  E.glass = make("sd-glassworks", 16, 0, "sd-glass")
  E.glass.get_fuel_inventory().insert{name = "coal", count = 10}
  input(E.glass).insert{name = "sd-sand", count = 20}
  input(E.glass).insert{name = "sd-potash", count = 5}
  input(E.glass).insert{name = "sd-quicklime", count = 5}
  E.bench = make("sd-workbench", 20, 0, "sd-glass-flask")
  input(E.bench).insert{name = "sd-glass", count = 10}
  input(E.bench).insert{name = "sd-bronze", count = 10}
  E.desk = make("sd-scholar-desk", 25, 0)
  E.desk.get_fuel_inventory().insert{name = "wood", count = 20}
  local lab = E.desk.get_inventory(defines.inventory.lab_input)
  E.flasks_in = lab.insert{name = "sd-glass-flask", count = 20}
  lab.insert{name = "sd-clay-tablet", count = 50}
  local f = game.forces[force]
  for _, t in pairs{"sd-pottery", "sd-quicklime", "sd-workbench", "sd-digger", "sd-fermentation", "sd-levers", "sd-distillation",
                    "sd-awakening", "sd-mining", "sd-smelting", "sd-millstone", "sd-potash", "sd-glass", "sd-bronze", "sd-glass-flask"} do
    f.technologies[t].researched = true
  end
  f.add_research("sd-bronze-tools")

  for x = -1, 0 do for y = 9, 10 do s.create_entity{name = "copper-ore", position = at(x + 0.5, y + 0.5), amount = 500} end end
  E.pick = make("sd-pick-digger", 0, 10)
  E.pick.get_fuel_inventory().insert{name = "wood", count = 10}
  E.pick_chest = s.create_entity{name = "wooden-chest", position = E.pick.drop_position, force = force}
  for x = 5, 6 do for y = 9, 10 do s.create_entity{name = "sd-tin-ore", position = at(x + 0.5, y + 0.5), amount = 500} end end
  E.drill = make("sd-bronze-drill", 6, 10)
  E.drill.get_fuel_inventory().insert{name = "coal", count = 10}
  E.drill_chest = s.create_entity{name = "wooden-chest", position = E.drill.drop_position, force = force}

  E.arm = make("sd-bronze-arm", 12, 10)
  E.arm.get_fuel_inventory().insert{name = "wood", count = 5}
  E.from = s.create_entity{name = "wooden-chest", position = E.arm.pickup_position, force = force}
  E.to = s.create_entity{name = "wooden-chest", position = E.arm.drop_position, force = force}
  E.from.insert{name = "stone", count = 20}

  E.rect = make("sd-alembic", 18, 10, "sd-rectified")
  E.rect.get_fuel_inventory().insert{name = "coal", count = 10}
  input(E.rect).insert{name = "sd-spirit-jug", count = 4}
  input(E.rect).insert{name = "sd-bottle", count = 2}

  -- Chamber with a tier I charge, making tier I.
  E.chamber = s.create_entity{name = "sd-revival-chamber", position = at(0, 30), force = force, recipe = "sd-revival-charge-1", raise_built = true}
  E.chamber.get_fuel_inventory().insert{name = "coal", count = 50}
  E.chamber.fluidbox[1] = {name = "sd-revival-charge-1", amount = 1}
  -- Waves 1-3 are behind us.
  remote.call("second-dawn", "set_wave_count", 3)
end

local function forces_state() return remote.call("second-dawn", "state").forces[game.forces[force].index] end
local function tank() local fb = E.chamber.fluidbox[1]; return fb and (fb.name .. "=" .. fb.amount) or "empty" end

local steps = {
  [2] = setup,
  [1500] = function()
    check("bloomery refuses wood", E.bloomery_wood == 0)
    check("bloomery alloys bronze on coal", out(E.bloomery, "sd-bronze") >= 12, out(E.bloomery, "sd-bronze") .. "")
    check("bloomery smelts copper on charcoal", out(E.copper, "copper-plate") >= 5, out(E.copper, "copper-plate") .. "")
    check("millstone grinds sand", out(E.mill, "sd-sand") >= 10, out(E.mill, "sd-sand") .. "")
    check("kiln boils potash", out(E.ash, "sd-potash") >= 2, out(E.ash, "sd-potash") .. "")
    check("glassworks melts glass", out(E.glass, "sd-glass") >= 4, out(E.glass, "sd-glass") .. "")
    check("workbench makes flasks", out(E.bench, "sd-glass-flask") >= 1, out(E.bench, "sd-glass-flask") .. "")
    check("desk takes flasks", E.flasks_in == 20)
    check("desk researches with two sciences", game.forces[force].research_progress > 0, string.format("%.2f", game.forces[force].research_progress))
    check("pick digger mines copper ore", E.pick_chest.get_item_count("copper-ore") >= 3, E.pick_chest.get_item_count("copper-ore") .. "")
    check("bronze drill mines tin ore", E.drill_chest.get_item_count("sd-tin-ore") >= 7, E.drill_chest.get_item_count("sd-tin-ore") .. "")
    check("bronze arm moves items", E.to.get_item_count("stone") > 0, E.to.get_item_count("stone") .. "")
    check("rectified spirit, jugs back", out(E.rect, "sd-rectified-bottle") >= 1 and out(E.rect, "sd-jug") >= 2,
      out(E.rect, "sd-rectified-bottle") .. " bottles, " .. out(E.rect, "sd-jug") .. " jugs")
    remote.call("second-dawn", "wave_in", 60)
  end,
  [1600] = function()
    local f = forces_state()
    check("wave 4 ignores a tier I charge", f and f.required == 2 and f.thaw_tick == 1560 + 30 * 3600, serpent.line(f))
    check("tier I charge stays in the tank", tank() == "sd-revival-charge-1=1", tank())
    E.chamber.set_recipe("sd-revival-charge-2")
    local inp = input(E.chamber)
    inp.insert{name = "sd-rectified-bottle", count = 10}
    inp.insert{name = "sd-conc-acid-bottle", count = 10}
  end,
  [1700] = function()
    check("switching to charge II pours tier I out", tank() == "empty" and not E.chamber.disabled_by_script, tank())
  end,
  [1590 + 54000 + 200] = function()
    check("charge II wakes the team", forces_state() == nil, tank())
    check("bottles come back", out(E.chamber, "sd-bottle") == 20, out(E.chamber, "sd-bottle") .. "")
    L("failures: " .. failures)
  end,
}

script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
