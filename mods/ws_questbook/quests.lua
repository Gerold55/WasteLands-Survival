ws_questbook.chapters = {
    ["wasteland_intro"] = {
        title = "Wasteland Introduction",
        description = "Start your adventure in the wastelands",
        quests = {}
    }
}

ws_questbook.quests = {
    ["find_water"] = {
        title = "Find Water",
        description = "Locate a water source",
        objectives = {
            { type = "collect", item = "ws_core:water_bottle", amount = 1 }
        },
        rewards = {
            { item = "ws_core:bandage", amount = 1 }
        }
    }
}

-- assign quest to chapter
table.insert(ws_questbook.chapters["wasteland_intro"].quests, "find_water")
