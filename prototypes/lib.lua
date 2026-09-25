-- Helpers for building Second Dawn prototypes out of vanilla graphics: recoloured and rescaled sprites,
-- layered icons, burner energy sources.
local lib = {}

lib.colors = {
  clay = {0.86, 0.56, 0.40},
  wood = {0.78, 0.58, 0.38},
  stone = {0.62, 0.62, 0.60},
  shell = {1.00, 0.90, 0.84},
  saltpeter = {0.92, 0.95, 1.00},
  fruit = {0.85, 0.25, 0.30},
  fiber = {0.62, 0.72, 0.35},
  lime = {0.98, 0.97, 0.92},
  mash = {0.75, 0.55, 0.25},
  spirit = {0.85, 0.92, 1.00},
  acid = {0.95, 0.80, 0.30},
  charge = {0.55, 0.95, 0.80},
  green = {0.55, 0.80, 0.45},
  copper = {0.85, 0.55, 0.35},
}

local function is_sprite(t)
  return t.filename ~= nil or t.filenames ~= nil or t.stripes ~= nil
end

-- Walks a graphics definition: every sprite gets `scale` applied (with its shift), every sprite that is
-- not a shadow, light, glow or runtime-tinted mask gets `tint`.
function lib.recolor(t, tint, scale, seen)
  if type(t) ~= "table" then return end
  seen = seen or {}
  if seen[t] then return end
  seen[t] = true
  if is_sprite(t) then
    if scale and scale ~= 1 then
      t.scale = (t.scale or 1) * scale
      if t.shift then t.shift = {(t.shift[1] or t.shift.x) * scale, (t.shift[2] or t.shift.y) * scale} end
    end
    if tint and not (t.draw_as_shadow or t.draw_as_light or t.draw_as_glow or t.apply_runtime_tint) then
      t.tint = tint
    end
  end
  for k, v in pairs(t) do
    if type(v) == "table" and k ~= "tint" and k ~= "shift" then lib.recolor(v, tint, scale, seen) end
  end
end

function lib.recolor_fields(entity, fields, tint, scale)
  for _, f in pairs(fields) do
    if entity[f] then lib.recolor(entity[f], tint, scale) end
  end
end

-- Collision and selection boxes for a w×h entity. 0.3 tiles free on each side, like vanilla assemblers:
-- two buildings side by side leave 0.6, and a character (0.4 wide) walks between them.
function lib.size(entity, w, h)
  h = h or w
  entity.collision_box = {{-w / 2 + 0.3, -h / 2 + 0.3}, {w / 2 - 0.3, h / 2 - 0.3}}
  entity.selection_box = {{-w / 2, -h / 2}, {w / 2, h / 2}}
  entity.drawing_box_vertical_extension = nil
end

function lib.icon(path, tint, size)
  return {{icon = path, icon_size = size or 64, tint = tint}}
end

local barrel = "__base__/graphics/icons/fluid/barreling/"

function lib.jug_icon(fill)
  if not fill then -- A sprite imported by tools/import_art.py: graphics/entity/<building>/<name>.png at 64 px per tile, drawn
-- like vanilla's high-resolution sprites. `name` is the building or one of its layers ("sd-campfire-unlit",
-- "sd-campfire-shadow"); pixel sizes come from prototypes/art-sizes.lua.
local art_sizes = require("prototypes.art-sizes")
function lib.art_sprite(building, layer, shift, extra)
  local name = layer and (building .. "-" .. layer) or building
  local size = art_sizes[name]
  local sprite = {filename = "__second-dawn__/graphics/entity/" .. building .. "/" .. name .. ".png",
    width = size[1], height = size[2], scale = 0.5, shift = shift}
  for k, v in pairs(extra or {}) do sprite[k] = v end
  return sprite
end

return lib.icon(barrel .. "barrel-empty.png", lib.colors.clay) end
  return {
    {icon = barrel .. "barrel-fill.png", icon_size = 64, tint = lib.colors.clay},
    {icon = barrel .. "barrel-side-mask.png", icon_size = 64, tint = fill},
    {icon = barrel .. "barrel-hoop-top-mask.png", icon_size = 64, tint = fill},
  }
end

local smoke = table.deepcopy(data.raw.furnace["stone-furnace"].energy_source.smoke)

-- Burner energy source. `fuel` is "wood" (anything burnable) or "charcoal" (charcoal only).
function lib.burner(fuel, pollution)
  return {
    type = "burner",
    fuel_categories = fuel == "charcoal" and {"sd-charcoal"} or {"chemical", "sd-charcoal"},
    effectivity = 1,
    fuel_inventory_size = 1,
    emissions_per_minute = {pollution = pollution or 2},
    light_flicker = {color = {0, 0, 0}, minimum_intensity = 0.6, maximum_intensity = 0.95},
    smoke = smoke,
  }
end

-- Ship sprites rendered by tools/render_ships.py: 64 directions, 8 x 8 frames of 256 px, plus a shadow sheet.
function lib.ship_pictures(name)
  local path = "__second-dawn__/graphics/entity/" .. name .. "/" .. name
  local function sheet(file, shadow)
    return {filenames = {file}, width = 256, height = 256, direction_count = 64, line_length = 8, lines_per_file = 8,
      scale = 1, draw_as_shadow = shadow or nil}
  end
  return {rotated = {layers = {sheet(path .. ".png"), sheet(path .. "-shadow.png", true)}}}
end

function lib.ship_icon(name)
  return {{icon = "__second-dawn__/graphics/icons/" .. name .. ".png", icon_size = 64}}
end

-- A sprite imported by tools/import_art.py: graphics/entity/<building>/<name>.png at 64 px per tile, drawn
-- like vanilla's high-resolution sprites. `name` is the building or one of its layers ("sd-campfire-unlit",
-- "sd-campfire-shadow"); pixel sizes come from prototypes/art-sizes.lua.
local art_sizes = require("prototypes.art-sizes")
function lib.art_sprite(building, layer, shift, extra)
  local name = layer and (building .. "-" .. layer) or building
  local size = art_sizes[name]
  local sprite = {filename = "__second-dawn__/graphics/entity/" .. building .. "/" .. name .. ".png",
    width = size[1], height = size[2], scale = 0.5, shift = shift}
  for k, v in pairs(extra or {}) do sprite[k] = v end
  return sprite
end

return lib
