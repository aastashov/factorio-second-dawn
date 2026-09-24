-- Domestication: a net at a guarded lair fails; after the wolves are gone it captures; a thrown net
-- (a real projectile) captures a boar lair frozen by a wave; farms produce.
local function L(s) log("SD-TEST " .. s) end
local failures = 0
local function check(name, ok, detail)
  if not ok then failures = failures + 1 end
  L(string.format("%-4s %6d %s %s", ok and "ok" or "FAIL", game.tick, name, detail or ""))
end
local O = {x = -1500, y = -1500}
local function at(x, y) return {O.x + x, O.y + y} end
local force = "player"
script.on_init(function() storage.t = {} end)

local steps = {
  [2] = function()
    local T, s = storage.t, game.surfaces.nauvis
    s.request_to_generate_chunks(O, 4); s.force_generate_chunk_requests()
    local tiles = {}
    for x = -80, 80 do for y = -80, 80 do tiles[#tiles + 1] = {name = "grass-1", position = at(x, y)} end end
    s.set_tiles(tiles)
    for _, e in pairs(s.find_entities_filtered{area = {at(-80, -80), at(80, 80)}}) do e.destroy() end
    T.wolves = s.create_entity{name = "sd-wolf-lair", position = at(0, 0), force = "sd-wildlife"}
    T.boars = s.create_entity{name = "sd-boar-lair", position = at(60, 0), force = "sd-wildlife"}
  end,
  [1500] = function()
    local T = storage.t
    local r = remote.call("second-dawn", "capture", T.wolves.position, force)
    check("guarded lair is not captured", r == "guarded" and T.wolves.valid, tostring(r))
    for _, u in pairs(game.surfaces.nauvis.find_entities_filtered{type = "unit", position = T.wolves.position, radius = 40}) do u.destroy() end
    r = remote.call("second-dawn", "capture", T.wolves.position, force)
    check("lair without its wolves is captured", r == "sd-wolf-kennel", tostring(r))
    local kennel = game.surfaces.nauvis.find_entity("sd-wolf-kennel", at(0, 0)) or
      game.surfaces.nauvis.find_entities_filtered{name = "sd-wolf-kennel", position = at(0, 0), radius = 3}[1]
    T.kennel = kennel
    check("kennel belongs to the player", kennel and kennel.force.name == force)
    if kennel then kennel.get_inventory(defines.inventory.crafter_input).insert{name = "sd-meat", count = 8} end
    remote.call("second-dawn", "wave_in", 30)
  end,
  [1600] = function()
    local T, s = storage.t, game.surfaces.nauvis
    check("boar lair frozen by the wave", T.boars.disabled_by_script)
    T.thrower = s.create_entity{name = "character", position = at(50, 0), force = force}
    s.create_entity{name = "sd-net-projectile", position = at(51, 0), target = T.boars.position, speed = 0.3,
      source = T.thrower, force = force}
  end,
  [1900] = function()
    local T, s = storage.t, game.surfaces.nauvis
    local farm = s.find_entities_filtered{name = "sd-boar-farm", position = at(60, 0), radius = 3}[1]
    check("thrown net captures a frozen lair", farm ~= nil and not T.boars.valid)
    if farm then farm.get_inventory(defines.inventory.crafter_input).insert{name = "sd-feed", count = 20} end
    T.farm = farm
  end,
  [1900 + 3700] = function()
    local T = storage.t
    local hides = T.kennel and T.kennel.get_output_inventory().get_item_count("sd-hide") or 0
    check("kennel turns meat into hides", hides >= 3, hides .. "")
    local meat = T.farm and T.farm.get_output_inventory().get_item_count("sd-meat") or 0
    check("pig farm turns feed into meat", meat >= 6, meat .. "")
    L("failures: " .. failures)
  end,
}
script.on_event(defines.events.on_tick, function(e)
  local f = steps[e.tick]
  if f then f() end
end)
