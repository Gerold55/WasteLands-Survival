local achievements = {}
achievements.registered_achievements = {}
achievements.player_achievements = {}
achievements.active_displays = {}

-- Achievement categories
achievements.categories = {
    survival = {name = "Survival", color = "#FF6B35"},
    crafting = {name = "Crafting", color = "#4ECDC4"},
    exploration = {name = "Exploration", color = "#45B7D1"},
    combat = {name = "Combat", color = "#FF6384"},
    story = {name = "Story", color = "#A05195"}
}

-- Register achievement
function achievements.register_achievement(id, def)
    def.id = id
    def.players = def.players or {}
    achievements.registered_achievements[id] = def
end

-- Check if player has achievement
function achievements.has_achievement(player_name, achievement_id)
    return achievements.player_achievements[player_name] and 
           achievements.player_achievements[player_name][achievement_id]
end
-- Grant achievement to player
function achievements.grant_achievement(player_name, achievement_id)
    if not achievements.registered_achievements[achievement_id] then
        minetest.log("warning", "[ws_achievements] Attempted to grant unknown achievement: " .. achievement_id)
        return false
    end
    
    achievements.player_achievements[player_name] = achievements.player_achievements[player_name] or {}
    
    if not achievements.player_achievements[player_name][achievement_id] then
        achievements.player_achievements[player_name][achievement_id] = {
            unlocked = true,
            timestamp = os.time()
        }
        
        -- Show achievement notification
        achievements.show_achievement(player_name, achievement_id)
        
        -- Add to journal if story achievement
        local achievement = achievements.registered_achievements[achievement_id]
        if achievement.category == "story" and minetest.get_modpath("ws_story") then
            local entries = journal.require("entries")
            entries.add_entry(player_name, "ws_story:survivor",
                "Achievement Unlocked: " .. achievement.title .. " - " .. achievement.description, true)
        end
        
        minetest.log("action", "[ws_achievements] " .. player_name .. " unlocked achievement: " .. achievement_id)
        return true
    end
    return false
end

-- Show achievement notification
function achievements.show_achievement(player_name, achievement_id)
    local achievement = achievements.registered_achievements[achievement_id]
    if not achievement then return end
    
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    local formspec = "size[8,3.5]" ..
        "bgcolor[#1E1E1E;false]" ..
        "background9[0,0;8,3.5;ws_achievements_bg.png;false;10]" ..
        "image[0.5,0.5;2,2;" .. (achievement.icon or "ws_achievements_unknown.png") .. "]" ..
        "label[2.5,0.7;" .. minetest.colorize(achievements.categories[achievement.category].color, "Achievement Unlocked!") .. "]" ..
        "label[2.5,1.3;" .. minetest.colorize("#FFFFFF", achievement.title) .. "]" ..
        "textarea[2.5,1.7;5,1.5;;" .. minetest.formspec_escape(achievement.description) .. ";]" ..
        "button_exit[3,2.8;2,0.5;close;Awesome!]"
    
    minetest.show_formspec(player_name, "ws_achievements:notification_" .. achievement_id, formspec)
    
    minetest.after(5, function()
        achievements.hide_achievement(player_name, achievement_id)
    end)
end

function achievements.hide_achievement(player_name, achievement_id)
    local player = minetest.get_player_by_name(player_name)
    if player then
        minetest.close_formspec(player_name, "ws_achievements:notification_" .. achievement_id)
    end
end
-- Unified Achievement Menu (All achievements in one list)
function achievements.show_achievement_menu(player_name, selected_achievement_id)
    local player_achievements = achievements.player_achievements[player_name] or {}

    -- Build unified achievement list
    local list_str = ""
    local ach_index_map = {}
    local unlocked_count = 0
    local total_count = 0
    local idx = 1

    -- Sort achievements alphabetically
    local sorted = {}
    for id, def in pairs(achievements.registered_achievements) do
        sorted[#sorted + 1] = {id = id, def = def}
    end
    table.sort(sorted, function(a, b)
        return a.def.title < b.def.title
    end)

    for _, entry in ipairs(sorted) do
        local achievement_id = entry.id
        local def = entry.def

        total_count = total_count + 1
        local unlocked = achievements.has_achievement(player_name, achievement_id)
        if unlocked then unlocked_count = unlocked_count + 1 end

        local status = unlocked and "✓ " or "○ "
        local title = status .. def.title

        list_str = list_str .. minetest.formspec_escape(title) .. ","
        ach_index_map[idx] = achievement_id
        idx = idx + 1
    end

    -- Selected achievement details
    local detail_title = "Select an achievement"
    local detail_desc = ""
    local detail_how = ""

    if selected_achievement_id and achievements.registered_achievements[selected_achievement_id] then
        local def = achievements.registered_achievements[selected_achievement_id]
        detail_title = def.title
        detail_desc = def.description or ""
        detail_how = def.how or "Complete the requirement to unlock this achievement."
    end

    local formspec =
        "size[13,9]" ..
        "bgcolor[#1E1E1E;false]" ..
        "background9[0,0;13,9;ws_achievements_bg.png;false;10]" ..

        -- Header
        "label[0.5,0.3;" .. minetest.colorize("#FFFFFF", "Wastelands Survival Achievements") .. "]" ..

        -- Unified list panel
        "box[0.4,1.4;6,7.2;#00000055]" ..
        "label[0.6,1.5;" .. minetest.colorize("#CCCCCC", "All Achievements") .. "]" ..
        "textlist[0.6,1.9;5.7,6.6;ach_list;" .. list_str .. "]" ..

        -- Details panel
        "box[6.7,1.4;6,7.2;#00000055]" ..
        "label[6.9,1.5;" .. minetest.colorize("#FFFFFF", detail_title) .. "]" ..
        "textarea[6.9,2.0;5.7,2.5;;" .. minetest.formspec_escape(detail_desc) .. ";]" ..
        "label[6.9,4.7;" .. minetest.colorize("#CCCCCC", "How to Unlock") .. "]" ..
        "textarea[6.9,5.1;5.7,3.0;;" .. minetest.formspec_escape(detail_how) .. ";]" ..

        -- Progress
        "label[0.5,8.3;" .. minetest.colorize("#FFFFFF",
            "Progress: " .. unlocked_count .. "/" .. total_count .. " achievements unlocked") .. "]" ..

        "button_exit[11,8.2;2,0.7;close;Close]"

    -- Store mapping for click resolution
    achievements._ui_state = achievements._ui_state or {}
    achievements._ui_state[player_name] = {
        ach_index_map = ach_index_map,
    }

    minetest.show_formspec(player_name, "ws_achievements:menu", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ws_achievements:menu" then return end
    local name = player:get_player_name()
    local state = achievements._ui_state[name]
    if not state then return end

    if fields.ach_list then
        local event = minetest.explode_textlist_event(fields.ach_list)

        -- Some Minetest versions use CHG, others use DCL
        if event.type == "CHG" or event.type == "DCL" then
            local idx = event.index
            local achievement_id = state.ach_index_map[idx]

            if achievement_id then
                achievements.show_achievement_menu(name, achievement_id)
            end
        end
    end
end)

achievements.register_achievement("first_steps", {
    title = "First Steps",
    description = "Survive your first day in the wasteland",
    how = "Stay alive through one full day-night cycle.",
    category = "survival",
    icon = "ws_achievements_first_steps.png"
})

achievements.register_achievement("journal_finder", {
    title = "Chronicler",
    description = "Discover the survivor's journal",
    how = "Find and open the survivor's journal in the world.",
    category = "story",
    icon = "ws_achievements_journal.png"
})

achievements.register_achievement("crafting_master", {
    title = "Crafting Apprentice",
    description = "Craft your first crafting table",
    how = "Gather basic resources and craft a crafting table.",
    category = "crafting",
    icon = "ws_achievements_crafting.png"
})

achievements.register_achievement("water_collector", {
    title = "Water Collector",
    description = "Craft your first dew collector barrel",
    how = "Craft a dew collector barrel from the dewcollector mod.",
    category = "survival",
    icon = "ws_achievements_water.png"
})

achievements.register_achievement("first_shelter", {
    title = "Homesteader",
    description = "Place your first door",
    how = "Place any door or gate to mark your first shelter.",
    category = "survival",
    icon = "ws_achievements_shelter.png"
})

achievements.register_achievement("ore_miner", {
    title = "Ore Miner",
    description = "Mine your first valuable ore",
    how = "Mine iron, copper, gold, or diamond ore.",
    category = "crafting",
    icon = "ws_achievements_mining.png"
})

achievements.register_achievement("monster_slayer", {
    title = "Monster Slayer",
    description = "Defeat your first hostile creature",
    how = "Kill any hostile mob from the mobs mod.",
    category = "combat",
    icon = "ws_achievements_combat.png"
})

achievements.register_achievement("explorer", {
    title = "Explorer",
    description = "Discover 5 different landmarks",
    how = "Travel the world and find at least five unique landmarks.",
    category = "exploration",
    icon = "ws_achievements_exploration.png"
})

achievements.register_achievement("chef", {
    title = "Chef",
    description = "Cook your first proper meal",
    how = "Craft cooked food like bread, meat, or fish.",
    category = "survival",
    icon = "ws_achievements_cooking.png"
})

achievements.register_achievement("master_survivor", {
    title = "Master Survivor",
    description = "Survive for 10 in-game days",
    how = "Stay alive for ten full day-night cycles.",
    category = "survival",
    icon = "ws_achievements_master.png"
})
-- Integration with ws_story triggers
if minetest.get_modpath("ws_story") then
    local triggers = journal.require("triggers")
    
    triggers.register_on_join({
        id = "ws_achievements:journal",
        call_once = true,
        call = function(data)
            minetest.after(2, function()
                achievements.grant_achievement(data.playerName, "journal_finder")
            end)
        end,
    })
    
    triggers.register_on_craft({
        target = "crafting:crafting_table",
        id = "ws_achievements:crafting_table",
        call_once = true,
        call = function(data)
            achievements.grant_achievement(data.playerName, "crafting_master")
        end,
    })
    
    triggers.register_on_craft({
        target = "dewcollector:barrel_closed",
        id = "ws_achievements:dew_collector",
        call_once = true,
        call = function(data)
            achievements.grant_achievement(data.playerName, "water_collector")
        end,
    })
    
    triggers.register_on_place({
        target = {"group:door", "group:gate"},
        id = "ws_achievements:first_door",
        call_once = true,
        call = function(data)
            achievements.grant_achievement(data.playerName, "first_shelter")
        end,
    })
end

-- Day survival tracking
local player_days = {}
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local time_of_day = minetest.get_timeofday()
        
        if time_of_day < 0.1 and not player_days[player_name] then
            player_days[player_name] = true
            
            if not achievements.has_achievement(player_name, "first_steps") then
                achievements.grant_achievement(player_name, "first_steps")
            end
        elseif time_of_day > 0.5 then
            player_days[player_name] = false
        end
    end
end)

-- Ore mining detection
minetest.register_on_dignode(function(pos, oldnode, digger)
    if not digger then return end
    local player_name = digger:get_player_name()
    
    local ores = {
        ["default:stone_with_iron"] = "ore_miner",
        ["default:stone_with_copper"] = "ore_miner",
        ["default:stone_with_gold"] = "ore_miner",
        ["default:stone_with_diamond"] = "ore_miner",
    }
    
    if ores[oldnode.name] and not achievements.has_achievement(player_name, "ore_miner") then
        achievements.grant_achievement(player_name, "ore_miner")
    end
end)

-- Monster slayer detection
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    if hitter and hitter:is_player() and damage > 0 then
        local entity = player:get_luaentity()
        if entity and entity.name:find("mobs:") then
            local player_name = hitter:get_player_name()
            if not achievements.has_achievement(player_name, "monster_slayer") then
                achievements.grant_achievement(player_name, "monster_slayer")
            end
        end
    end
end)

-- Cooking achievement
minetest.register_on_craft(function(itemstack, player, old_craft_grid, craft_inv)
    if player then
        local player_name = player:get_player_name()
        local cooked_foods = {
            "farming:bread",
            "mobs:meat",
            "mobs:fish",
        }
        
        for _, food in ipairs(cooked_foods) do
            if itemstack:get_name() == food and not achievements.has_achievement(player_name, "chef") then
                achievements.grant_achievement(player_name, "chef")
                break
            end
        end
    end
end)
minetest.register_chatcommand("achievements", {
    description = "View your unlocked achievements",
    func = function(name, param)
        achievements.show_achievement_menu(name, nil, nil)
        return true
    end,
})

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    player_days[player_name] = nil
    if achievements._ui_state then
        achievements._ui_state[player_name] = nil
    end
end)

ws_achievements = achievements

minetest.log("action", "[ws_achievements] Achievement system loaded with " ..
    #achievements.registered_achievements .. " achievements")
