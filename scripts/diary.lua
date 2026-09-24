-- The diary window (J): read notes of the player's force on the left, the selected text on the right.
local notes = require("scripts.notes")
local NOTES = require("scripts.notes-data")

local diary = {}

local KIND = {}
for _, n in pairs(NOTES) do KIND[n.id] = n end

local function entry_text(entry)
  local n = KIND[entry.id]
  local text = {"", {"sd-note-text." .. entry.id}}
  if n.kind == "recipe" then
    text = {"", text, "\n\n", {"sd-gui.recipe-unlocked", "[recipe=" .. n.recipe .. "]"}}
  elseif n.kind == "cache" then
    if entry.position then
      text = {"", text, "\n\n", {"sd-gui.cache-at", string.format("[gps=%d,%d]", entry.position.x, entry.position.y)}}
    else
      text = {"", text, "\n\n", {"sd-gui.cache-lost"}}
    end
  end
  return text
end

local function show(player, index)
  local frame = player.gui.screen.sd_diary
  if not frame then return end
  local entries = notes.diary(player.force)
  local entry = entries[index]
  if not entry then return end
  frame.body.sd_diary_text.caption = {"", "[font=default-bold]", {"sd-note-title." .. entry.id}, "[/font]\n\n", entry_text(entry)}
end

function diary.open(player)
  local screen = player.gui.screen
  if screen.sd_diary then screen.sd_diary.destroy() end
  local frame = screen.add{type = "frame", name = "sd_diary", direction = "vertical"}
  local bar = frame.add{type = "flow", direction = "horizontal"}
  bar.drag_target = frame
  bar.add{type = "label", caption = {"sd-gui.diary"}, style = "frame_title", ignored_by_interaction = true}
  local drag = bar.add{type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true}
  drag.style.horizontally_stretchable = true
  drag.style.height = 24
  bar.add{type = "sprite-button", name = "sd_diary_close", sprite = "utility/close", style = "frame_action_button"}

  local body = frame.add{type = "frame", name = "body", direction = "horizontal", style = "inside_shallow_frame_with_padding"}
  local list = body.add{type = "list-box", name = "sd_diary_list"}
  list.style.width = 260
  list.style.height = 400
  local text = body.add{type = "label", name = "sd_diary_text"}
  text.style.single_line = false
  text.style.width = 420
  text.style.left_margin = 12
  text.style.vertically_stretchable = true

  local entries = notes.diary(player.force)
  local seen = storage.notes.seen[player.index] or 0
  for i, entry in pairs(entries) do
    local title = {"sd-note-title." .. entry.id}
    list.add_item(i > seen and {"", "● ", title} or title)
  end
  storage.notes.seen[player.index] = #entries
  if #entries > 0 then
    local pick = math.min(seen + 1, #entries)
    list.selected_index = pick
    show(player, pick)
  end
  frame.force_auto_center()
  player.opened = frame
end

function diary.toggle(player)
  if player.gui.screen.sd_diary then
    player.gui.screen.sd_diary.destroy()
  else
    diary.open(player)
  end
end

function diary.on_selection(e)
  if e.element.name ~= "sd_diary_list" then return end
  show(game.get_player(e.player_index), e.element.selected_index)
end

function diary.on_click(e)
  if e.element.name == "sd_diary_close" then
    local f = game.get_player(e.player_index).gui.screen.sd_diary
    if f then f.destroy() end
  end
end

function diary.on_closed(e)
  if e.element and e.element.name == "sd_diary" then e.element.destroy() end
end

return diary
