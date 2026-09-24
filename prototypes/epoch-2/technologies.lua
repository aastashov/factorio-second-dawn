-- Epoch 2 tech tree (docs/DESIGN.md §14.4).
local lib = require("prototypes.lib")
local c = lib.colors
local tech_icons = "__base__/graphics/technology/"

local function tech(name, icon, tint, count, time, flasks, prerequisites, recipes)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = {type = "unlock-recipe", recipe = "sd-" .. r} end
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local ingredients = {{"sd-clay-tablet", 1}}
  if flasks then ingredients[2] = {"sd-glass-flask", 1} end
  return {
    type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = effects, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients},
  }
end

data:extend{
  tech("mining", "electric-mining-drill", c.stone, 50, 15, false, {"awakening"}, {"pick-digger"}),
  tech("smelting", "advanced-material-processing", {0.55, 0.45, 0.4}, 60, 15, false, {"mining"}, {"bloomery", "copper", "tin"}),
  tech("millstone", "automation-2", c.stone, 40, 15, false, {"awakening"}, {"millstone", "sand"}),
  tech("potash", "sulfur-processing", c.ash, 40, 15, false, {"awakening"}, {"ash", "potash"}),
  tech("glass", "advanced-material-processing-2", c.glass, 75, 20, false, {"millstone", "potash"}, {"glassworks", "glass", "bottle"}),
  tech("bronze", "steel-processing", c.bronze, 75, 20, false, {"smelting"}, {"bronze"}),
  tech("glass-flask", "logistic-science-pack", c.glass, 100, 20, false, {"glass", "bronze"}, {"glass-flask"}),
  tech("bronze-tools", "fast-inserter", c.bronze, 100, 25, true, {"glass-flask"}, {"bronze-drill", "bronze-arm"}),
  tech("logistics-2", "logistics-2", c.bronze, 75, 25, true, {"glass-flask"}, {"roller-chute", "underground-chute", "splitter-chute"}),
  tech("rectification", "oil-processing", c.glass, 100, 25, true, {"glass-flask"}, {"rectified", "conc-acid"}),
  tech("second-awakening", "research-speed", {0.45, 0.85, 1}, 150, 30, true, {"rectification"}, {"revival-charge-2"}),
}
