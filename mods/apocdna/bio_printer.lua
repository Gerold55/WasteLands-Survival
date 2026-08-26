-- apocdna/bio_printer.lua

apocdna = apocdna or {}

local S = minetest.get_translator and minetest.get_translator("apocdna") or function(s) return s end

------------------------------------------------------------
-- FORMSPEC
------------------------------------------------------------
function apocdna.get_printer_formspec(pos)
    return "size[8,8]" ..
        "label[0,0;" .. S("Bio‑Printer") .. "]" ..
        "list[current_name;input;1,1;1,1;]" ..
        "list[current_name;output;5,1;1,1;]" ..
        "image[3,1;1,1;printer_progress.png]" ..
        "label[1,2;" .. S("Genome") .. "]" ..
        "label[5,2;" .. S("Result") .. "]" ..
        "list[current_player;main;0,4;8,4;]"
end

------------------------------------------------------------
-- NODE DEFINITION
------------------------------------------------------------
minetest.register_node("apocdna:bio_printer", {
    description = S("Bio‑Printer"),
    tiles = {
        "printer_top.png",
        "printer_bottom.png",
        "printer_side.png",
        "printer_side.png",
        "printer_side.png",
        "printer_front.png"
    },
    groups = {cracky = 2},
    paramtype2 = "facedir",

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Bio‑Printer"))
        local inv = meta:get_inventory()
        inv:set_size("input", 1)
        inv:set_size("output", 1)
    end,

    on_rightclick = function(pos, node, clicker)
        minetest.show_formspec(
            clicker:get_player_name(),
            "apocdna:bio_printer",
            apocdna.get_printer_formspec(pos)
        )
    end,

    on_timer = function(pos, elapsed)
        apocdna.run_printer_cycle(pos)
        return false
    end,
})

------------------------------------------------------------
-- PRINTING LOGIC
------------------------------------------------------------
function apocdna.print_from_genome(stack, pos)
    if stack:is_empty() then
        return nil
    end

    local meta = stack:get_meta()
    local species = meta:get_string("species")
    local mutation = meta:get_int("mutation")
    local type = meta:get_string("type")

    --------------------------------------------------------
    -- TERMINAL BOOST (if terminal is above printer)
    --------------------------------------------------------
    local terminal_pos = vector.add(pos, {x=0, y=1, z=0})
    local node = minetest.get_node(terminal_pos)

    local terminal_bonus = false
    if node.name == "apocdna:genome_terminal" then
        local tmeta = minetest.get_meta(terminal_pos)
        local library = minetest.deserialize(tmeta:get_string("library")) or {}
        if library[species] then
            terminal_bonus = true
        end
    end

    --------------------------------------------------------
    -- MUTATION EFFECTS
    --------------------------------------------------------
    local mutated = mutation >= 10
    local heavily_mutated = mutation >= 15

    --------------------------------------------------------
    -- PLANT GENOME → SEED
    --------------------------------------------------------
    if type == "plant" then
        local seed = ItemStack("apocdna:seed_" .. species)
        local smeta = seed:get_meta()

        smeta:set_string("species", species)

        if mutated then
            smeta:set_string("trait", "mutated")
        end
        if heavily_mutated then
            smeta:set_string("trait", "unstable")
        end

        if terminal_bonus then
            smeta:set_string("trait", "stable_growth")
        end

        return seed
    end

    --------------------------------------------------------
    -- CREATURE GENOME → EGG / EMBRYO
    --------------------------------------------------------
    if type == "creature" then
        local egg = ItemStack("apocdna:egg_" .. species)
        local emeta = egg:get_meta()

        emeta:set_string("species", species)

        if mutated then
            emeta:set_string("trait", "mutated")
        end
        if heavily_mutated then
            emeta:set_string("trait", "aggressive")
        end

        if terminal_bonus then
            emeta:set_string("trait", "stable_embryo")
        end

        return egg
    end

    --------------------------------------------------------
    -- CONTAMINATION EVENT (rare)
    --------------------------------------------------------
    if math.random(1,100) <= 5 then
        return ItemStack("apocdna:contamination_blob")
    end

    return ItemStack("apocdna:failed_print")
end

------------------------------------------------------------
-- RUN PRINTER CYCLE
------------------------------------------------------------
function apocdna.run_printer_cycle(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local input = inv:get_stack("input", 1)

    if input:is_empty() then
        return
    end

    local result = apocdna.print_from_genome(input, pos)
    if not result then
        return
    end

    -- consume input
    input:take_item(1)
    inv:set_stack("input", 1, input)

    -- output result
    if inv:room_for_item("output", result) then
        inv:add_item("output", result)
    else
        minetest.item_drop(result, nil, pos)
    end
end

------------------------------------------------------------
-- OPTIONAL: punch to start printing
------------------------------------------------------------
minetest.register_on_punchnode(function(pos, node)
    if node.name ~= "apocdna:bio_printer" then
        return
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if not inv:get_stack("input", 1):is_empty() then
        minetest.get_node_timer(pos):start(3.0)
    end
end)
