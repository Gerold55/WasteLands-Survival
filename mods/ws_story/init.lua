local entries = journal.require("entries")
local triggers = journal.require("triggers")

entries.register_page("ws_story:survivor", "Survivor's Log", "A tale of the last survivors in this world")

-- Creative mode detection
local function is_creative_enabled_for(player_name)
    if minetest.get_modpath("creative") then
        return creative.is_enabled_for(player_name)
    else
        return false
    end
end

-- Location tracking system
local location_memory = {}
local landmark_types = {
    ["default:tree"] = "tree grove",
    ["default:jungletree"] = "jungle area",
    ["default:pine_tree"] = "pine forest",
    ["default:sand"] = "sandy area",
    ["default:desert_sand"] = "desert",
    ["default:snowblock"] = "snowy region",
    ["default:water_source"] = "water source",
    ["default:stone"] = "rocky outcrop",
    ["default:clay"] = "clay deposit",
    ["default:coalblock"] = "coal-rich area",
}

-- Creative mode warning
triggers.register_on_join({
    id = "ws_story:creative",
    call_once = true,
    is_active = function(player_name)
        return is_creative_enabled_for(player_name)
    end,
    call = function(data)
        entries.add_entry(data.playerName, "ws_story:survivor",
            "--- In creative mode the story " ..
            "of Wastelands Survival may lose its consistency. ---", false)
    end,
})

-- Journal discovery and main story (Family-Friendly Wasteland Edition)
local function find_journal(player_name)
    entries.add_entry(player_name, "ws_story:survivor",
        "Today I found an old journal. Whoever owned it before must have faced the same hardships I do now. " ..
        "I suppose I’ll continue their story with my own. My last rations ran out today… I need to stay strong. " ..
        "The wasteland is harsh, but I won’t give up.", true)
end

triggers.register_on_join({
    id = "ws_story:start",
    call_once = true,
    call = function(data)
        find_journal(data.playerName)

        -- Enhanced plot with smoother pacing and family-friendly tone
        minetest.after(10, entries.add_entry, data.playerName, "ws_story:survivor",
            "Before I go any further, I should explain what happened. Long ago, a dangerous formula was stolen " ..
            "from a military research group. During the escape, it spilled into the water and spread across the oceans. " ..
            "Over time, the world changed. Clean food and water became rare, and people struggled to survive. " ..
            "Now only a few of us remain in these wastelands.", false)

        minetest.after(20, entries.add_entry, data.playerName, "ws_story:survivor",
            "Strange creatures roam the land now—ogres, giant insects, and other unusual beings. " ..
            "Many were once animals or even people, changed by the contaminated water. " ..
            "They’re not all hostile, but caution is always wise.", false)

        minetest.after(30, entries.add_entry, data.playerName, "ws_story:survivor",
            "If I’m going to make it out here, I’ll need tools. Crafting with bare hands only gets me so far. " ..
            "A simple wooden table would help me organize materials and build better equipment.", false)

        minetest.after(45, entries.add_entry, data.playerName, "ws_story:survivor",
            "The journal’s previous owner mentioned landmarks. That might be useful. " ..
            "I should mark any important places I find. A simple right-click with an empty hand should do it.", false)
    end,
})

-- Enhanced death system with progression (Family-Friendly Wasteland Edition)
local death_counters = {}
triggers.register_on_die(function(data)
    death_counters[data.playerName] = (death_counters[data.playerName] or 0) + 1
    
    local death_msgs = {
        "That was a close call… I need to stay alert out here.",
        "The wasteland nearly got the better of me. I must move carefully.",
        "I stumbled today, but I’m still standing. I won’t let this place defeat me.",
        "Another narrow escape. Survival means learning from every mistake."
    }
    
    if death_counters[data.playerName] == 1 then
        entries.add_entry(data.playerName, "ws_story:survivor",
            "My first real brush with danger… It reminds me how fragile life is out here.", true)
    elseif death_counters[data.playerName] >= 3 then
        entries.add_entry(data.playerName, "ws_story:survivor",
            "I’m taking too many risks. If I want to survive, I need to slow down and think things through.", true)
    else
        entries.add_entry(data.playerName, "ws_story:survivor", 
            random_msg(death_msgs), true)
    end
end)

-- Location marking system
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "" and fields.quit then
        local player_name = player:get_player_name()
        if location_memory[player_name] then
            local pos = player:get_pos()
            local node = minetest.get_node(pos)
            local landmark_name = landmark_types[node.name] or "interesting location"
            
            entries.add_entry(player_name, "ws_story:survivor",
                "Marked a " .. landmark_name .. " at coordinates: " ..
                math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ", " .. math.floor(pos.z), true)
            
            location_memory[player_name] = nil
        end
    end
end)

-- minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
--     local player_name = puncher:get_player_name()
--     if player_name and puncher:get_wielded_item():is_empty() then
--         location_memory[player_name] = pos
--         minetest.show_formspec(player_name, "ws_story:mark_location", 
--             "field[location_name;Name this location;]")
--     end
-- end)

-- Enhanced wood breaking with location awareness
triggers.register_on_dig({
    target = {"group:tree", "group:wood"},
    id = "ws_story:treepunch",
    call_once = true,
    call = function(data)
        if minetest.get_item_group(data.tool, "hatchet") == 0 and minetest.get_item_group(data.tool, "axe") == 0 then
            local location_hint = ""
            if math.random(1, 3) == 1 then
                location_hint = " I remember seeing some stones near that old ruin - maybe I can make a proper tool there."
            end
            entries.add_entry(data.playerName, "ws_story:survivor",
                "Ouch, just hitting wood won't do. I guess I need a hatchet or an axe." .. location_hint, true)
        end
    end
})

-- Enhanced stair crafting with location memory
triggers.register_on_dig({
    target = {"group:stair"},
    id = "ws_story:staircombine",
    call_once = true,
    call = function(data)
        entries.add_entry(data.playerName, "ws_story:survivor",
            "I get all these broken planks from the ruins... Maybe I can combine them back into full walls. " ..
            "There's that collapsed building to the east with plenty more materials.", true)
    end
})

-- Enhanced crafting table with progression
triggers.register_on_craft({
    target = "crafting:crafting_table",
    id = "ws_story:crafting_table",
    call_once = true,
    call = function(data)
        entries.add_entry(data.playerName, "ws_story:survivor",
            "♭Crafting steeeeeel!!!!♭ " ..
            "First priority: something against this unbearable thirst. " ..
            "I remember seeing some barrels near the old farm - maybe I can repurpose them for water collection.", true)
    end,
})

-- Random message helper
local function random_msg(list)
    return list[math.random(1, #list)]
end

-- Enhanced creature encounters with location context (Family-Friendly Wasteland Edition)
local creature_encounters = {
    ["mobs:bigfoot"] = {
        msgs = {
            "A towering figure moved between the trees. Looked like a forest giant.",
            "I spotted something huge and hairy. Might’ve been Bigfoot.",
            "Saw a large silhouette watching from the woods. Hope it’s friendly."
        },
        location = "forest"
    },
    ["mobs:yeti"] = {
        msgs = {
            "A white, snow-covered giant wandered past. A real wasteland yeti.",
            "Caught sight of a tall creature in the snow. Looked peaceful enough.",
            "A fluffy white giant crossed my path. The cold doesn’t bother it at all."
        },
        location = "snow"
    },
    ["mobs:sand_worm"] = {
        msgs = {
            "The desert shifted today… a massive sand worm surfaced for a moment.",
            "Saw a huge worm rise from the dunes. The wasteland never stops surprising me.",
            "A giant sand creature moved beneath my feet. Best to tread lightly out here."
        },
        location = "desert"
    },
    ["mobs:spider"] = {
        msgs = {
            "Found a large spider in the caves. It kept its distance, thankfully.",
            "Saw fresh webs stretched across the rocks. Something big lives here.",
            "A cave spider skittered past. Quick little thing, but harmless if left alone."
        },
        location = "caves"
    },
    ["mobs:ogre"] = {
        msgs = {
            "A massive green ogre lumbered across the mountains. Strong, but calm.",
            "Spotted an ogre today. It looked curious more than anything.",
            "Thought I saw a moving boulder… turns out it was an ogre taking a stroll."
        },
        location = "mountains"
    },
    ["mobs:piranha"] = {
        msgs = {
            "The rivers here have tiny fish with sharp instincts. Best to stay cautious.",
            "A piranha nibbled at my boot today. Quick little swimmers.",
            "Small fish with big energy live in these waters. They keep you on your toes."
        },
        location = "water"
    }
}

-- Register all creature encounters
--for mob, data in pairs(creature_encounters) do
    ---#FIXME
    --[[
    triggers.register_on_punch({
        target = {mob},
        id = "ws_story:" .. mob,
        call_once = true,
        call = function(punch_data)
            local msg = random_msg(data.msgs)
            entries.add_entry(punch_data.playerName, "ws_story:survivor", msg, true)
        end,
    })
    --]]
--end

-- Enhanced dew barrel system with progression
triggers.register_counter("ws_story:dew_barrel_count", "craft", "dewcollector:barrel_closed", false)

local dew_messages = {
    [1] = "It is done, my first dew collection barrel! Now I just have to place it somewhere high and wait until it fills up. There's a good spot on that hill to the west.",
    [2] = "Second barrel ready. With two, I might actually survive the dry season. I should place this one near my shelter.",
    [3] = "Three barrels should be enough for now. Time to focus on building better shelter - that ruined house could be repaired.",
    [4] = "Four barrels collecting dew... but it's still not enough during heat waves. I need a better solution.",
    [5] = "These dew barrels are quite inefficient. I should try building a filter to clean the toxic water from the river."
}

triggers.register_on_craft({
    target = "dewcollector:barrel_closed",
    id = "ws_story:dew_barrel_progression",
    call = function(data)
        local count = triggers.get_count("ws_story:dew_barrel_count", data.playerName)
        if dew_messages[count] then
            entries.add_entry(data.playerName, "ws_story:survivor", dew_messages[count], true)
        elseif count > 5 then
            entries.add_entry(data.playerName, "ws_story:survivor",
                "I'm becoming a water hoarder with " .. count .. " barrels. Maybe I should focus on purification instead.", true)
        end
    end,
})

-- New: Shelter building progression
triggers.register_on_place({
    target = {"group:door", "group:gate"},
    id = "ws_story:first_door",
    call_once = true,
    call = function(data)
        entries.add_entry(data.playerName, "ws_story:survivor",
            "A door! Now I have some real privacy and security. Feels more like home already.", true)
    end,
})

triggers.register_on_craft({
    target = {"group:bed", "default:bed"},
    id = "ws_story:first_bed",
    call_once = true,
    call = function(data)
        entries.add_entry(data.playerName, "ws_story:survivor",
            "A proper bed! No more sleeping on the ground. This should he...", true)
    end,
})

-- New: Resource discovery system
local resource_discoveries = {
    ["default:coal_lump"] = "Coal! This could be useful for torches and smelting.",
    ["default:iron_lump"] = "Iron ore! With a furnace, I could make proper tools.",
    ["default:copper_lump"] = "Copper! XD",
    ["default:gold_lump"] = "Gold! Not very practical, but might be valuable if I find other survivors.",
    ["default:diamond"] = "A diamond! : This could make excellent tools.",
}

for item, message in pairs(resource_discoveries) do
    ---#FIXME
    --[[
    triggers.register_on_craft({
        target = item,
        id = "ws_story:discover_" .. item,
        call_once = true,
        call = function(data)
            entries.add_entry(data.playerName, "ws_story:survivor", message, true)
        end,
    })
    --]]
end

-- New: Weather and time-based entries
local function add_time_based_entries(player_name)
    -- Night time entry
    minetest.after(120, function()
        if minetest.get_player_by_name(player_name) then
            entries.add_entry(player_name, "ws_story:survivor",
                "Night falls quickly here. The temperature drops and strange noises emerge from the darkness.", false)
        end
    end)
    
    -- Rain entry (if weather mod detected)
    minetest.after(300, function()
        if minetest.get_modpath("weather") and minetest.get_player_by_name(player_name) then
            entries.add_entry(player_name, "ws_story:survivor",
                "Rain! The barrels will fill faster, but I need to stay dry. At least it washes some toxins away.", false)
        end
    end)
end

triggers.register_on_join({
    id = "ws_story:time_events",
    call_once = true,
    call = function(data)
        add_time_based_entries(data.playerName)
    end,
})

-- New: Achievement system for major milestones
local milestones = {
    ["default:furnace"] = "Built my first furnace! Now I can smelt ores and cook proper food.",
    ["default:chest"] = "A storage chest! No more leaving valuable items on the ground.",
    ["farming:bread"] = "Real bread! After eating scraps for so long, this feels like a feast.",
}

for item, message in pairs(milestones) do
    ---#FIXME
    --[[
    triggers.register_on_craft({
        target = item,
        id = "ws_story:milestone_" .. item,
        call_once = true,
        call = function(data)
            entries.add_entry(data.playerName, "ws_story:survivor", 
                "Milestone reached: " .. message, true)
        end,
    })
    --]]
end

-- Cleanup on player leave
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    location_memory[player_name] = nil
    death_counters[player_name] = nil
end)

minetest.log("action", "[ws_story] Enhanced survivor journal system loaded")

return creature_encounters