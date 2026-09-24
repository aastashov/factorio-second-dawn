-- Domestication (docs/DESIGN.md §16.5): a capture net thrown at a lair turns it into the thrower's farm,
-- if none of the lair's animals are around or they are petrified.
local capture = {}

local FARMS = {["sd-wolf-lair"] = "sd-wolf-kennel", ["sd-boar-lair"] = "sd-boar-farm", ["sd-bear-den"] = "sd-bear-pen"}
local HIT_RADIUS = 4
local GUARD_RADIUS = 30

-- Tries to capture the lair at `position` for `force`. Returns the farm entity, or nil and a reason.
function capture.at(surface, position, force)
  local lair = surface.find_entities_filtered{position = position, radius = HIT_RADIUS, type = "unit-spawner", force = "sd-wildlife", limit = 1}[1]
  if not lair or not FARMS[lair.name] then return nil, "no-lair" end
  local guards = surface.count_entities_filtered{position = lair.position, radius = GUARD_RADIUS, type = "unit", force = "sd-wildlife"}
  if guards > 0 and not lair.disabled_by_script then return nil, "guarded" end
  local name, pos = FARMS[lair.name], lair.position
  lair.destroy()
  -- petrified guards stay stone where they were; they are no longer anyone's
  return surface.create_entity{name = name, position = pos, force = force}
end

function capture.on_trigger(e)
  if e.effect_id ~= "sd-capture" then return end
  local source = e.source_entity or e.cause_entity
  local force = source and source.force
  if not force or not e.target_position then return end
  local surface = game.get_surface(e.surface_index)
  local farm, reason = capture.at(surface, e.target_position, force)
  local player = source.type == "character" and source.player
  local message = farm and {"sd-message.captured", {"entity-name." .. farm.name}} or {"sd-message.capture-" .. reason}
  if player then player.print(message) else force.print(message) end
end

return capture
