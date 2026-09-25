local util = require("util")
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
    local near = s.count_entities_filtered{type = "unit-spawner", position = {0, 0}, radius = 190}
    local bears_close = s.count_entities_filtered{name = "sd-bear-den", position = {0, 0}, radius = 480}
    local wolves = s.count_entities_filtered{name = "sd-wolf-lair"}
    local boars = s.count_entities_filtered{name = "sd-boar-lair"}
    local bears = s.count_entities_filtered{name = "sd-bear-den"}
    check("no lairs at the camp", near == 0, near .. "")
    check("lairs spread out", wolves > 10 and boars > 5, wolves .. " wolf, " .. boars .. " boar")
    check("no bears in the temperate belt", bears == 0, bears .. " bears (they live in the cold, see climate test)")
    local run = prototypes.entity.character.running_speed
    for _, a in pairs{"sd-wolf", "sd-wolf-leader", "sd-boar", "sd-tusker", "sd-bear-cub", "sd-bear"} do
      check(a .. " is slower than a running character", prototypes.entity[a].speed < run, prototypes.entity[a].speed .. " < " .. run)
    end
    for lair, pack in pairs{["sd-wolf-lair"] = {"sd-wolf", "sd-wolf-leader"}, ["sd-boar-lair"] = {"sd-boar", "sd-tusker"},
                            ["sd-bear-den"] = {"sd-bear-cub", "sd-bear"}} do
      local names = {}
      for _, u in pairs(prototypes.entity[lair].result_units) do names[u.unit] = true end
      local small, big = prototypes.entity[pack[1]], prototypes.entity[pack[2]]
      check(lair .. ": a pack with a leader", names[pack[1]] and names[pack[2]] and big.get_max_health() > 2 * small.get_max_health(),
        small.get_max_health() .. " / " .. big.get_max_health() .. " health")
    end
    check("the bow and stone arrows need no research", game.forces.player.recipes["sd-bow"].enabled and game.forces.player.recipes["sd-stone-arrows"].enabled)
    check("no vanilla biters", s.count_entities_filtered{force = "enemy"} == 0)

    -- A test ground far away: a wolf lair, a building 60 tiles off, a character near the lair.
    s.request_to_generate_chunks(O, 4); s.force_generate_chunk_requests()
    clear(s, {at(-80, -80), at(80, 80)})
    storage.t.lair = s.create_entity{name = "sd-wolf-lair", position = at(0, 0), force = "sd-wildlife"}
    -- A second lair for the raid, untouched by the territory check (the first one's pack may be off chasing).
    storage.t.raid_lair = s.create_entity{name = "sd-wolf-lair", position = at(-40, 20), force = "sd-wildlife"}
    storage.t.box = s.create_entity{name = "wooden-chest", position = at(0, 60), force = "player"}
    storage.t.box2 = s.create_entity{name = "wooden-chest", position = at(-45, 75), force = "player"} -- deeper in the base
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
    local b2 = storage.t.box2
    check("the pack goes on into the base", not b2.valid or b2.health < b2.max_health, b2.valid and (b2.health .. " hp") or "destroyed")

    -- Crossbow turret with the weakest arrows against three wolves.
    local s = game.surfaces.nauvis
    local t = s.create_entity{name = "sd-crossbow", position = at(-50, -50), force = "player"}
    t.insert{name = "sd-stone-arrows", count = 50}
    storage.t.turret = t
    -- The swivel gun with musket balls, the gunpowder weapon of epoch 2, against three more.
    local g = s.create_entity{name = "sd-swivel-gun", position = at(-50, 30), force = "player"}
    g.insert{name = "sd-musket-balls", count = 20}
    storage.t.gun = g
    storage.t.gun_wolves = {}
    for i = 1, 3 do
      local w = s.create_entity{name = "sd-wolf", position = at(-50 + 8 + i, 30), force = "sd-wildlife"}
      w.commandable.set_command{type = defines.command.attack, target = g}
      storage.t.gun_wolves[i] = w
    end
    storage.t.wolves = {}
    for i = 1, 3 do
      storage.t.wolves[i] = s.create_entity{name = "sd-wolf", position = at(-50 + 8 + i, -50), force = "sd-wildlife"}
      storage.t.wolves[i].commandable.set_command{type = defines.command.attack, target = t} -- no wandering off
    end
  end,
  [8500] = function()
    -- Now and then a wolf breaks off and runs home; the turret is judged on the ones in its reach.
    local alive, killed = 0, 0
    for _, w in pairs(storage.t.wolves) do
      if not w.valid then killed = killed + 1
      elseif util.distance(w.position, storage.t.turret.position) < 25 then alive = alive + 1 end
    end
    check("crossbow turret kills wolves", alive == 0 and killed >= 2, killed .. " killed, " .. alive .. " alive in reach")
    local s = game.surfaces.nauvis
    local items = {}
    for _, e in pairs(s.find_entities_filtered{name = "item-on-ground", position = at(-50, -50), radius = 25}) do
      items[e.stack.name] = (items[e.stack.name] or 0) + e.stack.count
    end
    local gun_alive, gun_killed = 0, 0
    for _, w in pairs(storage.t.gun_wolves) do
      if not w.valid then gun_killed = gun_killed + 1
      elseif util.distance(w.position, storage.t.gun.position) < 25 then gun_alive = gun_alive + 1 end
    end
    check("swivel gun kills wolves", gun_alive == 0 and gun_killed >= 2, gun_killed .. " killed, " .. gun_alive .. " alive in reach")
    local force = game.forces.player
    local before = force.get_ammo_damage_modifier("sd-arrow")
    force.technologies["sd-arrowheads-1"].researched = true
    force.technologies["sd-arrowheads-2"].researched = true
    check("sharper arrowheads: +20% per level", math.abs(force.get_ammo_damage_modifier("sd-arrow") - before - 0.4) < 1e-6,
      before .. " -> " .. force.get_ammo_damage_modifier("sd-arrow"))
    check("wolves drop meat", (items["sd-meat"] or 0) >= killed, serpent.line(items))

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
    -- The leash: provoke the lair, then run away at a character's running speed. The pack gives up
    -- 60 tiles from its lair and goes home.
    local s = game.surfaces.nauvis
    local c = s.create_entity{name = "character", position = at(15, 0), force = "player"}
    remote.call("second-dawn", "provoke", c.position)
    storage.t.far = c
  end,
  [8560 + 36000 + 100 + 1200] = function()
    -- A pack at a player's corpse: calmed, it leaves.
    local s = game.surfaces.nauvis
    local box = s.create_entity{name = "wooden-chest", position = at(-60, 60), force = "player"}
    storage.t.calm_wolves = {}
    for i = 1, 3 do
      local w = s.create_entity{name = "sd-wolf", position = at(-60 + i, 58), force = "sd-wildlife"}
      w.commandable.set_command{type = defines.command.attack, target = box}
      storage.t.calm_wolves[i] = w
    end
    storage.t.calm_box = box
    storage.t.calmed = remote.call("second-dawn", "calm", box.position, 30)
  end,
  [8560 + 36000 + 100 + 2400] = function()
    local c, lair = storage.t.far, storage.t.lair
    local near_player = game.surfaces.nauvis.count_entities_filtered{type = "unit", position = c.position, radius = 25}
    local leashed = remote.call("second-dawn", "wildlife").leashed or 0
    local near = game.surfaces.nauvis.count_entities_filtered{type = "unit", position = storage.t.calm_box.position, radius = 20}
    check("after a death, animals nearby go home", storage.t.calmed >= 3 and near == 0 and storage.t.calm_box.valid,
      storage.t.calmed .. " calmed, " .. near .. " still there")
    local w = remote.call("second-dawn", "wildlife")
    check("a raid ends: the pack goes home after 4 minutes", (w.raids_ended or 0) > 0 and
      game.surfaces.nauvis.count_entities_filtered{type = "unit", position = at(0, 60), radius = 25} == 0,
      tostring(w.raids_ended) .. " raiders sent home")
    check("animals give up the chase 60 tiles from their lair", leashed > 0 and near_player == 0 and c.valid,
      leashed .. " sent home, " .. near_player .. " within 25 tiles of the player, player " .. (c.valid and c.health .. " hp" or "dead"))
    L("failures: " .. failures)
  end,
}

script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
  local runner = storage.t.far
  if runner and runner.valid and runner.position.x < O.x + 150 then
    runner.teleport({runner.position.x + 0.15, runner.position.y})
  end
end)
