-- ws_manual/manual_content.lua
local content = {}

-- Front cover (always first)
content.cover = {
    title = "Wastelands Survival Manual",
    body = table.concat({
        "A field guide for survivors of the post‑apocalyptic frontier.",
        "",
        "Compiled by the Wastelands Engineering Corps.",
        "Includes crafting, blacksmithing, and genetic research protocols.",
        "",
        "Press 'Next' to begin your training."
    }, "\n"),
    images = { "ws_manual/textures/manual_cover_art.png" } -- new front cover texture
}

-- Core survival topics (always present)
content.core = {
    {
        title = "Introduction",
        body = table.concat({
            "This Manual collects practical instructions for surviving in Wastelands Survival.",
            "Use it as your quick reference for crafting, blacksmithing, lab equipment, and safety.",
            "",
            "Tip: Keep the manual in your hotbar for quick access (or use /manual to open it)."
        }, "\n"),
        images = { "ws_manual/textures/manual_cover.png" },
    },
    {
    title = "Basic Survival",
    body = table.concat({
        "Water:",
        "Boil or purify before drinking. Early on, craft a Filter Straw to safely drink from lakes or the ocean.",
        "Later, build a Dew Collector to generate small amounts of clean water each morning.",
        "",
        "Food:",
        "Canned goods last the longest. Cook meat to avoid infection from mutated fauna.",
        "",
        "Shelter:",
        "Reinforce vault door panels with scrap metal to reduce radiation seep.",
        "",
        "Tip:",
        "If you find a 'campfire' node, you can craft a simple cooking grate to prepare meals."
    }, "\n"),
    items = {
        "ws_survival:filter_straw",
        "ws_survival:dew_collector",
        "fire:basic_flame",
        "ws_core:torch"
    },
}
}

-- Blacksmithing guide (show if mod present)
content.blacksmithing = {
    title = "Blacksmithing (ws_blacksmith)",
    body = table.concat({
        "Blacksmithing lets you repair, upgrade and craft metal tools and armor.",
        "",
        "Core stations:",
        "- Forge: Smelts scrap into ingots (requires fuel: coal/charcoal).",
        "- Anvil: Combine ingots and blueprints to craft upgrades.",
        "",
        "Usage tips:",
        "- Bring extra fuel and a hammer when visiting the anvil.",
    }, "\n"),
    images = { "ws_manual/textures/forge_example.png" }
}

-- DNA Analyzer guide
content.dna = {
    title = "DNA Analyzer (apocdna)",
    body = table.concat({
        "The DNA Analyzer processes biological samples and extracts usable genetic information.",
        "",
        "Workflow:",
        "1) Collect organic material and store it in a Sample Vial.",
        "2) Insert the vial into the DNA Analyzer and allow the scan to complete.",
        "3) Retrieve the decoded data to unlock mutations, traits, or restoration blueprints.",
    }, "\n"),
    items = { "apocdna:genome_analyzer", "apocdna:sample_vial" }
}

-- Quick recipes
content.recipes = {
    title = "Quick Crafting Recipes",
    body = table.concat({
        "- Bandage: Cloth x2 -> Bandage (healing over time)",
        "- Filter: Fabric + Charcoal -> Gas Filter (reduces toxic damage)",
        "- Repair Kit: Scrap + Glue -> Repair Kit (used at workbench to restore item durability)"
    }, "\n"),
    images = { "ws_manual/textures/recipes_panel.png" }
}

return content
