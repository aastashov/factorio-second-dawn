local lib = require("prototypes.lib")
local c = lib.colors
local icons = "__base__/graphics/icons/"

data:extend{
  {type = "recipe-category", name = "sd-blast"},
  {type = "recipe-category", name = "sd-awakening-electric"},
  {type = "tool", name = "sd-mechanism", subgroup = "sd-science", order = "c", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "chemical-science-pack.png", {0.8, 0.75, 0.7})},
  {type = "item", name = "sd-electrode", subgroup = "sd-metal", order = "c", stack_size = 100,
   icons = lib.icon(icons .. "copper-cable.png", {1, 0.75, 0.45})},
  {type = "fluid", name = "sd-revival-charge-3", subgroup = "sd-revival", order = "a3",
   default_temperature = 15, base_color = {0.75, 0.6, 1}, flow_color = {0.75, 0.6, 1},
   icons = lib.icon(icons .. "fluid/water.png", {0.75, 0.6, 1}), auto_barrel = false},
  {type = "item", name = "sd-lab", subgroup = "sd-research-buildings", order = "b", stack_size = 10,
   icon = "__base__/graphics/icons/lab.png", icon_size = 64, place_result = "sd-lab"},
  {type = "item", name = "sd-revival-chamber-2", subgroup = "sd-revival", order = "c", stack_size = 1,
   icons = lib.icon(icons .. "nuclear-reactor.png", {0.6, 0.7, 0.85}), place_result = "sd-revival-chamber-2"},
}
