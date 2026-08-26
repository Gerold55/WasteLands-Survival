-- apocdna/init.lua
-- Main entry point for the Apocalypse DNA Restoration Mod

apocdna = apocdna or {}

local modpath = minetest.get_modpath("apocdna")

------------------------------------------------------------
-- LOAD ORDER (IMPORTANT)
------------------------------------------------------------

-- Items (DNA, fossils, seeds, eggs, misc)
dofile(modpath .. "/items.lua")

-- Machines
dofile(modpath .. "/genome_analyzer.lua")
dofile(modpath .. "/genome_sequencer.lua")
dofile(modpath .. "/bio_printer.lua")
dofile(modpath .. "/genome_terminal.lua")

-- Fossil nodes + excavation tools
--dofile(modpath .. "/fossils.lua")
--dofile(modpath .. "/excavation.lua")

------------------------------------------------------------
-- GLOBAL SETTINGS
------------------------------------------------------------

apocdna.settings = {
    analyzer_speed = 2.0,
    sequencer_speed = 3.0,
    printer_speed = 3.0,
    contamination_chance = 5,
}

------------------------------------------------------------
-- CHAT COMMAND (OPTIONAL)
-- Lets you inspect the genome library stored in terminals
------------------------------------------------------------

minetest.register_chatcommand("genomes", {
    description = "List all known genomes in nearby terminals",
    privs = {interact = true},
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        local pos = vector.round(player:get_pos())
        local found = false

        for dx = -3, 3 do
            for dy = -3, 3 do
                for dz = -3, 3 do
                    local p = {x = pos.x + dx, y = pos.y + dy, z = pos.z + dz}
                    local node = minetest.get_node(p)

                    if node.name == "apocdna:genome_terminal" then
                        found = true
                        local meta = minetest.get_meta(p)
                        local library = minetest.deserialize(meta:get_string("library")) or {}

                        minetest.chat_send_player(name, "=== Genome Terminal @ " ..
                            minetest.pos_to_string(p) .. " ===")

                        for species, data in pairs(library) do
                            minetest.chat_send_player(name,
                                "- " .. species .. " (Purity " .. data.purity .. "%)")
                        end
                    end
                end
            end
        end

        if not found then
            return "No genome terminals found nearby."
        end
    end
})

------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

minetest.log("action", "[apocdna] Apocalypse DNA Restoration Mod Loaded")
