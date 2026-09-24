script.on_event(defines.events.on_tick, function(e) if e.tick == 5 then log("SD-TEST tick 5, sd techs: " .. #prototypes.get_technology_filtered{{filter = "enabled"}}) end end)
