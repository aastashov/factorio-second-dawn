-- New game setup: no vanilla starting kit or crash site, and a starting area that surely has every
-- epoch 1 resource and fruit trees (the garden needs fruit to start, so missing fruit would be a dead end).
local start = {}

local RESOURCES = {"sd-clay", "sd-shells", "sd-saltpeter", "stone", "copper-ore", "coal", "iron-ore"}
local TIN = {"sd-tin-ore", 150, 250} -- the first expedition: tin is never in the starting area
local FRUIT_TREES = {"tree-02-red", "tree-08-red", "tree-09-red"}
local RADIUS = 150

-- Dying costs the inventory (it waits in the corpse), not the means to get it back: a bow and arrows.
function start.configure_respawn()
  local fp = remote.interfaces["freeplay"]
  if fp and fp.set_respawn_items then
    remote.call("freeplay", "set_respawn_items", {["sd-bow"] = 1, ["sd-stone-arrows"] = 20})
  end
end

-- 0.12, once: players who died before the respawn kit existed and are back empty-handed get it too.
function start.give_kit_once()
  if storage.kit_given then return end
  storage.kit_given = true
  for _, player in pairs(game.players) do
    local c = player.character
    if c and c.get_item_count("sd-bow") == 0 then
      c.insert{name = "sd-bow", count = 1}
      c.insert{name = "sd-stone-arrows", count = 20}
    end
  end
end

function start.configure_freeplay()
  -- a rocket launch is not the end here: the game is won on the Moon (scripts/moon.lua)
  if remote.interfaces["silo_script"] then remote.call("silo_script", "set_no_victory", true) end
  local fp = remote.interfaces["freeplay"]
  if not fp then return end
  if fp.set_disable_crashsite then remote.call("freeplay", "set_disable_crashsite", true) end
  if fp.set_skip_intro then remote.call("freeplay", "set_skip_intro", true) end
  if fp.set_created_items then remote.call("freeplay", "set_created_items", {}) end
  start.configure_respawn()
end

local function land_spot(surface, rng, name, min_d, max_d, half)
  for _ = 1, 60 do
    local a = rng() * 2 * math.pi
    local d = min_d + rng() * (max_d - min_d)
    local cx, cy = math.floor(math.cos(a) * d), math.floor(math.sin(a) * d)
    local ok = true
    for x = -half, half do
      for y = -half, half do
        if not surface.can_place_entity{name = name, position = {cx + x + 0.5, cy + y + 0.5}} then ok = false end
      end
    end
    if ok then return cx, cy end
  end
end

local function place_patch(surface, rng, name, min_d, max_d)
  local cx, cy = land_spot(surface, rng, name, min_d or 40, max_d or 110, 3)
  if not cx then return false end
  for x = -3, 3 do
    for y = -3, 3 do
      if x * x + y * y <= 10 then
        surface.create_entity{name = name, position = {cx + x + 0.5, cy + y + 0.5}, amount = 1200}
      end
    end
  end
  return true
end

-- The camp's clay: at least CLAY_AMOUNT within reach of the start, so a few diggers can run for hours.
local CLAY_AMOUNT = 150000
local function ensure_clay(surface, rng)
  local have = 0
  for _, e in pairs(surface.find_entities_filtered{name = "sd-clay", position = {0, 0}, radius = 100}) do have = have + e.amount end
  if have >= CLAY_AMOUNT then return false end
  local cx, cy = land_spot(surface, rng, "sd-clay", 25, 70, 6)
  if not cx then return false end
  for x = -6, 6 do
    for y = -6, 6 do
      local pos = {cx + x + 0.5, cy + y + 0.5}
      if x * x + y * y <= 36 and surface.can_place_entity{name = "sd-clay", position = pos} then
        surface.create_entity{name = "sd-clay", position = pos, amount = 1500}
      end
    end
  end
  return true
end

-- Hands are quicker in this age: +50% mining by hand for every team.
function start.hands(force)
  if force.manual_mining_speed_modifier < 0.5 then force.manual_mining_speed_modifier = 0.5 end
end

local function plant_trees(surface, rng)
  local cx, cy = land_spot(surface, rng, "tree-02-red", 20, 60, 2)
  if not cx then return end
  for i = 1, 14 do
    local name = FRUIT_TREES[i % #FRUIT_TREES + 1]
    local pos = surface.find_non_colliding_position(name, {cx + rng(-6, 6), cy + rng(-6, 6)}, 8, 1)
    if pos then surface.create_entity{name = name, position = pos} end
  end
end

-- Returns what had to be added, for tests and the log.
function start.ensure_starting_area(surface)
  surface.request_to_generate_chunks({0, 0}, math.ceil(TIN[3] / 32))
  surface.force_generate_chunk_requests()
  local rng = game.create_random_generator(surface.map_gen_settings.seed)
  local added = {}
  for _, name in pairs(RESOURCES) do
    if surface.count_entities_filtered{name = name, position = {0, 0}, radius = RADIUS, limit = 1} == 0 then
      if place_patch(surface, rng, name) then added[#added + 1] = name end
    end
  end
  if ensure_clay(surface, rng) then added[#added + 1] = "big clay patch" end
  if surface.count_entities_filtered{name = TIN[1], position = {0, 0}, radius = TIN[3], limit = 1} == 0 then
    if place_patch(surface, rng, TIN[1], TIN[2], TIN[3]) then added[#added + 1] = TIN[1] end
  end
  if surface.count_entities_filtered{name = FRUIT_TREES, position = {0, 0}, radius = 120} < 10 then
    plant_trees(surface, rng)
    added[#added + 1] = "fruit-trees"
  end
  if #added > 0 then log("Second Dawn: added to the starting area: " .. table.concat(added, ", ")) end
  return added
end

return start
