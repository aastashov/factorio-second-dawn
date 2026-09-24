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
