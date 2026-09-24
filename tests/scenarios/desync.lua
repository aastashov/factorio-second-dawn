-- Short wave cycle for heavy mode (tests/run-heavy.sh): the game is saved, loaded and compared every tick,
-- so all test state lives in storage. Charges are written straight into the chamber's tank.
local function L(s) log("SD-TEST " .. s) end
local function charge() storage.t.chamber.fluidbox[1] = {name = "sd-revival-charge-1", amount = 1} end
local function forces() return remote.call("second-dawn", "state").forces[game.forces.player.index] end

script.on_init(function()
  storage.t = {}
end)

script.on_event(defines.events.on_tick, function(e)
  local t = e.tick
  if t == 300 then
    local s = game.surfaces.nauvis
    storage.t.chamber = s.create_entity{name = "sd-revival-chamber", position = {300, 300}, force = "player", raise_built = true}
    charge()
    remote.call("second-dawn", "wave_in", 50)
  elseif t == 400 then
    L("charged wave: " .. serpent.line(forces()))
  elseif t == 600 then
    L("after wake: " .. serpent.line(forces()))
    remote.call("second-dawn", "wave_in", 50)
  elseif t == 700 then
    L("uncharged wave: " .. serpent.line(forces()))
    charge()
  elseif t == 800 then
    L("woken by chamber: " .. serpent.line(forces()))
  end
end)
