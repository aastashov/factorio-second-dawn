-- Ships (docs/DESIGN.md §19): trains on waterway rails that can only be laid on water. The tug is a
-- locomotive, barges are wagons, a pier is a train stop, buoys are signals. Ship sprites come from
-- tools/render_ships.py; piers and buoys are still recoloured vanilla.
local lib = require("prototypes.lib")
local icons = "__base__/graphics/icons/"
local WATER_TINT = {0.35, 0.6, 0.95, 0.45}
local HULL = {0.7, 0.55, 0.4}

local function without(mask, layer)
  local layers = {}
  for k, v in pairs(mask.layers) do if k ~= layer then layers[k] = v end end
  return {layers = layers}
end
local function default_mask(type)
  return require("collision-mask-util").get_default_mask(type)
end
local function strip(e)
  e.next_upgrade = nil
  e.fast_replaceable_group = nil
  e.factoriopedia_simulation = nil
end

-- Waterway: the four 2.0 rail shapes, placeable on water only (they collide with ground tiles instead).
local rails = {}
for _, t in pairs{"straight-rail", "half-diagonal-rail", "curved-rail-a", "curved-rail-b"} do
  local r = table.deepcopy(data.raw[t][t])
  local mask = without(r.collision_mask or default_mask(t), "water_tile")
  mask.layers.ground_tile = true
  r.collision_mask = mask
  r.name = "sd-waterway-" .. t
  r.placeable_by = {item = "sd-waterway", count = 1}
  r.minable = {mining_time = 0.2, result = "sd-waterway"}
  lib.recolor_fields(r, {"pictures", "fence_pictures"}, WATER_TINT)
  strip(r)
  rails[#rails + 1] = r.name
  data:extend{r}
end
local planner = table.deepcopy(data.raw["rail-planner"].rail)
planner.name = "sd-waterway"
planner.icons = lib.icon(icons .. "rail.png", WATER_TINT)
planner.icon = nil
planner.rails = rails
planner.subgroup = "sd-shipping"
planner.order = "a"

local function vehicle(type, base, name, order, extra)
  local e = table.deepcopy(data.raw[type][base])
  e.name = "sd-" .. name
  e.icons = lib.ship_icon(name)
  e.icon = nil
  e.minable = {mining_time = 0.5, result = "sd-" .. name}
  strip(e)
  e.pictures = lib.ship_pictures(name)
  e.wheels = nil
  e.horizontal_doors = nil
  e.vertical_doors = nil
  for k, v in pairs(extra) do e[k] = v end
  local item = {type = "item-with-entity-data", name = "sd-" .. name, icons = e.icons, subgroup = "sd-shipping", order = order,
    stack_size = 5, place_result = "sd-" .. name}
  return e, item
end
local tug, tug_item = vehicle("locomotive", "locomotive", "tug", "b", {max_speed = 0.3, max_power = "600kW", weight = 1500})
tug.energy_source.fuel_categories = {"chemical", "sd-charcoal"}
local barge, barge_item = vehicle("cargo-wagon", "cargo-wagon", "barge", "c", {inventory_size = 40, max_speed = 0.3})
local tanker, tanker_item = vehicle("fluid-wagon", "fluid-wagon", "fluid-barge", "d", {capacity = 25000, max_speed = 0.3})

local function fixture(type, base, name, order)
  local e = table.deepcopy(data.raw[type][base])
  e.name = "sd-" .. name
  e.icons = lib.icon(icons .. base .. ".png", HULL)
  e.icon = nil
  e.minable = {mining_time = 0.3, result = "sd-" .. name}
  e.collision_mask = without(e.collision_mask or default_mask(type), "water_tile")
  strip(e)
  local item = {type = "item", name = "sd-" .. name, icons = e.icons, subgroup = "sd-shipping", order = order,
    stack_size = 20, place_result = "sd-" .. name}
  return e, item
end
local pier, pier_item = fixture("train-stop", "train-stop", "pier", "e")
local buoy, buoy_item = fixture("rail-signal", "rail-signal", "buoy", "f")
local chain, chain_item = fixture("rail-chain-signal", "rail-chain-signal", "chain-buoy", "g")

data:extend{
  {type = "item-subgroup", name = "sd-shipping", group = "second-dawn", order = "i"},
  planner, tug, tug_item, barge, barge_item, tanker, tanker_item, pier, pier_item, buoy, buoy_item, chain, chain_item,
  {type = "item", name = "sd-pitch", subgroup = "sd-materials", order = "i", stack_size = 100,
   icons = lib.icon(icons .. "coal.png", {0.35, 0.25, 0.15})},
}

local function recipe(name, category, time, ingredients, results, extra)
  local function items(list)
    local out = {}
    for _, it in pairs(list) do out[#out + 1] = {type = "item", name = it[1], amount = it[2]} end
    return out
  end
  local r = {type = "recipe", name = "sd-" .. name, category = category, energy_required = time,
    ingredients = items(ingredients), results = items(results), enabled = false}
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end
local C = "sd-crafting"
data:extend{
  recipe("pitch", "sd-distillation", 15, {{"wood", 10}}, {{"sd-pitch", 2}, {"sd-charcoal", 3}}, {main_product = "sd-pitch"}),
  recipe("waterway", C, 1, {{"wood", 2}, {"sd-rope", 1}, {"iron-plate", 1}}, {{"sd-waterway", 2}}),
  recipe("tug", C, 10, {{"steel-plate", 20}, {"iron-gear-wheel", 20}, {"pipe", 10}, {"wood", 50}, {"sd-pitch", 20}}, {{"sd-tug", 1}}),
  recipe("barge", C, 5, {{"wood", 60}, {"steel-plate", 10}, {"sd-pitch", 20}}, {{"sd-barge", 1}}),
  recipe("fluid-barge", C, 5, {{"steel-plate", 30}, {"pipe", 20}, {"sd-pitch", 20}}, {{"sd-fluid-barge", 1}}),
  recipe("pier", C, 2, {{"wood", 20}, {"steel-plate", 5}, {"copper-cable", 5}}, {{"sd-pier", 1}}),
  recipe("buoy", C, 1, {{"wood", 5}, {"copper-cable", 2}, {"sd-glass", 1}}, {{"sd-buoy", 1}}),
  recipe("chain-buoy", C, 1, {{"wood", 5}, {"copper-cable", 2}, {"sd-glass", 1}}, {{"sd-chain-buoy", 1}}),
}

local tech_icons = "__base__/graphics/technology/"
local function tech(name, icon, tint, count, time, packs, prerequisites, effects)
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local ingredients = {{"sd-clay-tablet", 1}, {"sd-glass-flask", 1}}
  if packs == 3 then ingredients[3] = {"sd-mechanism", 1} end
  local eff = {}
  for _, e in pairs(effects) do
    eff[#eff + 1] = type(e) == "string" and {type = "unlock-recipe", recipe = "sd-" .. e} or e
  end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = eff, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
data:extend{
  tech("pitch", "oil-processing", {0.45, 0.3, 0.2}, 75, 20, 2, {"distillation", "glass-flask"}, {"pitch"}),
  tech("shipbuilding", "railway", WATER_TINT, 200, 40, 3, {"mechanism", "steam-power", "pitch"}, {"waterway", "tug", "barge", "pier"}),
  tech("buoys", "automated-rail-transportation", WATER_TINT, 100, 30, 3, {"shipbuilding"}, {"buoy", "chain-buoy"}),
  tech("fluid-barges", "fluid-wagon", WATER_TINT, 150, 30, 3, {"shipbuilding", "fluid-handling"}, {"fluid-barge"}),
}
