-- apocdna/genome_analyzer.lua

apocdna = apocdna or {}

local S = minetest.get_translator and minetest.get_translator("apocdna") or function(s) return s end

------------------------------------------------------------
-- FORMSPEC
------------------------------------------------------------
function apocdna.get_analyzer_formspec(pos)
    return "size[8,8]" ..
        "label[0,0;" .. S("Genome Analyzer") .. "]" ..
        "list[current_name;input;1,1;1,1;]" ..
        "list[current_name;output;5,1;2,1;]" ..
        "image[3,1;1,1;analyzer_progress.png]" ..
        "label[1,2;" .. S("Input") .. "]" ..
        "label[5,2;" .. S("Output") .. "]" ..
        "list[current_player;main;0,4;8,4;]"
end

------------------------------------------------------------
-- NODE DEFINITION
------------------------------------------------------------
minetest.register_node("apocdna:genome_analyzer", {
    description = S("Genome Analyzer"),
    tiles = {
        "analyzer_top.png",
        "analyzer_bottom.png",
        "analyzer_side.png",
        "analyzer_side.png",
        "analyzer_side.png",
        "analyzer_front.png"
    },
    groups = {cracky = 2},
    paramtype2 = "facedir",

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Genome Analyzer"))
        local inv = meta:get_inventory()
        inv:set_size("input", 1)
        inv:set_size("output", 2)
    end,

    on_rightclick = function(pos, node, clicker)
        minetest.show_formspec(
            clicker:get_player_name(),
            "apocdna:genome_analyzer",
            apocdna.get_analyzer_formspec(pos)
        )
    end,

    on_timer = function(pos, elapsed)
        apocdna.run_analyzer_cycle(pos)
        return false
    end,
})

------------------------------------------------------------
-- PROCESSING LOGIC
------------------------------------------------------------
function apocdna.process_fragment(stack)
    if stack:is_empty() then
        return nil
    end

    local name = stack:get_name()
    local meta = stack:get_meta()
    local purity = meta:get_int("purity")
    local species_hint = meta:get_string("species_hint")

    -- fallback metadata
    if purity <= 0 then
        purity = math.random(20, 80)
        meta:set_int("purity", purity)
    end

    --------------------------------------------------------
    -- GENOME FRAGMENTS (plants, crops, trees)
    --------------------------------------------------------
    if name == "apocdna:genome_fragment" then
        if purity < 30 then
            return ItemStack("apocdna:contaminated_sample")
        end

        if species_hint == "" then
            return ItemStack("apocdna:failed_sample")
        end

        local dna = ItemStack("apocdna:dna_" .. species_hint)
        local dmeta = dna:get_meta()
        dmeta:set_int("purity", purity)
        dmeta:set_int("missing_segments", math.random(1, 4))
        dmeta:set_string("species_hint", species_hint)
        return dna
    end

    --------------------------------------------------------
    -- FOSSILS (animals, extinct creatures)
    --------------------------------------------------------
    if stack:get_group("fossil") == 1 then

        -- low purity → bone shards
        if purity < 25 then
            return ItemStack("apocdna:bone_shard")
        end

        -- mid purity → relics or junk
        if purity < 45 then
            local roll = math.random(1, 100)
            if roll < 50 then
                return ItemStack("apocdna:relic_fragment")
            else
                return ItemStack("apocdna:failed_sample")
            end
        end

        -- high purity → creature DNA
        if species_hint == "" then
            species_hint = "unknown_creature"
        end

        local dna = ItemStack("apocdna:dna_creature_" .. species_hint)
        local dmeta = dna:get_meta()
        dmeta:set_int("purity", purity)
        dmeta:set_int("missing_segments", math.random(2, 6))
        dmeta:set_string("species_hint", species_hint)
        return dna
    end

    --------------------------------------------------------
    -- fallback
    --------------------------------------------------------
    return ItemStack("apocdna:failed_sample")
end

------------------------------------------------------------
-- RUN ANALYZER CYCLE
------------------------------------------------------------
function apocdna.run_analyzer_cycle(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local input = inv:get_stack("input", 1)

    if input:is_empty() then
        return
    end

    local result = apocdna.process_fragment(input)
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
    if node.name ~= "apocdna:genome_analyzer" then
        return
    end
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    if not inv:get_stack("input", 1):is_empty() then
        minetest.get_node_timer(pos):start(2.0)
    end
end)
