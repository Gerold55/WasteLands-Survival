-------------------------------
-- Questbook API
-- Provides: quest registration, task updates, completion checks,
-- reward handling, and player progress storage.
-------------------------------

local storage = minetest.get_mod_storage()

questbook = {
    quests = {},        -- All registered quests
    task_handlers = {}, -- Custom task types
}

-------------------------------------------------------
-- STORAGE
-------------------------------------------------------

local function load_player(name)
    local raw = storage:get_string(name)
    if raw == "" then
        return { completed = {}, progress = {} }
    end
    return minetest.parse_json(raw)
end

local function save_player(name, data)
    storage:set_string(name, minetest.write_json(data))
end

-------------------------------------------------------
-- QUEST REGISTRATION
-------------------------------------------------------

-- Register a quest definition
-- quest = {
--   id = "string",
--   title = "string",
--   desc = "string",
--   tasks = { {type="", item="", count=1}, ... },
--   rewards = { {type="", item="", count=1}, ... },
--   requires = { "quest_id", ... }
-- }
function questbook.register_quest(quest)
    if not quest.id then
        error("[questbook] Quest missing id")
    end
    questbook.quests[quest.id] = quest
end

-- Fetch quest by ID
function questbook.get_quest(id)
    return questbook.quests[id]
end

-- Return all quests
function questbook.get_all_quests()
    return questbook.quests
end

-------------------------------------------------------
-- TASK HANDLING
-------------------------------------------------------

-- Register a custom task handler
-- Example: questbook.register_task_type("kill", function(player, task, amount) ... end)
function questbook.register_task_type(task_type, func)
    questbook.task_handlers[task_type] = func
end

-- Update task progress
function questbook.update_task(player, task_type, target, amount)
    local name = player:get_player_name()
    local data = load_player(name)

    for quest_id, quest in pairs(questbook.quests) do
        if not data.completed[quest_id] then
            for _,task in ipairs(quest.tasks or {}) do
                if task.type == task_type and (task.item == target or task.target == target) then
                    -- Initialize progress
                    data.progress[quest_id] = data.progress[quest_id] or {}
                    local prog = data.progress[quest_id]

                    prog[task_type] = (prog[task_type] or 0) + amount

                    -- Check completion
                    if prog[task_type] >= task.count then
                        questbook.try_complete(player, quest)
                    end
                end
            end
        end
    end

    save_player(name, data)
end

-------------------------------------------------------
-- COMPLETION CHECK
-------------------------------------------------------

-- Check if a single task is complete
local function task_complete(progress, task)
    local p = progress[task.type]
    return p and p >= task.count
end

-- Check if all tasks are complete
local function all_tasks_complete(data, quest)
    local progress = data.progress[quest.id] or {}
    for _,task in ipairs(quest.tasks or {}) do
        if not task_complete(progress, task) then
            return false
        end
    end
    return true
end

-- Check if quest is unlocked
function questbook.is_unlocked(player, quest)
    local name = player:get_player_name()
    local data = load_player(name)

    for _,req in ipairs(quest.requires or {}) do
        if not data.completed[req] then
            return false
        end
    end
    return true
end

-------------------------------------------------------
-- REWARDS
-------------------------------------------------------

local function give_item_reward(player, reward)
    local inv = player:get_inventory()
    inv:add_item("main", reward.item .. " " .. reward.count)
end

local reward_handlers = {
    item = give_item_reward,
}

function questbook.give_rewards(player, rewards)
    for _,reward in ipairs(rewards or {}) do
        local handler = reward_handlers[reward.type]
        if handler then
            handler(player, reward)
        end
    end
end

-------------------------------------------------------
-- COMPLETE QUEST
-------------------------------------------------------

function questbook.try_complete(player, quest)
    local name = player:get_player_name()
    local data = load_player(name)

    -- Check unlock
    if not questbook.is_unlocked(player, quest) then
        return false
    end

    -- Check tasks
    if not all_tasks_complete(data, quest) then
        return false
    end

    -- Mark complete
    data.completed[quest.id] = true
    save_player(name, data)

    -- Give rewards
    questbook.give_rewards(player, quest.rewards)

    minetest.chat_send_player(name, "Quest completed: " .. quest.title)

    return true
end

-------------------------------------------------------
-- API READY
-------------------------------------------------------

minetest.log("action", "[questbook] API loaded")
return questbook
