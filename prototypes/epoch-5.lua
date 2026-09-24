-- Epoch 5 "Rocket" (docs/DESIGN.md §21): plastics and electronics, the instrument board, the rocket, the
-- spacesuit, charge V; the Moon tile and the emitter — the source of petrification.
local lib = require("prototypes.lib")
local icons = "__base__/graphics/icons/"
local tech_icons = "__base__/graphics/technology/"
local board_tint, moon_tint = {0.4, 0.85, 0.5}, {0.55, 0.55, 0.58}

-- Moon: one grey tile; generated only where a surface asks for it (the Moon surface), never on Nauvis.
local moon = table.deepcopy(data.raw.tile["sand-1"])
moon.name = "sd-moon"
moon.tint = moon_tint
moon.map_color = {0.45, 0.45, 0.47}
moon.autoplace = {probability_expression = "1"}

-- The emitter: can't be damaged, only dismantled (mining it wins the game).
local emitter = {
  type = "simple-entity-with-owner",
  name = "sd-emitter",
  icons = lib.icon(icons .. "nuclear-reactor.png", {0.5, 0.35, 0.6}),
  flags = {"placeable-neutral", "get-by-unit-number"},
  minable = {mining_time = 15},
  max_health = 10000,
  collision_box = {{-2.2, -2.2}, {2.2, 2.2}},
  selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
  picture = table.deepcopy(data.raw.reactor["nuclear-reactor"].picture),
  map_color = {0.8, 0.3, 1},
}
lib.recolor(emitter.picture, {0.5, 0.35, 0.6})

local suit = table.deepcopy(data.raw.armor["heavy-armor"])
suit.name = "sd-spacesuit"
suit.icons = lib.icon(icons .. "heavy-armor.png", {0.9, 0.9, 1})
suit.icon = nil
suit.subgroup = "sd-hunting"
suit.order = "k4"
suit.resistances = {{type = "physical", decrease = 5, percent = 30}}

data:extend{
  moon, emitter, suit,
  {type = "tool", name = "sd-board", subgroup = "sd-science", order = "f", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "space-science-pack.png", board_tint)},
  {type = "item", name = "sd-control-unit", subgroup = "sd-metal", order = "f", stack_size = 50,
   icons = lib.icon(icons .. "processing-unit.png", {0.7, 0.7, 0.8})},
  {type = "item", name = "sd-oxygen-tank", subgroup = "sd-hunting", order = "k5", stack_size = 20,
   icons = lib.icon(icons .. "fluid/barreling/barrel-empty.png", {0.6, 0.85, 1})},
  {type = "fluid", name = "sd-revival-charge-5", subgroup = "sd-revival", order = "a5",
   default_temperature = 15, base_color = {1, 1, 1}, flow_color = {1, 1, 1},
   icons = lib.icon(icons .. "fluid/water.png", {1, 1, 1}), auto_barrel = false},
}
data.raw.lab["sd-lab"].inputs = {"sd-clay-tablet", "sd-glass-flask", "sd-mechanism", "sd-reactive", "sd-navigation", "sd-board"}

local silo = data.raw["rocket-silo"]["rocket-silo"]
silo.fixed_recipe = "sd-rocket-part"
silo.rocket_parts_required = 30

local function recipe(name, category, time, ingredients, results, extra)
  local function list(l)
    local out = {}
    for _, it in pairs(l) do out[#out + 1] = {type = it[3] or "item", name = it[1], amount = it[2]} end
    return out
  end
  local r = {type = "recipe", name = "sd-" .. name, category = category, energy_required = time,
    ingredients = list(ingredients), results = list(results), enabled = false, allow_productivity = false}
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end
local C, CH, F = "sd-crafting", "sd-chemistry", "fluid"
data:extend{
  recipe("plastic", CH, 1, {{"petroleum-gas", 20, F}, {"coal", 1}}, {{"plastic-bar", 2}}),
  recipe("circuit", C, 0.5, {{"plastic-bar", 1}, {"copper-cable", 3}, {"iron-plate", 1}}, {{"electronic-circuit", 1}}),
  recipe("radar", C, 1, {{"iron-plate", 10}, {"iron-gear-wheel", 5}, {"electronic-circuit", 5}}, {{"radar", 1}}),
  recipe("board", C, 10, {{"electronic-circuit", 3}, {"plastic-bar", 2}, {"sd-tungsten", 1}}, {{"sd-board", 2}}),
  recipe("rocket-fuel", CH, 10, {{"light-oil", 10, F}, {"sd-fuel-oil", 1}}, {{"rocket-fuel", 1}}),
  recipe("low-density", C, 10, {{"steel-plate", 2}, {"copper-plate", 5}, {"plastic-bar", 2}}, {{"low-density-structure", 1}}),
  recipe("control-unit", C, 10, {{"electronic-circuit", 5}, {"sd-tungsten", 1}, {"plastic-bar", 1}}, {{"sd-control-unit", 1}}),
  recipe("rocket-part", "rocket-building", 3, {{"low-density-structure", 2}, {"rocket-fuel", 2}, {"sd-control-unit", 2}},
    {{"rocket-part", 1}}, {hide_from_player_crafting = true}),
  recipe("rocket-silo", C, 30, {{"steel-plate", 200}, {"sd-brick", 500}, {"electronic-circuit", 100}, {"pipe", 100}, {"iron-gear-wheel", 100}},
    {{"rocket-silo", 1}}),
  recipe("spacesuit", C, 20, {{"sd-rubber", 30}, {"sd-glass", 20}, {"sd-tungsten", 10}, {"electronic-circuit", 10}, {"sd-leather", 10}},
    {{"sd-spacesuit", 1}}),
  recipe("oxygen-tank", C, 5, {{"steel-plate", 2}, {"sd-rubber", 1}}, {{"sd-oxygen-tank", 1}}),
  recipe("revival-charge-5", "sd-awakening-electric", 1800,
    {{"sd-rectified-bottle", 25}, {"sd-conc-acid-bottle", 25}, {"sd-ether-bottle", 15}, {"sd-control-unit", 5}},
    {{"sd-revival-charge-5", 1, F}, {"sd-bottle", 65}}, {main_product = "sd-revival-charge-5"}),
}

local function tech(name, icon, tint, count, time, packs, prerequisites, recipes)
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local all = {"sd-clay-tablet", "sd-glass-flask", "sd-mechanism", "sd-reactive", "sd-navigation", "sd-board"}
  local ingredients = {}
  for i = 1, packs do ingredients[i] = {all[i], 1} end
  local eff = {}
  for _, r in pairs(recipes) do eff[#eff + 1] = {type = "unlock-recipe", recipe = "sd-" .. r} end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = eff, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
data:extend{
  tech("plastics", "plastics", {0.9, 0.9, 0.9}, 200, 30, 5, {"oil-processing", "navigation"}, {"plastic"}),
  tech("electronics", "electronics", board_tint, 200, 30, 5, {"plastics"}, {"circuit"}),
  tech("radio", "radar", board_tint, 150, 30, 5, {"electronics"}, {"radar"}),
  tech("instrument-board", "space-science-pack", board_tint, 250, 30, 5, {"electronics", "tungsten"}, {"board"}),
  tech("rocket-fuel", "rocket-fuel", {1, 0.5, 0.3}, 250, 30, 6, {"instrument-board", "fuel-oil"}, {"rocket-fuel"}),
  tech("light-structures", "low-density-structure", {0.8, 0.8, 0.9}, 250, 30, 6, {"instrument-board"}, {"low-density"}),
  tech("control-units", "processing-unit", {0.7, 0.7, 0.8}, 250, 30, 6, {"instrument-board"}, {"control-unit"}),
  tech("rocket-silo", "rocket-silo", {1, 1, 1}, 400, 60, 6, {"rocket-fuel", "light-structures", "control-units"}, {"rocket-silo", "rocket-part"}),
  tech("spacesuit", "power-armor", {0.9, 0.9, 1}, 300, 30, 6, {"instrument-board", "rubber", "tanning"}, {"spacesuit", "oxygen-tank"}),
  tech("fifth-awakening", "research-speed", {1, 1, 1}, 400, 60, 6, {"control-units", "fourth-awakening"}, {"revival-charge-5"}),
}
