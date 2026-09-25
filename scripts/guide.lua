-- "Next step": a small panel that leads a new team through the first hour, one step at a time, up to the
-- first revival charge. A step is done once the team has done it (production statistics, buildings,
-- research) and never comes back; steps already done by an older save are skipped at once.
local chamber = require("scripts.chamber")

local guide = {}

-- Made, used up, or in someone's pockets: wood and stone taken from trees and rocks by hand don't count
-- as production, but they are spent soon enough.
local function made(force, name, count)
  count = count or 1
  local stats = force.get_item_production_statistics("nauvis")
  if stats.get_input_count(name) >= count or stats.get_output_count(name) >= count then return true end
  local held = 0
  for _, player in pairs(force.players) do held = held + player.get_item_count(name) end
  return held >= count
end

local function built(force, name)
  return game.surfaces.nauvis.count_entities_filtered{force = force, name = name, limit = 1} > 0
end

local function researching(force, tech)
  local t = force.technologies[tech]
  if t.researched then return true end
  local current = force.current_research
  return current ~= nil and current.name == tech and force.research_progress > 0
end

guide.STEPS = {
  {id = "gather", done = function(f) return made(f, "wood", 10) and made(f, "stone", 10) and made(f, "sd-clay", 4) end},
  -- A team that got to its first research without a bow isn't nagged about it any more.
  {id = "weapon", done = function(f) return made(f, "sd-bow") and made(f, "sd-stone-arrows") or researching(f, "sd-pottery") end},
  {id = "campfire", done = function(f) return built(f, "sd-campfire") end},
  {id = "charcoal", done = function(f) return made(f, "sd-charcoal") end},
  {id = "digger", done = function(f) return built(f, "sd-digger") end},
  {id = "tablets", done = function(f) return made(f, "sd-clay-tablet", 10) end},
  {id = "desk", done = function(f) return built(f, "sd-scholar-desk") end},
  {id = "research", done = function(f) return researching(f, "sd-pottery") end},
  {id = "woodlot", done = function(f) return built(f, "sd-woodlot") end},
  {id = "awakening", done = function(f) return f.technologies["sd-awakening"].researched end},
  {id = "charge", done = function(f) return chamber.charge_tier(f) ~= nil end},
}

function guide.init()
  storage.guide = storage.guide or {}
end

-- The current step of `force`: the first one not done yet (nil when the guide is over).
function guide.step(force)
  local state = storage.guide[force.index]
  if not state then
    state = {done = {}}
    storage.guide[force.index] = state
  end
  if state.finished then return nil end
  -- A step done further on means the ones before it were done too, even if their traces are gone
  -- (a campfire burnt down in a raid doesn't bring the team back to "place a campfire").
  for i = #guide.STEPS, 1, -1 do
    local step = guide.STEPS[i]
    if state.done[step.id] or step.done(force) then
      for k = 1, i do state.done[guide.STEPS[k].id] = true end
      break
    end
  end
  for _, step in pairs(guide.STEPS) do
    if not state.done[step.id] then
      if step.done(force) then
        state.done[step.id] = true
      else
        return step.id
      end
    end
  end
  state.finished = true
  return nil
end

-- Runs every second: shows the step to every connected player who hasn't switched the guide off.
function guide.update()
  local steps = {}
  for _, player in pairs(game.connected_players) do
    local force = player.force
    if steps[force.index] == nil then steps[force.index] = guide.step(force) or false end
    local step = steps[force.index]
    local frame = player.gui.left.sd_guide
    if not step or not settings.get_player_settings(player)["sd-show-guide"].value then
      if frame then frame.destroy() end
    else
      if not frame then
        frame = player.gui.left.add{type = "frame", name = "sd_guide", caption = {"sd-guide.title"}, direction = "vertical"}
        local label = frame.add{type = "label", name = "sd_text"}
        label.style.single_line = false
        label.style.maximal_width = 320
      end
      frame.sd_text.caption = {"sd-guide." .. step}
    end
  end
end

return guide
