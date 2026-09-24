-- Buildings drawn from imported art (docs/PROMPTS.md, tools/art.sh): runs in data-final-fixes and replaces
-- the recoloured vanilla graphics of every building that has pictures in prototypes/art-sizes.lua.
-- Layers: <name>-ground (optional), <name>-shadow, the idle state (<name>-idle or -unlit, else <name>);
-- while working, <name> itself is drawn on top, plus the extras below.
local lib = require("prototypes.lib")
local sizes = require("prototypes.art-sizes")

-- Per building: where the picture sits on the tile grid, and effects while working.
local EXTRAS = {
  ["sd-campfire"] = {shift = {0.08, -0.05}, light = {intensity = 0.8, size = 12, color = {1, 0.65, 0.35}},
    flame = {scale = 0.22, shift = {0.02, -0.3}}},
  ["sd-scholar-desk"] = {shift = {0, -0.1}, light = {intensity = 0.5, size = 6, color = {1, 0.8, 0.5}}},
}

local function find_entity(name)
  for type, protos in pairs(data.raw) do
    local p = protos[name]
    if p and p.collision_box and type ~= "item" then return p end
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
    if x.flame then
      local flame = table.deepcopy(data.raw.fire["fire-flame"].pictures[1])
      flame.scale, flame.shift, flame.draw_as_glow = x.flame.scale, x.flame.shift, true
      working[#working + 1] = flame
    end

    if entity.type == "furnace" or entity.type == "assembling-machine" then
      local visualisations = {}
      for _, w in pairs(working) do visualisations[#visualisations + 1] = {animation = w} end
      if x.light then visualisations[#visualisations + 1] = {effect = "flicker", light = x.light} end
      entity.graphics_set = {animation = {layers = base}, working_visualisations = visualisations}
    elseif entity.type == "lab" then
      local on = table.deepcopy(base)
      for _, w in pairs(working) do on[#on + 1] = w end
      entity.on_animation = {layers = on}
      entity.off_animation = {layers = base}
      if x.light then entity.light = x.light end
    else
      error("prototypes/art.lua: art for " .. entity.type .. " " .. name .. " is not wired yet")
    end
  end
end
