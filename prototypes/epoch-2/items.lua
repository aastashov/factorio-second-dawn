local lib = require("prototypes.lib")
local c = lib.colors
local icons = "__base__/graphics/icons/"

c.tin = {0.80, 0.84, 0.90}
c.bronze = {0.85, 0.62, 0.32}
c.glass = {0.70, 0.92, 0.95}
c.ash = {0.55, 0.55, 0.55}

data:extend{
  {type = "recipe-category", name = "sd-grinding"},
  {type = "recipe-category", name = "sd-smelting"},
  {type = "recipe-category", name = "sd-glassmaking"},
  {type = "item-subgroup", name = "sd-metal", group = "second-dawn", order = "b2"},
  {type = "item-subgroup", name = "sd-glassware", group = "second-dawn", order = "c2"},
}

local function item(name, subgroup, order, iconset, extra)
  local t = {type = "item", name = "sd-" .. name, subgroup = subgroup, order = order, icons = iconset, stack_size = 50}
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end

local function bottle_icon(fill)
  local layers = lib.icon(icons .. "fluid/barreling/barrel-empty.png", c.glass)
  if fill then
    layers = {
      {icon = icons .. "fluid/barreling/barrel-fill.png", icon_size = 64, tint = c.glass},
      {icon = icons .. "fluid/barreling/barrel-side-mask.png", icon_size = 64, tint = fill},
    }
  end
  return layers
end

data:extend{
  item("tin-ore", "sd-raw", "f", lib.icon(icons .. "iron-ore.png", c.tin)),
  item("sand", "sd-materials", "f", lib.icon(icons .. "stone.png", {1, 0.9, 0.65}), {stack_size = 100}),
  item("ash", "sd-materials", "g", lib.icon(icons .. "coal.png", c.ash), {stack_size = 100}),
  item("potash", "sd-materials", "h", lib.icon(icons .. "stone.png", {0.95, 0.95, 0.95}), {stack_size = 100}),
  item("tin", "sd-metal", "a", lib.icon(icons .. "iron-plate.png", c.tin), {stack_size = 100}),
  item("bronze", "sd-metal", "b", lib.icon(icons .. "copper-plate.png", c.bronze), {stack_size = 100}),
  item("glass", "sd-glassware", "a", lib.icon(icons .. "stone-brick.png", c.glass), {stack_size = 100}),
  item("bottle", "sd-glassware", "b", bottle_icon()),
  item("rectified-bottle", "sd-glassware", "c", bottle_icon(lib.colors.spirit)),
  item("conc-acid-bottle", "sd-glassware", "d", bottle_icon({1, 0.6, 0.2})),
  {type = "tool", name = "sd-glass-flask", subgroup = "sd-science", order = "b", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "logistic-science-pack.png", c.glass)},
  {type = "fluid", name = "sd-revival-charge-2", subgroup = "sd-revival", order = "a2",
   default_temperature = 15, base_color = {0.45, 0.85, 1}, flow_color = {0.45, 0.85, 1},
   icons = lib.icon(icons .. "fluid/water.png", {0.45, 0.85, 1}), auto_barrel = false},
}

local buildings = {
  {"pick-digger", "burner-mining-drill", c.stone, "sd-production", "i"},
  {"millstone", "assembling-machine-1", c.stone, "sd-production", "j"},
  {"bloomery", "stone-furnace", {0.55, 0.45, 0.4}, "sd-production", "k"},
  {"glassworks", "steel-furnace", c.glass, "sd-production", "l"},
  {"bronze-drill", "burner-mining-drill", c.bronze, "sd-production", "m"},
  {"bronze-arm", "inserter", c.bronze, "sd-logistics", "c"},
  {"roller-chute", "transport-belt", c.bronze, "sd-logistics", "d"},
  {"underground-chute", "underground-belt", c.bronze, "sd-logistics", "e"},
  {"splitter-chute", "splitter", c.bronze, "sd-logistics", "f"},
}
for _, b in pairs(buildings) do
  data:extend{item(b[1], b[4], b[5], lib.icon(icons .. b[2] .. ".png", b[3]),
    {place_result = "sd-" .. b[1], stack_size = b[1]:find("chute") and 100 or 50})}
end
