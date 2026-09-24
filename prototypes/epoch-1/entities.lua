-- Epoch 1 buildings. All graphics are vanilla sprites, recoloured and rescaled (placeholders until
-- dedicated art exists, see docs/DESIGN.md §6).
local lib = require("prototypes.lib")
local c = lib.colors

local function item_icons(name)
  return data.raw.item[name].icons
end

-- Deep copy of a vanilla entity with the Second Dawn basics: name, icon, mining result, no upgrades,
-- no circuit connectors (their sprites do not follow rescaling).
local function copy(type, base, name)
  local e = table.deepcopy(data.raw[type][base])
  e.name = "sd-" .. name
  e.icons = item_icons("sd-" .. name)
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

-- An assembling machine built from a vanilla crafting machine's graphics.
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

local void = {type = "void"}

-- The campfire is a furnace: it picks its recipe from what is put in (wood -> charcoal, clay -> brick),
-- so the very first machine of the game needs no recipe chosen.
local campfire = copy("furnace", "stone-furnace", "campfire")
campfire.crafting_categories = {"sd-campfire"}
campfire.crafting_speed = 0.5
campfire.energy_source = lib.burner("wood", 3)
campfire.energy_usage = "50kW"
campfire.module_slots = 0
lib.size(campfire, 1)
lib.recolor_fields(campfire, {"graphics_set"}, {1, 0.8, 0.6}, 0.5)
local kiln = crafter("furnace", "stone-furnace", "kiln", 2, 1, c.clay, "sd-firing", 1, lib.burner("charcoal", 3), "90kW")
local workbench = crafter("assembling-machine", "assembling-machine-1", "workbench", 2, 2 / 3, c.wood, "sd-crafting", 0.5, void, "1kW")
local garden = crafter("assembling-machine", "assembling-machine-1", "garden", 3, 1, c.green, "sd-growing", 1, void, "1kW")
local vat = crafter("assembling-machine", "assembling-machine-1", "fermentation-vat", 2, 2 / 3, c.mash, "sd-fermenting", 1, void, "1kW")
local alembic = crafter("assembling-machine", "chemical-plant", "alembic", 3, 1, c.copper, "sd-distillation", 1, lib.burner("charcoal", 2), "100kW")

local desk = copy("lab", "lab", "scholar-desk")
desk.energy_source = lib.burner("wood", 1)
desk.energy_usage = "60kW"
desk.inputs = {"sd-clay-tablet"}
desk.module_slots = 0
desk.researching_speed = 1
lib.recolor_fields(desk, {"on_animation", "off_animation"}, c.wood)

local digger = copy("mining-drill", "burner-mining-drill", "digger")
digger.resource_categories = {"basic-solid"}
digger.mining_speed = 0.25
digger.energy_source = lib.burner("wood", 12)
digger.energy_usage = "150kW"
lib.recolor_fields(digger, {"graphics_set"}, c.wood)

local lever = copy("inserter", "burner-inserter", "lever-arm")
lever.energy_source.fuel_categories = {"chemical", "sd-charcoal"}
lib.recolor_fields(lever, {"hand_base_picture", "hand_closed_picture", "hand_open_picture", "platform_picture"}, c.wood)

local chute = copy("transport-belt", "transport-belt", "wooden-chute")
chute.speed = 0.015625 -- 7.5 items/s, half of a yellow belt
chute.related_underground_belt = nil
chute.fast_replaceable_group = "sd-chute"
lib.recolor_fields(chute, {"belt_animation_set"}, c.wood)

-- The revival chamber: nuclear reactor graphics, one per force (enforced in scripts/chamber.lua).
-- The charge goes into a fluid box without pipe connections, so it can't be taken out or stockpiled.
local reactor = data.raw.reactor["nuclear-reactor"]
local chamber = {
  type = "assembling-machine",
  name = "sd-revival-chamber",
  icons = item_icons("sd-revival-chamber"),
  flags = {"placeable-neutral", "placeable-player", "player-creation"},
  minable = {mining_time = 1, result = "sd-revival-chamber"},
  max_health = 1000,
  corpse = reactor.corpse,
  dying_explosion = reactor.dying_explosion,
  collision_box = reactor.collision_box,
  selection_box = reactor.selection_box,
  damaged_trigger_effect = reactor.damaged_trigger_effect,
  impact_category = reactor.impact_category,
  open_sound = reactor.open_sound,
  close_sound = reactor.close_sound,
  working_sound = reactor.working_sound,
  graphics_set = {animation = {layers = table.deepcopy(reactor.picture.layers)}},
  crafting_categories = {"sd-awakening"},
  crafting_speed = 1,
  energy_source = lib.burner("charcoal", 4),
  energy_usage = "200kW",
  fluid_boxes = {{production_type = "output", volume = 1, pipe_connections = {}}},
  fluid_boxes_off_when_no_fluid_recipe = false,
  show_recipe_icon_on_map = true,
}
lib.recolor(chamber.graphics_set, {0.72, 0.70, 0.66})

data:extend{campfire, kiln, workbench, garden, vat, alembic, desk, digger, lever, chute, chamber}
