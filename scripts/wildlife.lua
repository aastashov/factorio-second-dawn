-- Wild animals (docs/DESIGN.md §15): lairs placed as chunks generate, animals attacking players who come
-- too close, predators raiding at night, and petrification waves freezing them for a while.
local wildlife = {}

local FORCE = "sd-wildlife"
local LAIRS = {"sd-wolf-lair", "sd-boar-lair", "sd-bear-den"}
local PREDATORS = {"sd-wolf-lair", "sd-bear-den"}
local SAFE_RADIUS = 150
local FAR = 500
local TERRITORY = 25
local RAID_REACH = 300
local FREEZE = 10 * 60 * 60
local FIRST_RAID_TICK = 2 * 60 * 60 * 60 -- raids start with the first wave (or 2 h when waves are off)

local MODES = {
  peaceful = {territorial = false, raid_chance = 0},
  calm = {territorial = true, raid_chance = 0},
  normal = {territorial = true, raid_chance = 0.25, lairs = 1},
  dangerous = {territorial = true, raid_chance = 0.5, lairs = 2},
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
    }
  end
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
  local name
  if r < 0.06 then name = "sd-wolf-lair"
  elseif r < 0.10 then name = "sd-boar-lair"
  elseif d >= FAR and r < 0.13 then name = "sd-bear-den"
  else return end
  local pos = e.surface.find_non_colliding_position(name, centre, 10, 1)
  if pos then e.surface.create_entity{name = name, position = pos, force = FORCE} end
end

-- The units of a lair attack `target`.
local function unleash(lair, target)
  for _, unit in pairs(lair.units) do
    if unit.valid then
      unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.by_anything}
    end
  end
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
    for _, unit in pairs(c.lair.units) do group.add_member(unit) end
    group.set_command{type = defines.command.attack_area, destination = c.target.position, radius = 16}
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
