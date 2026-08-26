minetest.register_node("apocdna:genome_analyzer", {
    description = "Genome Analyzer",
    tiles = {"analyzer_top.png", "analyzer_bottom.png", "analyzer_side.png"},
    groups = {cracky = 2},
    paramtype2 = "facedir",
    on_rightclick = function(pos, node, clicker, itemstack)
        apocdna.open_analyzer_formspec(pos, clicker)
    end,
})

function apocdna.process_fragment(stack)
    local meta = stack:get_meta()
    local purity = meta:get_int("purity")

    if purity < 30 then
        return ItemStack("apocdna:contaminated_sample")
    end

    local species = meta:get_string("species_hint")
    return ItemStack("apocdna:dna_" .. species)
end

minetest.register_node("apocdna:genome_sequencer", {
    description = "Genome Sequencer",
    tiles = {"sequencer_top.png", "sequencer_bottom.png", "sequencer_side.png"},
    groups = {cracky = 2},
    on_rightclick = function(pos, node, clicker, itemstack)
        apocdna.open_sequencer_formspec(pos, clicker)
    end,
})

function apocdna.sequence_dna(stack)
    local meta = stack:get_meta()
    local missing = meta:get_int("missing_segments")
    local purity = meta:get_int("purity")

    local success_chance = purity + (100 - missing * 20)

    if math.random(1,100) <= success_chance then
        local new = ItemStack("apocdna:genome_complete")
        new:get_meta():set_string("species", meta:get_string("species_hint"))
        new:get_meta():set_int("mutation", math.random(0, 10))
        return new
    else
        return ItemStack("apocdna:failed_genome")
    end
end

minetest.register_node("apocdna:bio_printer", {
    description = "Bio-Printer",
    tiles = {"printer_top.png", "printer_bottom.png", "printer_side.png"},
    groups = {cracky = 2},
    on_rightclick = function(pos, node, clicker, itemstack)
        apocdna.open_printer_formspec(pos, clicker)
    end,
})

function apocdna.print_seed(stack)
    local meta = stack:get_meta()
    local species = meta:get_string("species")
    local mutation = meta:get_int("mutation")

    local seed = ItemStack("apocdna:seed_" .. species)

    if mutation > 5 then
        seed:get_meta():set_string("trait", "mutated")
    end

    return seed
end
