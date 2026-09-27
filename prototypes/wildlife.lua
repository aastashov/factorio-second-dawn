-- Wild animals, lairs, hunting weapons and what animals give (docs/DESIGN.md §15). Animals are vanilla
-- biters and nests recoloured; they belong to the force "sd-wildlife" (created in scripts/wildlife.lua).
local lib = require("prototypes.lib")
local c = lib.colors
local icons = "__base__/graphics/icons/"

-- Sets every damage amount found in an attack or ammo definition.
local function set_damage(t, amount, seen)
  if type(t) ~= "table" then return end
  seen = seen or {}
  if seen[t] then return end
  seen[t] = true
  if t.type == "damage" and t.damage then t.damage.amount = amount end
  for _, v in pairs(t) do set_damage(v, amount, seen) end
end

local function loot(list)
  local out = {}
  for _, l in pairs(list) do
    out[#out + 1] = {item = l[1], count_min = l[2], count_max = l[3] or l[2], probability = l[4] or 1}
  end
  return out
end

local function animal(name, base, tint, health, damage, speed, drops)
  local u = table.deepcopy(data.raw.unit[base])
  u.name = "sd-" .. name
  u.icons = lib.icon(icons .. base .. ".png", tint)
  u.icon = nil
  u.max_health = health
  u.movement_speed = speed
  u.vision_distance = 16 -- they notice a player close by, not across the clearing
  -- (no max_pursue_distance: it also made raiding packs turn back after the first building; chases are
  -- leashed by script instead, scripts/wildlife.lua)
  u.absorptions_to_join_attack = {}
  u.loot = loot(drops)
  u.factoriopedia_simulation = nil
  set_damage(u.attack_parameters.ammo_type, damage)
  lib.recolor_fields(u, {"run_animation", "attack_parameters"}, tint)
  return u
end

-- units: {{name, weight}, ...} — which animals come out; cooldown: seconds between animals (with evolution
-- off, the first value of spawning_cooldown applies).
local function lair(name, base, tint, health, units, count, cooldown, bones)
  local s = table.deepcopy(data.raw["unit-spawner"][base])
  s.name = "sd-" .. name
  s.icons = lib.icon(icons .. base .. ".png", tint)
  s.icon = nil
  s.max_health = health
  s.result_units = {}
  for _, u in pairs(units) do s.result_units[#s.result_units + 1] = {"sd-" .. u[1], {{0, u[2]}}} end
  s.max_count_of_owned_units = count
  s.max_friends_around_to_spawn = count
  s.spawning_cooldown = {cooldown * 60, cooldown * 60}
  s.absorptions_per_second = {}
  s.autoplace = nil
  s.loot = loot({{"sd-bones", bones[1], bones[2]}})
  s.map_color = {0.55, 0.40, 0.25}
  s.factoriopedia_simulation = nil
  lib.recolor_fields(s, {"graphics_set"}, tint)
  return s
end

-- Every lair has a pack: ordinary animals and, about one in a lair, a bigger and much tougher one — the
-- leader of the wolves, the old tusker of the boars, the she-bear with her cubs. Leaders use the next
-- bigger biter model, so they stand out in the pack. Speeds stay below a running character's 0.15
-- tiles/tick: you can always get away.
local wolf, boar, bear = {0.60, 0.58, 0.55}, {0.60, 0.42, 0.28}, {0.42, 0.30, 0.22}
local wolf_leader, tusker, cub = {0.36, 0.34, 0.33}, {0.42, 0.27, 0.17}, {0.58, 0.44, 0.32}
data:extend{
  animal("wolf", "small-biter", wolf, 40, 8, 0.13, {{"sd-meat", 1}, {"sd-hide", 1, 1, 0.7}, {"sd-bones", 1, 1, 0.5}}),
  animal("wolf-leader", "medium-biter", wolf_leader, 150, 15, 0.13, {{"sd-meat", 2}, {"sd-hide", 2}, {"sd-bones", 1, 2}}),
  animal("boar", "medium-biter", boar, 120, 15, 0.12, {{"sd-meat", 3}, {"sd-hide", 1}, {"sd-bones", 1, 2}}),
  animal("tusker", "big-biter", tusker, 350, 25, 0.115, {{"sd-meat", 6}, {"sd-hide", 2}, {"sd-bones", 2, 3}}),
  animal("bear-cub", "medium-biter", cub, 150, 15, 0.11, {{"sd-meat", 2}, {"sd-hide", 1}, {"sd-bones", 1}}),
  animal("bear", "big-biter", bear, 500, 40, 0.11, {{"sd-meat", 6}, {"sd-hide", 2}, {"sd-bones", 3}}),
  lair("wolf-lair", "biter-spawner", wolf, 300, {{"wolf", 0.8}, {"wolf-leader", 0.2}}, 5, 20, {5, 10}),
  lair("boar-lair", "spitter-spawner", boar, 400, {{"boar", 0.75}, {"tusker", 0.25}}, 4, 30, {5, 10}),
  lair("bear-den", "biter-spawner", bear, 800, {{"bear-cub", 0.6}, {"bear", 0.4}}, 3, 60, {8, 10}),
  {type = "ammo-category", name = "sd-arrow"},
  {type = "item-subgroup", name = "sd-hunting", group = "second-dawn", order = "h"},
}

-- Loot and food.
local function item(name, order, iconset, extra)
  local t = {type = "item", name = "sd-" .. name, subgroup = "sd-hunting", order = order, icons = iconset, stack_size = 50}
  for k, v in pairs(extra or {}) do t[k] = v end
  return t
end
local function food(name, order, tint, heal)
  local f = table.deepcopy(data.raw.capsule["raw-fish"])
  f.name = "sd-" .. name
  f.icons = lib.icon(icons .. "fish.png", tint)
  f.icon = nil
  f.subgroup = "sd-hunting"
  f.order = order
  f.pictures = nil
  set_damage(f.capsule_action, -heal)
  return f
end
data:extend{
  food("meat", "a", {0.95, 0.45, 0.45}, 60),
  item("hide", "b", lib.icon(icons .. "wood.png", {0.75, 0.6, 0.45})),
  item("bones", "c", lib.icon(icons .. "stone.png", {1, 0.97, 0.9})),
  item("leather", "d", lib.icon(icons .. "wood.png", {0.6, 0.38, 0.22}), {stack_size = 100}),
}

-- Weapons, ammo, armor.
local function gun(name, order, tint, category, range, cooldown)
  local g = table.deepcopy(data.raw.gun.pistol)
  g.name = "sd-" .. name
  g.icons = lib.icon(icons .. "pistol.png", tint)
  g.icon = nil
  g.subgroup = "sd-hunting"
  g.order = order
  g.attack_parameters.ammo_category = category
  g.attack_parameters.range = range
  g.attack_parameters.cooldown = cooldown
  g.attack_parameters.shell_particle = nil
  return g
end
local function ammo(name, order, tint, category, damage, magazine)
  local a = table.deepcopy(data.raw.ammo["firearm-magazine"])
  a.name = "sd-" .. name
  a.icons = lib.icon(icons .. "firearm-magazine.png", tint)
  a.icon = nil
  a.pictures = nil
  a.subgroup = "sd-hunting"
  a.order = order
  a.ammo_category = category
  a.magazine_size = magazine
  set_damage(a.ammo_type, damage)
  return a
end
local jacket = table.deepcopy(data.raw.armor["light-armor"])
jacket.name = "sd-leather-jacket"
jacket.icons = lib.icon(icons .. "light-armor.png", {0.65, 0.45, 0.3})
jacket.icon = nil
jacket.subgroup = "sd-hunting"
jacket.order = "k"
jacket.resistances = {{type = "physical", decrease = 2, percent = 20}}

data:extend{
  -- One ammo category: the bow and the crossbow turret shoot any arrows (docs/DESIGN.md §22).
  gun("bow", "g", c.wood, "sd-arrow", 16, 36),
  ammo("stone-arrows", "h", c.stone, "sd-arrow", 10, 10),
  ammo("bone-arrows", "i", {1, 0.97, 0.9}, "sd-arrow", 14, 10),
  ammo("arrows", "j", c.bronze, "sd-arrow", 18, 10),
  jacket,
}

-- Repair kit: the vanilla repair pack in wood and rope.
local kit = table.deepcopy(data.raw["repair-tool"]["repair-pack"])
kit.name = "sd-repair-kit"
kit.icons = lib.icon(icons .. "repair-pack.png", c.wood)
kit.icon = nil
kit.pictures = nil
kit.hidden = nil
kit.hidden_in_factoriopedia = nil
data:extend{kit}

-- Palisade and crossbow turret.
local palisade = table.deepcopy(data.raw.wall["stone-wall"])
palisade.name = "sd-palisade"
palisade.icons = lib.icon(icons .. "wall.png", c.wood)
palisade.icon = nil
palisade.minable = {mining_time = 0.2, result = "sd-palisade"}
palisade.max_health = 200
palisade.next_upgrade = nil
palisade.fast_replaceable_group = nil
palisade.factoriopedia_simulation = nil
lib.recolor(palisade.pictures, c.wood)

local crossbow = table.deepcopy(data.raw["ammo-turret"]["gun-turret"])
crossbow.name = "sd-crossbow"
crossbow.icons = lib.icon(icons .. "gun-turret.png", c.bronze)
crossbow.icon = nil
crossbow.minable = {mining_time = 0.3, result = "sd-crossbow"}
crossbow.max_health = 300
crossbow.next_upgrade = nil
crossbow.fast_replaceable_group = nil
crossbow.factoriopedia_simulation = nil
crossbow.circuit_connector = nil
crossbow.circuit_wire_max_distance = nil
crossbow.attack_parameters.ammo_category = "sd-arrow"
crossbow.attack_parameters.range = 18
crossbow.attack_parameters.cooldown = 40
crossbow.attack_parameters.shell_particle = nil
lib.recolor_fields(crossbow, {"folded_animation", "preparing_animation", "prepared_animation", "attacking_animation", "folding_animation", "graphics_set"}, c.bronze)

data:extend{
  palisade, crossbow,
  item("palisade", "l", palisade.icons, {place_result = "sd-palisade", stack_size = 100}),
  item("crossbow", "m", crossbow.icons, {place_result = "sd-crossbow"}),
}

-- Recipes and technologies.
local function recipe(name, category, time, ingredients, results, extra)
  local function items(list)
    local out = {}
    for _, it in pairs(list) do out[#out + 1] = {type = "item", name = it[1], amount = it[2]} end
    return out
  end
  local r = {type = "recipe", name = "sd-" .. name, category = category, energy_required = time,
    ingredients = items(ingredients), results = items(results), enabled = false, allow_productivity = false}
  for k, v in pairs(extra or {}) do r[k] = v end
  return r
end
data:extend{
  -- The bow and stone arrows need no research: wolves come before the first tablet is fired.
  recipe("bow", "sd-crafting", 3, {{"wood", 5}, {"sd-rope", 2}}, {{"sd-bow", 1}}, {enabled = true}),
  recipe("stone-arrows", "sd-crafting", 1, {{"wood", 1}, {"stone", 1}}, {{"sd-stone-arrows", 5}}, {enabled = true}),
  recipe("bone-arrows", "sd-crafting", 1, {{"wood", 1}, {"sd-bones", 1}}, {{"sd-bone-arrows", 5}}),
  recipe("palisade", "sd-crafting", 1, {{"wood", 6}, {"sd-rope", 1}}, {{"sd-palisade", 2}}),
  -- Repairs from the start too: raids come with the first wave.
  recipe("repair-kit", "sd-crafting", 1, {{"wood", 2}, {"sd-rope", 1}, {"stone", 1}}, {{"sd-repair-kit", 1}}, {enabled = true}),
  recipe("leather", "sd-fermenting", 20, {{"sd-hide", 2}, {"sd-quicklime", 1}}, {{"sd-leather", 2}}),
  recipe("leather-jacket", "sd-crafting", 5, {{"sd-leather", 10}, {"sd-rope", 5}}, {{"sd-leather-jacket", 1}}),
  recipe("arrows", "sd-crafting", 2, {{"wood", 1}, {"sd-bronze", 1}, {"sd-fiber", 2}}, {{"sd-arrows", 10}}),
  recipe("crossbow", "sd-crafting", 5, {{"sd-bronze", 10}, {"wood", 10}, {"sd-rope", 5}, {"sd-leather", 2}}, {{"sd-crossbow", 1}}),
}

local tech_icons = "__base__/graphics/technology/"
local function tech(name, icon, tint, count, time, flasks, prerequisites, recipes)
  local effects = {}
  for _, r in pairs(recipes) do effects[#effects + 1] = {type = "unlock-recipe", recipe = "sd-" .. r} end
  local pre = {}
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  local ingredients = {{"sd-clay-tablet", 1}}
  if flasks then ingredients[2] = {"sd-glass-flask", 1} end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = effects, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
data:extend{
  tech("hunting", "military", c.wood, 15, 10, false, {}, {"bone-arrows", "palisade"}),
  tech("tanning", "armor-making", {0.65, 0.45, 0.3}, 25, 15, false, {"quicklime", "fermentation"}, {"fermentation-vat", "leather", "leather-jacket"}),
  tech("bow", "weapon-shooting-speed-1", c.bronze, 60, 20, false, {"bronze"}, {"arrows"}), -- bronze arrows
  tech("crossbow", "gun-turret", c.bronze, 75, 25, true, {"bow", "glass-flask", "tanning"}, {"crossbow"}),
}
