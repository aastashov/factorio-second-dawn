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

local FLASH = 40 -- ticks the green flash stays on screen
local GREEN = {0.45, 1, 0.6}

-- A full-screen picture that doesn't catch clicks.
local function cover(player, name, sprite)
  local el = player.gui.screen[name]
  if not el then
    el = player.gui.screen.add{type = "sprite", name = name, sprite = sprite}
    el.ignored_by_interaction = true
    el.style.stretch_image_to_widget_size = true
  end
  local r, scale = player.display_resolution, player.display_scale
  el.style.width, el.style.height = math.ceil(r.width / scale), math.ceil(r.height / scale)
  el.location = {0, 0}
end

-- Stone creeping in from the edges of the screen while petrified; with `flash`, a green flash first,
-- on screen and in the world.
function statues.show_overlay(player, flash)
  if not player.connected then return end
  cover(player, "sd_petrified", "sd-petrified-vignette")
  if flash then
    cover(player, "sd_petrified_flash", "sd-petrified-flash")
    storage.statues[player.index].flash_until = game.tick + FLASH
    local c = storage.statues[player.index].character
    if c and c.valid then
      rendering.draw_light{sprite = "utility/light_medium", scale = 14, intensity = 1, color = GREEN,
        target = c, surface = c.surface, time_to_live = 45}
      rendering.draw_light{sprite = "utility/light_small", scale = 4, intensity = 1, color = {0.8, 1, 0.85},
        target = c, surface = c.surface, time_to_live = 25}
    end
  end
end

function statues.hide_overlay(player)
  for _, name in pairs{"sd_petrified", "sd_petrified_flash"} do
    local el = player.gui.screen[name]
    if el then el.destroy() end
  end
end

-- A statue does nothing: the character stops mining, walking, shooting, picking up and repairing before
-- the player is taken out of it (a character left alone keeps doing what it was doing, with animation
-- and sound, under the statue).
function statues.still(character)
  character.mining_state = {mining = false}
  character.walking_state = {walking = false, direction = character.direction}
  character.shooting_state = {state = defines.shooting.not_shooting, position = character.position}
  character.picking_state = false
  character.repair_state = {repairing = false, position = character.position}
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
  statues.still(character)
  player.set_controller{type = defines.controllers.spectator}
  local render = rendering.draw_animation{
    animation = "sd-statue", target = character, surface = character.surface,
    render_layer = "higher-object-under", animation_speed = 0,
  }
  storage.statues[player.index] = {character = character, render = render, thaw_tick = thaw_tick}
  statues.show_overlay(player, thaw_tick == nil) -- a wave flashes; waking up at the start doesn't
end

function statues.revive(player)
  local s = storage.statues[player.index]
  if not s then return end
  if not player.connected then
    s.thawed = true -- finish when they join
    return
  end
  storage.statues[player.index] = nil
  statues.hide_overlay(player)
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
    elseif s.flash_until and tick >= s.flash_until then
      s.flash_until = nil
      local el = player.gui.screen.sd_petrified_flash
      if el then el.destroy() end
    end
  end
end

return statues
