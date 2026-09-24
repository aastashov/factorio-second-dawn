-- Defeat: a wave that finds the team still stone from the previous one ends the game.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end
script.on_event(defines.events.on_tick, function(e)
  if e.tick == 2 then
    game.surfaces.nauvis.create_entity{name = "sd-revival-chamber", position = {200, 200}, force = "player", raise_built = true}
    remote.call("second-dawn", "set_wave_count", 5)
    remote.call("second-dawn", "wave_in", 30)
  elseif e.tick == 100 then
    local st = remote.call("second-dawn", "state")
    check("wave 6 without a charge petrifies", st.forces[game.forces.player.index] ~= nil)
    remote.call("second-dawn", "hit_wave")
    local m = remote.call("second-dawn", "moon")
    check("the next wave while still stone is defeat", m.lost and game.finished, serpent.line({m.lost, game.finished}))
    L("failures: " .. failures)
  end
end)
