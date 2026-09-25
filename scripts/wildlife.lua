-- Wild animals (docs/DESIGN.md §15): lairs placed as chunks generate, animals attacking players who come
-- too close, predators raiding at night, and petrification waves freezing them for a while.
local wildlife = {}

local FORCE = "sd-wildlife"
local LAIRS = {"sd-wolf-lair", "sd-boar-lair", "sd-bear-den"}
local PREDATORS = {"sd-wolf-lair", "sd-bear-den"}
local SAFE_RADIUS = 200
local D = settings.startup["sd-climate-distance"].value -- bears live in the cold, boars outside it
local TERRITORY = 25
local LEASH = 60 -- animals chase no farther than this from their lair
local WOLF_CHANCE, OTHER_CHANCE = 0.03, 0.02 -- per generated chunk
local RAID_REACH = 300
local FREEZE = 10 * 60 * 60
local RAID_TIME = 4 * 60 * 60 -- a raiding pack goes home after 4 minutes
local CALM_RADIUS = 60 -- after a player's death, animals this close go home
local FIRST_RAID_TICK = 2 * 60 * 60 * 60 -- raids start with the first wave (or 2 h when waves are off)

local MODES = {
  peaceful = {territorial = false, raid_chance = 0},
  calm = {territorial = true, raid_chance = 0},
  normal = {territorial = true, raid_chance = 0.4, lairs = 2},
  dangerous = {territorial = true, raid_chance = 0.7, lairs = 3},
}

local function mode() return MODES[settings.global["sd-wildlife"].value] end

function wildlife.init()
  if not game.forces[FORCE] then game.create_force(FORCE) end
  game.map_settings.enemy_expansion.enabled = false
  game.map_settings.enemy_evolution.enabled = false
  if not storage.wildlife then
    storage.wildlife = {
      rng = game.create_random_generator(game.surfaces.nauvis.map_gen_settings.seed + 104729),
      night = false,
      raids = 0,
      frozen_until = nil,
      thinned = true,
    }
  end
  storage.wildlife.chasers = storage.wildlife.chasers or {}
  storage.wildlife.raiders = storage.wildlife.raiders or {}
  wildlife.apply_mode()
end

-- Peaceful animals keep a cease-fire with every player force; players can still hunt them.
function wildlife.apply_mode()
  local peaceful = not mode().territorial
  local wild = game.forces[FORCE]
  for _, force in pairs(game.forces) do
    if force ~= wild and force.name ~= "neutral" and force.name ~= "enemy" then
      wild.set_cease_fire(force, peaceful)
    end
  end
end

function wildlife.on_chunk_generated(e)
  if not storage.wildlife or e.surface.name ~= "nauvis" then return end
  local lt = e.area.left_top
  local centre = {x = lt.x + 16, y = lt.y + 16}
  local d = math.sqrt(centre.x * centre.x + centre.y * centre.y)
  if d < SAFE_RADIUS then return end
  local r = storage.wildlife.rng()
  local cold = centre.y < -D
  local name
  if r < WOLF_CHANCE then name = "sd-wolf-lair"
  elseif r < WOLF_CHANCE + OTHER_CHANCE then name = cold and "sd-bear-den" or "sd-boar-lair"
  else return end
  local pos = e.surface.find_non_colliding_position(name, centre, 10, 1)
  if pos then e.surface.create_entity{name = name, position = pos, force = FORCE} end
end

-- The units of a lair attack `target`. A scripted attack takes them out of the lair, so they are
-- remembered with their home for the leash.
local function unleash(lair, target)
  local chasers = storage.wildlife.chasers
  for _, unit in pairs(lair.units) do
    if unit.valid then
      unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_anything}
      chasers[unit.unit_number] = {unit = unit, home = lair.position, since = game.tick}
    end
  end
end

function wildlife.provoke(character)
  local lairs = character.surface.find_entities_filtered{
    position = character.position, radius = TERRITORY, type = "unit-spawner", force = FORCE,
  }
  for _, lair in pairs(lairs) do unleash(lair, character) end
  return #lairs
end

-- Sends an animal back to `home` (or to the nearest lair; one with no lair left is gone), out of any pack.
local function go_home(unit, home)
  if not home then
    local best, dist
    for _, lair in pairs(unit.surface.find_entities_filtered{position = unit.position, radius = 400, type = "unit-spawner", force = FORCE}) do
      local dx, dy = lair.position.x - unit.position.x, lair.position.y - unit.position.y
      if not dist or dx * dx + dy * dy < dist then best, dist = lair, dx * dx + dy * dy end
    end
    if not best then
      unit.destroy()
      return
    end
    home = best.position
  end
  local cmd = unit.commandable
  if cmd.parent_group and cmd.parent_group.valid then cmd.parent_group.destroy() end
  cmd.set_command{type = defines.command.go_to_location, destination = home, radius = 5,
    distraction = defines.distraction.none}
end

-- Every animal within `radius` of `position` goes home: after a player dies nobody camps on the corpse.
function wildlife.calm(surface, position, radius)
  local w = storage.wildlife
  local n = 0
  for _, unit in pairs(surface.find_entities_filtered{position = position, radius = radius or CALM_RADIUS, type = "unit", force = FORCE}) do
    local known = w.chasers[unit.unit_number] or w.raiders[unit.unit_number]
    w.chasers[unit.unit_number], w.raiders[unit.unit_number] = nil, nil
    go_home(unit, known and known.home)
    n = n + 1
  end
  return n
end

-- 0.12: packs from raids before raids ended stay at the bases. They go home now.
function wildlife.calm_bases()
  local w = storage.wildlife
  if w.bases_calmed then return 0 end
  w.bases_calmed = true
  local n = 0
  local surface = game.surfaces.nauvis
  for _, unit in pairs(surface.find_entities_filtered{type = "unit", force = FORCE}) do
    if unit.valid then
      for _, force in pairs(game.forces) do
        if #force.players > 0 and surface.count_entities_filtered{position = unit.position, radius = CALM_RADIUS, force = force, limit = 1} > 0 then
          go_home(unit)
          n = n + 1
          break
        end
      end
    end
  end
  return n
end

-- Runs every 2 s: animals that chased farther than LEASH from their lair give up and go home. Returns
-- how many were sent home.
local CHASE_TIMEOUT = 5 * 60 * 60
function wildlife.leash(tick)
  local w = storage.wildlife
  local sent = 0
  for id, r in pairs(w.raiders) do
    if not r.unit.valid then
      w.raiders[id] = nil
    elseif tick >= r.until_tick then
      w.raiders[id] = nil
      go_home(r.unit, r.home)
      w.raids_ended = (w.raids_ended or 0) + 1
    else
      -- The pack's order ends once its first target is down; until the raid is over each animal takes the
      -- next building within reach, so the raid goes on into the base. Nothing left near: home.
      local cmd = r.unit.commandable
      local g = cmd.parent_group
      local pack_busy = g and g.valid and g.command ~= nil
      if not pack_busy and not (r.target and r.target.valid) then
        local force = r.force and game.forces[r.force]
        local target
        if force then
          for _, b in pairs(r.unit.surface.find_entities_filtered{force = force, position = r.unit.position, radius = 50, limit = 20}) do
            if b.type ~= "character" and b.destructible then target = b break end
          end
        end
        if target then
          if g and g.valid then g.destroy() end
          cmd.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_anything}
          r.target = target
        else
          w.raiders[id] = nil
          go_home(r.unit, r.home)
          w.raids_ended = (w.raids_ended or 0) + 1
        end
      end
    end
  end
  for id, c in pairs(w.chasers) do
    local unit = c.unit
    if not unit.valid or tick - c.since > CHASE_TIMEOUT then
      w.chasers[id] = nil
    else
      local dx, dy = unit.position.x - c.home.x, unit.position.y - c.home.y
      if dx * dx + dy * dy > LEASH * LEASH then
        unit.commandable.set_command{type = defines.command.go_to_location, destination = c.home, radius = 5,
          distraction = defines.distraction.none}
        w.chasers[id] = nil
        w.leashed = (w.leashed or 0) + 1
        sent = sent + 1
      end
    end
  end
  return sent
end

-- Runs every 2 s: animals attack players who come closer than 25 tiles to their lair.
function wildlife.territory(is_petrified)
  if not mode().territorial or storage.wildlife.frozen_until then return end
  for _, player in pairs(game.connected_players) do
    local character = player.character
    if character and not is_petrified(player) then
      wildlife.provoke(character)
    end
  end
end

-- 0.11: lairs were twice as dense and came as close as 150 tiles. Existing maps are thinned out to
-- what generation gives now.
function wildlife.thin_out()
  local w = storage.wildlife
  if w.thinned then return end
  w.thinned = true
  local removed = 0
  for _, lair in pairs(game.surfaces.nauvis.find_entities_filtered{name = LAIRS, force = FORCE}) do
    local p = lair.position
    local keep = lair.name == "sd-wolf-lair" and WOLF_CHANCE / 0.06 or OTHER_CHANCE / 0.04
    if p.x * p.x + p.y * p.y < SAFE_RADIUS * SAFE_RADIUS or w.rng() >= keep then
      for _, unit in pairs(lair.units) do if unit.valid then unit.destroy() end end
      lair.destroy()
      removed = removed + 1
    end
  end
  return removed
end

function wildlife.provoke(character)
  local lairs = character.surface.find_entities_filtered{
    position = character.position, radius = TERRITORY, type = "unit-spawner", force = FORCE,
  }
  for _, lair in pairs(lairs) do unleash(lair, character) end
  return #lairs
end

-- A building of `force` near `position`, searching outwards; characters don't count.
local function nearest_building(surface, force, position)
  for _, radius in pairs{40, 80, 160, RAID_REACH} do
    for _, e in pairs(surface.find_entities_filtered{force = force, position = position, radius = radius, limit = 4}) do
      if e.type ~= "character" then return e end
    end
  end
end

-- Sends predators of up to `count` lairs near `force`'s buildings after them. Returns the lairs sent.
function wildlife.raid(force, count)
  local surface = game.surfaces.nauvis
  local candidates = {}
  for _, lair in pairs(surface.find_entities_filtered{name = PREDATORS, force = FORCE}) do
    if #lair.units > 0 then
      local target = nearest_building(surface, force, lair.position)
      if target then candidates[#candidates + 1] = {lair = lair, target = target} end
    end
  end
  local sent = {}
  for _ = 1, math.min(count, #candidates) do
    local i = storage.wildlife.rng(1, #candidates)
    local c = table.remove(candidates, i)
    local group = surface.create_unit_group{position = c.lair.position, force = FORCE}
    for _, unit in pairs(c.lair.units) do
      -- Out of the lair's care: an animal that still belongs to its lair walks back to it as soon as an
      -- order is done, which ended raids after the first building.
      unit.release_from_spawner()
      storage.wildlife.chasers[unit.unit_number] = nil -- a raider is off the leash: it goes where the raid goes
      group.add_member(unit)
      storage.wildlife.raiders[unit.unit_number] = {unit = unit, home = c.lair.position, until_tick = game.tick + RAID_TIME,
        force = force.index}
    end
    -- Into the base, not only its edge: the pack goes for the middle of the buildings around the one nearest
    -- to its lair, and anything in reach of that (the nearest building included) is fair game.
    local x, y, n = 0, 0, 0
    for _, bld in pairs(surface.find_entities_filtered{force = force, position = c.target.position, radius = 60, limit = 200}) do
      if bld.type ~= "character" then x, y, n = x + bld.position.x, y + bld.position.y, n + 1 end
    end
    local inner = n > 0 and {x = x / n, y = y / n} or c.target.position
    local dx, dy = inner.x - c.target.position.x, inner.y - c.target.position.y
    local reach = math.min(45, math.max(20, math.sqrt(dx * dx + dy * dy) + 15))
    group.set_command{type = defines.command.attack_area, destination = inner, radius = reach,
      distraction = defines.distraction.by_anything}
    force.print({"sd-message.raid", string.format("[gps=%d,%d]", c.lair.position.x, c.lair.position.y)})
    sent[#sent + 1] = c.lair
    storage.wildlife.raids = storage.wildlife.raids + 1
  end
  return sent
end

-- Runs every 5 s: at nightfall, each player force may be raided.
function wildlife.night(tick, waves_started)
  local w = storage.wildlife
  local night = game.surfaces.nauvis.darkness >= 0.5
  local fell = night and not w.night
  w.night = night
  if not fell or w.frozen_until then return end
  local m = mode()
  if m.raid_chance == 0 or not (waves_started or tick >= FIRST_RAID_TICK) then return end
  for _, force in pairs(game.forces) do
    if #force.players > 0 and w.rng() < m.raid_chance then
      wildlife.raid(force, m.lairs)
    end
  end
end

local function set_frozen(frozen)
  for _, e in pairs(game.surfaces.nauvis.find_entities_filtered{force = FORCE}) do
    e.disabled_by_script = frozen
  end
end

-- A petrification wave turns animals to stone for 10 minutes.
function wildlife.freeze(tick)
  storage.wildlife.frozen_until = tick + FREEZE
  set_frozen(true)
end

function wildlife.update(tick)
  local w = storage.wildlife
  if w.frozen_until and tick >= w.frozen_until then
    w.frozen_until = nil
    set_frozen(false)
  end
end

return wildlife
