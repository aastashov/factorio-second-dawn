-- Climate (docs/DESIGN.md §17). Only buildings in the cold or hot belt are tracked. A building there is
-- protected when a working heater (cold) or cooler (hot) of the same force covers it; coverage is
-- recomputed when buildings or sources come and go, and when a source starts or stops working.
-- Cold: unprotected buildings stop. Heat: unprotected buildings work every other 5 s.
local climate = {}

local D = settings.startup["sd-climate-distance"].value
local AFFECTED = {"assembling-machine", "furnace", "mining-drill", "lab", "boiler"}
local EXEMPT = {
  ["sd-brazier"] = true, ["sd-radiator"] = true, ["sd-cooler"] = true,
  ["sd-revival-chamber"] = true, ["sd-revival-chamber-2"] = true,
  ["sd-boar-farm"] = true, ["sd-wolf-kennel"] = true, ["sd-bear-pen"] = true,
  ["sd-plantation"] = true, -- made for the heat
}
local SOURCES = {
  ["sd-brazier"] = {belt = "cold", radius = 6},
  ["sd-radiator"] = {belt = "cold", radius = 10},
  ["sd-cooler"] = {belt = "hot", radius = 8},
}
local SOURCE_NAMES = {"sd-brazier", "sd-radiator", "sd-cooler"}
local MAX_RADIUS = 10
local CLOTHING = {["sd-fur-coat"] = "cold", ["sd-light-cloak"] = "hot"}
local EXPOSURE = 2 -- HP per second
local HEAT_CYCLE = 300

climate.AFFECTED = AFFECTED

function climate.belt(position)
  if position.y < -D then return "cold" end
  if position.y > D then return "hot" end
  return nil
end

function climate.init()
  storage.climate = storage.climate or {entities = {}, sources = {}, phase = false}
end

local function covered(entity, belt)
  for _, s in pairs(entity.surface.find_entities_filtered{name = SOURCE_NAMES, position = entity.position, radius = MAX_RADIUS, force = entity.force}) do
    local def = SOURCES[s.name]
    local src = storage.climate.sources[s.unit_number]
    if def.belt == belt and src and src.working then
      local dx, dy = s.position.x - entity.position.x, s.position.y - entity.position.y
      if dx * dx + dy * dy <= def.radius * def.radius then return true end
    end
  end
  return false
end

local function set_status(e, key)
  if key then
    e.custom_status = {diode = defines.entity_status_diode.red, label = {"sd-gui." .. key}}
  else
    e.custom_status = nil
  end
end

local function apply(entry)
  local e = entry.entity
  if not e.valid then return end
  if entry.belt == "cold" then
    e.disabled_by_script = not entry.covered
    set_status(e, not entry.covered and "frozen" or nil)
    if not entry.covered and not (entry.render and entry.render.valid) then
      entry.render = rendering.draw_sprite{sprite = "virtual-signal/signal-snowflake", target = e, surface = e.surface,
        x_scale = 0.6, y_scale = 0.6, render_layer = "entity-info-icon"}
    elseif entry.covered and entry.render and entry.render.valid then
      entry.render.destroy()
      entry.render = nil
    end
  else
    if entry.covered then
      e.disabled_by_script = false
      set_status(e, nil)
    else
      e.disabled_by_script = storage.climate.phase
      set_status(e, "overheating")
    end
  end
end

local function refresh(entry)
  if not entry.entity.valid then return end
  entry.covered = covered(entry.entity, entry.belt)
  apply(entry)
end

-- Recomputes coverage of tracked buildings around `position`.
local function refresh_around(surface, position, force)
  for _, e in pairs(surface.find_entities_filtered{type = AFFECTED, position = position, radius = MAX_RADIUS, force = force}) do
    local entry = storage.climate.entities[e.unit_number]
    if entry then refresh(entry) end
  end
end

function climate.on_built(entity)
  if SOURCES[entity.name] then
    storage.climate.sources[entity.unit_number] = {entity = entity, working = false}
    return
  end
  if EXEMPT[entity.name] or entity.force.name == "neutral" or entity.unit_number == nil then return end
  local belt = climate.belt(entity.position)
  if not belt then return end
  local entry = {entity = entity, belt = belt}
  storage.climate.entities[entity.unit_number] = entry
  refresh(entry)
end

function climate.on_removed(entity)
  local n = entity.unit_number
  if not n then return end
  local c = storage.climate
  if c.entities[n] then
    local r = c.entities[n].render
    if r and r.valid then r.destroy() end
    c.entities[n] = nil
  elseif c.sources[n] then
    c.sources[n] = nil
    local surface, position, force = entity.surface, entity.position, entity.force
    -- the source is still there during the removal event; look again next tick
    c.pending = c.pending or {}
    c.pending[#c.pending + 1] = {surface = surface, position = position, force = force}
  end
end

-- Runs every 60 ticks: sources that started or stopped working change their surroundings.
function climate.update_sources()
  local c = storage.climate
  if c.pending then
    for _, p in pairs(c.pending) do
      if p.surface.valid then refresh_around(p.surface, p.position, p.force) end
    end
    c.pending = nil
  end
  for n, src in pairs(c.sources) do
    local e = src.entity
    if not e.valid then
      c.sources[n] = nil
    else
      local working = e.status == defines.entity_status.working
      if working ~= src.working then
        src.working = working
        refresh_around(e.surface, e.position, e.force)
      end
    end
  end
end

-- Runs every HEAT_CYCLE ticks: unprotected buildings in the heat switch between working and resting.
function climate.heat_cycle()
  local c = storage.climate
  c.phase = not c.phase
  for n, entry in pairs(c.entities) do
    if not entry.entity.valid then
      c.entities[n] = nil
    elseif entry.belt == "hot" and not entry.covered then
      apply(entry)
    end
  end
end

-- Exposure of one character for one second. Returns the belt and whether it is protected.
function climate.expose(character)
  local belt = climate.belt(character.position)
  if not belt then return nil, true end
  local armor = character.get_inventory(defines.inventory.character_armor)
  local worn = armor and not armor.is_empty() and armor[1].name
  local protected = CLOTHING[worn] == belt
  if not protected then character.damage(EXPOSURE, "neutral", "sd-exposure") end
  return belt, protected
end

function climate.players(is_petrified)
  for _, player in pairs(game.connected_players) do
    local character = player.character
    if character and not is_petrified(player) then
      local belt, protected = climate.expose(character)
      storage.climate.player_state = storage.climate.player_state or {}
      storage.climate.player_state[player.index] = belt and {belt = belt, protected = protected} or nil
    end
  end
end

-- For saves from before 0.6: track what already stands in the belts.
function climate.scan()
  for _, surface in pairs(game.surfaces) do
    for _, e in pairs(surface.find_entities_filtered{type = AFFECTED}) do
      if e.force.name ~= "neutral" and e.force.name ~= "sd-wildlife" and e.force.name ~= "enemy" then climate.on_built(e) end
    end
    for _, e in pairs(surface.find_entities_filtered{name = SOURCE_NAMES}) do climate.on_built(e) end
  end
end

return climate
