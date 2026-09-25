-- UPS with wild animals: ~40 chunks in every direction generated (lairs everywhere past 200 tiles),
-- lairs filled for a minute, then a base's worth of buildings in a ring through the lairs and a night of
-- raids from every predator lair at once (raiders take building after building for 4 minutes).
-- Run with SD_BENCH_VERBOSE=1 and ups-report.py <log> 4000.
script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 2 then
    s.request_to_generate_chunks({0, 0}, 20)
    s.force_generate_chunk_requests()
  elseif e.tick == 3900 then
    -- 120 chests in a ring at 250 tiles, among the lairs
    for i = 1, 120 do
      local a = i / 120 * 2 * math.pi
      local p = s.find_non_colliding_position("wooden-chest", {math.cos(a) * 250, math.sin(a) * 250}, 10, 1)
      if p then s.create_entity{name = "wooden-chest", position = p, force = "player"} end
    end
  elseif e.tick == 4000 then
    local sent = remote.call("second-dawn", "raid", "player", 1000)
    log("SD-TEST lairs " .. s.count_entities_filtered{type = "unit-spawner", force = "sd-wildlife"} ..
      ", animals " .. s.count_entities_filtered{type = "unit", force = "sd-wildlife"} .. ", raids sent " .. sent)
  elseif e.tick == 7000 then
    local w = remote.call("second-dawn", "wildlife")
    log("SD-TEST raiders " .. table_size(w.raiders) .. ", chests left " ..
      s.count_entities_filtered{name = "wooden-chest", force = "player"})
  end
end)
