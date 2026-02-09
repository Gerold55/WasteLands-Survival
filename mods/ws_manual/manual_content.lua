-- ws_manual/manual_content.lua
local content = {}

-- Core survival topics (always present) — sample page uses images and items
content.core = {
    {
        title = "Introduction",
        body = table.concat({
            "This Manual collects practical instructions for surviving in Wastelands Survival.",
            "Use it as your quick reference for crafting, blacksmithing, lab equipment, and safety.",
            "",
            "Tip: Keep the manual in your hotbar for quick access (or use /manual to open it)."
        }, "\n"),
        images = { "ws_manual/textures/manual_cover.png" }, -- optional
    },
    {
        title = "Basic Survival",
        body = table.concat({
            "1) Water: Boil or purify before drinking. Look for supply caches in ruined kitchens.",
            "2) Food: Canned goods last. Cook meat to avoid infection from mutated fauna.",
            "3) Shelter: Reinforce the vault door panels with scrap metal to reduce radiation seep.",
            "",
            "If you find a 'campfire' node, you can craft a simple cooking grate to prepare meals."
        }, "\n"),
        -- show the campfire node inventory image (uses registered item name)
        items = { "fire:basic_flame", "default:torch" },
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

-- DNA analyzer guide (show if mod present)
content.dna = {
    title = "DNA Analyzer (ws_lab)",
    body = table.concat({
        "The DNA Analyzer decodes biological samples to reveal mutations and potential uses.",
        "",
        "Workflow:",
        "1) Collect sample -> Sample Vial",
        "2) At DNA Analyzer, insert vial -> wait for analysis",
        "3) Extract data -> recipe/blueprint unlock or mutation log entry",
    }, "\n"),
    items = { "ws_lab:analyzer", "ws_lab:sample_vial" }
}

-- Misc / mod-agnostic quick recipes
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
