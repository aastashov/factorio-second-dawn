-- Where everything of the mod sits in the crafting menu and Factoriopedia, tab by tab like vanilla:
-- Logistics, Production, Intermediate products, Fleet, Combat, Research, Awakening. Runs in
-- data-final-fixes, after every prototype exists. A new item goes into one of the rows below
-- (tests/check_factoriopedia.py fails for an item of the mod left in a row of no tab).
local TABS = {
  {"sd-fleet", "d", "__second-dawn__/graphics/icons/tug.png"},
  {"sd-research", "e5", "__second-dawn__/graphics/icons/sd-clay-tablet.png"},
  {"second-dawn", "e6", "__second-dawn__/graphics/icons/sd-group-awakening.png", 128},
}

-- {row, tab, order, names}
local ROWS = {
  {"sd-logistics", "logistics", "a-a", {"sd-wooden-chute", "sd-wooden-underground-chute", "sd-wooden-splitter-chute",
    "sd-roller-chute", "sd-underground-chute", "sd-splitter-chute", "sd-lever-arm", "sd-bronze-arm"}},

  {"sd-furnaces", "production", "a-a", {"sd-campfire", "sd-kiln", "sd-bloomery", "sd-glassworks", "sd-alembic"}},
  {"sd-crafting", "production", "a-b", {"sd-workbench", "sd-millstone", "sd-fermentation-vat"}},
  {"sd-mining", "production", "a-c", {"sd-digger", "sd-pick-digger", "sd-bronze-drill"}},
  {"sd-farming", "production", "a-d", {"sd-garden", "sd-woodlot", "sd-plantation"}},
  {"sd-climate", "production", "a-e", {"sd-brazier", "sd-radiator", "sd-cooler"}},

  {"sd-raw", "intermediate-products", "a-a", {"sd-clay", "sd-shells", "sd-saltpeter", "sd-fiber", "sd-fruit",
    "sd-tin-ore", "sd-tungsten-ore"}},
  {"sd-materials", "intermediate-products", "a-b", {"sd-charcoal", "sd-brick", "sd-rope", "sd-quicklime",
    "sd-mortar", "sd-sand", "sd-ash", "sd-potash", "sd-pitch", "sd-fuel-oil", "sd-gunpowder",
    "sd-latex", "sd-rubber"}},
  {"sd-animal", "intermediate-products", "a-c", {"sd-hide", "sd-leather", "sd-bones"}},
  {"sd-metal", "intermediate-products", "a-d", {"sd-tin", "sd-bronze", "sd-tungsten", "sd-electrode",
    "sd-tungsten-electrode", "sd-control-unit"}},
  {"sd-jugs", "intermediate-products", "a-e", {"sd-jug", "sd-spirit-jug", "sd-acid-jug"}},
  {"sd-glassware", "intermediate-products", "a-f", {"sd-glass", "sd-bottle", "sd-rectified-bottle",
    "sd-conc-acid-bottle", "sd-ether-bottle"}},

  {"sd-shipping", "sd-fleet", "a", {"sd-waterway", "sd-pier", "sd-buoy", "sd-chain-buoy"}},
  {"sd-ships", "sd-fleet", "b", {"sd-tug", "sd-screw-steamer", "sd-barge", "sd-fluid-barge"}},

  {"sd-weapons", "combat", "a-a", {"sd-bow", "sd-hand-crossbow", "pistol", "submachine-gun"}},
  {"sd-ammo", "combat", "a-b", {"sd-stone-arrows", "sd-bone-arrows", "sd-arrows", "sd-steel-bolts",
    "firearm-magazine", "piercing-rounds-magazine"}},
  {"sd-turrets", "combat", "a-c", {"sd-crossbow", "sd-repeating-crossbow", "gun-turret", "sd-palisade", "sd-repair-kit"}},
  {"sd-armor", "combat", "a-d", {"sd-leather-jacket", "sd-fur-coat", "sd-light-cloak"}},
  {"sd-food", "combat", "a-e", {"sd-meat"}},

  {"sd-revival", "second-dawn", "a", {"sd-revival-chamber", "sd-revival-chamber-2", "sd-revival-charge-1",
    "sd-revival-charge-2", "sd-revival-charge-3", "sd-revival-charge-4", "sd-revival-charge-5"}},
  {"sd-moon", "second-dawn", "b", {"sd-spacesuit", "sd-oxygen-tank"}},
}

local ITEM_TYPES = {"item", "tool", "capsule", "gun", "ammo", "armor", "item-with-entity-data", "rail-planner", "fluid",
  "repair-tool"}

for _, t in pairs(TABS) do
  local group = data.raw["item-group"][t[1]]
  if not group then
    group = {type = "item-group", name = t[1]}
    data:extend{group}
  end
  group.order = t[2]
  group.icons = {{icon = t[3], icon_size = t[4] or 64}}
  group.icon = nil
end

for _, row in pairs(ROWS) do
  local name, group, order, items = row[1], row[2], row[3], row[4]
  local sub = data.raw["item-subgroup"][name]
  if sub then
    sub.group, sub.order = group, order
  else
    data:extend{{type = "item-subgroup", name = name, group = group, order = order}}
  end
  for i, item in pairs(items) do
    for _, t in pairs(ITEM_TYPES) do
      local p = data.raw[t] and data.raw[t][item]
      if p then
        p.subgroup = name
        p.order = string.format("%02d", i)
      end
    end
  end
end
