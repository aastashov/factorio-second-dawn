local chamber = require("scripts.chamber")
local statues = require("scripts.statues")
local waves = require("scripts.waves")
local start = require("scripts.start")
local gui = require("scripts.gui")

local INTRO_STATUE = 4 * 60      -- the first players wake from stone a few seconds into the game
local NEWCOMER_STATUE = 3 * 60 * 60

local function init()
  chamber.init()
  statues.init()
  waves.init()
end

script.on_init(function()
  init()
  start.configure_freeplay()
  start.ensure_starting_area(game.surfaces.nauvis)
end)

script.on_configuration_changed(init)

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
end)

script.on_nth_tick(30, function(e)
  chamber.update()
  waves.update(e.tick)
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
  charge_tier = function(force) return chamber.charge_tier(game.forces[force]) end,
  chamber = function(force) return chamber.get(game.forces[force]) end,
  starting_area = function() return start.ensure_starting_area(game.surfaces.nauvis) end,
})
