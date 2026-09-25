-- Buildings drawn from imported art (docs/PROMPTS.md, tools/art.sh): runs in data-final-fixes and replaces
-- the recoloured vanilla graphics of every building that has pictures in prototypes/art-sizes.lua.
-- Layers: <name>-ground (optional), <name>-shadow, the idle state (<name>-idle or -unlit, else <name>);
-- while working, <name> itself is drawn on top, then the flames (<name>-fire, 16 frames, or vanilla's),
-- plus the extras below. Lairs (unit-spawner) have a single picture and <name>-ruin as their corpse; simple
-- entities and walls (a ruin fragment, drawn the same whatever it joins) have a single picture.
local lib = require("prototypes.lib")
local sizes = require("prototypes.art-sizes")

-- Per building: where the picture sits on the tile grid, effects while working, and where the recipe icon is
-- drawn in alt mode (icon_draw_specification).
local EXTRAS = {
  ["sd-campfire"] = {shift = {0, -0.05}, light = {intensity = 0.8, size = 12, color = {1, 0.65, 0.35}},
    flame = {scale = 0.22, shift = {0.02, -0.3}}, fire_shift = {0, -0.35},
    icon = {scale = 0.4, shift = {0, -0.75}}}, -- the recipe icon in alt mode: small, above the fire, not over it
  ["sd-ruin-wall"] = {shift = {0, -0.2}},
  ["sd-scholar-desk"] = {shift = {0, -0.1}, light = {intensity = 0.5, size = 6, shift = {-1.1, -0.9}, color = {1, 0.8, 0.5}}},
}

local function find_entity(name)
  for type, protos in pairs(data.raw) do
    local p = protos[name]
    if p and p.collision_box and type ~= "item" then return p end
  end
end

-- Resources: <name>-stages is vanilla's ore sheet, 8 variations x 8 stages (import_art.py --pieces).
for key, size in pairs(sizes) do
  local name = key:match("^(.+)%-stages$")
  local resource = name and data.raw.resource[name]
  if resource then
    resource.stages = {sheet = {filename = "__second-dawn__/graphics/entity/" .. name .. "/" .. key .. ".png",
      priority = "extra-high", size = size[1] / 8, frame_count = 8, variation_count = 8, scale = 0.5}}
  end
end

for name in pairs(sizes) do
  local entity = find_entity(name)
  if entity then
    local x = EXTRAS[name] or {}
    local at = x.shift or {0, 0}
    local idle_state = sizes[name .. "-idle"] and "idle" or sizes[name .. "-unlit"] and "unlit" or nil
    local base = {}
    if sizes[name .. "-ground"] then base[#base + 1] = lib.art_sprite(name, "ground", at) end
    base[#base + 1] = lib.art_sprite(name, "shadow", at, {draw_as_shadow = true})
    base[#base + 1] = lib.art_sprite(name, idle_state, at)
    local working = {}
    if idle_state then working[#working + 1] = lib.art_sprite(name, nil, at) end
    if sizes[name .. "-fire"] then -- drawn flames: 16 frames, 4 per line
      local size = sizes[name .. "-fire"]
      working[#working + 1] = {filename = "__second-dawn__/graphics/entity/" .. name .. "/" .. name .. "-fire.png",
        width = size[1], height = size[2], frame_count = 16, line_length = 4, animation_speed = 0.4, scale = 0.5,
        shift = x.fire_shift or {0, -0.5}, draw_as_glow = true}
    elseif x.flame then -- vanilla's flames
      local flame = table.deepcopy(data.raw.fire["fire-flame"].pictures[1])
      flame.scale, flame.shift, flame.draw_as_glow = x.flame.scale, x.flame.shift, true
      working[#working + 1] = flame
    end

    if entity.type == "furnace" or entity.type == "assembling-machine" then
      local visualisations = {}
      for _, w in pairs(working) do visualisations[#visualisations + 1] = {animation = w} end
      if x.light then visualisations[#visualisations + 1] = {effect = "flicker", light = x.light} end
      entity.graphics_set = {animation = {layers = base}, working_visualisations = visualisations}
      if x.icon then entity.icon_draw_specification = x.icon end
    elseif entity.type == "lab" then
      local on = table.deepcopy(base)
      for _, w in pairs(working) do on[#on + 1] = w end
      entity.on_animation = {layers = on}
      entity.off_animation = {layers = base}
      if x.light then entity.light = x.light end
    elseif entity.type == "unit-spawner" then -- lairs; <name>-ruin is left lying where one was destroyed
      entity.graphics_set = {animations = {{layers = base}}}
      if sizes[name .. "-ruin"] then
        data:extend{{type = "corpse", name = name .. "-ruin", icons = entity.icons, icon = entity.icon,
          flags = {"placeable-neutral", "not-on-map"}, hidden_in_factoriopedia = true,
          selection_box = entity.selection_box, selectable_in_game = false,
          time_before_removed = 15 * 60 * 60, final_render_layer = "remnants", remove_on_tile_placement = true,
          animation = {layers = {lib.art_sprite(name, "shadow", at, {draw_as_shadow = true}),
            lib.art_sprite(name, "ruin", at)}}}}
        entity.corpse = name .. "-ruin"
      end
    elseif entity.type == "simple-entity-with-owner" then
      entity.picture = {layers = base}
    elseif entity.type == "wall" then -- a lone piece of wall: the same picture whatever it joins, no filling
      local empty = {filename = "__core__/graphics/empty.png", size = 1}
      for key in pairs(entity.pictures) do
        entity.pictures[key] = (key == "filling" or key:match("patch$")) and empty or {layers = base}
      end
    else
      error("prototypes/art.lua: art for " .. entity.type .. " " .. name .. " is not wired yet")
    end
  end
end
