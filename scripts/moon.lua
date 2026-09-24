-- The finale (docs/DESIGN.md §21): characters in spacesuits standing by a rocket silo when a rocket starts
-- fly to the Moon. There they have air for 5 minutes plus 2 per oxygen tank, the emitter petrifies anyone
-- within 100 tiles every 45 s, and dismantling it wins the game: waves stop for good, the crew comes home.
-- Crew members are characters, so the same code serves players and scripted tests.
local statues = require("scripts.statues")

local moon = {}

local SURFACE = "sd-moon"
local CREW_RADIUS = 10
local AIR = 300          -- seconds in a spacesuit
local TANK = 120         -- seconds per oxygen tank
local SUFFOCATION = 10   -- HP per second without air
local NO_SUIT = 20       -- HP per second without a spacesuit
local PULSE_EVERY = 45 * 60
local PULSE_RADIUS = 100
local PULSE_STONE = 8 * 60
local RETURN_AFTER = 600

function moon.init()
  storage.moon = storage.moon or {crew = {}, boarding = {}, won = false}
end

local function suited(character)
  local armor = character.get_inventory(defines.inventory.character_armor)
  return armor and not armor.is_empty() and armor[1].name == "sd-spacesuit"
end

-- Creates the Moon and the emitter the first time anyone flies.
function moon.surface()
  local s = game.surfaces[SURFACE]
  if s then return s end
  s = game.create_surface(SURFACE, {
    default_enable_all_autoplace_controls = false,
    autoplace_settings = {
      tile = {treat_missing_as_default = false, settings = {["sd-moon"] = {}}},
      entity = {treat_missing_as_default = false, settings = {}},
      decorative = {treat_missing_as_default = false, settings = {}},
    },
    peaceful_mode = true, no_enemies_mode = true, width = 4000, height = 4000,
  })
  s.always_day = true
  local rng = game.create_random_generator(game.surfaces.nauvis.map_gen_settings.seed + 314159)
  local a, d = rng() * 2 * math.pi, 250 + rng() * 100
  local pos = {x = math.floor(math.cos(a) * d), y = math.floor(math.sin(a) * d)}
  s.request_to_generate_chunks({0, 0}, 2)
  s.request_to_generate_chunks(pos, 2)
  s.force_generate_chunk_requests()
  local emitter = s.create_entity{name = "sd-emitter", position = pos, force = "neutral"}
  emitter.destructible = false
  storage.moon.emitter = emitter
  storage.moon.pulse_tick = game.tick + PULSE_EVERY
  storage.moon.emitter_reg = script.register_on_object_destroyed(emitter)
  for _, force in pairs(game.forces) do
    if #force.players > 0 then force.add_chart_tag(s, {position = pos, icon = {type = "virtual", name = "signal-skull"}}) end
  end
  return s
end

-- Rocket starts: characters in spacesuits by the silo are the crew of this flight.
function moon.on_launch_ordered(silo)
  local crew = {}
  for _, c in pairs(silo.surface.find_entities_filtered{type = "character", position = silo.position, radius = CREW_RADIUS}) do
    if suited(c) then crew[#crew + 1] = c end
  end
  if #crew > 0 then storage.moon.boarding[silo.unit_number] = crew end
  for _, c in pairs(crew) do
    if c.player then c.player.print({"sd-message.boarding"}) end
  end
end

local function send(character, surface, position)
  local pos = surface.find_non_colliding_position("character", position, 20, 1) or position
  if character.player then character.player.teleport(pos, surface) else character.teleport(pos, surface) end
end

-- Rocket arrives: the crew lands.
function moon.on_launched(silo)
  local crew = silo and storage.moon.boarding[silo.unit_number]
  if not crew then return end
  storage.moon.boarding[silo.unit_number] = nil
  local s = moon.surface()
  for _, c in pairs(crew) do
    if c.valid then
      send(c, s, {0, 0})
      storage.moon.crew[c.unit_number] = {character = c, air = AIR}
      if c.player then c.player.print({"sd-message.landed"}) end
    end
  end
end

-- Runs every 60 ticks: air, suffocation, the emitter's pulse, the return home.
function moon.update(tick)
  local m = storage.moon
  for n, member in pairs(m.crew) do
    local c = member.character
    if not c.valid or c.surface.name ~= SURFACE then
      m.crew[n] = nil
    elseif not suited(c) then
      c.damage(NO_SUIT, "neutral", "sd-exposure")
    else
      member.air = member.air - 1
      if member.air <= 10 then
        local inv = c.get_main_inventory()
        if inv and inv.remove{name = "sd-oxygen-tank", count = 1} > 0 then member.air = member.air + TANK end
      end
      if member.air <= 0 then
        member.air = 0
        c.damage(SUFFOCATION, "neutral", "sd-exposure")
      end
    end
  end
  local e = m.emitter
  if e and e.valid and m.pulse_tick and tick >= m.pulse_tick then
    m.pulse_tick = tick + PULSE_EVERY
    m.pulses = (m.pulses or 0) + 1
    for _, c in pairs(e.surface.find_entities_filtered{type = "character", position = e.position, radius = PULSE_RADIUS}) do
      m.hits = (m.hits or 0) + 1
      if c.player then statues.petrify(c.player, tick + PULSE_STONE) end
    end
  end
  if m.return_tick and tick >= m.return_tick then
    m.return_tick = nil
    local home = game.surfaces.nauvis
    for n, member in pairs(m.crew) do
      if member.character.valid then
        local force = member.character.force
        send(member.character, home, force.get_spawn_position(home))
      end
      m.crew[n] = nil
    end
  end
end

-- The emitter is gone: the game is won.
function moon.on_destroyed(e, wake_everyone)
  local m = storage.moon
  if m.won or not m.emitter_reg or e.registration_number ~= m.emitter_reg then return end
  m.won = true
  m.emitter = nil
  m.return_tick = game.tick + RETURN_AFTER
  local w = storage.waves
  w.finished, w.next_tick = true, nil
  wake_everyone()
  game.print({"sd-message.victory"})
  -- scripted tests keep the game running to check what happens after the victory screen
  if not m.no_victory_screen then
    game.set_game_state{game_finished = true, player_won = true, can_continue = true}
  end
end

function moon.air(character)
  local member = character and character.valid and storage.moon.crew[character.unit_number]
  return member and member.air
end

return moon
