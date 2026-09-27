-- Screenshots for the mod portal (tools/screenshots.sh): builds a few scenes and takes pictures of them with
-- game.take_screenshot, plus the tech tree and the crafting menu (GUI, needs the local player). Needs a
-- Factorio with graphics; headless runs only build the scenes.
local S = {}
local force = "player"

local function clear(s, cx, cy, r, tile)
  local tiles = {}
  for x = cx - r, cx + r do for y = cy - r, cy + r do tiles[#tiles + 1] = {name = tile or "grass-1", position = {x, y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{cx - r, cy - r}, {cx + r, cy + r}}}) do
    if e.type ~= "character" then e.destroy() end
  end
end

local function put(s, name, x, y, dir)
  local e = s.create_entity{name = name, position = {x, y}, direction = dir, force = force, raise_built = true}
  return e
end

local function fuel(e, name, n) local inv = e.get_fuel_inventory(); if inv then inv.insert{name = name, count = n} end end

-- A lived-in first camp: fire, clay, a defended work area and the first tiny production line.
local function camp(s, cx, cy)
  clear(s, cx, cy, 22)
  local path = {}
  for x = -17, 17 do for y = -2, 2 do path[#path + 1] = {name = "dirt-7", position = {cx + x, cy + y}} end end
  s.set_tiles(path)
  for x = 0, 9 do for y = -4, 3 do
    s.create_entity{name = "sd-clay", position = {cx + 6 + x + 0.5, cy + y + 0.5}, amount = 2000}
  end end
  for i = 0, 2 do
    local d = put(s, "sd-digger", cx + 7 + i * 3, cy - 3, defines.direction.south)
    fuel(d, "wood", 20)
  end
  for x = cx + 5, cx + 15 do put(s, "sd-wooden-chute", x + 0.5, cy - 0.5, defines.direction.west) end
  put(s, "wooden-chest", cx + 4.5, cy - 0.5)
  for i = 0, 3 do
    local f = put(s, "sd-campfire", cx - 5 + (i % 2) * 2, cy - 5 + math.floor(i / 2) * 2)
    fuel(f, "wood", 20); f.get_inventory(defines.inventory.furnace_source).insert{name = "wood", count = 50}
  end
  local desk = put(s, "sd-scholar-desk", cx - 9, cy - 4)
  fuel(desk, "wood", 20)
  desk.get_inventory(defines.inventory.lab_input).insert{name = "sd-clay-tablet", count = 50}
  for i = 0, 2 do
    local k = put(s, "sd-kiln", cx - 6 + i * 3, cy + 2)
    fuel(k, "sd-charcoal", 20); k.get_inventory(defines.inventory.furnace_source).insert{name = "sd-clay", count = 50}
  end
  for i = 0, 2 do put(s, "sd-lever-arm", cx + 1, cy - 2 + i, defines.direction.west) end
  for x = -18, -5 do put(s, "sd-palisade", cx + x + 0.5, cy + 7.5) end
  for x = 4, 18 do put(s, "sd-palisade", cx + x + 0.5, cy + 7.5) end
  for y = 0, 7 do put(s, "sd-palisade", cx - 17.5, cy + y + 0.5) end
  s.create_entity{name = "character", position = {cx - 2, cy - 1}, force = force}
  game.forces[force].add_research("sd-pottery")
end

-- A pack presses against a defended outpost. This should read as an encounter, not an animal catalogue.
local function wolves(s, cx, cy)
  clear(s, cx, cy, 20)
  for x = -16, 16 do put(s, "sd-palisade", cx + x + 0.5, cy + 4.5) end
  local turret = put(s, "sd-crossbow", cx - 5, cy + 1)
  turret.insert{name = "sd-stone-arrows", count = 100}
  local gun = put(s, "gun-turret", cx + 5, cy + 1)
  gun.insert{name = "firearm-magazine", count = 100}
  s.create_entity{name = "character", position = {cx, cy + 1}, force = force}
  for i = 1, 6 do
    local a = i / 6 * math.pi
    s.create_entity{name = i == 1 and "sd-wolf-leader" or "sd-wolf", position = {cx - 10 + i * 4, cy - 4 + math.sin(a) * 2},
      force = "sd-wildlife"}
  end
end

-- A compact, working early workshop: machines grouped by the materials moving through them, not in a row.
local function workshop(s, cx, cy)
  clear(s, cx, cy, 22)
  local function run(name, x, y, recipe, fuel_name)
    local e = put(s, name, cx + x, cy + y)
    if recipe then pcall(e.set_recipe, recipe) end
    if fuel_name then fuel(e, fuel_name, 20) end
    return e
  end
  run("sd-revival-chamber", -10, -5, nil, "wood")
  run("sd-alembic", -4, -5, nil, "wood")
  run("sd-kiln", 2, -5, nil, "sd-charcoal")
  run("sd-bloomery", 7, -5, nil, "sd-charcoal")
  run("sd-glassworks", 11, -5, nil, "sd-charcoal")
  run("sd-workbench", -10, 1)
  run("sd-fermentation-vat", -6, 1)
  run("sd-millstone", -2, 1)
  run("sd-brazier", 2, 1, nil, "wood")
  run("sd-garden", 7, 1)
  run("sd-woodlot", 12, 1)
  for x = -14, 15 do put(s, "sd-palisade", cx + x + 0.5, cy + 6.5) end
  for x = -12, 12, 3 do put(s, "wooden-chest", cx + x + 0.5, cy + 4.5) end
  s.create_entity{name = "character", position = {cx, cy + 3}, force = force}
end

-- A real harbour: rail-like waterways, a tug with barges, and a pier as the bridge to a new continent.
local function harbour(s, cx, cy)
  clear(s, cx, cy, 28, "deepwater")
  for x = -22, 22, 2 do put(s, "sd-waterway-straight-rail", cx + x, cy, defines.direction.east) end
  local pier = put(s, "sd-pier", cx + 16, cy + 3, defines.direction.east)
  if pier then pier.backer_name = "Northbound" end
  local tug = put(s, "sd-tug", cx - 12, cy, defines.direction.east)
  if tug then fuel(tug, "coal", 20) end
  put(s, "sd-barge", cx - 5, cy, defines.direction.east)
  put(s, "sd-barge", cx + 2, cy, defines.direction.east)
  for x = -20, 14, 8 do put(s, "sd-buoy", cx + x, cy - 2) end
end

-- GUI pictures need the player: the tech tree (a few techs researched) and the crafting menu on the mod's tab.
local function open_tree(p)
  local f = game.forces[force]
  for _, t in pairs{"sd-pottery", "sd-workbench", "sd-levers", "sd-quicklime", "sd-hunting", "sd-fermentation"} do
    if f.technologies[t] then f.technologies[t].researched = true end
  end
  p.open_technology_gui("sd-awakening")
end

local SHOTS = {
  {name = "camp", tick = 600, at = function() return {S.camp[1], S.camp[2]} end, zoom = 2.4, daytime = 0},
  {name = "camp-night", tick = 600, at = function() return {S.camp[1] - 3, S.camp[2] - 2} end, zoom = 2.4, daytime = 0.5},
  {name = "wolves", tick = 30, at = function() return S.wolves end, zoom = 2.8, daytime = 0},
  {name = "workshop", tick = 620, at = function() return {S.workshop[1], S.workshop[2]} end, zoom = 2.2, daytime = 0},
  {name = "harbour", tick = 700, at = function() return S.harbour end, zoom = 1.7, daytime = 0},
  {name = "recipes", tick = 760, gui = function(p)
    if not pcall(function() p.opened = defines.gui_type.controller end) or not p.opened then p.opened = p.character end
    log("SD-TEST recipes opened " .. tostring(p.opened_gui_type))
  end},
  -- the tech tree pauses a single-player game: the last picture
  {name = "tech-tree", tick = 860, gui = open_tree, last = true},
}

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 5 then
    s.request_to_generate_chunks({600, 600}, 3); s.request_to_generate_chunks({600, 700}, 3); s.request_to_generate_chunks({700, 700}, 3)
    s.force_generate_chunk_requests()
    remote.call("second-dawn", "wave_in", 60 * 60 * 60) -- no wave while the pictures are taken
    S.camp = {600, 600}
    S.wolves = {600, 700}
    S.workshop = {700, 600}
    S.harbour = {700, 700}
    s.request_to_generate_chunks({700, 600}, 3); s.force_generate_chunk_requests()
    camp(s, 600, 600)
    wolves(s, 600, 700)
    workshop(s, 700, 600)
    harbour(s, 700, 700)
    storage.built = true
  elseif storage.built then
    local p = game.connected_players[1]
    for _, shot in pairs(SHOTS) do
      if e.tick ~= shot.tick + 5 then goto next end
      -- a window opened by script gets into the picture only when opened in the same tick
      if shot.gui and p then log("SD-TEST open " .. shot.name .. " " .. tostring(pcall(shot.gui, p))) end
      local ok
      if shot.gui then
        ok = p and pcall(game.take_screenshot, {player = p, show_gui = true, resolution = {1920, 1080},
          path = "second-dawn-shots/" .. shot.name .. ".png", allow_in_replay = true})
        if p and not shot.last then p.opened = nil end
      else
        ok = pcall(game.take_screenshot, {surface = s, position = shot.at(), resolution = {1920, 1080}, zoom = shot.zoom,
          path = "second-dawn-shots/" .. shot.name .. ".png", show_entity_info = false, daytime = shot.daytime,
          anti_alias = true, allow_in_replay = true})
      end
      log("SD-TEST shot " .. shot.name .. " " .. tostring(ok))
      if shot.last then helpers.write_file("second-dawn-shots/done.txt", "done") end
      ::next::
    end
    if e.tick == 960 and not p then helpers.write_file("second-dawn-shots/done.txt", "done") end
  end
end)
