-- A small line at the top of the screen: time to the next wave, or what a petrified team waits for.
local chamber = require("scripts.chamber")

local gui = {}

local function hms(ticks)
  local s = math.max(0, math.floor(ticks / 60))
  return string.format("%d:%02d:%02d", math.floor(s / 3600), math.floor(s / 60) % 60, s % 60)
end

local function text(player, tick)
  local state = storage.forces[player.force.index]
  if state then
    if state.revive_tick then return {"sd-gui.waking"} end
    return {"sd-gui.petrified", state.required, hms(state.thaw_tick - tick)}
  end
  local w = storage.waves
  if w.finished then return nil end
  if not w.next_tick then return nil end
  local charged = chamber.charge_tier(player.force) ~= nil
  return {"sd-gui.next-wave", w.count + 1, hms(w.next_tick - tick), {charged and "sd-gui.charged" or "sd-gui.not-charged"}}
end

function gui.update(tick)
  for _, player in pairs(game.connected_players) do
    local caption = text(player, tick)
    local label = player.gui.top.sd_wave
    if not caption then
      if label then label.destroy() end
    else
      if not label then
        label = player.gui.top.add{type = "label", name = "sd_wave"}
        label.style.font = "default-bold"
        label.style.left_padding = 8
      end
      label.caption = caption
    end
  end
end

return gui
