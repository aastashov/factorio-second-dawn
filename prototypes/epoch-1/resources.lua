-- Soft-rock resources of epoch 1: stone look-alikes in their own colour, placed by map generation with
-- a guaranteed spot in the starting area (scripts/start.lua adds one if generation missed).
local lib = require("prototypes.lib")
local resource_autoplace = require("resource-autoplace")
local c = lib.colors

local function resource(name, tint, mining_time, order, density, spots)
  local r = table.deepcopy(data.raw.resource.stone)
  r.name = "sd-" .. name
  r.icons = lib.icon("__base__/graphics/icons/stone.png", tint)
  r.icon = nil
  r.minable = {mining_time = mining_time, result = "sd-" .. name}
  r.map_color = {tint[1] * 0.8, tint[2] * 0.8, tint[3] * 0.8}
  r.mining_visualisation_tint = tint
  r.factoriopedia_simulation = nil
  lib.recolor(r.stages, tint)
  r.autoplace = resource_autoplace.resource_autoplace_settings{
    name = "sd-" .. name,
    order = "b",
    base_density = density,
    base_spots_per_km2 = spots,
    has_starting_area_placement = true,
    regular_rq_factor_multiplier = 1,
    starting_rq_factor_multiplier = 1.1,
  }
  data:extend{
    r,
    {type = "autoplace-control", name = "sd-" .. name, richness = true, order = "b-" .. order, category = "resource"},
  }
  local gen = data.raw.planet.nauvis.map_gen_settings
  gen.autoplace_controls["sd-" .. name] = {}
  gen.autoplace_settings.entity.settings["sd-" .. name] = {}
end

resource("clay", c.clay, 1, "f", 8, 2.5)
resource("shells", c.shell, 1, "g", 6, 2)
resource("saltpeter", c.saltpeter, 1.5, "h", 6, 2)
