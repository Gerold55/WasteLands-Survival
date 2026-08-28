local function esc(s)
    return minetest.formspec_escape(s or "")
end

function questbook.show_chapters(name)
    local prog = questbook.ensure_progress(name)

    local fs = {
        "formspec_version[6]",
        "size[20,12]",
        "bgcolor[#00000000]",
        -- No textures, just flat background
        "box[0,0;20,12;#202020]",
    }

    ------------------------------------------------------------
    -- LEFT: CHAPTER LIST
    ------------------------------------------------------------
    table.insert(fs, "label[0.6,0.6;Chapters]")
    table.insert(fs, "box[0.4,1.0;3.6,9.5;#303030]")

    local cy = 1.3
    for cid, chap in pairs(questbook.chapters) do
        local icon = chap.icon or "default_book.png"
        table.insert(fs, "image_button[0.6,"..cy..";1,1;"..icon..";chapter_"..cid..";]")
        table.insert(fs, "label[1.8,"..(cy+0.3)..";"..esc(chap.title).."]")
        cy = cy + 1.2
    end

    ------------------------------------------------------------
-- RIGHT: SECTION LIST (scrollable + clickable, NO IMAGES)
------------------------------------------------------------
local chapter_id = prog.current_chapter or next(questbook.chapters)
prog.current_chapter = chapter_id

local chap = questbook.chapters[chapter_id]
local sections = questbook.sections[chapter_id] or {}

table.insert(fs, "label[4.5,0.6;"..esc(chap.title).."]")

-- Scroll container for tasks/sections
table.insert(fs, "scroll_container[4.5,1.3;14.5,7.2;section_scroll;vertical]")

local y = 0

for _, sec in ipairs(sections) do
    --------------------------------------------------------
    -- Row background (flat color)
    --------------------------------------------------------
    table.insert(fs, "box[0,"..y..";14.5,1.2;#404040]")

    --------------------------------------------------------
    -- Title text only
    --------------------------------------------------------
    table.insert(fs,
        "label[0.4,"..(y+0.4)..";"..esc(sec.title).."]"
    )

    --------------------------------------------------------
    -- Progress (right aligned)
    --------------------------------------------------------
    table.insert(fs,
        "label[12.0,"..(y+0.4)..";"..esc(sec.progress or "0/0").."]"
    )

    --------------------------------------------------------
    -- FULL CLICKABLE ROW
    --------------------------------------------------------
    table.insert(fs,
        "image_button[0,"..y..";14.5,1.2;blank.png;section_"..sec.id..";]"
    )

    y = y + 1.4
end

table.insert(fs, "scroll_container_end[]")

    ------------------------------------------------------------
    -- DESCRIPTION BOX (flat color)
    ------------------------------------------------------------
    table.insert(fs, "box[4.5,9.0;14.5,2.5;#303030]")
    table.insert(fs, "label[4.7,9.2;Info]")
    table.insert(fs, "textarea[5.8,9.1;12.8,2.2;;;"..esc(chap.desc).."]")

    ------------------------------------------------------------
    -- EXIT BUTTON
    ------------------------------------------------------------
    table.insert(fs, "button[0.4,10.8;3.6,1;exit;Exit]")

    minetest.show_formspec(name, "questbook:chapters", table.concat(fs))
end

------------------------------------------------------------
-- HANDLER
------------------------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "questbook:chapters" then return end

    local name = player:get_player_name()
    local prog = questbook.ensure_progress(name)

    -- Exit
    if fields.exit then
        return
    end

    -- Chapter switching
    for cid,_ in pairs(questbook.chapters) do
        if fields["chapter_"..cid] then
            prog.current_chapter = cid
            questbook.show_chapters(name)
            return
        end
    end

    -- Section opening
    for cid, sec_list in pairs(questbook.sections) do
        for _, sec in ipairs(sec_list) do
            if fields["section_"..sec.id] then
                prog.current_section = sec.id
                questbook.show_section(name, sec.id)
                return
            end
        end
    end
end)
