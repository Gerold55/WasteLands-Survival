local function esc(s)
    return minetest.formspec_escape(s or "")
end

function questbook.show_quest(name, id)
    local q = questbook.quests[id]
    local prog = questbook.ensure_progress(name)
    prog.current_quest = id

    local tprog = prog.tasks[id] or {}

    local fs = {
        "formspec_version[6]",
        "size[20,12]",
        "bgcolor[#00000000]",
        "background[0,0;20,12;questbook_page_bg.png]",
    }

    ------------------------------------------------------------
    -- LEFT PANEL (Quest Info)
    ------------------------------------------------------------
    table.insert(fs, "box[0.4,0.4;9.2,11.2;#1E1E1E]")

    -- Title
    table.insert(fs, "label[0.7,0.6;"..esc(q.title).."]")

    -- Description
    table.insert(fs,
        "textarea[0.7,1.2;8.8,3.5;desc;;"..
        esc(q.desc or "").."]"
    )

    ------------------------------------------------------------
    -- Choice Reward Box
    ------------------------------------------------------------
    table.insert(fs, "label[0.7,4.9;Choice Reward]")
    table.insert(fs, "box[0.7,5.2;8.8,1.8;#2A2A2A]")

    local reward = q.reward and q.reward.items and q.reward.items[1]
    if reward then
        table.insert(fs, "image[0.9,5.5;1,1;"..reward.icon.."]")
        table.insert(fs, "label[2.2,5.8;"..reward.count.."x "..reward.id.."]")
    else
        table.insert(fs, "label[0.9,5.8;No reward defined]")
    end

    ------------------------------------------------------------
    -- Claim / Done Buttons
    ------------------------------------------------------------
    local complete = questbook.is_quest_complete(name, id)

    if complete then
        table.insert(fs, "button[0.7,7.4;3,1;claim;Claim]")
    else
        table.insert(fs, "button[0.7,7.4;3,1;;Claim]")
        table.insert(fs, "label[0.7,8.6;§8Complete all tasks first]")
    end

    table.insert(fs, "button[4.0,7.4;3,1;done;Done]")

    ------------------------------------------------------------
    -- RIGHT PANEL (Tasks)
    ------------------------------------------------------------
    table.insert(fs, "box[10.0,0.4;9.6,11.2;#1E1E1E]")
    table.insert(fs, "label[10.3,0.6;Crafting Task]")

    table.insert(fs, "scroll_container[10.3,1.2;9.2,8.5;task_scroll;vertical]")

    local y = 0
    for _, task in ipairs(q.tasks or {}) do
        local have = tprog[task.id] or 0
        local need = task.count or 1
        local status = (have >= need) and "§2COMPLETE" or "§8INCOMPLETE"
        local icon = task.icon or "default_unknown.png"

        -- Task row background
        table.insert(fs, "box[0,"..y..";9,1.2;#2A2A2A]")

        -- Icon
        table.insert(fs, "image[0.2,"..(y+0.15)..";0.9,0.9;"..icon.."]")

        -- Name
        table.insert(fs, "label[1.4,"..(y+0.4)..";"..esc(task.name).."]")

        -- Progress
        table.insert(fs, "label[5.5,"..(y+0.4)..";"..have.."/"..need.."]")

        -- Status
        table.insert(fs, "label[7.2,"..(y+0.4)..";"..status.."]")

        y = y + 1.4
    end

    table.insert(fs, "scroll_container_end[]")

    ------------------------------------------------------------
    -- Bottom Buttons
    ------------------------------------------------------------
    table.insert(fs, "button[10.3,10.2;4,1;detect;Detect/Submit]")
    table.insert(fs, "button[15.0,10.2;4,1;back;Back]")

    minetest.show_formspec(name, "questbook:quest", table.concat(fs))
end

function questbook.detect_tasks(name, quest_id)
    local q = questbook.quests[quest_id]
    local prog = questbook.ensure_progress(name)
    prog.tasks[quest_id] = prog.tasks[quest_id] or {}

    local player = minetest.get_player_by_name(name)
    local inv = player:get_inventory()
    local main = inv:get_list("main") or {}

    for _, task in ipairs(q.tasks or {}) do
        local count = 0
        for _, stack in ipairs(main) do
            if not stack:is_empty() and stack:get_name() == task.id then
                count = count + stack:get_count()
            end
        end
        prog.tasks[quest_id][task.id] = count
    end
end

function questbook.is_quest_complete(name, quest_id)
    local q = questbook.quests[quest_id]
    local prog = questbook.ensure_progress(name)
    local tprog = prog.tasks[quest_id] or {}

    for _, task in ipairs(q.tasks or {}) do
        if (tprog[task.id] or 0) < (task.count or 1) then
            return false
        end
    end
    return true
end

function questbook.mark_quest_completed(name, quest_id)
    local prog = questbook.ensure_progress(name)
    if questbook.is_quest_complete(name, quest_id) then
        prog.completed[quest_id] = true
        return true
    end
    return false
end
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "questbook:quest" then return end

    local name = player:get_player_name()
    local prog = questbook.ensure_progress(name)
    local quest_id = prog.current_quest

    if fields.back then
        questbook.show_section(name, prog.current_section)
        return
    end

    if fields.detect then
        questbook.detect_tasks(name, quest_id)
        questbook.show_quest(name, quest_id)
        return
    end

    if fields.claim then
        if questbook.mark_quest_completed(name, quest_id) then
            minetest.chat_send_player(name, "Quest completed and reward claimed!")
        else
            minetest.chat_send_player(name, "You must complete all tasks first.")
        end
        return
    end

    if fields.done then
        if questbook.mark_quest_completed(name, quest_id) then
            minetest.chat_send_player(name, "Quest completed!")
        else
            minetest.chat_send_player(name, "Quest not complete yet.")
        end
        return
    end
end)
