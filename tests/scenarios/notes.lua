-- Ruins and notes: starting ruins, ruins in newly generated chunks, unique notes then caches, reading a
-- recipe note and a cache note, whether a character can mine a neutral note.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end

local KIND = {}
for _, n in pairs(require("__second-dawn__.scripts.notes-data")) do KIND[n.id] = n end

local function notes() return remote.call("second-dawn", "notes") end

local function find(kind)
  for unit, id in pairs(notes().entities) do
    if KIND[id].kind == kind then return unit, id end
  end
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 5 then return end
  local s = game.surfaces.nauvis
  local force = game.forces.player

  local near = s.find_entities_filtered{name = "sd-note", position = {0, 0}, radius = 150}
  local ids = {}
  for _, n in pairs(near) do ids[#ids + 1] = notes().entities[n.unit_number] end
  check("two ruins near spawn", #near >= 2, table.concat(ids, ", "))
  local has_first = false
  for _, id in pairs(ids) do has_first = has_first or id == "first-steps" end
  check("first-steps note near spawn", has_first)
  local walls = s.count_entities_filtered{name = "sd-ruin-wall", position = {0, 0}, radius = 160}
  check("ruins have walls", walls >= 6, walls .. " wall pieces")

  s.request_to_generate_chunks({0, 0}, 12)
  s.force_generate_chunk_requests()
  local n = notes()
  local unique, caches = 0, 0
  for _, id in pairs(n.entities) do
    if id == "cache" then caches = caches + 1 else unique = unique + 1 end
  end
  local placed = 0
  for _ in pairs(n.placed) do placed = placed + 1 end
  check("ruins spread over new chunks", n.ruins >= 20, n.ruins .. " ruins")
  check("each unique note placed once", unique == placed, unique .. " unique note entities, " .. placed .. " placed ids")
  local total = 0
  for _, k in pairs(KIND) do if k.kind ~= "journal" and k.kind ~= "cache" then total = total + 1 end end
  check("caches after unique notes run out", placed < total or caches > 0, caches .. " cache notes, " .. total .. " unique notes")

  local unit, id = find("recipe")
  local recipe = KIND[id].recipe
  check("recipe locked before reading", not force.recipes[recipe].enabled, recipe)
  remote.call("second-dawn", "read_note", unit, "player")
  check("recipe note unlocks recipe", force.recipes[recipe].enabled, recipe)

  unit = find("cache")
  if unit then
    local tags = #force.find_chart_tags(s)
    remote.call("second-dawn", "read_note", unit, "player")
    local diary = notes().read[force.index]
    local entry = diary[#diary]
    check("cache note marks a cache", entry.position ~= nil and #force.find_chart_tags(s) == tags + 1, serpent.line(entry))
    if entry.position then
      local chest = s.find_entity("wooden-chest", entry.position)
      check("cache chest has loot", chest and not chest.get_inventory(defines.inventory.chest).is_empty())
    end
  end
  local diary = notes().read[force.index]
  check("diary: journal + read notes", #diary >= 3 and diary[1].id == "journal-1", #diary .. " entries")

  -- Can a character of the player force mine a neutral note (as a player would)?
  local note = s.find_entities_filtered{name = "sd-note", limit = 1}[1]
  local char = s.create_entity{name = "character", position = note.position, force = "player"}
  local before = #notes().read[force.index]
  local mined = char.mine_entity(note)
  check("character can mine a neutral note", mined, "")
  L("     mining by a character without player raised the read: " .. tostring(#notes().read[force.index] > before))

  for name, r in pairs(prototypes.recipe) do
    if name:find("^sd%-alt%-") then
      local ok = false
      for _, m in pairs(prototypes.get_entity_filtered{{filter = "crafting-category", crafting_category = r.category}}) do ok = true end
      check("alt recipe has a machine: " .. name, ok)
    end
  end
  L("failures: " .. failures)
end)
