-- ws_journal/init.lua
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local flashbacks = dofile(modpath .. "/flashbacks.lua")

-- Helpers: player meta storage
local function get_journal(player)
    local meta = player:get_meta()
    local raw = meta:get_string("ws_journal:data")
    if raw == "" then
        local data = {
            flashbacks = {},      -- list of unlocked {title, body}
            notes = {},           -- list of {text, time}
            activities = {},      -- list of {day, text, time}
            next_flashback = 1,   -- index into flashbacks table to unlock next
            day_counter = 1       -- day number for activities
        }
        return data
    else
        local ok, d = pcall(minetest.deserialize, raw)
        if ok and type(d) == "table" then return d end
        -- fallback
        return {
            flashbacks = {},
            notes = {},
            activities = {},
            next_flashback = 1,
            day_counter = 1
        }
    end
end

local function save_journal(player, data)
    local meta = player:get_meta()
    meta:set_string("ws_journal:data", minetest.serialize(data))
end

-- Utility: split long text into lines of max_chars (splits at spaces)
local function split_text_into_lines(text, max_chars)
    max_chars = max_chars or 56
    local words = {}
    for w in text:gmatch("%S+") do table.insert(words, w) end
    local lines = {}
    local cur = ""
    for i, w in ipairs(words) do
        if #cur + #w + 1 <= max_chars then
            if cur == "" then cur = w else cur = cur .. " " .. w end
        else
            table.insert(lines, cur)
            cur = w
        end
    end
    if cur ~= "" then table.insert(lines, cur) end
    return lines
end

-- Build the formspec for journal. Tabs: Flashbacks, Activities, Notes
-- Flashbacks are paginated: show one flashback page (title + split label lines)
local function build_journal_formspec(player, tab, fb_index)
    tab = tab or "flashbacks" -- "flashbacks", "activities", "notes"
    fb_index = fb_index or 1

    local pname = player:get_player_name()
    local data = get_journal(player)
    local formspec = {}
    table.insert(formspec, "formspec_version[6]")
    table.insert(formspec, "size[10,8]")
    table.insert(formspec, "bgcolor[#000000aa]")
    table.insert(formspec, "label[0.45,0.25;Survivor's Journal]")
    -- top-right small book icon to hint
    table.insert(formspec, "image[8.4,0.2;1.2,1.2;ws_journal_icon.png]")

    -- Tab header emulation (simple buttons)
    table.insert(formspec, "button[0.5,0.6;2.6,0.6;tab_fb;Flashbacks]")
    table.insert(formspec, "button[3.2,0.6;2.6,0.6;tab_act;Activities]")
    table.insert(formspec, "button[5.9,0.6;2.6,0.6;tab_notes;Notes]")

    if tab == "flashbacks" then
        -- Fetch unlocked flashbacks
        local unlocked = data.flashbacks or {}
        local count = #unlocked
        if count == 0 then
            table.insert(formspec, "label[0.6,1.5;No memories uncovered yet. Rest through the night to unlock the first flashback.]")
        else
            -- Clamp index
            if fb_index < 1 then fb_index = 1 end
            if fb_index > count then fb_index = count end
            local entry = unlocked[fb_index]
            local title = minetest.formspec_escape(entry.title or ("Memory Day " .. fb_index))
            -- Title
            table.insert(formspec, "label[0.6,1.3;" .. title .. "]")
            -- Body lines as multiple label elements (no textarea)
            local lines = split_text_into_lines(entry.body or "", 62)
            local y = 1.7
            for i, line in ipairs(lines) do
                -- place labels moving down; ensure we don't overflow the window
                if y > 5.8 then break end
                table.insert(formspec, string.format("label[0.6,%.2f;%s]", y, minetest.formspec_escape(line)))
                y = y + 0.35
            end
            -- Prev / Next buttons and index
            table.insert(formspec, string.format("button[3.2,6.7;1.6,0.6;fb_prev;Prev]"))
            table.insert(formspec, string.format("button[5.0,6.7;1.6,0.6;fb_next;Next]"))
            table.insert(formspec, string.format("label[6.6,6.7;Memory %d / %d]", fb_index, count))
        end

    elseif tab == "activities" then
        -- Show activities in a textarea (activities are admin/player logs; textarea ok here)
        local act_text = ""
        for i, a in ipairs(data.activities or {}) do
            local ts = a.time and os.date("%Y-%m-%d %H:%M", a.time) or ""
            act_text = act_text .. string.format("[%s] Day %d: %s\n\n", ts, a.day or 0, a.text or "")
        end
        if act_text == "" then act_text = "No activities recorded yet." end
        -- Use textarea for activities because it's a list; flashbacks specifically avoided
        table.insert(formspec, "textarea[0.6,1.3;8.6,5.6;activities_text;;" .. minetest.formspec_escape(act_text) .. "]")
        -- Manual activity add button
        table.insert(formspec, "field[0.6,6.98;6.2,0.6;activity_input;Add Activity;]")
        table.insert(formspec, "button[6.9,6.9;1.6,0.6;add_activity;Add]")
    else -- notes tab
        local notes_text = ""
        for i, n in ipairs(data.notes or {}) do
            local ts = n.time and os.date("%Y-%m-%d %H:%M", n.time) or ""
            notes_text = notes_text .. string.format("[%s] %s\n\n", ts, n.text or "")
        end
        if notes_text == "" then notes_text = "No notes yet. Use the field below to write a personal note." end
        table.insert(formspec, "textarea[0.6,1.3;8.6,5.6;notes_text;;" .. minetest.formspec_escape(notes_text) .. "]")
        table.insert(formspec, "field[0.6,6.98;6.2,0.6;note_input;Write Note;]")
        table.insert(formspec, "button[6.9,6.9;1.6,0.6;add_note;Add]")
    end

    -- Close button always
    table.insert(formspec, "button_exit[8.2,0.5;1.6,0.6;close;Close]")

    return table.concat(formspec, "")
end

-- Register journal item
minetest.register_craftitem("ws_journal:book", {
    description = "Survivor's Journal",
    inventory_image = "ws_journal_book.png",
    stack_max = 1,
    on_use = function(itemstack, user)
        local name = user:get_player_name()
        user:get_meta():set_int("ws_journal:view_fb_index", 1)
        minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(user, "flashbacks", 1))
        return itemstack
    end
})

-- Give new players the journal
minetest.register_on_newplayer(function(player)
    local inv = player:get_inventory()
    if not inv:contains_item("main", "ws_journal:book") then
        inv:add_item("main", "ws_journal:book")
    end
    -- initialize journal meta if not present
    local data = get_journal(player)
    save_journal(player, data)
end)

-- HUD icon (top-right reminder)
minetest.register_on_joinplayer(function(player)
    local hud_id = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.98, y = 0.05},
        offset = {x = -32, y = 0},
        text = "ws_journal_icon.png",
        scale = {x = 1, y = 1},
        alignment = {x = -1, y = 1},
    })
    player:get_meta():set_int("ws_journal:hud_id", hud_id)
end)

-- Nightly unlock: use real time-of-day or a timer. Here we use minetest.get_timeofday() daily crossing.
-- We'll track last_timeofday per server step to detect a "midnight" crossing.
local last_timeofday = minetest.get_us_time() / 1000000
minetest.register_globalstep(function(dtime)
    -- simple timer check every ~5s
    last_timeofday = last_timeofday + dtime
end)

-- Use a periodic timer to unlock once per configured real-time interval (adjust as needed).
local unlock_timer = 0
local UNLOCK_INTERVAL = 600 -- seconds (10 minutes) -> treat as one "night" for unlocking
minetest.register_globalstep(function(dtime)
    unlock_timer = unlock_timer + dtime
    if unlock_timer < UNLOCK_INTERVAL then return end
    unlock_timer = 0

    for _, player in ipairs(minetest.get_connected_players()) do
        local data = get_journal(player)
        local idx = data.next_flashback
        if flashbacks[idx] then
            -- Add flashback object (title/body) to player's unlocked list
            table.insert(data.flashbacks, { title = flashbacks[idx].title, body = flashbacks[idx].body })
            data.next_flashback = idx + 1
            save_journal(player, data)
            minetest.chat_send_player(player:get_player_name(),
                minetest.colorize("#d0c060", "[Journal] A memory returns. Open your journal to read it."))
            -- make hud icon briefly pulse (remove/add) as attention ping
            local hid = player:get_meta():get_int("ws_journal:hud_id")
            if hid and hid > 0 then
                -- crude pulse: hide then show after small delay
                player:hud_remove(hid)
                minetest.after(0.2, function()
                    if player:is_player() then
                        local newhid = player:hud_add({
                            hud_elem_type = "image",
                            position = {x = 0.98, y = 0.05},
                            offset = {x = -32, y = 0},
                            text = "ws_journal_icon.png",
                            scale = {x = 1.2, y = 1.2},
                            alignment = {x = -1, y = 1},
                        })
                        player:get_meta():set_int("ws_journal:hud_id", newhid)
                        -- revert size after 1.5s
                        minetest.after(1.5, function()
                            if player:is_player() then
                                player:hud_remove(newhid)
                                local finalhid = player:hud_add({
                                    hud_elem_type = "image",
                                    position = {x = 0.98, y = 0.05},
                                    offset = {x = -32, y = 0},
                                    text = "ws_journal_icon.png",
                                    scale = {x = 1, y = 1},
                                    alignment = {x = -1, y = 1},
                                })
                                player:get_meta():set_int("ws_journal:hud_id", finalhid)
                            end
                        end)
                    end
                end)
            end
        end
    end
end)

-- Handle formspec input
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ws_journal:fs" then return end
    local name = player:get_player_name()
    local meta = player:get_meta()
    local data = get_journal(player)

    -- Tab buttons
    if fields.tab_fb then
        meta:set_string("ws_journal:active_tab", "flashbacks")
        meta:set_int("ws_journal:view_fb_index", 1)
        minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(player, "flashbacks", 1))
        return
    elseif fields.tab_act then
        meta:set_string("ws_journal:active_tab", "activities")
        minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(player, "activities"))
        return
    elseif fields.tab_notes then
        meta:set_string("ws_journal:active_tab", "notes")
        minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(player, "notes"))
        return
    end

    -- Flashback prev/next
    if fields.fb_prev or fields.fb_next then
        local idx = meta:get_int("ws_journal:view_fb_index") or 1
        local max = #data.flashbacks
        if max == 0 then return end
        if fields.fb_prev then idx = idx - 1 end
        if fields.fb_next then idx = idx + 1 end
        if idx < 1 then idx = max end
        if idx > max then idx = 1 end
        meta:set_int("ws_journal:view_fb_index", idx)
        minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(player, "flashbacks", idx))
        return
    end

    -- Add activity from field
    if fields.add_activity and fields.activity_input then
        local txt = fields.activity_input:trim()
        if txt ~= "" then
            table.insert(data.activities, { day = data.day_counter or 1, text = txt, time = os.time() })
            save_journal(player, data)
            minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(player, "activities"))
        end
        return
    end

    -- Add note
    if fields.add_note and fields.note_input then
        local txt = fields.note_input:trim()
        if txt ~= "" then
            table.insert(data.notes, { text = txt, time = os.time() })
            save_journal(player, data)
            minetest.show_formspec(name, "ws_journal:fs", build_journal_formspec(player, "notes"))
        end
        return
    end
end)

-- Chat commands for quick recording (same behavior as buttons)
minetest.register_chatcommand("add_note", {
    params = "<text>",
    description = "Add a personal note to your journal",
    func = function(name, param)
        if param == "" then return false, "No text provided." end
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not online." end
        local data = get_journal(player)
        table.insert(data.notes, { text = param, time = os.time() })
        save_journal(player, data)
        return true, "Note added."
    end
})

minetest.register_chatcommand("log_activity", {
    params = "<text>",
    description = "Record an activity into your journal",
    func = function(name, param)
        if param == "" then return false, "No text provided." end
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not online." end
        local data = get_journal(player)
        table.insert(data.activities, { day = data.day_counter or 1, text = param, time = os.time() })
        save_journal(player, data)
        return true, "Activity logged."
    end
})

-- (Optional) Exposure for other mods: allow adding an activity programmatically:
-- local ws_journal = minetest.get_mod_storage() not needed; instead provide global functions:
ws_journal = ws_journal or {}
function ws_journal.add_activity(player, text)
    if not player then return false end
    local data = get_journal(player)
    table.insert(data.activities, { day = data.day_counter or 1, text = text, time = os.time() })
    save_journal(player, data)
    return true
end

function ws_journal.add_note(player, text)
    if not player then return false end
    local data = get_journal(player)
    table.insert(data.notes, { text = text, time = os.time() })
    save_journal(player, data)
    return true
end

-- Optional: function to advance day counter (call from your day-cycle handler)
function ws_journal.advance_day_for(player)
    if not player then return end
    local data = get_journal(player)
    data.day_counter = (data.day_counter or 1) + 1
    save_journal(player, data)
end
