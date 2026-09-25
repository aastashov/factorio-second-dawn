local lib = require("prototypes.lib")
local c = lib.colors
local icons = "__base__/graphics/icons/"

local function item(name, subgroup, order, iconset, extra)
  local t = {type = "item", name = "sd-" .. name, subgroup = subgroup, order = order, icons = iconset, stack_size = 50}
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

data:extend{
  item("clay", "sd-raw", "a", lib.icon(icons .. "stone.png", c.clay)),
  item("shells", "sd-raw", "b", lib.icon(icons .. "stone.png", c.shell)),
  item("saltpeter", "sd-raw", "c", lib.icon(icons .. "stone.png", c.saltpeter)),
  item("fruit", "sd-raw", "d", lib.icon(icons .. "coin.png", c.fruit)),
  -- Dry fiber is kindling: weak fuel for anything that burns wood, so the surplus from trees isn't dead weight.
  item("fiber", "sd-raw", "e", lib.icon(icons .. "copper-cable.png", c.fiber),
    {stack_size = 100, fuel_category = "chemical", fuel_value = "1MJ"}),

  item("charcoal", "sd-materials", "a", lib.icon(icons .. "coal.png", {0.75, 0.65, 0.6}),
    {fuel_category = "sd-charcoal", fuel_value = "4MJ"}),
  item("rope", "sd-materials", "b", lib.icon(icons .. "copper-cable.png", c.wood), {stack_size = 100}),
  item("brick", "sd-materials", "c", lib.icon(icons .. "stone-brick.png", c.clay), {stack_size = 100}),
  item("quicklime", "sd-materials", "d", lib.icon(icons .. "stone.png", c.lime)),
  item("mortar", "sd-materials", "e", lib.icon(icons .. "concrete.png", c.lime), {stack_size = 100}),

  item("jug", "sd-jugs", "a", lib.jug_icon()),
  item("spirit-jug", "sd-jugs", "c", lib.jug_icon(c.spirit)),
  item("acid-jug", "sd-jugs", "d", lib.jug_icon(c.acid)),

  {type = "tool", name = "sd-clay-tablet", subgroup = "sd-science", order = "a", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "stone-brick.png", {0.95, 0.72, 0.55})},

  {type = "fluid", name = "sd-revival-charge-1", subgroup = "sd-revival", order = "a",
   default_temperature = 15, base_color = c.charge, flow_color = c.charge,
   icons = lib.icon(icons .. "fluid/water.png", c.charge), auto_barrel = false},
}

-- Building items: icon is the vanilla entity icon in the building's colour.
local buildings = {
  {"campfire", "stone-furnace", {1, 0.75, 0.5}, "sd-production", "a"},
  {"kiln", "stone-furnace", c.clay, "sd-production", "b"},
  {"workbench", "assembling-machine-1", c.wood, "sd-production", "c"},
  {"scholar-desk", "lab", c.wood, "sd-research-buildings", "a"},
  {"digger", "burner-mining-drill", c.wood, "sd-production", "e"},
  {"garden", "assembling-machine-1", c.green, "sd-production", "f"},
  {"woodlot", "assembling-machine-1", {0.45, 0.62, 0.30}, "sd-production", "fa"},
  {"fermentation-vat", "assembling-machine-1", c.mash, "sd-production", "g"},
  {"alembic", "chemical-plant", c.copper, "sd-production", "h"},
  {"lever-arm", "burner-inserter", c.wood, "sd-logistics", "a"},
  {"wooden-chute", "transport-belt", c.wood, "sd-logistics", "b"},
  {"wooden-underground-chute", "underground-belt", c.wood, "sd-logistics", "ba"},
  {"wooden-splitter-chute", "splitter", c.wood, "sd-logistics", "bb"},
  {"revival-chamber", "nuclear-reactor", c.stone, "sd-revival", "b"},
}
for _, b in pairs(buildings) do
  data:extend{item(b[1], b[4], b[5], lib.icon(icons .. b[2] .. ".png", b[3]),
    {place_result = "sd-" .. b[1], stack_size = b[1] == "wooden-chute" and 100 or (b[1] == "revival-chamber" and 1 or 50)})}
end
