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

-- Collision and selection boxes for a w×h entity.
function lib.size(entity, w, h)
  h = h or w
  entity.collision_box = {{-w / 2 + 0.15, -h / 2 + 0.15}, {w / 2 - 0.15, h / 2 - 0.15}}
  entity.selection_box = {{-w / 2, -h / 2}, {w / 2, h / 2}}
  entity.drawing_box_vertical_extension = nil
end

function lib.icon(path, tint, size)
  return {{icon = path, icon_size = size or 64, tint = tint}}
end

local barrel = "__base__/graphics/icons/fluid/barreling/"

function lib.jug_icon(fill)
  if not fill then return lib.icon(barrel .. "barrel-empty.png", lib.colors.clay) end
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

return lib
