-- Epoch 2 buildings, vanilla graphics recoloured (placeholders, docs/DESIGN.md §14.2).
local lib = require("prototypes.lib")
local c = lib.colors

local function copy(type, base, name)
  local e = table.deepcopy(data.raw[type][base])
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
  e.placeable_by = nil
  return e
end

local function crafter(base_type, base, name, size, scale, tint, category, speed, energy_source, usage)
  local e = copy(base_type, base, name)
  e.type = "assembling-machine"
  e.source_inventory_size = nil
  e.result_inventory_size = nil
  e.fluid_boxes = nil
  e.module_slots = 0
  e.allowed_effects = nil
  e.crafting_categories = {category}
  e.crafting_speed = speed
  e.energy_source = energy_source
  e.energy_usage = usage
  lib.size(e, size)
  lib.recolor_fields(e, {"graphics_set"}, tint, scale)
  return e
end

local function drill(name, speed, tint)
  local e = copy("mining-drill", "burner-mining-drill", name)
  e.resource_categories = {"basic-solid", "sd-hard"}
  e.mining_speed = speed
  e.energy_source = lib.burner("wood", 12)
  e.energy_usage = "150kW"
  lib.recolor_fields(e, {"graphics_set"}, tint)
  return e
end

local millstone = crafter("assembling-machine", "assembling-machine-1", "millstone", 2, 2 / 3, c.stone, "sd-grinding", 0.5, {type = "void"}, "1kW")
local bloomery = crafter("furnace", "stone-furnace", "bloomery", 2, 1, {0.55, 0.45, 0.4}, "sd-smelting", 1, lib.burner("charcoal", 4), "120kW")
local glassworks = crafter("furnace", "steel-furnace", "glassworks", 2, 1, c.glass, "sd-glassmaking", 1, lib.burner("charcoal", 4), "150kW")

local arm = copy("inserter", "inserter", "bronze-arm")
arm.energy_source = {type = "burner", fuel_categories = {"chemical", "sd-charcoal"}, effectivity = 1, fuel_inventory_size = 1}
lib.recolor_fields(arm, {"hand_base_picture", "hand_closed_picture", "hand_open_picture", "platform_picture"}, c.bronze)

local SPEED = 0.03125 -- 15 items/s, a yellow belt
local chute = copy("transport-belt", "transport-belt", "roller-chute")
chute.speed = SPEED
chute.related_underground_belt = "sd-underground-chute"
chute.fast_replaceable_group = "sd-roller-chute"
lib.recolor_fields(chute, {"belt_animation_set"}, c.bronze)

local under = copy("underground-belt", "underground-belt", "underground-chute")
under.speed = SPEED
under.max_distance = 5
under.fast_replaceable_group = "sd-roller-chute"
lib.recolor_fields(under, {"structure", "belt_animation_set"}, c.bronze)

local splitter = copy("splitter", "splitter", "splitter-chute")
splitter.speed = SPEED
splitter.related_transport_belt = "sd-roller-chute"
splitter.fast_replaceable_group = "sd-roller-chute"
lib.recolor_fields(splitter, {"structure", "structure_patch", "belt_animation_set"}, c.bronze)

data:extend{
  drill("pick-digger", 0.5, c.stone), drill("bronze-drill", 0.75, c.bronze), -- never slower than the digger before
  millstone, bloomery, glassworks, arm, chute, under, splitter,
}

-- The scholar's desk takes the second science from now on.
data.raw.lab["sd-scholar-desk"].inputs = {"sd-clay-tablet", "sd-glass-flask"}
