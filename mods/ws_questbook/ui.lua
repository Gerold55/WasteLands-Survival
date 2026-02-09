-- Show Player QuestBook
function ws_questbook.show_questbook(player)
    local formspec = "size[12,9]label[0,0;Quest Book]"
    local y = 1
    local data = ws_questbook.player_data[player:get_name()]
    if data then
        for quest_id, quest in pairs(data.active_quests) do
            local q = ws_questbook.quests[quest_id]
            formspec = formspec.."label[0,"..y..";"..q.title.."]"
            y = y + 1
        end
    end

    if ws_questbook.settings.dev_mode then
        formspec = formspec.."button[10,0;2,1;open_editor;Editor]"
    end

    player:gui_formspec(formspec)
end

-- Show Chapter Editor
function ws_questbook.show_chapter_editor(player)
    local formspec = "size[12,9]label[0,0;Chapter Editor]"
    local y = 1
    for chapter_id, chapter in pairs(ws_questbook.chapters) do
        formspec = formspec.."label[0,"..y..";"..chapter.title.."]"
        formspec = formspec.."button[6,"..y..";3,1;edit_chapter_"..chapter_id..";Edit]"
        y = y + 1
    end
    formspec = formspec.."button[0,"..y..";4,1;new_chapter;New Chapter]"
    player:gui_formspec(formspec)
end

-- Show Quest Editor for Chapter
function ws_questbook.show_quest_editor(player, chapter_id)
    local chapter = ws_questbook.chapters[chapter_id]
    if not chapter then return end
    local formspec = "size[12,9]label[0,0;Quest Editor: "..chapter.title.."]"
    local y = 1
    for _, quest_id in ipairs(chapter.quests) do
        local quest = ws_questbook.quests[quest_id]
        formspec = formspec.."label[0,"..y..";"..quest.title.."]"
        formspec = formspec.."button[6,"..y..";3,1;edit_quest_"..quest_id..";Edit]"
        y = y + 1
    end
    formspec = formspec.."button[0,"..y..";4,1;new_quest;New Quest]"
    player:gui_formspec(formspec)
end

-- Receive Form Inputs
function ws_questbook.on_formspec_receive(player, fields)
    local name = player:get_name()
    if fields.open_editor then ws_questbook.show_chapter_editor(player) end

    if fields.new_chapter then
        local new_id = "chapter_"..os.time()
        ws_questbook.chapters[new_id] = { title = "New Chapter", description = "", quests = {} }
        ws_questbook.show_chapter_editor(player)
    end

    for k,_ in pairs(fields) do
        if k:match("edit_chapter_(.+)") then
            local chapter_id = k:match("edit_chapter_(.+)")
            ws_questbook.show_quest_editor(player, chapter_id)
        elseif k:match("edit_quest_(.+)") then
            local quest_id = k:match("edit_quest_(.+)")
            player:send_message("Edit quest feature coming soon: "..quest_id)
        elseif k:match("new_quest") then
            local chapter_id = "wasteland_intro" -- fallback, can be improved
            local new_id = "quest_"..os.time()
            ws_questbook.quests[new_id] = { title="New Quest", description="", objectives={}, rewards={} }
            table.insert(ws_questbook.chapters[chapter_id].quests, new_id)
            ws_questbook.show_quest_editor(player, chapter_id)
        end
    end
end
