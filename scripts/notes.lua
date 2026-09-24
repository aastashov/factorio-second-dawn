-- Ruins, notes and caches (docs/DESIGN.md §13). Ruins are placed as chunks generate, from a random
-- generator kept in storage so every client places the same ones. A note read by anyone is read by the
-- whole force: it goes into the force's diary and may unlock a recipe or reveal a cache.
local NOTES = require("scripts.notes-data")

local notes = {}

local BY_ID = {}
for _, n in pairs(NOTES) do BY_ID[n.id] = n end

local RUIN_CHANCE = 0.1         -- per generated chunk
local START_RUINS = {60, 150}   -- guaranteed ruins near spawn, distance range
local CACHE_DISTANCE = {100, 300}

-- Loot by epoch; a cache holds 3 of these, a ruin chest 1. Caches use the reading force's epoch.
local LOOT = {
  {{"sd-jug", 10}, {"sd-brick", 20}, {"sd-rope", 20}, {"sd-saltpeter", 20}, {"sd-fruit", 20}, {"sd-charcoal", 30}, {"sd-mortar", 10}},
  {{"copper-plate", 30}, {"sd-tin", 15}, {"sd-bronze", 20}, {"sd-glass", 20}, {"sd-bottle", 10}, {"coal", 50}, {"sd-potash", 10}},
}

local function epoch_of(force)
  if force and force.technologies["sd-smelting"].researched then return 2 end
  return 1
end

function notes.init()
  if storage.notes then return end
  storage.notes = {
    rng = game.create_random_generator(game.surfaces.nauvis.map_gen_settings.seed + 7919),
    placed = {},       -- unique note id -> true once a ruin holds it
    entities = {},     -- note entity unit number -> note id
    read = {},         -- force index -> list of {id = ..., position = ...}
    seen = {},         -- player index -> number of diary entries seen
    ruins = 0,
    caches = 0,
  }
end

local function force_diary(force)
  local d = storage.notes.read[force.index]
  if not d then
    d = {}
    for _, n in pairs(NOTES) do
      if n.kind == "journal" then d[#d + 1] = {id = n.id} end
    end
    storage.notes.read[force.index] = d
  end
  return d
end
notes.diary = force_diary

local function rand(a, b) return storage.notes.rng(a, b) end
local function randf() return storage.notes.rng() end

-- A land spot `min..max` tiles from `origin` where a size×size square is free and dry.
local function land_spot(surface, origin, min, max, size)
  for _ = 1, 40 do
    local a = randf() * 2 * math.pi
    local d = min + randf() * (max - min)
    local p = {x = math.floor(origin.x + math.cos(a) * d) + 0.5, y = math.floor(origin.y + math.sin(a) * d) + 0.5}
    local area = {{p.x - size, p.y - size}, {p.x + size, p.y + size}}
    if surface.is_chunk_generated({math.floor(p.x / 32), math.floor(p.y / 32)})
      and surface.count_tiles_filtered{area = area, collision_mask = "water_tile", limit = 1} == 0
      and surface.count_entities_filtered{area = area, type = {"resource", "tree", "simple-entity", "container", "wall"}, limit = 1} == 0 then
      return p
    end
  end
end

-- Next note for a ruin: a random unplaced unique note, or a cache note when all are placed.
local function pick_note()
  local free = {}
  for _, n in pairs(NOTES) do
    if n.kind ~= "journal" and n.kind ~= "cache" and not storage.notes.placed[n.id] then free[#free + 1] = n.id end
  end
  if #free == 0 then return "cache" end
  return free[rand(1, #free)]
end

local function fill(chest, count, epoch)
  local pool = LOOT[epoch or 1]
  for _ = 1, count do
    local it = pool[rand(1, #pool)]
    chest.insert{name = it[1], count = it[2]}
  end
end

function notes.build_ruin(surface, p, id)
  id = id or pick_note()
  if id ~= "cache" then storage.notes.placed[id] = true end
  local pieces = rand(6, 14)
  for i = 1, pieces do
    local side, t = rand(0, 3), rand(-2, 2)
    local pos = ({{t, -3}, {3, t}, {t, 3}, {-3, t}})[side + 1]
    local wall = surface.create_entity{name = "sd-ruin-wall", position = {p.x + pos[1], p.y + pos[2]}, force = "neutral"}
    if wall then wall.health = wall.max_health * (0.3 + 0.5 * randf()) end
  end
  local note = surface.create_entity{name = "sd-note", position = p, force = "neutral"}
  storage.notes.entities[note.unit_number] = id
  if randf() < 0.4 then
    local chest = surface.create_entity{name = "wooden-chest", position = {p.x + 1, p.y + 1}, force = "neutral"}
    if chest then fill(chest, 1) end
  end
  storage.notes.ruins = storage.notes.ruins + 1
  return note
end

function notes.place_start_ruins(surface)
  local first = land_spot(surface, {x = 0, y = 0}, START_RUINS[1], START_RUINS[2], 4)
  if first then notes.build_ruin(surface, first, "first-steps") end
  local second = land_spot(surface, {x = 0, y = 0}, START_RUINS[1], START_RUINS[2], 4)
  if second then notes.build_ruin(surface, second) end
end

function notes.on_chunk_generated(e)
  if not storage.notes or e.surface.name ~= "nauvis" then return end
  local c = e.position
  if math.abs(c.x) <= 5 and math.abs(c.y) <= 5 then return end -- the start area gets its own ruins
  if randf() >= RUIN_CHANCE then return end
  local lt = e.area.left_top
  local centre = {x = lt.x + 16, y = lt.y + 16}
  local p = land_spot(e.surface, centre, 0, 8, 4)
  if p then notes.build_ruin(e.surface, p) end
end

local function add_cache(force, surface, near)
  local p = land_spot(surface, near, CACHE_DISTANCE[1], CACHE_DISTANCE[2], 1)
  if not p then return nil end
  local chest = surface.create_entity{name = "wooden-chest", position = p, force = "neutral"}
  fill(chest, 3, epoch_of(force))
  force.add_chart_tag(surface, {position = p, icon = {type = "item", name = "wooden-chest"}})
  storage.notes.caches = storage.notes.caches + 1
  return p
end

-- Reads a note entity for `force`: diary entry, effect, message. Returns the note id.
function notes.read(entity, force)
  local id = storage.notes.entities[entity.unit_number]
  if not id then return nil end
  storage.notes.entities[entity.unit_number] = nil
  local note = BY_ID[id]
  local entry = {id = id}
  if note.kind == "recipe" then
    force.recipes[note.recipe].enabled = true
  elseif note.kind == "cache" then
    entry.position = add_cache(force, entity.surface, entity.position)
  end
  local diary = force_diary(force)
  diary[#diary + 1] = entry
  force.print({"sd-message.note-read", {"sd-note-title." .. id}})
  return id
end

function notes.on_mined(e)
  if e.entity.name ~= "sd-note" then return end
  local force = e.player_index and game.get_player(e.player_index).force or (e.robot and e.robot.force)
  if force then notes.read(e.entity, force) end
end

function notes.unseen(player)
  return #force_diary(player.force) - (storage.notes.seen[player.index] or 0)
end

return notes
