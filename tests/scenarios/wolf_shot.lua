-- One picture of a running sd-wolf, commanded to a distant point so it's mid-stride, not idle.
--   SD_TEST_DIR=... tests/run-scenario.sh wolf_shot 2   (builds the save; screenshots need graphics, see tools/screenshots.sh)
local function clear(s, cx, cy, r)
  local tiles = {}
  for x = cx - r, cx + r do for y = cy - r, cy + r do tiles[#tiles + 1] = {name = "grass-1", position = {x, y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{cx - r, cy - r}, {cx + r, cy + r}}}) do
    if e.type ~= "character" then e.destroy() end
  end
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 5 then
    s.request_to_generate_chunks({0, 0}, 4)
    s.force_generate_chunk_requests()
    clear(s, 20, 20, 25)
    local wolf = s.create_entity{name = "sd-wolf", position = {20, 20}, force = "sd-wildlife"}
    storage.wolf = wolf
    wolf.commandable.set_command{type = defines.command.go_to_location, destination = {60, 20},
      distraction = defines.distraction.none}
    log("SD-TEST wolf placed " .. tostring(wolf.valid))
  elseif e.tick == 90 and storage.wolf and storage.wolf.valid then
    local ok = pcall(game.take_screenshot, {surface = s, position = storage.wolf.position, resolution = {960, 720},
      zoom = 3, path = "sd-wolf-shot/running.png", show_entity_info = false, daytime = 0,
      anti_alias = true, allow_in_replay = true})
    log("SD-TEST shot running " .. tostring(ok) .. " at " .. serpent.line(storage.wolf.position))
    helpers.write_file("sd-wolf-shot/done.txt", "done")
  end
end)
