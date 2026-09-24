-- Petrification waves (docs/DESIGN.md §4). Waves come at shrinking intervals and petrify every player of
-- a force. A charge of the required tier in the force's revival chamber is spent and wakes everyone at
-- once; without one the force stays stone until the chamber makes a charge or the statues thaw.
local chamber = require("scripts.chamber")
local statues = require("scripts.statues")

local waves = {}

local MINUTE = 60 * 60
local HOUR = 60 * MINUTE
local FIRST_WAVE = 2 * HOUR
local FIRST_INTERVAL = 4 * HOUR
local SHRINK = 0.92
local LAST_WAVE = 10            -- release 0.5 ends after wave 10; later epochs extend this
local CHAMBER_WAKE_DELAY = 180  -- a charged chamber still leaves the team stone for 3 s
local WARNINGS = {10 * MINUTE, 1 * MINUTE}

local FACTORS = {relaxed = 1.5, normal = 1, hard = 0.7}

-- Wave from which each charge tier is required (docs/DESIGN.md §4.2).
local TIERS = {{wave = 1, tier = 1}, {wave = 4, tier = 2}, {wave = 7, tier = 3}}

function waves.required_tier(n)
  local tier = 1
  for _, t in pairs(TIERS) do
    if n >= t.wave then tier = t.tier end
  end
  return tier
end

-- How long statues of wave n stay stone without a charge.
function waves.thaw_time(n)
  if n <= 2 then return 5 * MINUTE end
  return 15 * MINUTE * 2 ^ (n - 3)
end

local function factor()
  return FACTORS[settings.global["sd-wave-difficulty"].value]
end

-- Time from wave n to wave n + 1 (from the start of the game for n = 0), at the current difficulty.
function waves.interval(n)
  local f = factor()
  if not f then return nil end
  if n == 0 then return math.floor(FIRST_WAVE * f) end
  return math.floor(FIRST_INTERVAL * SHRINK ^ (n - 1) * f)
end

function waves.init()
  storage.forces = storage.forces or {}
  if not storage.waves then
    storage.waves = {count = 0, warned = {}}
    waves.schedule()
  end
end

-- Schedules the next wave after the current one (or the first wave) at the current difficulty.
function waves.schedule()
  local w = storage.waves
  local interval = not w.finished and waves.interval(w.count)
  w.next_tick = interval and game.tick + interval or nil
  w.factor = factor()
  w.warned = {}
end

-- A new version with more waves continues a game that ended at the previous version's last wave.
function waves.on_version_changed()
  local w = storage.waves
  if w.finished and w.count < LAST_WAVE then
    w.finished = false
    waves.schedule()
  end
end

-- A difficulty change rescales the wait that is left; "off" stops waves until switched back.
function waves.on_difficulty_changed()
  local w = storage.waves
  if w.finished then return end
  local f = factor()
  if not f then
    w.next_tick, w.factor = nil, nil
  elseif w.next_tick and w.factor then
    w.next_tick = game.tick + math.floor((w.next_tick - game.tick) * f / w.factor)
    w.factor = f
  else
    waves.schedule()
  end
end

function waves.force_petrified(force)
  return storage.forces[force.index] ~= nil
end

-- Forces the wave hits: those with players, and those with a chamber (so scripted tests can run).
local function affected_forces()
  local out = {}
  for _, force in pairs(game.forces) do
    if #force.players > 0 or chamber.get(force) then out[#out + 1] = force end
  end
  return out
end

local function petrify_players(force)
  for _, player in pairs(force.players) do
    statues.petrify(player)
  end
end

local function wake(force, message)
  storage.forces[force.index] = nil
  for _, player in pairs(force.players) do
    statues.revive(player)
  end
  if message then force.print(message) end
end

function waves.hit()
  local w = storage.waves
  w.count = w.count + 1
  local n = w.count
  local required = waves.required_tier(n)
  for _, force in pairs(affected_forces()) do
    local state = {wave = n, required = required}
    local tier = chamber.charge_tier(force)
    if tier and tier >= required then
      chamber.consume(force)
      state.revive_tick = game.tick + CHAMBER_WAKE_DELAY
      force.print({"sd-message.wave-charged", n})
    else
      state.thaw_tick = game.tick + waves.thaw_time(n)
      if tier then
        force.print({"sd-message.wave-weak-charge", n, tier, required, math.floor(waves.thaw_time(n) / MINUTE)})
      else
        force.print({"sd-message.wave-no-charge", n, math.floor(waves.thaw_time(n) / MINUTE)})
      end
    end
    storage.forces[force.index] = state
    petrify_players(force)
  end
  if n >= LAST_WAVE then
    w.finished = true
    game.print({"sd-message.to-be-continued"})
  end
  waves.schedule()
end

-- Runs every 30 ticks.
function waves.update(tick)
  local w = storage.waves
  if w.next_tick then
    for i, before in pairs(WARNINGS) do
      if not w.warned[i] and w.next_tick - tick <= before and w.next_tick - tick > 0 then
        w.warned[i] = true
        game.print({"sd-message.wave-warning", math.ceil((w.next_tick - tick) / MINUTE)})
      end
    end
    if tick >= w.next_tick then waves.hit() end
  end
  for index, state in pairs(storage.forces) do
    local force = game.forces[index]
    if not force then
      storage.forces[index] = nil
    elseif state.revive_tick then
      if tick >= state.revive_tick then wake(force) end
    else
      local tier = chamber.charge_tier(force)
      if tier and tier >= state.required then
        chamber.consume(force)
        wake(force, {"sd-message.revived-by-chamber"})
      elseif tick >= state.thaw_tick then
        wake(force, {"sd-message.thawed"})
      end
    end
  end
end

return waves
