-- Epoch 1 recipes. Numbers mirror docs/DESIGN.md §5.3 and tools/balance.py; tests/scenarios/tree.lua
-- checks the tree against these prototypes.
local function items(list)
  local out = {}
  for _, it in pairs(list) do
    out[#out + 1] = {type = it[3] or "item", name = it[1], amount = it[2]}
  end
  return out
end

-- recipe(name, category, seconds, ingredients, results, enabled_at_start)
local function recipe(name, category, time, ingredients, results, enabled, extra)
  local r = {
    type = "recipe",
    name = "sd-" .. name,
    category = category,
    energy_required = time,
    ingredients = items(ingredients),
    results = items(results),
    enabled = enabled or false,
    allow_productivity = false,
  }
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end

data:extend{
  -- Start: no research needed.
  -- "sd-campfire" recipes run in the campfire (a furnace: it picks the recipe by its input) and in the kiln
  recipe("charcoal", "sd-campfire", 3.2, {{"wood", 3}}, {{"sd-charcoal", 1}}, true),
  recipe("brick", "sd-campfire", 3.2, {{"sd-clay", 2}}, {{"sd-brick", 1}}, true),
  recipe("fiber", "sd-crafting", 1, {{"wood", 1}}, {{"sd-fiber", 2}}, true), -- by hand or on the workbench: rope can be automated
  recipe("rope", "sd-crafting", 1, {{"sd-fiber", 3}}, {{"sd-rope", 1}}, true),
  recipe("clay-tablet", "sd-crafting", 8, {{"sd-clay", 1}, {"sd-charcoal", 1}}, {{"sd-clay-tablet", 2}}, true),
  recipe("campfire", "sd-crafting", 1, {{"stone", 5}, {"wood", 2}}, {{"sd-campfire", 1}}, true),
  -- The digger from the start: clay, shells, saltpeter and stone without digging by hand.
  recipe("digger", "sd-crafting", 2, {{"stone", 10}, {"wood", 10}, {"sd-rope", 4}}, {{"sd-digger", 1}}, true),
  recipe("scholar-desk", "sd-crafting", 2, {{"wood", 10}, {"stone", 5}, {"sd-rope", 2}}, {{"sd-scholar-desk", 1}}, true),
  recipe("wooden-chest", "sd-crafting", 0.5, {{"wood", 2}}, {{"wooden-chest", 1}}, true),

  -- Pottery
  recipe("jug", "sd-firing", 4, {{"sd-clay", 3}}, {{"sd-jug", 1}}),
  recipe("kiln", "sd-crafting", 2, {{"stone", 10}, {"sd-brick", 6}}, {{"sd-kiln", 1}}),
  -- Workbench
  recipe("workbench", "sd-crafting", 2, {{"wood", 10}, {"sd-rope", 4}, {"stone", 4}}, {{"sd-workbench", 1}}),
  -- Levers and chutes
  recipe("lever-arm", "sd-crafting", 1, {{"wood", 2}, {"sd-rope", 1}, {"stone", 1}}, {{"sd-lever-arm", 1}}),
  recipe("wooden-chute", "sd-crafting", 1, {{"wood", 1}, {"sd-rope", 1}}, {{"sd-wooden-chute", 2}}),
  recipe("wooden-underground-chute", "sd-crafting", 2, {{"sd-wooden-chute", 5}, {"wood", 5}}, {{"sd-wooden-underground-chute", 2}}),
  recipe("wooden-splitter-chute", "sd-crafting", 2, {{"sd-wooden-chute", 4}, {"wood", 5}, {"sd-rope", 2}}, {{"sd-wooden-splitter-chute", 1}}),
  -- Digger

  -- Quicklime
  recipe("quicklime", "sd-firing", 3.2, {{"sd-shells", 2}}, {{"sd-quicklime", 1}}),
  recipe("mortar", "sd-crafting", 1, {{"sd-quicklime", 1}, {"stone", 2}}, {{"sd-mortar", 2}}),
  -- Fermentation
  recipe("garden", "sd-crafting", 2, {{"wood", 6}, {"sd-fiber", 4}}, {{"sd-garden", 1}}),
  recipe("woodlot", "sd-crafting", 2, {{"wood", 10}, {"sd-fiber", 10}, {"stone", 5}}, {{"sd-woodlot", 1}}),
  recipe("grow-wood", "sd-forestry", 60, {{"wood", 2}}, {{"wood", 12}}, false, {main_product = "wood"}),
  recipe("fermentation-vat", "sd-crafting", 2, {{"wood", 10}, {"sd-jug", 4}, {"sd-rope", 2}}, {{"sd-fermentation-vat", 1}}),
  recipe("grow-fruit", "sd-growing", 60, {{"sd-fruit", 2}}, {{"sd-fruit", 6}}, false, {main_product = "sd-fruit"}),
  -- Distillation
  recipe("alembic", "sd-crafting", 3, {{"sd-brick", 10}, {"sd-jug", 4}, {"sd-mortar", 4}}, {{"sd-alembic", 1}}),
  -- Spirit straight from fruit: no mash step (docs/DESIGN.md §23).
  recipe("spirit", "sd-distillation", 20, {{"sd-fruit", 8}, {"sd-jug", 1}}, {{"sd-spirit-jug", 1}}),
  recipe("nitric-acid", "sd-distillation", 10, {{"sd-jug", 1}, {"sd-saltpeter", 4}, {"sd-charcoal", 1}}, {{"sd-acid-jug", 1}}),
  -- Awakening
  recipe("revival-chamber", "sd-crafting", 10,
    {{"sd-brick", 60}, {"sd-mortar", 40}, {"sd-jug", 10}, {"sd-rope", 20}, {"stone", 50}}, {{"sd-revival-chamber", 1}}),
  recipe("revival-charge-1", "sd-awakening", 600, {{"sd-acid-jug", 10}, {"sd-spirit-jug", 10}},
    {{"sd-revival-charge-1", 1, "fluid"}, {"sd-jug", 20}}, false, {main_product = "sd-revival-charge-1"}),
}
