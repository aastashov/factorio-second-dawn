-- The world and the tech tree on the real prototypes: research everything in order, every recipe's
-- ingredients must be obtainable when it unlocks, every recipe category needs a building (or the
-- character) that is itself craftable by then. Also: vanilla tree hidden, no biters, starting area.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %s %s", ok and "ok" or "FAIL", name, detail or ""))
end

-- Things the world gives without machines: trees and rocks. Resources come from whatever can mine them:
-- the character from the start, drills once they can be built.
local RAW = {"wood", "sd-fruit", "sd-fiber", "stone", "coal", "sd-meat", "sd-hide", "sd-bones"}

local function tree_check()
  local have, enabled, researched = {}, {}, {}
  for _, name in pairs(RAW) do have[name] = true end
  local character_categories = prototypes.entity.character.crafting_categories
  local machines = {}  -- crafting category -> building names
  for name, e in pairs(prototypes.get_entity_filtered{{filter = "crafting-machine"}}) do
    for cat in pairs(e.crafting_categories or {}) do
      machines[cat] = machines[cat] or {}
      table.insert(machines[cat], name)
    end
  end
  local problems = {}
  local function mine_with(categories)
    for _, r in pairs(prototypes.get_entity_filtered{{filter = "type", type = "resource"}}) do
      if categories[r.resource_category] and r.mineable_properties.products then
        for _, p in pairs(r.mineable_properties.products) do have[p.name] = true end
      end
    end
  end
  mine_with(prototypes.entity.character.resource_categories)
  local function can_craft(recipe)
    if character_categories[recipe.category] then return true end
    for _, m in pairs(machines[recipe.category] or {}) do
      if have[m] then return true end
    end
    return false
  end
  -- Adds outputs of enabled recipes whose ingredients and building are available, until nothing changes.
  local function saturate()
    local changed = true
    while changed do
      changed = false
      for name in pairs(enabled) do
        local r = prototypes.recipe[name]
        local ok = can_craft(r)
        for _, ing in pairs(r.ingredients) do ok = ok and have[ing.name] end
        if ok then
          for _, p in pairs(r.products) do
            if not have[p.name] then
              have[p.name] = true
              changed = true
              local e = prototypes.entity[p.name]
              if e and e.type == "mining-drill" then mine_with(e.resource_categories) end
              -- fluids that come from buildings, not recipes
              if p.name == "offshore-pump" then have.water = true end
              if p.name == "boiler" and have.water then have.steam = true end
            end
          end
        end
      end
    end
  end
  for name, r in pairs(prototypes.recipe) do
    if r.enabled then enabled[name] = true end
  end
  saturate()
  local order = {}
  local progress = true
  while progress do
    progress = false
    for name, t in pairs(prototypes.technology) do
      if t.enabled and not researched[name] then
        local ready = true
        for pre in pairs(t.prerequisites) do ready = ready and researched[pre] end
        for _, ing in pairs(t.research_unit_ingredients) do ready = ready and have[ing.name] end
        if ready then
          researched[name] = true
          order[#order + 1] = name
          for _, eff in pairs(t.effects) do
            if eff.type == "unlock-recipe" then enabled[eff.recipe] = true end
          end
          saturate()
          for _, eff in pairs(t.effects) do
            if eff.type == "unlock-recipe" then
              local r = prototypes.recipe[eff.recipe]
              for _, ing in pairs(r.ingredients) do
                if not have[ing.name] then problems[#problems + 1] = eff.recipe .. " needs " .. ing.name end
              end
              if not can_craft(r) then problems[#problems + 1] = eff.recipe .. " has no building for " .. r.category end
            end
          end
          progress = true
        end
      end
    end
  end
  local stuck = {}
  for name, t in pairs(prototypes.technology) do
    if t.enabled and not researched[name] then stuck[#stuck + 1] = name end
  end
  check("tree: every technology researchable", #stuck == 0, #stuck > 0 and ("stuck: " .. table.concat(stuck, ", ")) or ("order: " .. table.concat(order, " → ")))
  check("tree: every unlocked recipe makeable", #problems == 0, table.concat(problems, "; "))
  -- Strict: each technology's science packs must be makeable with only what its prerequisites (and
  -- their prerequisites) unlock. Researching in any order would hide a missing prerequisite.
  local function prereq_closure(name, acc)
    acc = acc or {}
    for pre in pairs(prototypes.technology[name].prerequisites) do
      if not acc[pre] then acc[pre] = true; prereq_closure(pre, acc) end
    end
    return acc
  end
  local strict = {}
  for name, t in pairs(prototypes.technology) do
    if t.enabled then
      local saved_have, saved_enabled = have, enabled
      have, enabled = {}, {}
      for _, n in pairs(RAW) do have[n] = true end
      mine_with(prototypes.entity.character.resource_categories)
      for rname, r in pairs(prototypes.recipe) do if r.enabled then enabled[rname] = true end end
      for pre in pairs(prereq_closure(name)) do
        for _, eff in pairs(prototypes.technology[pre].effects) do
          if eff.type == "unlock-recipe" then enabled[eff.recipe] = true end
        end
      end
      saturate()
      for _, ing in pairs(t.research_unit_ingredients) do
        if not have[ing.name] then strict[#strict + 1] = name .. " needs " .. ing.name end
      end
      have, enabled = saved_have, saved_enabled
    end
  end
  check("tree: prerequisites provide every science pack", #strict == 0, table.concat(strict, "; "))
  check("tree: revival charge I reachable", have["sd-revival-charge-1"] == true)
  check("tree: revival charge II reachable", have["sd-revival-charge-2"] == true)
  check("tree: revival charge III reachable", have["sd-revival-charge-3"] == true)
  check("tree: revival charge IV reachable", have["sd-revival-charge-4"] == true)
end

script.on_event(defines.events.on_tick, function(e)
  if e.tick ~= 5 then return end
  tree_check()

  local vanilla = 0
  for name, t in pairs(prototypes.technology) do
    if t.enabled and not name:find("^sd%-") then vanilla = vanilla + 1 end
  end
  check("vanilla technologies hidden", vanilla == 0, vanilla .. " visible")

  local cats = prototypes.entity.character.resource_categories
  check("character mines soft rock only", cats["basic-solid"] and not cats["sd-hard"], serpent.line(cats))
  check("iron ore needs later tools", prototypes.entity["iron-ore"].resource_category == "sd-hard")

  local s = game.surfaces.nauvis
  local spawners = s.count_entities_filtered{type = {"unit-spawner", "turret"}, force = "enemy"}
  check("no biters", spawners == 0, spawners .. " enemy structures")

  for _, name in pairs{"sd-clay", "sd-shells", "sd-saltpeter", "stone", "copper-ore", "coal", "iron-ore"} do
    local n = s.count_entities_filtered{name = name, position = {0, 0}, radius = 150}
    check("starting area has " .. name, n > 0, n .. " tiles")
  end
  local tin_near = s.count_entities_filtered{name = "sd-tin-ore", position = {0, 0}, radius = 140}
  local tin_far = s.count_entities_filtered{name = "sd-tin-ore", position = {0, 0}, radius = 260}
  check("tin: none at the camp, some within 250", tin_near == 0 and tin_far > 0, tin_near .. " near, " .. tin_far .. " within 260")
  local fruit = s.count_entities_filtered{name = {"tree-02-red", "tree-08-red", "tree-09-red"}, position = {0, 0}, radius = 120}
  check("fruit trees near spawn", fruit >= 10, fruit .. " trees")

  -- Buildings side by side leave room to walk between them.
  local clay = 0
  for _, r in pairs(s.find_entities_filtered{name = "sd-clay", position = {0, 0}, radius = 100}) do clay = clay + r.amount end
  check("plenty of clay at the camp", clay >= 150000, clay .. "")
  s.request_to_generate_chunks({3000, 3000}, 1); s.force_generate_chunk_requests()
  local tiles = {}
  for x = 2990, 3010 do for y = 2990, 3010 do tiles[#tiles + 1] = {name = "grass-1", position = {x, y}} end end
  s.set_tiles(tiles)
  for _, e in pairs(s.find_entities_filtered{area = {{2990, 2990}, {3010, 3010}}}) do e.destroy() end
  for _, pair in pairs{{"sd-kiln", 2}, {"sd-workbench", 2}, {"sd-garden", 3}, {"sd-alembic", 3}} do
    local name, size = pair[1], pair[2]
    local a = s.create_entity{name = name, position = {3000, 3000}, force = "player"}
    local b = s.create_entity{name = name, position = {3000 + size, 3000}, force = "player"}
    -- odd-sized buildings snap to tile centres, so the gap is taken from where they actually stand
    local gap = a and b and {(a.position.x + b.position.x) / 2, a.position.y}
    check("walk between two " .. name, gap and s.can_place_entity{name = "character", position = gap},
      tostring(a ~= nil) .. " " .. tostring(b ~= nil))
    if a then a.destroy() end
    if b then b.destroy() end
  end

  local st = remote.call("second-dawn", "state")
  check("first wave scheduled at 2 h", st.waves.next_tick == 2 * 216000, tostring(st.waves.next_tick))
  L("failures: " .. failures)
end)
