local chamber = require("scripts.chamber")
local statues = require("scripts.statues")
local waves = require("scripts.waves")
local start = require("scripts.start")
local gui = require("scripts.gui")
local notes = require("scripts.notes")
local diary = require("scripts.diary")
local wildlife = require("scripts.wildlife")
local climate = require("scripts.climate")
local moon = require("scripts.moon")
local guide = require("scripts.guide")

local INTRO_STATUE = 4 * 60      -- the first players wake from stone a few seconds into the game
local NEWCOMER_STATUE = 3 * 60 * 60

local function init()
  chamber.init()
  statues.init()
  waves.init()
  wildlife.init()
  moon.init()
  guide.init()
  local new_climate = not storage.climate
  climate.init()
  if new_climate and game.tick > 0 then climate.scan() end
  local new_notes = not storage.notes
  notes.init()
  return new_notes
end

script.on_init(function()
  init()
  storage.kit_given = true -- a new game has the respawn kit from the start
  for _, force in pairs(game.forces) do start.hands(force) end
  start.configure_freeplay()
  start.ensure_starting_area(game.surfaces.nauvis)
  notes.place_start_ruins(game.surfaces.nauvis)
end)

script.on_configuration_changed(function()
  -- Saves from earlier versions get what a new game would have: starting ruins (0.2), tin (0.3),
  -- the waves of the new version, no vanilla victory on rocket launch (0.10), and see below (0.11).
  if remote.interfaces["silo_script"] then remote.call("silo_script", "set_no_victory", true) end
  if init() then notes.place_start_ruins(game.surfaces.nauvis) end
  start.ensure_starting_area(game.surfaces.nauvis)
  waves.on_version_changed()
  -- Statues from before the stone on screen get it now.
  for _, player in pairs(game.connected_players) do
    if statues.is_petrified(player) and not player.gui.screen.sd_petrified then statues.show_overlay(player) end
  end
  -- 0.12: packs left at bases by raids go home; respawning players get a bow and arrows.
  wildlife.calm_bases()
  start.configure_respawn()
  start.give_kit_once()
  -- 0.12: the digger from the start, the woodlot with pottery, quicker hands.
  for _, force in pairs(game.forces) do
    start.hands(force)
    force.recipes["sd-digger"].enabled = true
    if force.technologies["sd-pottery"].researched then
      force.recipes["sd-woodlot"].enabled = true
      force.recipes["sd-grow-wood"].enabled = true
    end
  end
  -- 0.11: fewer lairs, the bow and stone arrows from the start, bone arrows with "Hunting".
  wildlife.thin_out()
  for _, force in pairs(game.forces) do
    force.recipes["sd-bow"].enabled = true
    force.recipes["sd-stone-arrows"].enabled = true
    if force.technologies["sd-hunting"].researched then force.recipes["sd-bone-arrows"].enabled = true end
  end
end)

script.on_event(defines.events.on_chunk_generated, function(e)
  notes.on_chunk_generated(e)
  wildlife.on_chunk_generated(e)
end)
-- Removal: notes are read when mined; climate forgets buildings and sources.
local removal_filter = {{filter = "name", name = "sd-note"}}
for _, t in pairs(climate.AFFECTED) do removal_filter[#removal_filter + 1] = {filter = "type", type = t} end
local function on_removed(e)
  if e.entity.name == "sd-note" then
    if e.name ~= defines.events.on_entity_died and e.name ~= defines.events.script_raised_destroy then notes.on_mined(e) end
  else
    climate.on_removed(e.entity)
  end
end
script.on_event(defines.events.on_player_mined_entity, on_removed, removal_filter)
script.on_event(defines.events.on_robot_mined_entity, on_removed, removal_filter)
script.on_event(defines.events.on_entity_died, on_removed, removal_filter)
script.on_event(defines.events.script_raised_destroy, on_removed, removal_filter)

script.on_event("sd-diary", function(e) diary.toggle(game.get_player(e.player_index)) end)
script.on_event(defines.events.on_gui_selection_state_changed, diary.on_selection)
script.on_event(defines.events.on_gui_click, diary.on_click)
script.on_event(defines.events.on_gui_closed, diary.on_closed)

-- Building: one revival chamber per force; climate tracks buildings and sources in the belts.
local build_filter = {}
for _, t in pairs(climate.AFFECTED) do build_filter[#build_filter + 1] = {filter = "type", type = t} end
local CHAMBERS = {[chamber.NAMES[1]] = true, [chamber.NAMES[2]] = true}
local function on_built(e)
  local entity = e.entity
  local player = e.player_index and game.get_player(e.player_index)
  if CHAMBERS[entity.name] then
    chamber.on_built(entity, player)
    if not entity.valid then return end
  end
  -- Rubber plantations only grow in the hot belt.
  if entity.name == "sd-plantation" and climate.belt(entity.position) ~= "hot" then
    local surface, position = entity.surface, entity.position
    entity.destroy()
    local stack = {name = "sd-plantation", count = 1}
    if not (player and player.insert(stack) > 0) then
      surface.spill_item_stack{position = position, stack = stack, enable_looted = true}
    end
    if player then player.print({"sd-message.plantation-hot-only"}) end
    return
  end
  climate.on_built(entity)
end
script.on_event(defines.events.on_built_entity, on_built, build_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, build_filter)
script.on_event(defines.events.script_raised_built, on_built, build_filter)
script.on_event(defines.events.script_raised_revive, on_built, build_filter)

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index)
  if waves.force_petrified(player.force) then
    statues.petrify(player)
  elseif game.tick < 60 then
    player.print({"sd-message.intro"})
    statues.petrify(player, game.tick + INTRO_STATUE)
  elseif settings.global["sd-petrify-newcomers"].value then
    player.print({"sd-message.newcomer"})
    statues.petrify(player, game.tick + NEWCOMER_STATUE)
  end
end)

script.on_event(defines.events.on_player_joined_game, function(e)
  local player = game.get_player(e.player_index)
  statues.on_joined(player, waves.force_petrified(player.force))
end)

-- The stone on screen follows the window size.
local function refit(e)
  local player = game.get_player(e.player_index)
  if statues.is_petrified(player) and player.gui.screen.sd_petrified then statues.show_overlay(player) end
end
script.on_event(defines.events.on_player_display_resolution_changed, refit)
script.on_event(defines.events.on_player_display_scale_changed, refit)

-- Whoever killed the player goes home: the corpse can be reached.
script.on_event(defines.events.on_player_died, function(e)
  local player = game.get_player(e.player_index)
  local corpse = player.surface.find_entities_filtered{type = "character-corpse", position = player.position, radius = 3, limit = 1}[1]
  wildlife.calm(player.surface, corpse and corpse.position or player.position)
end)

script.on_event(defines.events.on_player_respawned, function(e)
  local player = game.get_player(e.player_index)
  if waves.force_petrified(player.force) then statues.petrify(player) end
end)

script.on_event(defines.events.on_player_changed_force, function(e)
  local player = game.get_player(e.player_index)
  if waves.force_petrified(player.force) then
    statues.petrify(player)
  elseif statues.is_petrified(player) then
    statues.revive(player)
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if e.setting == "sd-wave-difficulty" then waves.on_difficulty_changed() end
  if e.setting == "sd-wildlife" then wildlife.apply_mode() end
end)

script.on_event(defines.events.on_rocket_launch_ordered, function(e) moon.on_launch_ordered(e.rocket_silo) end)
script.on_event(defines.events.on_rocket_launched, function(e) moon.on_launched(e.rocket_silo) end)
script.on_event(defines.events.on_object_destroyed, function(e) moon.on_destroyed(e, waves.wake_everyone) end)

script.on_event(defines.events.on_force_created, function(e)
  wildlife.apply_mode()
  start.hands(e.force)
end)

script.on_nth_tick(30, function(e)
  chamber.update()
  local count = storage.waves.count
  waves.update(e.tick)
  if storage.waves.count > count then wildlife.freeze(e.tick) end
  wildlife.update(e.tick)
  if e.tick % 120 == 0 then
    wildlife.territory(statues.is_petrified)
    wildlife.leash(e.tick)
  end
  if e.tick % 300 == 0 then wildlife.night(e.tick, storage.waves.count > 0) end
  if e.tick % 60 == 0 then
    climate.update_sources()
    climate.players(statues.is_petrified)
  end
  if e.tick % 300 == 0 then climate.heat_cycle() end
  if e.tick % 60 == 0 then moon.update(e.tick) end
  statues.update(e.tick, waves.force_petrified)
  if e.tick % 60 == 0 then
    gui.update(e.tick)
    guide.update()
  end
end)

-- For scenario tests and debugging.
remote.add_interface("second-dawn", {
  state = function()
    return {waves = storage.waves, forces = storage.forces, statues = table_size(storage.statues)}
  end,
  wave_in = function(ticks)
    storage.waves.next_tick = game.tick + ticks
    storage.waves.warned = {}
  end,
  set_wave_count = function(n)
    storage.waves.count = n
    storage.waves.finished = false
    waves.schedule()
  end,
  charge_tier = function(force) return chamber.charge_tier(game.forces[force]) end,
  chamber = function(force) return chamber.get(game.forces[force]) end,
  starting_area = function() return start.ensure_starting_area(game.surfaces.nauvis) end,
  wildlife = function() return storage.wildlife end,
  petrify = function(player_index, thaw_tick) statues.petrify(game.get_player(player_index), thaw_tick) end,
  revive = function(player_index) statues.revive(game.get_player(player_index)) end,
  calm = function(position, radius) return wildlife.calm(game.surfaces.nauvis, position, radius) end,
  still = function(position)
    local c = game.surfaces.nauvis.find_entities_filtered{type = "character", position = position, radius = 1}[1]
    if c then statues.still(c) end
  end,
  guide_step = function(force) return guide.step(game.forces[force or "player"]) end,
  moon = function()
    local m = storage.moon
    local crew = {}
    for n, member in pairs(m.crew) do crew[#crew + 1] = {unit = n, air = member.air, surface = member.character.valid and member.character.surface.name} end
    return {won = m.won, crew = crew, emitter = m.emitter and m.emitter.valid and m.emitter.position, pulses = m.pulses, hits = m.hits,
      lost = storage.waves.lost, finished = storage.waves.finished}
  end,
  set_air = function(unit, seconds) if storage.moon.crew[unit] then storage.moon.crew[unit].air = seconds end end,
  moon_pulse_now = function() storage.moon.pulse_tick = game.tick end,
  no_victory_screen = function() storage.moon.no_victory_screen = true end,
  hit_wave = function() waves.hit() end,
  expose = function(position)
    local c = game.surfaces.nauvis.find_entities_filtered{type = "character", position = position, radius = 1}[1]
    if not c then return nil end
    local belt, protected = climate.expose(c)
    return {belt = belt, protected = protected, health = c.health}
  end,
  climate = function(unit_number)
    local entry = storage.climate.entities[unit_number]
    return entry and {belt = entry.belt, covered = entry.covered}
  end,
  raid = function(force, count) return #wildlife.raid(game.forces[force], count or 1) end,
  provoke = function(position)
    local c = game.surfaces.nauvis.find_entities_filtered{type = "character", position = position, radius = 1}[1]
    return c and wildlife.provoke(c)
  end,
  notes = function()
    local n = storage.notes
    return {ruins = n.ruins, caches = n.caches, placed = n.placed, entities = n.entities, read = n.read}
  end,
  read_note = function(unit_number, force)
    local e = game.get_entity_by_unit_number(unit_number)
    return e and notes.read(e, game.forces[force])
  end,
})
