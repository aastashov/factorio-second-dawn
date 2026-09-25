-- Chutes behave like vanilla belts: a splitter or an underground goes straight onto a chute of any tier
-- (fast replace), and each tier upgrades into the next.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 5 then return end
  local s = game.surfaces.nauvis
  s.request_to_generate_chunks({2000, 0}, 2); s.force_generate_chunk_requests()
  local tiles = {}
  for x = 1980, 2020 do for y = -20, 20 do tiles[#tiles + 1] = {name = "grass-1", position = {x, y}} end end
  s.set_tiles(tiles)
  for _, en in pairs(s.find_entities_filtered{area = {{1980, -20}, {2020, 20}}}) do en.destroy() end

  local y = -15
  local function line(belt)
    y = y + 4
    for x = 1990, 1995 do
      s.create_entity{name = belt, position = {x + 0.5, y + 0.5}, direction = defines.direction.east, force = "player"}
    end
    return y
  end
  local belts = {"sd-wooden-chute", "sd-roller-chute", "fast-transport-belt"}
  local others = {"sd-wooden-underground-chute", "sd-underground-chute", "fast-underground-belt",
                  "sd-wooden-splitter-chute", "sd-splitter-chute", "fast-splitter"}
  for _, belt in pairs(belts) do
    local row = line(belt)
    for _, other in pairs(others) do
      -- a splitter is 2 wide across the belt: it sits between two tiles, over this belt and the next row
      local pos = other:find("splitter") and {1992.5, row + 1} or {1992.5, row + 0.5}
      local ok = s.can_fast_replace{name = other, position = pos, direction = defines.direction.east, force = "player"}
      check(other .. " over " .. belt, ok)
    end
  end
  for _, pair in pairs{{"sd-wooden-chute", "sd-roller-chute"}, {"sd-roller-chute", "fast-transport-belt"},
                       {"sd-wooden-underground-chute", "sd-underground-chute"}, {"sd-underground-chute", "fast-underground-belt"},
                       {"sd-wooden-splitter-chute", "sd-splitter-chute"}, {"sd-splitter-chute", "fast-splitter"}} do
    local up = prototypes.entity[pair[1]].next_upgrade
    check(pair[1] .. " upgrades to " .. pair[2], up and up.name == pair[2], up and up.name or "nothing")
  end
  L("failures: " .. failures)
end)
