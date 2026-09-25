-- World rules of the stone age: what the character can mine and craft, trees that give fiber and fruit,
-- no biters (wild animals replace them in a later release), metal ores need later tools.

local character = data.raw.character.character
character.mining_categories = {"basic-solid"}
character.crafting_categories = {"sd-crafting", "sd-handcraft"}

for _, name in pairs{"iron-ore", "copper-ore", "coal", "uranium-ore"} do
  data.raw.resource[name].category = "sd-hard"
end

-- Living trees give wood and fiber; red-leaved ones are fruit trees, any other tree sometimes drops fruit.
local fruit_trees = {["tree-02-red"] = true, ["tree-08-red"] = true, ["tree-09-red"] = true}
for name, tree in pairs(data.raw.tree) do
  local m = tree.minable
  if m and m.result == "wood" and not name:find("dead") and not name:find("dry") then
    m.results = {
      {type = "item", name = "wood", amount = m.count or 4},
      {type = "item", name = "sd-fiber", amount = 1},
      {type = "item", name = "sd-fruit", amount = 1, probability = fruit_trees[name] and 0.3 or 0.05},
    }
    m.result = nil
    m.count = nil
  end
end

-- No biters.
for _, type in pairs{"unit-spawner", "turret"} do
  for _, e in pairs(data.raw[type]) do
    e.autoplace = nil
  end
end
local gen = data.raw.planet.nauvis.map_gen_settings
gen.autoplace_controls["enemy-base"] = nil
