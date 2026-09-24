-- Climate belts (docs/DESIGN.md §17): north of -D is cold, south of +D is hot. Belt tiles, trees,
-- resources and oil follow latitude; heaters, coolers and clothing protect buildings and players.
local lib = require("prototypes.lib")
local resource_autoplace = require("resource-autoplace")
local D = settings.startup["sd-climate-distance"].value
local COLD = "(y < -" .. D .. ")"
local HOT = "(y > " .. D .. ")"
local icons = "__base__/graphics/icons/"
local gen = data.raw.planet.nauvis.map_gen_settings

-- Belt tiles: strongly preferred inside the belt, strongly avoided outside (a tile whose probability
-- is 0 would otherwise win wherever all the others are below zero).
local function belt_tile(name, base, tint, mask, map_color)
  local t = table.deepcopy(data.raw.tile[base])
  t.name = name
  t.tint = tint
  t.map_color = map_color
  t.autoplace = {probability_expression = "(" .. mask .. " * 1010) - 1000"}
  data:extend{t}
  gen.autoplace_settings.tile.settings[name] = {}
end
belt_tile("sd-snow", "sand-1", {1.45, 1.45, 1.55}, COLD, {0.93, 0.94, 0.98})
belt_tile("sd-dunes", "sand-2", {1.15, 0.95, 0.7}, HOT, {0.85, 0.68, 0.42})

-- Fewer trees in the cold.
for _, tree in pairs(data.raw.tree) do
  if tree.autoplace and type(tree.autoplace.probability_expression) == "string" then
    tree.autoplace.probability_expression = "(" .. tree.autoplace.probability_expression .. ") * (1 - 0.8 * " .. COLD .. ")"
  end
end

-- Oil only in the heat.
local oil = data.raw.resource["crude-oil"]
oil.autoplace.probability_expression = "(" .. oil.autoplace.probability_expression .. ") * " .. HOT

local function belt_resource(name, base, tint, result, mask, map_color, order)
  local r = table.deepcopy(data.raw.resource[base])
  r.name = name
  r.category = "sd-hard"
  r.icons = lib.icon(icons .. base .. ".png", tint)
  r.icon = nil
  r.minable = {mining_time = 1, result = result}
  r.map_color = map_color
  r.mining_visualisation_tint = tint
  r.factoriopedia_simulation = nil
  lib.recolor(r.stages, tint)
  r.autoplace = resource_autoplace.resource_autoplace_settings{name = name, order = "b", base_density = 8,
    base_spots_per_km2 = 4, has_starting_area_placement = false, regular_rq_factor_multiplier = 1}
  r.autoplace.probability_expression = "(" .. r.autoplace.probability_expression .. ") * " .. mask
  data:extend{r, {type = "autoplace-control", name = name, richness = true, order = "b-" .. order, category = "resource",
    localised_name = {"", "[entity=" .. name .. "] ", {"entity-name." .. name}}}}
  gen.autoplace_controls[name] = {}
  gen.autoplace_settings.entity.settings[name] = {}
end
data:extend{
  {type = "item", name = "sd-tungsten-ore", subgroup = "sd-raw", order = "g", stack_size = 50,
   icons = lib.icon(icons .. "iron-ore.png", {0.45, 0.45, 0.5})},
}
belt_resource("sd-tungsten-ore", "iron-ore", {0.45, 0.45, 0.5}, "sd-tungsten-ore", COLD, {0.35, 0.35, 0.42}, "j")
belt_resource("sd-sulfur-deposit", "stone", {1, 0.9, 0.3}, "sulfur", HOT, {0.8, 0.72, 0.2}, "k")

-- Exposure damage ignores armor resistances.
data:extend{{type = "damage-type", name = "sd-exposure"}}

-- Heaters and coolers: machines with a recipe that only consumes.
data:extend{
  {type = "recipe-category", name = "sd-warmth"},
  {type = "recipe-category", name = "sd-radiating"},
  {type = "recipe-category", name = "sd-cooling"},
  {type = "recipe", name = "sd-warmth", category = "sd-warmth", energy_required = 10, ingredients = {}, results = {},
   enabled = true, hidden = true, icon = icons .. "wood.png", icon_size = 64},
  {type = "recipe", name = "sd-radiate", category = "sd-radiating", energy_required = 10,
   ingredients = {{type = "fluid", name = "steam", amount = 10}}, results = {},
   enabled = true, hidden = true, icon = icons .. "fluid/steam.png", icon_size = 64},
  {type = "recipe", name = "sd-cool", category = "sd-cooling", energy_required = 10,
   ingredients = {{type = "fluid", name = "water", amount = 100}}, results = {},
   enabled = true, hidden = true, icon = icons .. "fluid/water.png", icon_size = 64},
}

local function item(name, base_icon, tint, order, extra)
  local t = {type = "item", name = "sd-" .. name, subgroup = "sd-production", order = order, stack_size = 20,
    icons = lib.icon(icons .. base_icon .. ".png", tint), place_result = "sd-" .. name}
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end
data:extend{
  item("brazier", "stone-furnace", {1, 0.6, 0.3}, "r"),
  item("radiator", "assembling-machine-2", {1, 0.55, 0.45}, "s"),
  item("cooler", "assembling-machine-2", {0.5, 0.75, 1}, "t"),
}

local function machine(base_type, base, name, size, scale, tint, category, recipe, energy_source, usage)
  local e = table.deepcopy(data.raw[base_type][base])
  e.type = "assembling-machine"
  e.name = "sd-" .. name
  e.icons = data.raw.item["sd-" .. name].icons
  e.icon = nil
  e.minable = {mining_time = 0.2, result = "sd-" .. name}
  e.next_upgrade = nil
  e.fast_replaceable_group = nil
  e.circuit_connector = nil
  e.circuit_wire_max_distance = nil
  e.factoriopedia_simulation = nil
  e.icon_draw_specification = nil
  e.source_inventory_size = nil
  e.result_inventory_size = nil
  e.module_slots = 0
  e.allowed_effects = nil
  e.crafting_categories = {category}
  e.fixed_recipe = recipe
  e.crafting_speed = 1
  e.energy_source = energy_source
  e.energy_usage = usage
  e.show_recipe_icon = false
  lib.size(e, size)
  lib.recolor_fields(e, {"graphics_set"}, tint, scale)
  if e.fluid_boxes then
    for _, fb in pairs(e.fluid_boxes) do if fb.production_type == "output" then fb.production_type = "input" end end
    e.fluid_boxes_off_when_no_fluid_recipe = false
  end
  return e
end
data:extend{
  machine("furnace", "stone-furnace", "brazier", 1, 0.5, {1, 0.6, 0.3}, "sd-warmth", "sd-warmth", lib.burner("wood", 2), "100kW"),
  machine("assembling-machine", "assembling-machine-2", "radiator", 3, 1, {1, 0.55, 0.45}, "sd-radiating", "sd-radiate",
    {type = "void"}, "1kW"),
  machine("assembling-machine", "assembling-machine-2", "cooler", 3, 1, {0.5, 0.75, 1}, "sd-cooling", "sd-cool",
    {type = "electric", usage_priority = "secondary-input"}, "50kW"),
}

-- Clothing.
local function clothing(name, tint, order)
  local a = table.deepcopy(data.raw.armor["light-armor"])
  a.name = "sd-" .. name
  a.icons = lib.icon(icons .. "light-armor.png", tint)
  a.icon = nil
  a.subgroup = "sd-hunting"
  a.order = order
  a.resistances = {{type = "physical", decrease = 2, percent = 20}}
  return a
end
data:extend{clothing("fur-coat", {0.85, 0.8, 0.75}, "k2"), clothing("light-cloak", {0.95, 0.9, 0.6}, "k3")}

local function recipe(name, time, ingredients, result)
  local ing = {}
  for _, it in pairs(ingredients) do ing[#ing + 1] = {type = "item", name = it[1], amount = it[2]} end
  return {type = "recipe", name = "sd-" .. name, category = "sd-crafting", energy_required = time, ingredients = ing,
    results = {{type = "item", name = result, amount = 1}}, enabled = false}
end
data:extend{
  recipe("brazier", 1, {{"sd-brick", 5}, {"stone", 5}}, "sd-brazier"),
  recipe("fur-coat", 5, {{"sd-leather", 20}, {"sd-hide", 10}, {"sd-rope", 5}}, "sd-fur-coat"),
  recipe("light-cloak", 5, {{"sd-fiber", 40}, {"sd-leather", 5}}, "sd-light-cloak"),
  recipe("radiator", 2, {{"pipe", 10}, {"iron-plate", 10}, {"copper-plate", 5}}, "sd-radiator"),
  recipe("cooler", 2, {{"pipe", 10}, {"iron-gear-wheel", 5}, {"copper-cable", 10}, {"iron-plate", 10}}, "sd-cooler"),
}

local tech_icons = "__base__/graphics/technology/"
local function tech(name, icon, tint, count, time, flasks, prerequisites, recipes)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = {type = "unlock-recipe", recipe = "sd-" .. r} end
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local ingredients = {{"sd-clay-tablet", 1}}
  if flasks then ingredients[2] = {"sd-glass-flask", 1} end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = effects, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
data:extend{
  tech("brazier", "advanced-material-processing", {1, 0.6, 0.3}, 20, 10, false, {"pottery"}, {"brazier"}),
  tech("warm-clothing", "armor-making", {0.85, 0.8, 0.75}, 30, 10, false, {"tanning"}, {"fur-coat"}),
  tech("light-clothing", "armor-making", {0.95, 0.9, 0.6}, 30, 10, false, {"tanning"}, {"light-cloak"}),
  tech("steam-heating", "steam-power", {1, 0.55, 0.45}, 100, 30, true, {"steam-power"}, {"radiator"}),
  tech("cooling", "fluid-handling", {0.5, 0.75, 1}, 100, 30, true, {"fluid-handling", "electricity"}, {"cooler"}),
}
