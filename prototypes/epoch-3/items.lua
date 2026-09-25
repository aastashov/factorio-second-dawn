local lib = require("prototypes.lib")
local c = lib.colors
local icons = "__base__/graphics/icons/"

data:extend{
  {type = "recipe-category", name = "sd-blast"},
  {type = "recipe-category", name = "sd-awakening-electric"},
  {type = "recipe-category", name = "sd-farm-boar"},
  {type = "recipe-category", name = "sd-farm-wolf"},
  {type = "recipe-category", name = "sd-farm-bear"},
  {type = "tool", name = "sd-mechanism", subgroup = "sd-science", order = "c", stack_size = 200, durability = 1,
   icons = lib.icon(icons .. "chemical-science-pack.png", {0.8, 0.75, 0.7})},
  {type = "item", name = "sd-electrode", subgroup = "sd-metal", order = "c", stack_size = 100,
   icons = lib.icon(icons .. "copper-cable.png", {1, 0.75, 0.45})},
  {type = "item", name = "sd-feed", subgroup = "sd-hunting", order = "n", stack_size = 100,
   icons = lib.icon(icons .. "wood.png", {0.85, 0.8, 0.4})},
  {type = "fluid", name = "sd-revival-charge-3", subgroup = "sd-revival", order = "a3",
   default_temperature = 15, base_color = {0.75, 0.6, 1}, flow_color = {0.75, 0.6, 1},
   icons = lib.icon(icons .. "fluid/water.png", {0.75, 0.6, 1}), auto_barrel = false},
  {type = "item", name = "sd-lab", subgroup = "sd-research-buildings", order = "b", stack_size = 10,
   icon = "__base__/graphics/icons/lab.png", icon_size = 64, place_result = "sd-lab"},
  {type = "item", name = "sd-revival-chamber-2", subgroup = "sd-revival", order = "c", stack_size = 1,
   icons = lib.icon(icons .. "nuclear-reactor.png", {0.6, 0.7, 0.85}), place_result = "sd-revival-chamber-2"},
}

-- Farms: only from captured lairs, never crafted.
for _, f in pairs{{"boar-farm", "spitter-spawner", {0.60, 0.42, 0.28}, "o"}, {"wolf-kennel", "biter-spawner", {0.60, 0.58, 0.55}, "p"},
                  {"bear-pen", "biter-spawner", {0.42, 0.30, 0.22}, "q"}} do
  data:extend{{type = "item", name = "sd-" .. f[1], subgroup = "sd-hunting", order = f[4], stack_size = 10,
    icons = lib.icon(icons .. f[2] .. ".png", f[3]), place_result = "sd-" .. f[1]}}
end

-- Capture net: thrown like a grenade, the landing runs script effect "sd-capture".
local projectile = table.deepcopy(data.raw.projectile.grenade)
projectile.name = "sd-net-projectile"
projectile.action = {type = "direct", action_delivery = {type = "instant", target_effects = {{type = "script", effect_id = "sd-capture"}}}}
projectile.final_action = nil
lib.recolor(projectile.animation, {0.85, 0.7, 0.45})

local net = table.deepcopy(data.raw.capsule.grenade)
net.name = "sd-net"
net.icons = lib.icon(icons .. "grenade.png", {0.85, 0.7, 0.45})
net.icon = nil
net.pictures = nil
net.subgroup = "sd-hunting"
net.order = "r"
net.stack_size = 20
net.capsule_action.attack_parameters.range = 15
net.capsule_action.attack_parameters.ammo_type.action[1].action_delivery.projectile = "sd-net-projectile"
data:extend{projectile, net}
