-- Wild animals: lairs by distance, animals spawning, loot, the crossbow turret, a raid, territory,
-- and a petrification wave freezing animals for 10 minutes.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end
local O = {x = 2000, y = 0}
local function at(x, y) return {O.x + x, O.y + y} end

script.on_init(function() storage.t = {} end)

local function clear(s, area)
  local tiles = {}
  for x = area[1][1], area[2][1] do for y = area[1][2], area[2][2] do tiles[#tiles + 1] = {name = "grass-1", position = {x, y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = area}) do e.destroy() end
end

local steps = {
  [5] = function()
    local s = game.surfaces.nauvis
    s.request_to_generate_chunks({0, 0}, 20)
    s.force_generate_chunk_requests()
    local near = s.count_entities_filtered{type = "unit-spawner", position = {0, 0}, radius = 140}
    local bears_close = s.count_entities_filtered{name = "sd-bear-den", position = {0, 0}, radius = 480}
    local wolves = s.count_entities_filtered{name = "sd-wolf-lair"}
    local boars = s.count_entities_filtered{name = "sd-boar-lair"}
    local bears = s.count_entities_filtered{name = "sd-bear-den"}
    check("no lairs at the camp", near == 0, near .. "")
    check("lairs spread out", wolves > 10 and boars > 5, wolves .. " wolf, " .. boars .. " boar")
    check("no bears in the temperate belt", bears == 0, bears .. " bears (they live in the cold, see climate test)")
    check("no vanilla biters", s.count_entities_filtered{force = "enemy"} == 0)

    -- A test ground far away: a wolf lair, a building 60 tiles off, a character near the lair.
    s.request_to_generate_chunks(O, 4); s.force_generate_chunk_requests()
    clear(s, {at(-80, -80), at(80, 80)})
    storage.t.lair = s.create_entity{name = "sd-wolf-lair", position = at(0, 0), force = "sd-wildlife"}
    storage.t.box = s.create_entity{name = "wooden-chest", position = at(0, 60), force = "player"}
  end,
  [3700] = function()
    local lair = storage.t.lair
    check("wolves spawn in the lair", #lair.units >= 3, #lair.units .. " wolves")
    storage.t.char = game.surfaces.nauvis.create_entity{name = "character", position = at(20, 0), force = "player"}
    local provoked = remote.call("second-dawn", "provoke", storage.t.char.position)
    check("a character 20 tiles from a lair provokes it", provoked == 1, tostring(provoked))
  end,
  [4700] = function()
    local c = storage.t.char
    check("wolves attack the provoker", not c.valid or c.health < 250, c.valid and (c.health .. " hp") or "dead")
    local sent = remote.call("second-dawn", "raid", "player", 1)
    check("raid sent from a predator lair", sent == 1, tostring(sent))
  end,
  [7300] = function()
    local b = storage.t.box
    check("raid reaches the building", not b.valid or b.health < b.max_health, b.valid and (b.health .. " hp") or "destroyed")

    -- Crossbow turret with arrows against three wolves.
    local s = game.surfaces.nauvis
    local t = s.create_entity{name = "sd-crossbow", position = at(-50, -50), force = "player"}
    t.insert{name = "sd-arrows", count = 50}
    storage.t.turret = t
    storage.t.wolves = {}
    for i = 1, 3 do
      storage.t.wolves[i] = s.create_entity{name = "sd-wolf", position = at(-50 + 8 + i, -50), force = "sd-wildlife"}
    end
  end,
  [8500] = function()
    local alive = 0
    for _, w in pairs(storage.t.wolves) do if w.valid then alive = alive + 1 end end
    check("crossbow turret kills wolves", alive == 0, alive .. " alive")
    local s = game.surfaces.nauvis
    local items = {}
    for _, e in pairs(s.find_entities_filtered{name = "item-on-ground", position = at(-50, -50), radius = 25}) do
      items[e.stack.name] = (items[e.stack.name] or 0) + e.stack.count
    end
    check("wolves drop meat", (items["sd-meat"] or 0) >= 3, serpent.line(items))

    remote.call("second-dawn", "wave_in", 60)
  end,
  [8700] = function()
    local lair = storage.t.lair
    local frozen = lair.valid and lair.disabled_by_script
    for _, u in pairs(lair.valid and lair.units or {}) do frozen = frozen and u.disabled_by_script end
    check("a wave freezes lairs and animals", frozen)
    check("no raids while frozen", remote.call("second-dawn", "wildlife").frozen_until ~= nil)
  end,
  [8560 + 36000 + 100] = function()
    local lair = storage.t.lair
    check("animals thaw after 10 minutes", lair.valid and not lair.disabled_by_script)
    L("failures: " .. failures)
  end,
}

script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
