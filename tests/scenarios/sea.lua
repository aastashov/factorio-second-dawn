-- Continents: land at the camp, deep ocean around it, a shelf of shallow water along the coast, land
-- again past the ocean north and south; landfill only on shallow water, deep landfill only on deep water.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end
local D = settings.startup["sd-climate-distance"].value

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 2 then return end
  local s = game.surfaces.nauvis
  for _, p in pairs{{0, -(D + 700)}, {0, -900}, {0, 0}, {0, 900}, {0, D + 700}, {-1000, 0}, {1000, 0}, {-500, D + 700}, {500, D + 700}, {-500, -(D + 700)}, {500, -(D + 700)}, {-1300, 0}, {1300, 0}, {0, -1300}, {0, 1300}} do
    s.request_to_generate_chunks(p, 8)
  end
  s.force_generate_chunk_requests()
  local function tile(x, y)
    local c = {math.floor(x / 32), math.floor(y / 32)}
    if not s.is_chunk_generated(c) then
      s.request_to_generate_chunks({x, y}, 0)
      s.force_generate_chunk_requests()
    end
    return s.get_tile(x, y).name
  end
  local WATER = {water = "shallow", ["water-green"] = "shallow", deepwater = "deep", ["deepwater-green"] = "deep"}

  local land = s.count_tiles_filtered{area = {{-100, -100}, {100, 100}}, collision_mask = "water_tile"}
  check("land at the camp", land < 4000, land .. " water tiles in 200x200")

  -- 32 rays from the camp: the coast is the last land before the open ocean (inland lakes don't count),
  -- the shelf is the shallow water between the coast and the first deep water
  local widths, open_ocean = {}, 0
  for i = 0, 31 do
    local a = i * math.pi / 16
    local dx, dy = math.cos(a), math.sin(a)
    local kinds, last_land = {}, 0
    for d = 0, 1100, 1 do
      kinds[d] = WATER[tile(math.floor(dx * d), math.floor(dy * d))]
      if not kinds[d] and d < 1000 then last_land = d end
    end
    local first_deep
    for d = last_land + 1, 1100 do
      if kinds[d] == "deep" then first_deep = d break end
    end
    if first_deep then widths[#widths + 1] = first_deep - last_land - 1 end
    if kinds[1000] == "deep" then open_ocean = open_ocean + 1 end
  end
  table.sort(widths)
  local median = widths[math.floor(#widths / 2) + 1]
  check("shelf median 35-90 tiles", median and median >= 35 and median <= 90,
    string.format("median %s, min %s, max %s over %d rays", tostring(median), tostring(widths[1]), tostring(widths[#widths]), #widths))
  check("deep ocean 1000 tiles out in (almost) every direction", open_ocean >= 28, open_ocean .. " of 32 rays")

  local function land_share(y)
    local area = {{-600, y - 150}, {600, y + 150}}
    return 1 - s.count_tiles_filtered{area = area, collision_mask = "water_tile"} / (1200 * 300)
  end
  check("land in the north past the ocean", land_share(-(D + 700)) > 0.5, string.format("%.0f%%", land_share(-(D + 700)) * 100))
  check("land in the south past the ocean", land_share(D + 700) > 0.5, string.format("%.0f%%", land_share(D + 700) * 100))

  local function cond(item)
    local t = {}
    for _, c in pairs(prototypes.item[item].place_as_tile_result.tile_condition or {}) do t[#t + 1] = c.name or c end
    table.sort(t)
    return table.concat(t, ",")
  end
  check("landfill: shallow water only", not cond("landfill"):find("deep"), cond("landfill"))
  check("deep landfill: deep water only", cond("sd-deep-landfill") == "deepwater,deepwater-green", cond("sd-deep-landfill"))
  L("failures: " .. failures)
end)
