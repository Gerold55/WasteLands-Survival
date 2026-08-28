return {
    wood = {
        id = "wood",
        section = "basics",
        title = "Collect Wood",
        icon = "ws_log_dead.png",
        desc = "Punch a tree to gather wood.",
        order = 1,
        tasks = {
            { id = "ws_core:log_oak_dry", name = "Wood", count = 8, icon = "ws_log_dead.png" },
        },
    },

    workbench = {
        id = "workbench",
        section = "basics",
        title = "Craft a Workbench",
        icon = "default_workbench.png",
        desc = "Use wood to craft a workbench.",
        order = 2,
        tasks = {
            { id = "default:workbench", name = "Workbench", count = 1, icon = "default_workbench.png" },
        },
    },
}
