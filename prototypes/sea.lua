-- Continents and sea (docs/DESIGN.md §18): a starting continent, cold and hot continents beyond an ocean,
-- a shelf of shallow water along every coast. Landfill covers shallow water; deep landfill, deep water.
local lib = require("prototypes.lib")
local D = settings.startup["sd-climate-distance"].value
local R0 = math.floor(D * 2 / 3)

data:extend{{
  type = "noise-expression",
  name = "sd_elevation",
  -- coast: signed distance to the nearest coast in tiles (positive on land). Near the coast the height
  -- falls from 0 to about -2 over 45-80 tiles: that band is shallow water, deeper is "deepwater".
  -- Inside continents the vanilla relief (lakes, hills) takes over, raised with distance from the coast
  -- so that far inland the big vanilla lakes shrink, and never deeper than shallow water: lakes are
  -- shallow, and a lake that touches the coast does not cut the shelf.
  expression = "min(max(elevation_nauvis + 2 + max(0, coast) * 0.012, -1.9), coast * shelf_slope)",
  local_expressions = {
    wobble = "basis_noise{x = x, y = y, seed0 = map_seed, seed1 = 71, input_scale = 1/350, output_scale = 90}"
          .. " + basis_noise{x = x, y = y, seed0 = map_seed, seed1 = 72, input_scale = 1/90, output_scale = 25}",
    start = R0 .. " - distance + wobble",
    north = "-y - " .. (D + 300) .. " + wobble",
    south = "y - " .. (D + 300) .. " + wobble",
    coast = "max(start, north, south)",
    -- never flat or negative, or the open ocean would get land specks
    -- Measured (tests/scenarios/sea.lua, 32 rays): the shelf is about 2 / slope tiles wide, so
    -- 0.025-0.045 gives 45-80 tiles.
    shelf_slope = "max(0.025, 0.035 + 0.01 * basis_noise{x = x, y = y, seed0 = map_seed, seed1 = 74, input_scale = 1/200, output_scale = 1})",
  },
}}
if settings.startup["sd-continents"].value then
  data.raw.planet.nauvis.map_gen_settings.property_expression_names.elevation = "sd_elevation"
end

-- Landfill: vanilla landfill only on shallow water; deep landfill only on deep water.
local SHALLOW = {"water", "water-green", "water-shallow", "water-mud"}
local DEEP = {"deepwater", "deepwater-green"}
data.raw.item.landfill.place_as_tile.tile_condition = SHALLOW

local deep = table.deepcopy(data.raw.item.landfill)
deep.name = "sd-deep-landfill"
deep.icons = lib.icon("__base__/graphics/icons/landfill.png", {0.6, 0.6, 0.7})
deep.icon = nil
deep.place_as_tile.tile_condition = DEEP
deep.order = "c[landfill]-b[deep]"

local function recipe(name, ingredients, result)
  local ing = {}
  for _, it in pairs(ingredients) do ing[#ing + 1] = {type = "item", name = it[1], amount = it[2]} end
  return {type = "recipe", name = "sd-" .. name, category = "sd-crafting", energy_required = 1, ingredients = ing,
    results = {{type = "item", name = result, amount = 1}}, enabled = false}
end
data:extend{
  deep,
  recipe("landfill", {{"stone", 20}}, "landfill"),
  recipe("deep-landfill", {{"stone", 150}, {"steel-plate", 5}, {"sd-mortar", 10}}, "sd-deep-landfill"),
  {type = "technology", name = "sd-land-reclamation", icons = lib.icon("__base__/graphics/technology/landfill.png", nil, 256),
   effects = {{type = "unlock-recipe", recipe = "sd-landfill"}}, prerequisites = {"sd-fluid-handling"},
   unit = {count = 100, time = 30, ingredients = {{"sd-clay-tablet", 1}, {"sd-glass-flask", 1}}}},
  {type = "technology", name = "sd-deep-landfill", icons = lib.icon("__base__/graphics/technology/landfill.png", {0.6, 0.6, 0.7}, 256),
   effects = {{type = "unlock-recipe", recipe = "sd-deep-landfill"}}, prerequisites = {"sd-mechanism", "sd-land-reclamation"},
   unit = {count = 150, time = 30, ingredients = {{"sd-clay-tablet", 1}, {"sd-glass-flask", 1}, {"sd-mechanism", 1}}}},
}
