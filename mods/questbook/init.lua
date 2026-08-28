local modname = "questbook"
local modpath = minetest.get_modpath(modname)

questbook = {
    chapters = dofile(modpath .. "/quests/chapters.lua"),
    sections = dofile(modpath .. "/quests/sections.lua"),
    quests   = dofile(modpath .. "/quests/quests.lua"),
    progress = {},
}

function questbook.ensure_progress(name)
    if not questbook.progress[name] then
        questbook.progress[name] = {
            completed = {},
            tasks = {},
            current_chapter = nil,
            current_section = nil,
            current_quest = nil,
        }
    end
    return questbook.progress[name]
end

dofile(modpath .. "/ui_chapters.lua")
dofile(modpath .. "/ui_sections.lua")
dofile(modpath .. "/ui_quest.lua")

minetest.register_craftitem("questbook:book", {
    description = "Quest Book",
    inventory_image = "questbook.png",
    stack_max = 1,
    on_use = function(stack, user)
        local name = user:get_player_name()
        questbook.show_chapters(name)
        return stack
    end
})

minetest.register_chatcommand("questbook", {
    description = "Open the questbook",
    func = function(name)
        questbook.show_chapters(name)
        return true, "Questbook opened."
    end
})
