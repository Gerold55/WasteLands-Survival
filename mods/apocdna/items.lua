minetest.register_craftitem("apocdna:genome_fragment", {
    description = "Genome Fragment",
    inventory_image = "genome_fragment.png",
})

minetest.register_craftitem("apocdna:contaminated_sample", {
    description = "Contaminated Sample",
    inventory_image = "contaminated_sample.png",
})

minetest.register_craftitem("apocdna:failed_sample", {
    description = "Failed Sample",
    inventory_image = "failed_sample.png",
})

minetest.register_craftitem("apocdna:bone_shard", {
    description = "Bone Shard",
    inventory_image = "bone_shard.png",
})

minetest.register_craftitem("apocdna:relic_fragment", {
    description = "Relic Fragment",
    inventory_image = "relic_fragment.png",
})

minetest.register_craftitem("apocdna:dna_creature_unknown_creature", {
    description = "Unknown Creature DNA",
    inventory_image = "dna_creature.png",
})

minetest.register_craftitem("apocdna:fossil_common", {
    description = "Common Fossil",
    inventory_image = "fossil_common.png",
    groups = {fossil = 1},
})

minetest.register_craftitem("apocdna:fossil_animal", {
    description = "Animal Fossil",
    inventory_image = "fossil_animal.png",
    groups = {fossil = 1},
})

minetest.register_craftitem("apocdna:fossil_rare", {
    description = "Rare Fossil",
    inventory_image = "fossil_rare.png",
    groups = {fossil = 1},
})

minetest.register_craftitem("apocdna:memory_stick", {
    description = "Genome Memory Stick",
    inventory_image = "memory_stick_32.png",
})
