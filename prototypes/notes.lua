-- Ruins and notes (docs/DESIGN.md §13): a note lies on the ground, picking it up reads it for the whole
-- team. Ruin walls are mossy stone walls that give stone back. Alternative recipes are unlocked by notes.
local lib = require("prototypes.lib")

local note = {
  type = "simple-entity-with-owner",
  name = "sd-note",
  icons = lib.icon("__base__/graphics/icons/blueprint.png", {0.95, 0.85, 0.65}),
  flags = {"placeable-neutral", "not-on-map", "get-by-unit-number"},
  minable = {mining_time = 0.2},
  collision_box = {{-0.25, -0.25}, {0.25, 0.25}},
  selection_box = {{-0.45, -0.45}, {0.45, 0.45}},
  selection_priority = 60,
  render_layer = "object",
  picture = {filename = "__base__/graphics/icons/blueprint.png", size = 64, scale = 0.3, tint = {0.95, 0.85, 0.65}},
  map_color = {0.95, 0.85, 0.65},
}

local wall = table.deepcopy(data.raw.wall["stone-wall"])
wall.name = "sd-ruin-wall"
wall.minable = {mining_time = 0.5, results = {{type = "item", name = "stone", amount = 2}}}
wall.placeable_by = nil
wall.next_upgrade = nil
wall.fast_replaceable_group = nil
wall.factoriopedia_simulation = nil
wall.flags = {"placeable-neutral"}
wall.max_health = 150
lib.recolor(wall.pictures, {0.62, 0.68, 0.55})

local function recipe(name, category, time, ingredients, results, main)
  local function items(list)
    local out = {}
    for _, it in pairs(list) do out[#out + 1] = {type = "item", name = it[1], amount = it[2]} end
    return out
  end
  return {
    type = "recipe", name = "sd-alt-" .. name, category = category, energy_required = time,
    ingredients = items(ingredients), results = items(results), main_product = main,
    enabled = false, allow_productivity = false,
  }
end

data:extend{
  note, wall,
  {type = "custom-input", name = "sd-diary", key_sequence = "J", consuming = "none", order = "a"},
  recipe("charcoal-pit", "sd-firing", 40, {{"wood", 20}}, {{"sd-charcoal", 8}}),
  recipe("lime-acid", "sd-distillation", 10, {{"sd-jug", 1}, {"sd-saltpeter", 3}, {"sd-quicklime", 1}}, {{"sd-acid-jug", 1}}),
  recipe("compost", "sd-growing", 60, {{"sd-fruit", 2}, {"sd-fiber", 4}}, {{"sd-fruit", 8}}, "sd-fruit"),
  recipe("double-firing", "sd-firing", 7, {{"sd-clay", 5}}, {{"sd-jug", 2}}),
}
