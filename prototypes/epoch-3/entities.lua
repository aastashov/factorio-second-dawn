-- Epoch 3: vanilla steam and electric machines take their place in the mod; the electric revival
-- chamber; farms built from captured lairs (docs/DESIGN.md §16).
local lib = require("prototypes.lib")

-- Vanilla machines.
data.raw.boiler.boiler.energy_source.fuel_categories = {"chemical", "sd-charcoal"}
local blast = data.raw.furnace["steel-furnace"]
blast.crafting_categories = {"sd-blast"}
blast.energy_source.fuel_categories = {"sd-charcoal"}
data.raw["mining-drill"]["electric-mining-drill"].resource_categories = {"basic-solid", "sd-hard"}
for _, name in pairs{"assembling-machine-1", "assembling-machine-2"} do
  local a = data.raw["assembling-machine"][name]
  a.crafting_categories = {"sd-crafting", "crafting"}
end
-- The vanilla lab stays as it is (hidden vanilla technologies still need a lab for their packs);
-- the mod's electric lab is a copy that takes the mod's sciences.
local lab = table.deepcopy(data.raw.lab.lab)
lab.name = "sd-lab"
lab.minable = {mining_time = 0.2, result = "sd-lab"}
lab.inputs = {"sd-clay-tablet", "sd-glass-flask", "sd-mechanism"}
lab.next_upgrade = nil
lab.factoriopedia_simulation = nil
data:extend{lab}

-- Belts: all chutes are one fast-replace group, like vanilla belts (a splitter or an underground goes
-- straight onto a chute), and upgrade wooden -> roller -> vanilla red.
local belts = {
  {"transport-belt", "sd-wooden-chute", "sd-roller-chute"},
  {"underground-belt", "sd-wooden-underground-chute", "sd-underground-chute"},
  {"splitter", "sd-wooden-splitter-chute", "sd-splitter-chute"},
  {"transport-belt", "sd-roller-chute", "fast-transport-belt"},
  {"underground-belt", "sd-underground-chute", "fast-underground-belt"},
  {"splitter", "sd-splitter-chute", "fast-splitter"},
}
for _, b in pairs(belts) do
  local e = data.raw[b[1]][b[2]]
  e.fast_replaceable_group = "transport-belt"
  e.next_upgrade = b[3]
end

-- Electric revival chamber: replaces the old one in place, makes charges I to III.
local chamber = table.deepcopy(data.raw["assembling-machine"]["sd-revival-chamber"])
chamber.name = "sd-revival-chamber-2"
chamber.icons = data.raw.item["sd-revival-chamber-2"].icons
chamber.minable = {mining_time = 1, result = "sd-revival-chamber-2"}
chamber.crafting_categories = {"sd-awakening", "sd-awakening-electric"}
chamber.energy_source = {type = "electric", usage_priority = "secondary-input", emissions_per_minute = {pollution = 4}}
chamber.energy_usage = "2MW"
lib.recolor(chamber.graphics_set, {0.62, 0.72, 0.88})
chamber.fast_replaceable_group = "sd-revival-chamber"
data.raw["assembling-machine"]["sd-revival-chamber"].fast_replaceable_group = "sd-revival-chamber"
data.raw["assembling-machine"]["sd-revival-chamber"].next_upgrade = "sd-revival-chamber-2"

-- Farms: the lair's own graphics, now an assembling machine of the player that eats and produces.
local function farm(name, spawner, tint, category, recipe)
  local s = data.raw["unit-spawner"][spawner]
  return {
    type = "assembling-machine",
    name = "sd-" .. name,
    icons = data.raw.item["sd-" .. name].icons,
    flags = {"placeable-neutral", "placeable-player", "player-creation"},
    minable = {mining_time = 1, result = "sd-" .. name},
    max_health = 500,
    corpse = s.corpse,
    collision_box = {{-2.2, -2.2}, {2.2, 2.2}},
    selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
    graphics_set = {animation = table.deepcopy(s.graphics_set.animations[1])},
    crafting_categories = {category},
    fixed_recipe = recipe,
    crafting_speed = 1,
    energy_source = {type = "void"},
    energy_usage = "1kW",
    working_sound = s.working_sound,
  }
end
local farms = {
  farm("boar-farm", "spitter-spawner", {0.60, 0.42, 0.28}, "sd-farm-boar", "sd-breed-boars"),
  farm("wolf-kennel", "biter-spawner", {0.60, 0.58, 0.55}, "sd-farm-wolf", "sd-breed-wolves"),
  farm("bear-pen", "biter-spawner", {0.42, 0.30, 0.22}, "sd-farm-bear", "sd-breed-bears"),
}
for i, f in pairs(farms) do
  lib.recolor(f.graphics_set, ({{0.60, 0.42, 0.28}, {0.60, 0.58, 0.55}, {0.42, 0.30, 0.22}})[i])
end
data:extend{chamber, farms[1], farms[2], farms[3]}
