-- Ships: waterway only on water; a double-headed ship (tug, barge, tank barge, tug) sails between two
-- piers 380 tiles apart by schedule; shore inserters load it at the east pier and unload at the west;
-- the tank barge keeps its fluid; top speed with coal and with briquettes; a buoy stands on water.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end
local Y = -1100 -- open ocean between the start continent and the north
local E, W = defines.direction.east, defines.direction.west
script.on_init(function() storage.t = {trips = {}, max = {}} end)

local function setup()
  local s, T = game.surfaces.nauvis, storage.t
  for x = -240, 240, 64 do s.request_to_generate_chunks({x, Y}, 1) end
  s.force_generate_chunk_requests()
  local tiles = {}
  for x = -230, 230 do for y = -12, 12 do
    tiles[#tiles + 1] = {name = (y <= 1) and "deepwater" or "grass-1", position = {x, Y + y}}
  end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{-230, Y - 12}, {230, Y + 12}}}) do e.destroy() end
  local f = game.forces.player
  check("waterway not on land", not s.can_place_entity{name = "sd-waterway-straight-rail", position = {1, Y + 9}, direction = E, force = f})
  local n = 0
  for x = -201, 201, 2 do
    if s.create_entity{name = "sd-waterway-straight-rail", position = {x, Y + 1}, direction = E, force = f} then n = n + 1 end
  end
  check("waterway on water", n == 202, n .. " pieces")
  local east = s.create_entity{name = "sd-pier", position = {190, Y + 3}, direction = E, force = f}
  local west = s.create_entity{name = "sd-pier", position = {-190, Y - 1}, direction = W, force = f}
  check("piers placed (one on the shore, one on water)", east ~= nil and west ~= nil)
  east.backer_name, west.backer_name = "East", "West"
  check("buoy on water", s.create_entity{name = "sd-buoy", position = {0.5, Y - 0.5}, direction = W, force = f} ~= nil)

  T.front = s.create_entity{name = "sd-tug", position = {-150, Y + 1}, direction = E, force = f}
  T.barge = s.create_entity{name = "sd-barge", position = {-157, Y + 1}, direction = E, force = f}
  T.tank = s.create_entity{name = "sd-fluid-barge", position = {-164, Y + 1}, direction = E, force = f}
  T.back = s.create_entity{name = "sd-tug", position = {-171, Y + 1}, direction = W, force = f}
  check("four ships make one train", T.front.train == T.back.train and #T.front.train.carriages == 4, #T.front.train.carriages .. " carriages")
  for _, tug in pairs{T.front, T.back} do tug.get_fuel_inventory().insert{name = "coal", count = 50} end
  T.tank.insert_fluid{name = "water", amount = 20000}
  local train = T.front.train
  train.schedule = {current = 1, records = {
    {station = "East", wait_conditions = {{type = "time", ticks = 600}}},
    {station = "West", wait_conditions = {{type = "time", ticks = 600}}},
  }}
  train.manual_mode = false
  T.fuel = "coal"
end

-- Shore inserters next to the barge's berth: `into` true loads the barge from a chest, false unloads it.
local function shore(into)
  local s, T = game.surfaces.nauvis, storage.t
  local bx = math.floor(T.barge.position.x) + 0.5
  local chest = s.create_entity{name = "wooden-chest", position = {bx, Y + 3.5}, force = "player"}
  local ins = s.create_entity{name = "inserter", position = {bx, Y + 2.5}, direction = into and defines.direction.south or defines.direction.north, force = "player"}
  if into then chest.insert{name = "iron-plate", count = 50} end
  local power = s.create_entity{name = "electric-energy-interface", position = {bx + 3, Y + 4}, force = "player"}
  power.power_production = 1e5
  power.electric_buffer_size = 1e6
  s.create_entity{name = "small-electric-pole", position = {bx + 1.5, Y + 2.5}, force = "player"}
  return chest
end

script.on_event(defines.events.on_tick, function(e)
  local T = storage.t
  if e.tick == 2 then setup() return end
  if not T.front then return end
  local train = T.front.train
  T.max[T.fuel] = math.max(T.max[T.fuel] or 0, math.abs(train.speed))
  local at = train.station and train.station.backer_name
  if at ~= T.last then
    T.last = at
    if at then
      T.trips[#T.trips + 1] = {station = at, tick = e.tick}
      if at == "East" and not T.loader then T.loader = shore(true) end
      if at == "West" and T.loader and not T.unloader then
        T.unloader = shore(false)
        -- second trip on briquettes
        for _, tug in pairs{T.front, T.back} do
          tug.get_fuel_inventory().clear()
          tug.get_fuel_inventory().insert{name = "sd-briquettes", count = 50}
          tug.burner.currently_burning = "sd-briquettes"
          tug.burner.remaining_burning_fuel = 5e6
        end
        T.fuel = "briquettes"
      end
    end
  end
  if e.tick == 9000 then
    local names = {}
    for _, t in pairs(T.trips) do names[#names + 1] = t.station .. "@" .. t.tick end
    check("sails East, West, East by schedule", #T.trips >= 3 and T.trips[1].station == "East" and T.trips[2].station == "West",
      table.concat(names, " "))
    if T.trips[2] then
      local secs = (T.trips[2].tick - T.trips[1].tick - 600) / 60
      check("380 tiles in about 25-35 s", secs >= 20 and secs <= 40, string.format("%.1f s", secs))
    end
    local loaded = T.barge.get_inventory(defines.inventory.cargo_wagon).get_item_count("iron-plate")
    local unloaded = T.unloader and T.unloader.get_item_count("iron-plate") or 0
    check("loaded at East, unloaded at West", unloaded > 0, "unloaded " .. unloaded .. ", still aboard " .. loaded)
    check("tank barge keeps its water", T.tank.get_fluid_count("water") == 20000, tostring(T.tank.get_fluid_count("water")))
    local coal, bri = T.max.coal or 0, T.max.briquettes or 0
    check("top speed 0.3 tiles/tick on coal", math.abs(coal - 0.3) < 0.01, string.format("%.3f", coal))
    check("briquettes: 15% faster", bri > coal * 1.1, string.format("%.3f", bri))
    L("failures: " .. failures)
  end
end)
