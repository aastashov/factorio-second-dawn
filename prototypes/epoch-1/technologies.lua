-- Epoch 1 tech tree (docs/DESIGN.md §5.4). Icons are vanilla technology pictures in epoch colours.
local lib = require("prototypes.lib")
local c = lib.colors
local tech_icons = "__base__/graphics/technology/"

local function tech(name, icon, tint, count, time, prerequisites, recipes)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = {type = "unlock-recipe", recipe = "sd-" .. r} end
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  return {
    type = "technology",
    name = "sd-" .. name,
    icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = effects,
    prerequisites = pre,
    unit = {count = count, time = time, ingredients = {{"sd-clay-tablet", 1}}},
  }
end

data:extend{
  tech("pottery", "advanced-material-processing", c.clay, 10, 10, {}, {"jug", "kiln", "woodlot", "grow-wood"}),
  tech("workbench", "automation-1", c.wood, 15, 10, {"pottery"}, {"workbench"}),
  tech("levers", "logistics-1", c.wood, 20, 10, {"pottery"}, {"lever-arm", "wooden-chute"}),
  tech("wooden-logistics", "logistics-2", c.wood, 30, 10, {"levers"}, {"wooden-underground-chute", "wooden-splitter-chute"}),
  tech("quicklime", "concrete", c.lime, 15, 10, {"pottery"}, {"quicklime", "mortar"}),
  tech("fermentation", "fluid-handling", c.mash, 25, 15, {"pottery"}, {"garden", "grow-fruit"}),
  tech("distillation", "oil-processing", c.copper, 30, 15, {"fermentation", "quicklime"}, {"alembic", "spirit", "nitric-acid"}),
  tech("awakening", "research-speed", c.charge, 50, 20, {"distillation"}, {"revival-chamber", "revival-charge-1"}),
}
