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

-- Factoriopedia shows only what exists in a Second Dawn game: the mod's prototypes, vanilla items and
-- fluids its recipes use (wood, stone, copper plate, water...), what places or gives them, and the
-- world itself (trees, rocks, fish, resources). Everything else vanilla would appear next to the mod's
-- recoloured copy of it.
local ITEM_TYPES = {"item", "tool", "capsule", "gun", "ammo", "armor", "item-with-entity-data", "rail-planner",
  "repair-tool", "module", "selection-tool", "blueprint", "blueprint-book", "deconstruction-item",
  "upgrade-item", "copy-paste-tool", "spidertron-remote", "item-with-inventory", "item-with-label",
  "item-with-tags"}
local WORLD = {tree = true, ["simple-entity"] = true, fish = true, character = true, cliff = true, plant = true}
local NOT_ENTITY = {recipe = true, technology = true, fluid = true, tile = true, planet = true, ["space-location"] = true,
  ["item-group"] = true, ["item-subgroup"] = true, ["autoplace-control"] = true, ["noise-expression"] = true,
  ["noise-function"] = true, ["virtual-signal"] = true, quality = true}
for _, t in pairs(ITEM_TYPES) do NOT_ENTITY[t] = true end

local used = {}
local function use(list)
  for _, p in pairs(list or {}) do if p.name then used[p.name] = true end end
end
for name, recipe in pairs(data.raw.recipe) do
  if name:find("^sd%-") then use(recipe.ingredients); use(recipe.results) end
end
-- The world: what trees, rocks, fish and used resources are, and what they give.
local function mined(e)
  local m = e.minable
  if not m then return end
  if m.result then used[m.result] = true end
  use(m.results)
end
for type, protos in pairs(data.raw) do
  if WORLD[type] then for _, e in pairs(protos) do used[e.name] = true; mined(e) end end
end
for name, r in pairs(data.raw.resource) do
  local m = r.minable or {}
  local gives = m.result or (m.results and m.results[1] and m.results[1].name)
  if name:find("^sd%-") or (gives and used[gives]) then used[name] = true; mined(r) end
end
-- Entities placed by a used item are used; so is the item that places a used entity.
for _, t in pairs(ITEM_TYPES) do
  for name, item in pairs(data.raw[t] or {}) do
    if item.place_result and (used[name] or name:find("^sd%-")) then used[item.place_result] = true end
  end
end
-- Only prototypes with an icon can show in Factoriopedia; the rest of data.raw (GUI styles, utility
-- constants) is not a list of prototypes and must not be touched.
local function hide(type, name, proto)
  if not name:find("^sd%-") and not used[name] and (proto.icon or proto.icons) then proto.hidden_in_factoriopedia = true end
end
for type, protos in pairs(data.raw) do
  if type == "recipe" then
    for name, r in pairs(protos) do if not name:find("^sd%-") then r.hidden_in_factoriopedia = true end end
  elseif type == "fluid" or not NOT_ENTITY[type] then
    for name, p in pairs(protos) do hide(type, name, p) end
  end
end
for _, t in pairs(ITEM_TYPES) do
  for name, p in pairs(data.raw[t] or {}) do hide(t, name, p) end
end

-- Every technology says what its research takes and where: "Research: 10 × [clay tablet] at [scholar's desk]".
-- The cost row at the bottom of the tech screen is easy to miss on the first research.
for name, tech in pairs(data.raw.technology) do
  if name:find("^sd%-") and tech.unit then
    local cost, have = {""}, {}
    for i, ing in pairs(tech.unit.ingredients) do
      local item, amount = ing[1] or ing.name, ing[2] or ing.amount
      have[item] = true
      if i > 1 then cost[#cost + 1] = " + " end
      cost[#cost + 1] = (tech.unit.count and tech.unit.count * amount or "") .. " × [item=" .. item .. "]"
    end
    local labs = {""}
    for lab_name, lab in pairs(data.raw.lab) do
      if lab_name:find("^sd%-") then
        local takes = {}
        for _, input in pairs(lab.inputs) do takes[input] = true end
        local all = true
        for item in pairs(have) do if not takes[item] then all = false end end
        if all then
          if #labs > 1 then labs[#labs + 1] = ", " end
          labs[#labs + 1] = {"", "[entity=" .. lab_name .. "] ", {"entity-name." .. lab_name}}
        end
      end
    end
    tech.localised_description = {"", {"?", {"technology-description." .. name}, ""}, "\n\n",
      {"sd-tech.cost", cost, labs}}
  end
end

-- Hard rock says why the character can't mine it and what can.
for name, r in pairs(data.raw.resource) do
  if r.category == "sd-hard" then
    r.localised_description = {"", {"?", {"entity-description." .. name}, ""}, "\n", {"sd-tech.hard-rock"}}
  end
end
