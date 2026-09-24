local chamber = require("scripts.chamber")
local statues = require("scripts.statues")
local waves = require("scripts.waves")
local start = require("scripts.start")
local gui = require("scripts.gui")
local notes = require("scripts.notes")
local diary = require("scripts.diary")
local wildlife = require("scripts.wildlife")

local INTRO_STATUE = 4 * 60      -- the first players wake from stone a few seconds into the game
local NEWCOMER_STATUE = 3 * 60 * 60

local function init()
  chamber.init()
  statues.init()
  waves.init()
  wildlife.init()
  local new_notes = not storage.notes
  notes.init()
  return new_notes
end

script.on_init(function()
  init()
  start.configure_freeplay()
  start.ensure_starting_area(game.surfaces.nauvis)
  notes.place_start_ruins(game.surfaces.nauvis)
end)

script.on_configuration_changed(function()
  -- Saves from earlier versions get what a new game would have: starting ruins (0.2), tin (0.3),
  -- the waves of the new version.
  if init() then notes.place_start_ruins(game.surfaces.nauvis) end
  start.ensure_starting_area(game.surfaces.nauvis)
  waves.on_version_changed()
end)

script.on_event(defines.events.on_chunk_generated, function(e)
  notes.on_chunk_generated(e)
  wildlife.on_chunk_generated(e)
end)
local note_filter = {{filter = "name", name = "sd-note"}}
script.on_event(defines.events.on_player_mined_entity, notes.on_mined, note_filter)
script.on_event(defines.events.on_robot_mined_entity, notes.on_mined, note_filter)

script.on_event("sd-diary", function(e) diary.toggle(game.get_player(e.player_index)) end)
script.on_event(defines.events.on_gui_selection_state_changed, diary.on_selection)
script.on_event(defines.events.on_gui_click, diary.on_click)
script.on_event(defines.events.on_gui_closed, diary.on_closed)

local chamber_filter = {{filter = "name", name = chamber.NAME}}
local function on_built(e)
  local player = e.player_index and game.get_player(e.player_index)
  chamber.on_built(e.entity, player)
end
script.on_event(defines.events.on_built_entity, on_built, chamber_filter)
script.on_event(defines.events.on_robot_built_entity, on_built, chamber_filter)
script.on_event(defines.events.script_raised_built, on_built, chamber_filter)
script.on_event(defines.events.script_raised_revive, on_built, chamber_filter)

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

script.on_event(defines.events.on_force_created, function() wildlife.apply_mode() end)

script.on_nth_tick(30, function(e)
  chamber.update()
  local count = storage.waves.count
  waves.update(e.tick)
  if storage.waves.count > count then wildlife.freeze(e.tick) end
  wildlife.update(e.tick)
  if e.tick % 120 == 0 then wildlife.territory(statues.is_petrified) end
  if e.tick % 300 == 0 then wildlife.night(e.tick, storage.waves.count > 0) end
  statues.update(e.tick, waves.force_petrified)
  if e.tick % 60 == 0 then gui.update(e.tick) end
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
