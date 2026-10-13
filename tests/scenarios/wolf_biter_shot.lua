-- One picture of sd-wolf standing next to a vanilla small-biter, for a direct color/size comparison.
--   SD_TEST_DIR=... tests/run-scenario.sh wolf_biter_shot 2   (builds the save; screenshot needs graphics)
local function clear(s, cx, cy, r)
  local tiles = {}
  for x = cx - r, cx + r do for y = cy - r, cy + r do tiles[#tiles + 1] = {name = "grass-1", position = {x, y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{cx - r, cy - r}, {cx + r, cy + r}}}) do
    if e.type ~= "character" then e.destroy() end
  end
  s.destroy_decoratives{area = {{cx - r, cy - r}, {cx + r, cy + r}}} -- decoratives (grass tufts) aren't entities
end

script.on_event(defines.events.on_tick, function(e)
  local s = game.surfaces.nauvis
  if e.tick == 5 then
    s.request_to_generate_chunks({0, 0}, 4)
    s.force_generate_chunk_requests()
    clear(s, 20, 20, 15)
    local wolf = s.create_entity{name = "sd-wolf", position = {17, 20}, force = "sd-wildlife"}
    local biter = s.create_entity{name = "small-biter", position = {23, 20}, force = "enemy"}
    log("SD-TEST placed " .. tostring(wolf.valid) .. " " .. tostring(biter.valid))
  elseif e.tick == 30 then
    local ok = pcall(game.take_screenshot, {surface = s, position = {20, 20}, resolution = {960, 720},
      zoom = 3, path = "sd-wolf-biter-shot/compare.png", show_entity_info = false, daytime = 0,
      anti_alias = true, allow_in_replay = true})
    log("SD-TEST shot compare " .. tostring(ok))
    helpers.write_file("sd-wolf-biter-shot/done.txt", "done")
  end
end)
