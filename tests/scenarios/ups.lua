-- UPS: 200 epoch 1 machines working (plus the mod's own script) for a minute of game time.
-- Run with SD_BENCH_VERBOSE=1 to get per-tick timings; tests/ups-report.py summarises them.
local O = {x = -600, y = -600}
local force = "player"

local function build()
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks(O, 4); s.force_generate_chunk_requests()
  local tiles = {}
  for x = -10, 130 do for y = -10, 90 do tiles[#tiles + 1] = {name = "grass-1", position = {O.x + x, O.y + y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{O.x - 10, O.y - 10}, {O.x + 130, O.y + 90}}}) do e.destroy() end
  for name, r in pairs(game.forces[force].recipes) do
    if name:find("^sd%-") then r.enabled = true end
  end
  local kinds = {
    {"sd-kiln", "sd-brick", 2, {{"sd-clay", 2000}}, "sd-charcoal"},
    {"sd-workbench", "sd-clay-tablet", 2, {{"sd-clay", 2000}, {"sd-charcoal", 1000}}},
    {"sd-alembic", "sd-nitric-acid", 3, {{"sd-jug", 500}, {"sd-saltpeter", 2000}, {"sd-charcoal", 500}}, "sd-charcoal"},
    {"sd-fermentation-vat", "sd-mash", 2, {{"sd-jug", 500}, {"sd-fruit", 2000}}},
    {"sd-kiln", "sd-charcoal", 1, {{"wood", 2000}}, "sd-charcoal"},
  }
  local n = 0
  for row, k in pairs(kinds) do
    for i = 0, 39 do
      local e = s.create_entity{name = k[1], position = {O.x + i * 3 + 1, O.y + row * 8}, force = force, recipe = k[2]}
      local inv = e.get_inventory(defines.inventory.crafter_input)
      for _, it in pairs(k[4]) do inv.insert{name = it[1], count = it[2]} end
      if k[5] then e.get_fuel_inventory().insert{name = k[5], count = 50} end
      n = n + 1
    end
  end
  log("SD-TEST built " .. n .. " machines")
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick == 2 then build() end
  if e.tick == 3600 then
    local busy = game.surfaces.nauvis.count_entities_filtered{type = "assembling-machine", force = force}
    log("SD-TEST machines at the end: " .. busy)
  end
end)
