-- The "next step" guide: walks through its steps as the team does each of them, skips what is already
-- done, ends with the first revival charge.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end

local function step() return remote.call("second-dawn", "guide_step", "player") end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 5 then return end
  local s, force = game.surfaces.nauvis, game.forces.player
  local stats = force.get_item_production_statistics(s)
  local function make(name, n) stats.on_flow(name, n) end
  local function place(name, x)
    local pos = s.find_non_colliding_position(name, {x, 40}, 40, 1)
    return s.create_entity{name = name, position = pos, force = force, raise_built = true}
  end

  check("starts with gathering", step() == "gather", tostring(step()))
  make("wood", 10); make("stone", 10); make("sd-clay", 3)
  check("not done with too little clay", step() == "gather", tostring(step()))
  make("sd-clay", 1)
  check("gathered -> weapon", step() == "weapon", tostring(step()))
  make("sd-bow", 1); make("sd-stone-arrows", 5)
  check("armed -> campfire", step() == "campfire", tostring(step()))
  -- Several steps done at once are all skipped.
  place("sd-campfire", 0); make("sd-charcoal", 1)
  check("campfire and charcoal at once -> digger", step() == "digger", tostring(step()))
  place("sd-digger", 5); make("sd-clay-tablet", 10)
  check("digger and tablets -> desk", step() == "desk", tostring(step()))
  place("sd-scholar-desk", 10)
  check("desk -> research", step() == "research", tostring(step()))
  force.technologies["sd-pottery"].researched = true
  check("pottery -> woodlot", step() == "woodlot", tostring(step()))
  place("sd-woodlot", 20)
  check("woodlot -> awakening", step() == "awakening", tostring(step()))
  force.technologies["sd-awakening"].researched = true
  check("awakening -> charge", step() == "charge", tostring(step()))
  local c = place("sd-revival-chamber", 30)
  c.fluidbox[1] = {name = "sd-revival-charge-1", amount = 1}
  check("a charge ends the guide", step() == nil, tostring(step()))
  -- Done steps don't come back (and a later step done marks the earlier ones done): the campfire is gone, the guide stays over.
  for _, f in pairs(s.find_entities_filtered{name = "sd-campfire"}) do f.destroy() end
  check("stays over", step() == nil, tostring(step()))
  L("failures: " .. failures)
end)
