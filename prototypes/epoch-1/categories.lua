data:extend{
  {type = "fuel-category", name = "sd-charcoal"},
  {type = "resource-category", name = "sd-hard"},

  {type = "recipe-category", name = "sd-crafting"},   -- by hand and on the workbench
  {type = "recipe-category", name = "sd-handcraft"},  -- by hand only
  {type = "recipe-category", name = "sd-firing"},
  {type = "recipe-category", name = "sd-campfire"},   -- furnace: one recipe per input
  {type = "recipe-category", name = "sd-fermenting"},
  {type = "recipe-category", name = "sd-growing"},
  {type = "recipe-category", name = "sd-forestry"},
  {type = "recipe-category", name = "sd-distillation"},
  {type = "recipe-category", name = "sd-awakening"},

  {type = "item-group", name = "second-dawn", order = "0", icon = "__base__/graphics/icons/stone.png", icon_size = 64},
  {type = "item-subgroup", name = "sd-raw", group = "second-dawn", order = "a"},
  {type = "item-subgroup", name = "sd-materials", group = "second-dawn", order = "b"},
  {type = "item-subgroup", name = "sd-jugs", group = "second-dawn", order = "c"},
  -- Research has its own tab: the packs of every epoch in one row, the desks and labs below.
  {type = "item-group", name = "sd-research", order = "0a",
   icons = {{icon = "__second-dawn__/graphics/icons/sd-clay-tablet.png", icon_size = 64}}},
  {type = "item-subgroup", name = "sd-science", group = "sd-research", order = "a"},
  {type = "item-subgroup", name = "sd-research-buildings", group = "sd-research", order = "b"},
  {type = "item-subgroup", name = "sd-production", group = "second-dawn", order = "e"},
  {type = "item-subgroup", name = "sd-logistics", group = "second-dawn", order = "f"},
  {type = "item-subgroup", name = "sd-revival", group = "second-dawn", order = "g"},
}
