-- Epoch 3 recipes and technologies (docs/DESIGN.md §16, tools/balance.py). Vanilla items get recipes of
-- their own here; the vanilla recipes stay disabled.
local lib = require("prototypes.lib")

local function items(list)
  local out = {}
  for _, it in pairs(list) do out[#out + 1] = {type = it[3] or "item", name = it[1], amount = it[2]} end
  return out
end
local function recipe(name, category, time, ingredients, results, extra)
  local r = {type = "recipe", name = "sd-" .. name, category = category, energy_required = time,
    ingredients = items(ingredients), results = items(results), enabled = false, allow_productivity = false}
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end
local C = "sd-crafting"

data:extend{
  recipe("bloomery-iron", "sd-smelting", 6.4, {{"iron-ore", 2}, {"coal", 1}}, {{"iron-plate", 1}}),
  recipe("iron-gear", C, 0.5, {{"iron-plate", 2}}, {{"iron-gear-wheel", 1}}),
  recipe("pipe", C, 0.5, {{"iron-plate", 1}}, {{"pipe", 1}}),
  recipe("pipe-to-ground", C, 0.5, {{"pipe", 10}, {"iron-plate", 5}}, {{"pipe-to-ground", 2}}),
  recipe("offshore-pump", C, 1, {{"pipe", 2}, {"iron-gear-wheel", 1}, {"sd-bronze", 2}}, {{"offshore-pump", 1}}),
  recipe("storage-tank", C, 3, {{"iron-plate", 20}, {"steel-plate", 5}}, {{"storage-tank", 1}}),
  recipe("boiler", C, 1, {{"pipe", 4}, {"sd-brick", 10}}, {{"boiler", 1}}),
  recipe("steam-engine", C, 2, {{"iron-gear-wheel", 8}, {"pipe", 5}, {"iron-plate", 10}}, {{"steam-engine", 1}}),
  recipe("copper-cable", C, 0.5, {{"copper-plate", 1}}, {{"copper-cable", 2}}),
  recipe("small-pole", C, 0.5, {{"wood", 1}, {"copper-cable", 2}}, {{"small-electric-pole", 2}}),
  recipe("small-lamp", C, 0.5, {{"copper-cable", 3}, {"sd-glass", 1}, {"iron-plate", 1}}, {{"small-lamp", 1}}),
  -- A radio is useful while the player is still scouting coasts, ruins and lairs.  It deliberately uses
  -- the electrical parts already available in this epoch, rather than waiting for rocket electronics.
  recipe("radar", C, 1, {{"iron-plate", 10}, {"iron-gear-wheel", 5}, {"copper-cable", 10}, {"sd-glass", 5}}, {{"radar", 1}}),
  recipe("blast-furnace", C, 3, {{"sd-brick", 20}, {"iron-plate", 10}}, {{"steel-furnace", 1}}),
  recipe("iron-plate", "sd-blast", 3.2, {{"iron-ore", 1}}, {{"iron-plate", 1}}),
  recipe("steel", "sd-blast", 16, {{"iron-plate", 5}}, {{"steel-plate", 1}}),
  recipe("electric-drill", C, 2, {{"iron-gear-wheel", 5}, {"copper-cable", 6}, {"iron-plate", 10}}, {{"electric-mining-drill", 1}}),
  recipe("inserter", C, 0.5, {{"iron-gear-wheel", 1}, {"copper-cable", 2}, {"iron-plate", 1}}, {{"inserter", 1}}),
  recipe("assembler-1", C, 0.5, {{"iron-gear-wheel", 5}, {"copper-cable", 6}, {"iron-plate", 9}}, {{"assembling-machine-1", 1}}),
  recipe("lab", C, 2, {{"iron-gear-wheel", 10}, {"copper-cable", 10}, {"sd-glass", 10}}, {{"sd-lab", 1}}),
  recipe("mechanism", C, 8, {{"iron-gear-wheel", 2}, {"copper-cable", 2}, {"steel-plate", 1}}, {{"sd-mechanism", 1}}),
  recipe("fast-belt", C, 0.5, {{"iron-gear-wheel", 5}, {"sd-roller-chute", 1}}, {{"fast-transport-belt", 1}}),
  recipe("fast-underground", C, 2, {{"iron-gear-wheel", 40}, {"sd-underground-chute", 2}}, {{"fast-underground-belt", 2}}),
  recipe("fast-splitter", C, 2, {{"sd-splitter-chute", 1}, {"iron-gear-wheel", 10}, {"copper-cable", 10}}, {{"fast-splitter", 1}}),
  recipe("long-inserter", C, 0.5, {{"inserter", 1}, {"iron-gear-wheel", 1}, {"iron-plate", 1}}, {{"long-handed-inserter", 1}}),
  recipe("fast-inserter", C, 0.5, {{"inserter", 1}, {"steel-plate", 1}, {"copper-cable", 2}}, {{"fast-inserter", 1}}),
  recipe("assembler-2", C, 0.5, {{"assembling-machine-1", 1}, {"steel-plate", 2}, {"iron-gear-wheel", 5}, {"copper-cable", 5}}, {{"assembling-machine-2", 1}}),
  recipe("medium-pole", C, 0.5, {{"steel-plate", 2}, {"copper-cable", 2}, {"iron-plate", 2}}, {{"medium-electric-pole", 1}}),
  recipe("revival-chamber-2", C, 20, {{"steel-plate", 50}, {"sd-brick", 100}, {"copper-cable", 50}, {"iron-gear-wheel", 30}, {"sd-glass", 50}},
    {{"sd-revival-chamber-2", 1}}),
  recipe("electrode", C, 3, {{"copper-plate", 2}, {"sd-glass", 1}}, {{"sd-electrode", 1}}),
  recipe("revival-charge-3", "sd-awakening-electric", 1200, {{"sd-rectified-bottle", 15}, {"sd-conc-acid-bottle", 15}, {"sd-electrode", 5}},
    {{"sd-revival-charge-3", 1, "fluid"}, {"sd-bottle", 30}}, {main_product = "sd-revival-charge-3"}),
}

local tech_icons = "__base__/graphics/technology/"
local function tech(name, icon, tint, count, time, packs, prerequisites, recipes)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = {type = "unlock-recipe", recipe = "sd-" .. r} end
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local ingredients = {{"sd-clay-tablet", 1}, {"sd-glass-flask", 1}}
  if packs == 3 then ingredients[3] = {"sd-mechanism", 1} end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = effects, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
local iron, steam, copper = {0.75, 0.75, 0.8}, {0.85, 0.85, 0.9}, lib.colors.copper
data:extend{
  tech("wrought-iron", "steel-processing", iron, 75, 25, 2, {"bronze-tools"}, {"bloomery-iron"}),
  tech("ironworking", "automation-1", iron, 75, 25, 2, {"wrought-iron"}, {"iron-gear"}),
  tech("fluid-handling", "fluid-handling", iron, 100, 25, 2, {"ironworking"}, {"pipe", "pipe-to-ground", "offshore-pump", "storage-tank"}),
  tech("steam-power", "steam-power", steam, 100, 30, 2, {"fluid-handling"}, {"boiler", "steam-engine"}),
  tech("electricity", "electric-energy-distribution-1", copper, 100, 30, 2, {"steam-power"}, {"copper-cable", "small-pole", "small-lamp"}),
  tech("blast-furnace", "advanced-material-processing", iron, 120, 30, 2, {"ironworking"}, {"blast-furnace", "iron-plate", "steel"}),
  tech("electromechanics", "electric-mining-drill", iron, 150, 30, 2, {"electricity", "blast-furnace"}, {"electric-drill", "inserter", "assembler-1", "lab"}),
  tech("mechanism", "chemical-science-pack", iron, 150, 30, 2, {"electromechanics"}, {"mechanism"}),
  tech("radio", "radar", copper, 100, 30, 3, {"mechanism"}, {"radar"}),
  tech("logistics-3", "logistics-2", {1, 0.5, 0.5}, 150, 30, 3, {"mechanism"}, {"fast-belt", "fast-underground", "fast-splitter", "long-inserter", "fast-inserter"}),
  tech("automation-2", "automation-2", iron, 150, 30, 3, {"mechanism"}, {"assembler-2", "medium-pole"}),
  tech("electric-chamber", "research-speed", {0.62, 0.72, 0.88}, 200, 40, 3, {"mechanism"}, {"revival-chamber-2"}),
  tech("third-awakening", "research-speed", {0.75, 0.6, 1}, 250, 45, 3, {"electric-chamber", "rectification"}, {"electrode", "revival-charge-3"}),
}
