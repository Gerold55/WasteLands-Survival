ws_questbook.player_data = {}

function ws_questbook.start_quest(player, quest_id)
    local name = player:get_name()
    if not ws_questbook.player_data[name] then
        ws_questbook.player_data[name] = { active_quests = {}, completed_quests = {} }
    end

    local data = ws_questbook.player_data[name]
    if #data.active_quests >= ws_questbook.settings.max_active_quests then
        return false, "Too many active quests."
    end

    data.active_quests[quest_id] = { progress = {}, completed = false }
    local quest = ws_questbook.quests[quest_id]
    if quest then
        for _, obj in ipairs(quest.objectives) do
            local key = obj.type..":"..(obj.item or obj.target or "unknown")
            data.active_quests[quest_id].progress[key] = 0
        end
    end
    return true
end

function ws_questbook.complete_quest(player, quest_id)
    local name = player:get_name()
    local data = ws_questbook.player_data[name]
    if not data or not data.active_quests[quest_id] then return false end

    data.completed_quests[quest_id] = data.active_quests[quest_id]
    data.active_quests[quest_id] = nil

    local quest = ws_questbook.quests[quest_id]
    if quest then
        for _, reward in ipairs(quest.rewards) do
            player:add_item(reward.item, reward.amount or 1)
        end
    end
end
