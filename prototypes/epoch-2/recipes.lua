-- Epoch 2 recipes (docs/DESIGN.md §14.3, tools/balance.py).
local function items(list)
  local out = {}
  for _, it in pairs(list) do out[#out + 1] = {type = it[3] or "item", name = it[1], amount = it[2]} end
  return out
end

local function recipe(name, category, time, ingredients, results, extra)
  local r = {
    type = "recipe", name = "sd-" .. name, category = category, energy_required = time,
    ingredients = items(ingredients), results = items(results), enabled = false, allow_productivity = false,
  }
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end

data:extend{
  -- Mining
  recipe("pick-digger", "sd-crafting", 2, {{"sd-brick", 10}, {"sd-mortar", 6}, {"sd-rope", 4}, {"stone", 10}}, {{"sd-pick-digger", 1}}),
  -- Smelting
  recipe("bloomery", "sd-crafting", 3, {{"sd-brick", 20}, {"sd-mortar", 10}, {"stone", 10}}, {{"sd-bloomery", 1}}),
  recipe("copper", "sd-smelting", 3.2, {{"copper-ore", 1}}, {{"copper-plate", 1}}),
  recipe("tin", "sd-smelting", 3.2, {{"sd-tin-ore", 1}}, {{"sd-tin", 1}}),
  -- Millstone
  recipe("millstone", "sd-crafting", 2, {{"stone", 20}, {"wood", 10}}, {{"sd-millstone", 1}}),
  recipe("sand", "sd-grinding", 2, {{"stone", 1}}, {{"sd-sand", 2}}),
  -- Ash and potash
  recipe("ash", "sd-firing", 3.2, {{"wood", 4}}, {{"sd-ash", 2}}),
  recipe("potash", "sd-firing", 6.4, {{"sd-ash", 4}}, {{"sd-potash", 1}}),
  -- Glass
  recipe("glassworks", "sd-crafting", 3, {{"sd-brick", 30}, {"sd-mortar", 10}, {"copper-plate", 10}}, {{"sd-glassworks", 1}}),
  recipe("glass", "sd-glassmaking", 6.4, {{"sd-sand", 4}, {"sd-potash", 1}, {"sd-quicklime", 1}}, {{"sd-glass", 2}}),
  recipe("bottle", "sd-glassmaking", 2, {{"sd-glass", 1}}, {{"sd-bottle", 1}}),
  -- Bronze
  recipe("bronze", "sd-smelting", 6.4, {{"copper-plate", 3}, {"sd-tin", 1}}, {{"sd-bronze", 4}}),
  -- Glass flask (science 2)
  recipe("glass-flask", "sd-crafting", 6, {{"sd-glass", 1}, {"sd-bronze", 1}}, {{"sd-glass-flask", 1}}),
  -- Bronze tools
  recipe("bronze-drill", "sd-crafting", 3, {{"sd-bronze", 10}, {"sd-brick", 10}, {"sd-rope", 4}}, {{"sd-bronze-drill", 1}}),
  recipe("bronze-arm", "sd-crafting", 1, {{"sd-bronze", 1}, {"wood", 1}, {"sd-rope", 1}}, {{"sd-bronze-arm", 1}}),
  -- Logistics II
  recipe("roller-chute", "sd-crafting", 1, {{"sd-bronze", 1}, {"wood", 2}}, {{"sd-roller-chute", 2}}),
  recipe("underground-chute", "sd-crafting", 2, {{"sd-roller-chute", 10}, {"sd-bronze", 5}}, {{"sd-underground-chute", 2}}),
  recipe("splitter-chute", "sd-crafting", 2, {{"sd-roller-chute", 4}, {"sd-bronze", 5}, {"sd-rope", 2}}, {{"sd-splitter-chute", 1}}),
  -- Rectification
  recipe("rectified", "sd-distillation", 10, {{"sd-spirit-jug", 2}, {"sd-bottle", 1}}, {{"sd-rectified-bottle", 1}, {"sd-jug", 2}},
    {main_product = "sd-rectified-bottle"}),
  recipe("conc-acid", "sd-distillation", 12, {{"sd-acid-jug", 2}, {"sd-bottle", 1}}, {{"sd-conc-acid-bottle", 1}, {"sd-jug", 2}},
    {main_product = "sd-conc-acid-bottle"}),
  -- Second awakening
  recipe("revival-charge-2", "sd-awakening", 900, {{"sd-rectified-bottle", 10}, {"sd-conc-acid-bottle", 10}},
    {{"sd-revival-charge-2", 1, "fluid"}, {"sd-bottle", 20}}, {main_product = "sd-revival-charge-2"}),

  -- Alternative recipes from notes (docs/DESIGN.md §13.2)
  recipe("alt-low-tin-bronze", "sd-smelting", 12.8, {{"copper-plate", 7}, {"sd-tin", 1}}, {{"sd-bronze", 8}}),
  recipe("alt-ash-glass", "sd-glassmaking", 6.4, {{"sd-sand", 4}, {"sd-ash", 3}, {"sd-quicklime", 1}}, {{"sd-glass", 2}}),
  recipe("alt-coal-tin", "sd-smelting", 6.4, {{"sd-tin-ore", 2}, {"coal", 1}}, {{"sd-tin", 3}}),
}
