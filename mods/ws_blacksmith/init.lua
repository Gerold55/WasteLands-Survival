-- ============================================================
--  Wastelands: Survival - Blacksmithing Core
--  init.lua
--
--  This file loads the entire blacksmithing system:
--    - API (metals, casts, recipes, fluids)
--    - Items (scrap, ingots, rods, plates, buckets)
--    - Machines (melter, cooler, casting table, basin, anvil)
--    - Alloy mixer (advanced molten metal mixing)
--    - Molten bucket behavior (cooling, burning, puddles)
--
--  Everything is modular and expandable.
-- ============================================================

local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

ws_blacksmith = ws_blacksmith or {}

-- ============================================================
--  LOAD ORDER (IMPORTANT)
-- ============================================================

-- 1. API (must load first)
dofile(modpath .. "/api.lua")

-- 2. Items (depends on API)
dofile(modpath .. "/items.lua")

-- 3. Molten bucket behavior (depends on items)
dofile(modpath .. "/buckets.lua")

-- 4. Machines (depend on API + items)
dofile(modpath .. "/melter.lua")
dofile(modpath .. "/cooler.lua")
dofile(modpath .. "/casting_table.lua")
dofile(modpath .. "/casting_basin.lua")
dofile(modpath .. "/anvil.lua")

-- 5. Alloy mixer (depends on melter + API)
dofile(modpath .. "/alloy_mixer.lua")

-- ============================================================
--  LOGGING
-- ============================================================

minetest.log("action", "[Wastelands Blacksmithing] Loaded successfully.")

-- ============================================================
--  OPTIONAL: GLOBAL CHAT MESSAGE ON LOAD
-- ============================================================

minetest.register_on_mods_loaded(function()
    minetest.log("action", "[Wastelands Blacksmithing] Systems initialized.")
end)
