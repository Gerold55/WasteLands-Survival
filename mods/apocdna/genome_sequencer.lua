-- apocdna/genome_sequencer.lua

apocdna = apocdna or {}

local S = minetest.get_translator and minetest.get_translator("apocdna") or function(s) return s end

------------------------------------------------------------
-- FORMSPEC
------------------------------------------------------------
function apocdna.get_sequencer_formspec(pos)
    return "size[8,8]" ..
        "label[0,0;" .. S("Genome Sequencer") .. "]" ..
        "list[current_name;input;1,1;1,1;]" ..
        "list[current_name;output;5,1;1,1;]" ..
        "image[3,1;1,1;sequencer_progress.png]" ..
        "label[1,2;" .. S("DNA Input") .. "]" ..
        "label[5,2;" .. S("Genome") .. "]" ..
        "list[current_player;main;0,4;8,4;]"
end

------------------------------------------------------------
-- NODE DEFINITION
------------------------------------------------------------
minetest.register_node("apocdna:genome_sequencer", {
    description = S("Genome Sequencer"),
    tiles = {
        "sequencer_top.png",
        "sequencer_bottom.png",
        "sequencer_side.png",
        "sequencer_side.png",
        "sequencer_side.png",
        "sequencer_front.png"
    },
    groups = {cracky = 2},
    paramtype2 = "facedir",

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Genome Sequencer"))
        local inv = meta:get_inventory()
        inv:set_size("input", 1)
        inv:set_size("output", 1)
    end,

    on_rightclick = function(pos, node, clicker)
        minetest.show_formspec(
            clicker:get_player_name(),
            "apocdna:genome_sequencer",
            apocdna.get_sequencer_formspec(pos)
        )
    end,

    on_timer = function(pos, elapsed)
        apocdna.run_sequencer_cycle(pos)
        return false
    end,
})

------------------------------------------------------------
-- SEQUENCING LOGIC
------------------------------------------------------------
function apocdna.sequence_dna(stack)
    if stack:is_empty() then
        return nil
    end

    local name = stack:get_name()
    local meta = stack:get_meta()

    local purity = meta:get_int("purity")
    local missing = meta:get_int("missing_segments")
    local species = meta:get_string("species_hint")

    if purity <= 0 then purity = math.random(20, 80) end
    if missing <= 0 then missing = math.random(1, 4) end

    --------------------------------------------------------
    -- SUCCESS CHANCE
    --------------------------------------------------------
    local base = purity
    local penalty = missing * 15
    local success_chance = math.max(10, base - penalty)

    local roll = math.random(1, 100)

    --------------------------------------------------------
    -- FAILURE → corrupted genome
    --------------------------------------------------------
    if roll > success_chance then
        local fail = ItemStack("apocdna:failed_genome")
        fail:get_meta():set_string("species", species)
        return fail
    end

    --------------------------------------------------------
    -- SUCCESS → completed genome
    --------------------------------------------------------
    local genome = ItemStack("apocdna:genome_complete")
    local gmeta = genome:get_meta()

    gmeta:set_string("species", species)
    gmeta:set_int("purity", purity)
    gmeta:set_int("mutation", math.random(0, 12))

    -- creature DNA needs more reconstruction
    if name:find("dna_creature_") then
        gmeta:set_string("type", "creature")
        gmeta:set_int("mutation", math.random(3, 18))
    else
        gmeta:set_string("type", "plant")
    end

    return genome
end

------------------------------------------------------------
-- RUN SEQUENCER CYCLE
------------------------------------------------------------
function apocdna.run_sequencer_cycle(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local input = inv:get_stack("input", 1)

    if input:is_empty() then
        return
    end

    local result = apocdna.sequence_dna(input)
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
-- OPTIONAL: punch to start processing
------------------------------------------------------------
minetest.register_on_punchnode(function(pos, node)
    if node.name ~= "apocdna:genome_sequencer" then
        return
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if not inv:get_stack("input", 1):is_empty() then
        minetest.get_node_timer(pos):start(3.0) -- 3s per cycle
    end
end)
