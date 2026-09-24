-- Petrified players. A statue is the player's character left standing where it was, with a grey
-- statue drawn over it; the player watches as a spectator and can't build, craft or walk.
-- Disconnected players have no character reachable from script, so they are petrified or revived when
-- they join again.
local statues = {}

function statues.init()
  storage.statues = storage.statues or {}
end

function statues.is_petrified(player)
  return storage.statues[player.index] ~= nil
end

-- thaw_tick: when this statue thaws on its own (newcomers, intro); nil = follows its force's wave state.
function statues.petrify(player, thaw_tick)
  local s = storage.statues[player.index]
  if s then
    s.thaw_tick = thaw_tick
    return
  end
  local character = player.connected and player.character
  if not character then
    storage.statues[player.index] = {pending = true, thaw_tick = thaw_tick}
    return
  end
  player.set_controller{type = defines.controllers.spectator}
  local render = rendering.draw_animation{
    animation = "sd-statue", target = character, surface = character.surface,
    render_layer = "higher-object-under", animation_speed = 0,
  }
  storage.statues[player.index] = {character = character, render = render, thaw_tick = thaw_tick}
end

function statues.revive(player)
  local s = storage.statues[player.index]
  if not s then return end
  if not player.connected then
    s.thawed = true -- finish when they join
    return
  end
  storage.statues[player.index] = nil
  if s.render and s.render.valid then s.render.destroy() end
  if s.pending then return end
  if player.controller_type ~= defines.controllers.spectator then return end
  if s.character and s.character.valid then
    player.set_controller{type = defines.controllers.character, character = s.character}
  else
    player.set_controller{type = defines.controllers.god}
    player.create_character()
  end
end

-- Pending statues become real ones and thawed ones come back when their player is here.
function statues.on_joined(player, force_petrified)
  local s = storage.statues[player.index]
  if s and (s.thawed or (not force_petrified and not s.thaw_tick)) then
    statues.revive(player)
  elseif s and s.pending then
    storage.statues[player.index] = nil
    statues.petrify(player, s.thaw_tick)
  elseif not s and force_petrified then
    statues.petrify(player)
  end
end

-- Revives statues whose own thaw time has come (not those waiting for their force).
function statues.update(tick, force_petrified)
  for index, s in pairs(storage.statues) do
    local player = game.get_player(index)
    if not player then
      storage.statues[index] = nil
    elseif s.thaw_tick and tick >= s.thaw_tick and not force_petrified(player.force) then
      statues.revive(player)
    end
  end
end

return statues
