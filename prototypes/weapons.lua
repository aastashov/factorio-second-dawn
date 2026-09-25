-- Weapons after the bow (docs/DESIGN.md §22): the hand crossbow and gunpowder in epoch 2, steel bolts and
-- the repeating crossbow in epoch 3, sulfur gunpowder in epoch 4, and sharper arrowheads I–III. The bow,
-- the arrows and the crossbow turret are in prototypes/wildlife.lua.
local lib = require("prototypes.lib")
local icons = "__base__/graphics/icons/"
local bronze, steel, powder = {0.80, 0.55, 0.30}, {0.70, 0.72, 0.76}, {0.35, 0.33, 0.32}

local function set_damage(t, amount, seen)
  if type(t) ~= "table" then return end
  seen = seen or {}
  if seen[t] then return end
  seen[t] = true
  if t.type == "damage" and t.damage then t.damage.amount = amount end
  for _, v in pairs(t) do set_damage(v, amount, seen) end
end

local function gun(name, order, base_icon, tint, category, range, cooldown, damage_modifier)
  local g = table.deepcopy(data.raw.gun.pistol)
  g.name = "sd-" .. name
  g.icons = lib.icon(icons .. base_icon, tint)
  g.icon = nil
  g.subgroup = "sd-hunting"
  g.order = order
  g.attack_parameters.ammo_category = category
  g.attack_parameters.range = range
  g.attack_parameters.cooldown = cooldown
  g.attack_parameters.damage_modifier = damage_modifier
  g.attack_parameters.shell_particle = nil
  return g
end

local function ammo(name, order, base_icon, tint, category, damage, magazine)
  local a = table.deepcopy(data.raw.ammo["firearm-magazine"])
  a.name = "sd-" .. name
  a.icons = lib.icon(icons .. base_icon, tint)
  a.icon = nil
  a.pictures = nil
  a.subgroup = "sd-hunting"
  a.order = order
  a.ammo_category = category
  a.magazine_size = magazine
  set_damage(a.ammo_type, damage)
  return a
end

-- A turret on the gun turret's graphics, recoloured.
local function turret(name, order, tint, category, range, cooldown, health)
  local t = table.deepcopy(data.raw["ammo-turret"]["gun-turret"])
  t.name = "sd-" .. name
  t.icons = lib.icon(icons .. "gun-turret.png", tint)
  t.icon = nil
  t.minable = {mining_time = 0.3, result = "sd-" .. name}
  t.max_health = health
  t.next_upgrade = nil
  t.fast_replaceable_group = nil
  t.factoriopedia_simulation = nil
  t.circuit_connector = nil
  t.circuit_wire_max_distance = nil
  t.attack_parameters.ammo_category = category
  t.attack_parameters.range = range
  t.attack_parameters.cooldown = cooldown
  t.attack_parameters.shell_particle = nil
  lib.recolor_fields(t, {"folded_animation", "preparing_animation", "prepared_animation", "attacking_animation",
    "folding_animation", "graphics_set"}, tint)
  local item = {type = "item", name = "sd-" .. name, icons = t.icons, subgroup = "sd-hunting", order = order,
    stack_size = 50, place_result = "sd-" .. name}
  return t, item
end

local swivel, swivel_item = turret("swivel-gun", "q", powder, "sd-bullet", 22, 45, 400)
local repeater, repeater_item = turret("repeating-crossbow", "r", steel, "sd-arrow", 20, 12, 500)

data:extend{
  {type = "ammo-category", name = "sd-bullet"},
  gun("hand-crossbow", "ja", "pistol.png", bronze, "sd-arrow", 20, 50, 1.5),
  ammo("steel-bolts", "jb", "firearm-magazine.png", steel, "sd-arrow", 25, 10),
  {type = "item", name = "sd-gunpowder", subgroup = "sd-hunting", order = "n", stack_size = 100,
   icons = lib.icon(icons .. "explosives.png", powder)},
  gun("musket", "o", "shotgun.png", bronze, "sd-bullet", 22, 90, 1),
  ammo("musket-balls", "p", "shotgun-shell.png", powder, "sd-bullet", 40, 5),
  swivel, swivel_item, repeater, repeater_item,
}

local function recipe(name, category, time, ingredients, results)
  local function list(l)
    local out = {}
    for _, it in pairs(l) do out[#out + 1] = {type = "item", name = it[1], amount = it[2]} end
    return out
  end
  return {type = "recipe", name = "sd-" .. name, category = category, energy_required = time,
    ingredients = list(ingredients), results = list(results), enabled = false, allow_productivity = false}
end

data:extend{
  recipe("hand-crossbow", "sd-crafting", 5, {{"sd-bronze", 5}, {"wood", 5}, {"sd-rope", 3}}, {{"sd-hand-crossbow", 1}}),
  -- Black powder without sulfur: saltpeter and charcoal only, ground in the millstone. Weaker than real
  -- gunpowder (fewer balls per powder); the sulfur recipe of epoch 4 gives twice as much.
  recipe("gunpowder", "sd-grinding", 4, {{"sd-saltpeter", 3}, {"sd-charcoal", 1}}, {{"sd-gunpowder", 2}}),
  recipe("sulfur-gunpowder", "sd-grinding", 4, {{"sd-saltpeter", 2}, {"sd-charcoal", 1}, {"sulfur", 1}}, {{"sd-gunpowder", 4}}),
  recipe("musket", "sd-crafting", 5, {{"sd-bronze", 10}, {"wood", 5}, {"sd-rope", 2}}, {{"sd-musket", 1}}),
  recipe("musket-balls", "sd-crafting", 2, {{"sd-gunpowder", 1}, {"sd-bronze", 1}}, {{"sd-musket-balls", 5}}),
  recipe("swivel-gun", "sd-crafting", 8, {{"sd-bronze", 20}, {"wood", 10}, {"sd-musket", 1}}, {{"sd-swivel-gun", 1}}),
  recipe("steel-bolts", "sd-crafting", 2, {{"steel-plate", 1}, {"wood", 1}}, {{"sd-steel-bolts", 10}}),
  recipe("repeating-crossbow", "sd-crafting", 10, {{"sd-crossbow", 1}, {"steel-plate", 10}, {"iron-gear-wheel", 10}},
    {{"sd-repeating-crossbow", 1}}),
}

local tech_icons = "__base__/graphics/technology/"
local PACKS = {"sd-clay-tablet", "sd-glass-flask", "sd-mechanism", "sd-reactive"}
local function tech(name, icon, tint, count, time, packs, prerequisites, effects)
  local eff, pre, ingredients = {}, {}, {}
  for _, e in pairs(effects) do
    eff[#eff + 1] = type(e) == "string" and {type = "unlock-recipe", recipe = "sd-" .. e} or e
  end
  for _, p in pairs(prerequisites) do pre[#pre + 1] = "sd-" .. p end
  for i = 1, packs do ingredients[i] = {PACKS[i], 1} end
  return {type = "technology", name = "sd-" .. name, icons = lib.icon(tech_icons .. icon .. ".png", tint, 256),
    effects = eff, prerequisites = pre, unit = {count = count, time = time, ingredients = ingredients}}
end
local sharper = {type = "ammo-damage", ammo_category = "sd-arrow", modifier = 0.2}
local function arrowheads(level, t)
  t.upgrade = true
  t.localised_name = {"", {"technology-name.sd-arrowheads"}, " " .. ({"I", "II", "III"})[level]}
  t.localised_description = {"technology-description.sd-arrowheads"}
  return t
end

-- The hand crossbow comes with bronze arrows.
table.insert(data.raw.technology["sd-bow"].effects, {type = "unlock-recipe", recipe = "sd-hand-crossbow"})

data:extend{
  tech("gunpowder", "military", powder, 100, 20, 2, {"millstone", "bronze", "glass-flask"}, {"gunpowder", "musket", "musket-balls"}),
  tech("swivel-gun", "gun-turret", powder, 100, 25, 2, {"gunpowder", "crossbow"}, {"swivel-gun"}),
  tech("steel-bolts", "weapon-shooting-speed-1", steel, 150, 30, 3, {"blast-furnace", "mechanism", "crossbow"},
    {"steel-bolts", "repeating-crossbow"}),
  tech("sulfur-gunpowder", "explosives", {1, 0.9, 0.4}, 150, 30, 3, {"sulfur-processing", "gunpowder"}, {"sulfur-gunpowder"}),
  arrowheads(1, tech("arrowheads-1", "physical-projectile-damage-1", {0.8, 0.8, 0.75}, 50, 15, 1, {"hunting"}, {sharper})),
  arrowheads(2, tech("arrowheads-2", "physical-projectile-damage-1", bronze, 100, 20, 2, {"arrowheads-1", "bow", "glass-flask"}, {sharper})),
  arrowheads(3, tech("arrowheads-3", "physical-projectile-damage-1", steel, 150, 30, 3, {"arrowheads-2", "steel-bolts"}, {sharper})),
}
