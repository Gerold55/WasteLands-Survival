-- apocdna/genome_terminal.lua

apocdna = apocdna or {}
apocdna.genome_library = apocdna.genome_library or {}

local S = minetest.get_translator and minetest.get_translator("apocdna") or function(s) return s end

------------------------------------------------------------
-- FORMSPEC
------------------------------------------------------------
function apocdna.get_terminal_formspec(pos)
    local meta = minetest.get_meta(pos)
    local library = minetest.deserialize(meta:get_string("library")) or {}

    local list_text = ""
    for species, data in pairs(library) do
        list_text = list_text .. species .. " (Purity " .. data.purity .. "%)\n"
    end

    return "size[10,10]" ..
        "label[0,0;" .. S("Genome Terminal") .. "]" ..
        "textarea[0.5,1;9.5,6;genomes;Stored Genomes:;" .. list_text .. "]" ..
        "list[current_name;stick;1,7;1,1;]" ..
        "button[3,7;2,1;export;Export]" ..
        "button[6,7;2,1;import;Import]" ..
        "list[current_player;main;0,8;10,2;]"
end

------------------------------------------------------------
-- NODE DEFINITION
------------------------------------------------------------
minetest.register_node("apocdna:genome_terminal", {
    description = S("Genome Terminal"),
    tiles = {
        "terminal_top.png",
        "terminal_bottom.png",
        "terminal_side.png",
        "terminal_side.png",
        "terminal_side.png",
        "terminal_front.png"
    },
    groups = {cracky = 2},
    paramtype2 = "facedir",

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Genome Terminal"))
        meta:set_string("library", minetest.serialize({}))
        local inv = meta:get_inventory()
        inv:set_size("stick", 1)
    end,

    on_rightclick = function(pos, node, clicker)
        minetest.show_formspec(
            clicker:get_player_name(),
            "apocdna:genome_terminal",
            apocdna.get_terminal_formspec(pos)
        )
    end,
})

------------------------------------------------------------
-- ADD GENOME TO TERMINAL LIBRARY
------------------------------------------------------------
function apocdna.terminal_add_genome(pos, species, purity)
    local meta = minetest.get_meta(pos)
    local library = minetest.deserialize(meta:get_string("library")) or {}

    library[species] = {
        purity = purity,
        timestamp = os.time()
    }

    meta:set_string("library", minetest.serialize(library))
end

------------------------------------------------------------
-- EXPORT / IMPORT HANDLER
------------------------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "apocdna:genome_terminal" then
        return false
    end

    local pos = player:get_pos()
    local node = minetest.get_node(pos)
    if node.name ~= "apocdna:genome_terminal" then
        return false
    end

    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()

    local stick = inv:get_stack("stick", 1)
    local stick_meta = stick:get_meta()

    -- EXPORT
    if fields.export then
        stick_meta:set_string("genome_data", meta:get_string("library"))
        inv:set_stack("stick", 1, stick)
        minetest.chat_send_player(player:get_player_name(), "Exported genome data to memory stick.")
    end

    -- IMPORT
    if fields.import then
        local data = stick_meta:get_string("genome_data")
        if data and data ~= "" then
            meta:set_string("library", data)
            minetest.chat_send_player(player:get_player_name(), "Imported genome data from memory stick.")
        else
            minetest.chat_send_player(player:get_player_name(), "Memory stick is empty.")
        end
    end

    return true
end)
