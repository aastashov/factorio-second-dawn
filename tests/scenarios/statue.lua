-- A statue does nothing: a character caught mining stops when it turns to stone (it also stops walking,
-- shooting, picking up and repairing; a character without a player doesn't keep those on its own).
-- (Player controllers need a real player; the part a headless game can check is the character itself.)
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 5 then
    s.request_to_generate_chunks({0, 0}, 2); s.force_generate_chunk_requests()
    local rock = s.create_entity{name = "big-rock", position = {10, 10}}
    local c = s.create_entity{name = "character", position = {10, 8.5}, force = "player"}
    c.selected = rock
    c.mining_state = {mining = true, position = rock.position}
    storage.c, storage.rock = c, rock
  elseif e.tick == 30 then
    local c = storage.c
    -- The bug from the game: a character without its player keeps mining.
    check("the character keeps mining on its own", c.mining_state.mining, tostring(c.mining_state.mining))
    remote.call("second-dawn", "still", c.position)
    storage.at = c.position
  elseif e.tick == 120 then
    local c = storage.c
    check("stops mining", not c.mining_state.mining, tostring(c.mining_state.mining))
    check("stays where it was", c.position.x == storage.at.x and c.position.y == storage.at.y, serpent.line(c.position))
    check("the rock is untouched", storage.rock.valid)
    L("failures: " .. failures)
  end
end)
