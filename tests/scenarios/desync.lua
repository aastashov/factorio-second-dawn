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
  elseif t == 900 then
    local s = game.surfaces.nauvis
    s.request_to_generate_chunks({0, 0}, 10)
    s.force_generate_chunk_requests()
  elseif t == 1000 then
    -- read the first two notes found: ruins, recipes and caches go through save/load too
    local n = 0
    for unit in pairs(remote.call("second-dawn", "notes").entities) do
      remote.call("second-dawn", "read_note", unit, "player")
      n = n + 1
      if n == 12 then break end
    end
    local st = remote.call("second-dawn", "notes")
    L("notes: ruins " .. st.ruins .. ", caches " .. st.caches .. ", diary " .. #st.read[game.forces.player.index])
    charge()
  elseif t == 1100 then
    -- switching the chamber to charge II pours the tier I charge out
    game.forces.player.recipes["sd-revival-charge-2"].enabled = true
    storage.t.chamber.set_recipe("sd-revival-charge-2")
  elseif t == 1200 then
    L("tank after switching to charge II: " .. tostring(storage.t.chamber.fluidbox[1]))
  end
end)
