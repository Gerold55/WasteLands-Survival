local function esc(s)
    return minetest.formspec_escape(s or "")
end

local function get_chapter_quests(chapter_id)
    local list = {}
    for id, q in pairs(questbook.quests) do
        if q.chapter == chapter_id then
            table.insert(list, q)
        end
    end
    table.sort(list, function(a, b)
        return (a.order or 0) < (b.order or 0)
    end)
    return list
end

function questbook.show_tree(name, chapter_id)
    local chapters = questbook.chapters
    local prog = questbook.ensure_progress(name)

    -- Default to first chapter
    if not chapter_id then
        for cid,_ in pairs(chapters) do
            chapter_id = cid
            break
        end
    end

    prog.current_chapter = chapter_id

    local chap = chapters[chapter_id]
    local quests = get_chapter_quests(chapter_id)

    local fs = {
        "formspec_version[6]",
        "size[20,12]",
        "bgcolor[#00000000]",
        "background[0,0;20,12;questbook_bg.png]",
    }

    ------------------------------------------------------------
    -- LEFT: CHAPTERS (like your “Getting Started” list)
    ------------------------------------------------------------
    table.insert(fs, "label[0.6,0.6;Chapters]")
    table.insert(fs, "box[0.4,1.0;3.6,9.5;#1E1E1E]")

    local cy = 1.3
    for cid, c in pairs(chapters) do
        local icon = c.icon or "default_book.png"
        table.insert(fs, "image_button[0.6,"..cy..";1,1;"..icon..";chapter_"..cid..";]")
        table.insert(fs, "label[1.8,"..(cy+0.3)..";"..esc(c.title).."]")
        cy = cy + 1.2
    end

    ------------------------------------------------------------
    -- RIGHT TOP: BIG PANELS (like The Basics / Survival / World)
    ------------------------------------------------------------
    table.insert(fs, "label[4.5,0.6;"..esc(chap.title).."]")

    -- We’ll show up to 3 “panels” per chapter, like your screenshot
    local panel_y = 1.3
    local panel_index = 0

    for _, q in ipairs(quests) do
        panel_index = panel_index + 1
        if panel_index > 3 then break end

        local id   = q.id
        local icon = q.icon or "default_book.png"
        local p    = questbook.progress[name] or {}
        local total = q.total or #(q.tasks or {})
        local done  = p.tasks and p.tasks[id] and p.tasks[id].done or 0

        -- Panel background
        table.insert(fs, "box[4.5,"..panel_y..";14.5,2.2;#1E1E1E]")

        -- Icon
        table.insert(fs, "image_button[4.7,"..(panel_y+0.3)..";2,1.6;"..icon..";quest_"..id..";]")

        -- Title
        table.insert(fs, "label[7.0,"..(panel_y+0.4)..";"..esc(q.title).."]")

        -- Progress (0/6 style)
        table.insert(fs, "label[7.0,"..(panel_y+1.0)..";"..done.."/"..total.."]")

        panel_y = panel_y + 2.4
    end

    ------------------------------------------------------------
    -- RIGHT BOTTOM: Description box (like the “Welcome!” text)
    ------------------------------------------------------------
    table.insert(fs, "box[4.5,8.0;14.5,3.0;#1E1E1E]")

    -- Little book icon on the left of the text
    table.insert(fs, "image[4.7,8.3;1,1;default_book.png]")

    -- Description text
    local desc = chap.desc or "Welcome! Learn the basics of survival, crafting, and building in the world. Start your journey here."
    table.insert(fs, "textarea[5.8,8.2;12.8,2.5;;;"..esc(desc).."]")

    minetest.show_formspec(name, "questbook:tree", table.concat(fs))
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "questbook:tree" then return end
    local name = player:get_player_name()
    local prog = questbook.ensure_progress(name)

    -- Chapter switching
    for cid,_ in pairs(questbook.chapters) do
        if fields["chapter_"..cid] then
            questbook.show_tree(name, cid)
            return
        end
    end

    -- Quest opening (clicking a panel icon)
    for id,_ in pairs(questbook.quests) do
        if fields["quest_"..id] then
            prog.current_quest = id
            questbook.show_quest(name, id)
            return
        end
    end
end)
