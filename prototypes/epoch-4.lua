-- Epoch 4 "Chemistry and sea" (docs/DESIGN.md §20): sulfur and oil from the hot south, tungsten from the
-- cold north, rubber from plantations in the heat; vanilla chemical plant, refinery, pumpjack and
-- electric furnace with the mod's recipes; charge IV; the screw steamer and fuel oil.
local lib = require("prototypes.lib")
local icons = "__base__/graphics/icons/"
local tech_icons = "__base__/graphics/technology/"

data:extend{
  {type = "recipe-category", name = "sd-chemistry"},
  {type = "recipe-category", name = "sd-oil-processing"},
  {type = "recipe-category", name = "sd-electric-smelting"},
  {type = "recipe-category", name = "sd-plantation"},
}

-- Vanilla machines.
data.raw["assembling-machine"]["chemical-plant"].crafting_categories = {"sd-chemistry", "chemistry"}
data.raw["assembling-machine"]["oil-refinery"].crafting_categories = {"sd-oil-processing", "oil-processing"}
data.raw.furnace["electric-furnace"].crafting_categories = {"sd-electric-smelting", "smelting"}

-- Items and fluids.
local tungsten_tint = {0.55, 0.55, 0.62}
local function item(name, subgroup, order, iconset, extra)
  local t = {type = "item", name = "sd-" .. name, subgroup = subgroup, order = order, icons = iconset, stack_size = 100}
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end
data:extend{
  item("latex", "sd-materials", "k", lib.icon(icons .. "fluid/water.png", {1, 1, 0.9})),
  item("rubber", "sd-materials", "l", lib.icon(icons .. "plastic-bar.png", {0.3, 0.3, 0.3})),
  item("tungsten", "sd-metal", "d", lib.icon(icons .. "iron-plate.png", tungsten_tint)),
  item("tungsten-electrode", "sd-metal", "e", lib.icon(icons .. "copper-cable.png", tungsten_tint)),
  item("ether-bottle", "sd-glassware", "e", lib.icon(icons .. "fluid/barreling/barrel-fill.png", {0.9, 0.95, 1})),
  item("fuel-oil", "sd-materials", "m", lib.icon(icons .. "solid-fuel.png", {0.4, 0.35, 0.3}),
    {stack_size = 50, fuel_category = "sd-charcoal", fuel_value = "12MJ", fuel_top_speed_multiplier = 1.3, fuel_acceleration_multiplier = 1.5}),
  {type = "tool", name = "sd-reactive", subgroup = "sd-science", order = "d", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "production-science-pack.png", {1, 0.85, 0.3})},
  {type = "tool", name = "sd-navigation", subgroup = "sd-science", order = "e", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "utility-science-pack.png", {0.5, 0.75, 1})},
  {type = "fluid", name = "sd-revival-charge-4", subgroup = "sd-revival", order = "a4",
   default_temperature = 15, base_color = {1, 0.75, 0.45}, flow_color = {1, 0.75, 0.45},
   icons = lib.icon(icons .. "fluid/water.png", {1, 0.75, 0.45}), auto_barrel = false},
}
data.raw.lab["sd-lab"].inputs = {"sd-clay-tablet", "sd-glass-flask", "sd-mechanism", "sd-reactive", "sd-navigation"}

-- Plantation: an assembling machine that only stands in the hot belt (scripts/epoch4.lua).
local plantation = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-2"])
plantation.name = "sd-plantation"
plantation.icons = lib.icon(icons .. "assembling-machine-2.png", {0.5, 0.8, 0.4})
plantation.icon = nil
plantation.minable = {mining_time = 0.3, result = "sd-plantation"}
plantation.next_upgrade = nil
plantation.fast_replaceable_group = nil
plantation.circuit_connector = nil
plantation.factoriopedia_simulation = nil
plantation.module_slots = 0
plantation.allowed_effects = nil
plantation.crafting_categories = {"sd-plantation"}
plantation.fixed_recipe = "sd-latex"
plantation.crafting_speed = 1
plantation.energy_source = {type = "void"}
plantation.energy_usage = "1kW"
plantation.fluid_boxes_off_when_no_fluid_recipe = false
lib.recolor_fields(plantation, {"graphics_set"}, {0.5, 0.8, 0.4})

-- Screw steamer: a faster tug.
local steamer = table.deepcopy(data.raw.locomotive["sd-tug"])
steamer.name = "sd-screw-steamer"
steamer.icons = lib.ship_icon("screw-steamer")
steamer.minable = {mining_time = 0.5, result = "sd-screw-steamer"}
steamer.max_speed = 0.45
steamer.max_power = "1MW"
steamer.pictures = lib.ship_pictures("screw-steamer")

data:extend{
  plantation, steamer,
  item("plantation", "sd-production", "u", plantation.icons, {place_result = "sd-plantation", stack_size = 20}),
  {type = "item-with-entity-data", name = "sd-screw-steamer", icons = steamer.icons, subgroup = "sd-shipping", order = "b2",
   stack_size = 5, place_result = "sd-screw-steamer"},
}

-- Recipes.
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
local C, CH = "sd-crafting", "sd-chemistry"
local F = "fluid"
data:extend{
  recipe("chemical-plant", C, 3, {{"steel-plate", 5}, {"iron-gear-wheel", 5}, {"pipe", 5}, {"sd-glass", 5}}, {{"chemical-plant", 1}}),
  recipe("sulfuric-acid", CH, 1, {{"sulfur", 5}, {"iron-plate", 1}, {"water", 100, F}}, {{"sulfuric-acid", 50, F}}),
  recipe("pumpjack", C, 3, {{"steel-plate", 5}, {"iron-gear-wheel", 10}, {"pipe", 10}}, {{"pumpjack", 1}}),
  recipe("oil-refinery", C, 5, {{"steel-plate", 15}, {"iron-gear-wheel", 10}, {"pipe", 10}, {"sd-brick", 10}}, {{"oil-refinery", 1}}),
  recipe("oil-processing", "sd-oil-processing", 5, {{"crude-oil", 100, F}, {"water", 50, F}},
    {{"heavy-oil", 30, F}, {"light-oil", 45, F}, {"petroleum-gas", 55, F}}, {icon = icons .. "fluid/crude-oil.png", icon_size = 64, subgroup = "sd-materials"}),
  recipe("gas-sulfur", CH, 1, {{"petroleum-gas", 30, F}, {"water", 30, F}}, {{"sulfur", 2}}),
  recipe("plantation", C, 3, {{"wood", 20}, {"pipe", 5}, {"sd-glass", 10}}, {{"sd-plantation", 1}}),
  recipe("latex", "sd-plantation", 60, {{"water", 100, F}}, {{"sd-latex", 6}}),
  recipe("rubber", CH, 5, {{"sd-latex", 4}, {"sulfur", 1}}, {{"sd-rubber", 2}}),
  recipe("reactive", CH, 10, {{"sd-bottle", 1}, {"sulfuric-acid", 20, F}, {"sd-rubber", 1}}, {{"sd-reactive", 2}}),
  recipe("electric-furnace", C, 5, {{"steel-plate", 10}, {"sd-brick", 10}, {"copper-cable", 20}}, {{"electric-furnace", 1}}),
  recipe("tungsten", "sd-electric-smelting", 6.4, {{"sd-tungsten-ore", 2}}, {{"sd-tungsten", 1}}),
  recipe("navigation", C, 10, {{"sd-tungsten", 1}, {"sd-glass", 2}, {"sd-mechanism", 1}}, {{"sd-navigation", 1}}),
  recipe("heavy-cracking", CH, 2, {{"heavy-oil", 40, F}, {"water", 30, F}}, {{"light-oil", 30, F}}),
  recipe("light-cracking", CH, 2, {{"light-oil", 30, F}, {"water", 30, F}}, {{"petroleum-gas", 20, F}}),
  recipe("fuel-oil", CH, 2, {{"light-oil", 10, F}}, {{"sd-fuel-oil", 1}}),
  recipe("screw-steamer", C, 15, {{"steel-plate", 30}, {"sd-mechanism", 10}, {"sd-rubber", 20}, {"pipe", 10}, {"sd-pitch", 20}}, {{"sd-screw-steamer", 1}}),
  recipe("ether", CH, 5, {{"sd-spirit-jug", 2}, {"sulfuric-acid", 10, F}, {"sd-bottle", 1}}, {{"sd-ether-bottle", 1}, {"sd-jug", 2}},
    {main_product = "sd-ether-bottle"}),
  recipe("tungsten-electrode", C, 3, {{"sd-tungsten", 1}, {"sd-glass", 1}}, {{"sd-tungsten-electrode", 1}}),
  recipe("revival-charge-4", "sd-awakening-electric", 1500,
    {{"sd-rectified-bottle", 20}, {"sd-conc-acid-bottle", 20}, {"sd-ether-bottle", 10}, {"sd-tungsten-electrode", 5}},
    {{"sd-revival-charge-4", 1, F}, {"sd-bottle", 50}}, {main_product = "sd-revival-charge-4"}),
}

-- Technologies.
local function tech(name, icon, tint, count, time, packs, prerequisites, effects)
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local all = {"sd-clay-tablet", "sd-glass-flask", "sd-mechanism", "sd-reactive", "sd-navigation"}
  local ingredients = {}
  for i = 1, packs do ingredients[i] = {all[i], 1} end
  local eff = {}
  for _, e in pairs(effects) do eff[#eff + 1] = type(e) == "string" and {type = "unlock-recipe", recipe = "sd-" .. e} or e end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = eff, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
local yellow, blue, oil = {1, 0.85, 0.3}, {0.5, 0.75, 1}, {0.45, 0.4, 0.35}
data:extend{
  tech("sulfur-processing", "sulfur-processing", yellow, 200, 30, 3, {"mechanism", "fluid-handling"}, {"chemical-plant", "sulfuric-acid"}),
  tech("oil-extraction", "oil-gathering", oil, 200, 30, 3, {"electromechanics", "fluid-barges"}, {"pumpjack"}),
  tech("oil-processing", "oil-processing", oil, 250, 30, 3, {"oil-extraction"}, {"oil-refinery", "oil-processing", "gas-sulfur"}),
  tech("rubber", "plastics", {0.3, 0.3, 0.3}, 200, 30, 3, {"sulfur-processing"}, {"plantation", "latex", "rubber"}),
  tech("reactive", "production-science-pack", yellow, 250, 30, 3, {"rubber"}, {"reactive"}),
  tech("tungsten", "advanced-material-processing-2", tungsten_tint, 200, 30, 3, {"mechanism"}, {"electric-furnace", "tungsten"}),
  tech("navigation", "utility-science-pack", blue, 250, 30, 4, {"tungsten", "reactive"}, {"navigation"}),
  tech("cracking", "advanced-oil-processing", oil, 250, 30, 4, {"oil-processing", "reactive"}, {"heavy-cracking", "light-cracking"}),
  tech("fuel-oil", "rocket-fuel", oil, 200, 30, 4, {"oil-processing", "reactive"}, {"fuel-oil"}),
  tech("screw-steamer", "railway", {0.45, 0.5, 0.6}, 300, 45, 5, {"shipbuilding", "rubber", "navigation"}, {"screw-steamer"}),
  tech("ether", "chemical-science-pack", {0.9, 0.95, 1}, 250, 30, 4, {"reactive", "rectification"}, {"ether"}),
  tech("tungsten-electrodes", "electronics", tungsten_tint, 250, 30, 5, {"navigation", "third-awakening"}, {"tungsten-electrode"}),
  tech("fourth-awakening", "research-speed", {1, 0.75, 0.45}, 400, 60, 5, {"ether", "tungsten-electrodes"}, {"revival-charge-4"}),
  tech("lab-glassware-1", "research-speed", {0.8, 0.9, 1}, 150, 30, 3, {"mechanism"}, {{type = "laboratory-speed", modifier = 0.2}}),
  tech("lab-glassware-2", "research-speed", {0.8, 0.9, 1}, 250, 30, 4, {"lab-glassware-1", "reactive"}, {{type = "laboratory-speed", modifier = 0.3}}),
}
