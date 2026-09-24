-- UPS with wild animals: ~40 chunks in every direction generated (lairs everywhere past 150 tiles),
-- lairs filled for a minute, then measured. Run with SD_BENCH_VERBOSE=1 and ups-report.py <log> 4000.
script.on_event(defines.events.on_tick, function(e)
  if e.tick == 2 then
    local s = game.surfaces.nauvis
    s.request_to_generate_chunks({0, 0}, 20)
    s.force_generate_chunk_requests()
  elseif e.tick == 4000 then
    local s = game.surfaces.nauvis
    log("SD-TEST lairs " .. s.count_entities_filtered{type = "unit-spawner", force = "sd-wildlife"} ..
      ", animals " .. s.count_entities_filtered{type = "unit", force = "sd-wildlife"})
  end
end)
