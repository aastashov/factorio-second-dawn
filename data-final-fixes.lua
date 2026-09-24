-- Hides the vanilla tech tree and recipes: Second Dawn replaces the early game. Runs in final fixes so
-- that vanilla content added by data-updates is covered too. Technologies of other mods are left alone
-- unless they need vanilla science packs, which are unobtainable here.
local vanilla_packs = {}
for _, name in pairs{"automation-science-pack", "logistic-science-pack", "military-science-pack", "chemical-science-pack",
                     "production-science-pack", "utility-science-pack", "space-science-pack"} do
  vanilla_packs[name] = true
end

for name, tech in pairs(data.raw.technology) do
  if not name:find("^sd%-") then
    local vanilla = tech.research_trigger ~= nil
    for _, ing in pairs(tech.unit and tech.unit.ingredients or {}) do
      if vanilla_packs[ing[1] or ing.name] then vanilla = true end
    end
    if vanilla then
      tech.hidden = true
      tech.enabled = false
    end
  end
end

for name, recipe in pairs(data.raw.recipe) do
  if not name:find("^sd%-") and recipe.enabled ~= false then
    recipe.enabled = false
  end
end

-- Names of the mod's recipes: a recipe named "sd-x" that makes a vanilla item "x" has no key of its own;
-- the first name that exists wins: the recipe's own, then the product's as item, entity or fluid.
for name, recipe in pairs(data.raw.recipe) do
  if name:find("^sd%-") and not recipe.localised_name then
    local product = recipe.main_product
    if not product and recipe.results and #recipe.results == 1 then product = recipe.results[1].name end
    if product and product ~= "" then
      recipe.localised_name = {"?", {"recipe-name." .. name}, {"item-name." .. product}, {"entity-name." .. product},
        {"fluid-name." .. product}}
    end
  end
end

-- Drawn icons (tools/render_icons.py) for every prototype of that name except technologies, which need
-- large pictures. Waterway rails share the waterway's icon.
local drawn = require("prototypes.generated-icons")
for _, name in pairs(drawn) do
  local icons = {{icon = "__second-dawn__/graphics/icons/" .. name .. ".png", icon_size = 64}}
  for type, protos in pairs(data.raw) do
    if type ~= "technology" and protos[name] then
      protos[name].icons = icons
      protos[name].icon = nil
      protos[name].icon_size = nil
    end
  end
end
for _, t in pairs{"straight-rail", "half-diagonal-rail", "curved-rail-a", "curved-rail-b"} do
  local rail = data.raw[t]["sd-waterway-" .. t]
  if rail then rail.icons = data.raw["rail-planner"]["sd-waterway"].icons end
end
