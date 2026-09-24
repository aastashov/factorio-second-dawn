-- Tin ore: hard rock, not in the starting area (scripts/start.lua guarantees one patch 150–250 tiles out).
local lib = require("prototypes.lib")
local resource_autoplace = require("resource-autoplace")
local tint = lib.colors.tin

local r = table.deepcopy(data.raw.resource["iron-ore"])
r.name = "sd-tin-ore"
r.category = "sd-hard"
r.icons = lib.icon("__base__/graphics/icons/iron-ore.png", tint)
r.icon = nil
r.minable = {mining_time = 1, result = "sd-tin-ore"}
r.map_color = {0.62, 0.66, 0.74}
r.mining_visualisation_tint = tint
r.factoriopedia_simulation = nil
lib.recolor(r.stages, tint)
r.autoplace = resource_autoplace.resource_autoplace_settings{
  name = "sd-tin-ore", order = "b", base_density = 6, base_spots_per_km2 = 1.5,
  has_starting_area_placement = false, regular_rq_factor_multiplier = 1,
}
-- never at the camp: the first expedition is the point
r.autoplace.probability_expression = "(" .. r.autoplace.probability_expression .. ") * (distance > 160)"
data:extend{r, {type = "autoplace-control", name = "sd-tin-ore", richness = true, order = "b-i", category = "resource",
  localised_name = {"", "[entity=sd-tin-ore] ", {"entity-name.sd-tin-ore"}}}}
local gen = data.raw.planet.nauvis.map_gen_settings
gen.autoplace_controls["sd-tin-ore"] = {}
gen.autoplace_settings.entity.settings["sd-tin-ore"] = {}

-- Coal burns hot enough for kilns, alembics and the chamber.
data.raw.item.coal.fuel_category = "sd-charcoal"
