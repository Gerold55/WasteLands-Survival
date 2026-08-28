local function esc(s)
    return minetest.formspec_escape(s or "")
end

function questbook.show_section(name, section_id)
    local prog = questbook.ensure_progress(name)

    local fs = {
        "formspec_version[6]",
        "size[20,12]",
        "bgcolor[#00000000]",
        "background[0,0;20,12;questbook_bg.png]",
    }

    local section
    for _, sec_list in pairs(questbook.sections) do
        for _, sec in ipairs(sec_list) do
            if sec.id == section_id then
                section = sec
            end
        end
    end

    if not section then return end

    table.insert(fs, "label[0.6,0.6;"..esc(section.title).."]")

    ------------------------------------------------------------
    -- QUEST LIST (UNLIMITED)
    ------------------------------------------------------------
    local quests = {}
    for id, q in pairs(questbook.quests) do
        if q.section == section_id then
            table.insert(quests, q)
        end
    end

    table.sort(quests, function(a,b)
        return (a.order or 0) < (b.order or 0)
    end)

    local y = 1.3
    for _, q in ipairs(quests) do
        local icon = q.icon or "default_book.png"

        table.insert(fs, "box[0.4,"..y..";19.2,1.5;#1E1E1E]")
        table.insert(fs, "image_button[0.6,"..(y+0.2)..";1.2,1.2;"..icon..";quest_"..q.id..";]")
        table.insert(fs, "label[2.2,"..(y+0.5)..";"..esc(q.title).."]")

        y = y + 1.7
    end

    table.insert(fs, "button[0.4,10.5;3,1;back;Back]")

    minetest.show_formspec(name, "questbook:section", table.concat(fs))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "questbook:section" then return end
    local name = player:get_player_name()
    local prog = questbook.ensure_progress(name)

    if fields.back then
        questbook.show_chapters(name)
        return
    end

    for id,_ in pairs(questbook.quests) do
        if fields["quest_"..id] then
            prog.current_quest = id
            questbook.show_quest(name, id)
            return
        end
    end
end)
