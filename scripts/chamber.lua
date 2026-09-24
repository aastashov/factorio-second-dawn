-- The revival chamber: one per force. Its charge sits in a fluid box without pipe connections, so it
-- can't be taken out. The engine lets that box fill a bit past its volume, so while a charge is inside
-- the chamber is switched off by script: an unfinished next craft keeps its progress and ingredients,
-- nothing is stockpiled.
local chamber = {}

chamber.NAME = "sd-revival-chamber"

function chamber.init()
  storage.chambers = storage.chambers or {}
end

function chamber.get(force)
  local e = storage.chambers[force.index]
  if e and e.valid then return e end
  storage.chambers[force.index] = nil
end

-- Tier of the charge in the force's chamber, or nil.
function chamber.charge_tier(force)
  local e = chamber.get(force)
  if not e then return nil end
  local fb = e.fluidbox[1]
  if not fb or fb.amount < 1 then return nil end
  return tonumber(fb.name:match("^sd%-revival%-charge%-(%d+)$"))
end

function chamber.consume(force)
  local e = chamber.get(force)
  if not e then return end
  e.fluidbox[1] = nil
  e.disabled_by_script = false
end

-- Keeps every chamber off while it holds a charge.
function chamber.update()
  for _, e in pairs(storage.chambers) do
    if e.valid then
      local fb = e.fluidbox[1]
      e.disabled_by_script = fb ~= nil and fb.amount >= 1
    end
  end
end

-- A second chamber of the same force is removed and its item given back.
function chamber.on_built(entity, player)
  local existing = chamber.get(entity.force)
  if existing and existing ~= entity then
    local surface, position = entity.surface, entity.position
    entity.destroy()
    local stack = {name = chamber.NAME, count = 1}
    if not (player and player.insert(stack) > 0) then
      surface.spill_item_stack{position = position, stack = stack, enable_looted = true}
    end
    if player then player.print({"sd-message.chamber-exists"}) end
    return
  end
  storage.chambers[entity.force.index] = entity
end

return chamber
