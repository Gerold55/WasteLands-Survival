-- ============================================================
--  Wastelands: Survival - Blacksmithing Items
--  Compatible with ws_buckets:metal_empty
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")

ws_blacksmith = ws_blacksmith or {}

-- ============================================================
--  SECTION 1: USE EXISTING EMPTY BUCKET
-- ============================================================

-- We DO NOT register ws_buckets:metal_empty here.
-- We simply reference it when needed.

local EMPTY_BUCKET = "ws_buckets:metal_empty"

-- ============================================================
--  SECTION 2: MOLTEN BUCKETS (AUTO-GENERATED)
-- ============================================================

-- Every metal gets a molten bucket:
--   ws_blacksmith:bucket_molten_<metal>
--
-- These buckets return ws_buckets:metal_empty when emptied.

for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_craftitem("ws_blacksmith:bucket_molten_" .. id, {
        description = S("Molten " .. def.name .. " Bucket"),
        inventory_image = "ws_bucket_molten_" .. id .. ".png",
        stack_max = 1,
        groups = {molten_bucket = 1},

        -- When used in crafting or forging, return empty bucket
        on_use = function(itemstack, user, pointed)
            return ItemStack(EMPTY_BUCKET)
        end,
    })
end

-- ============================================================
--  SECTION 3: CASTS (AUTO-GENERATED)
-- ============================================================

for id, def in pairs(ws_blacksmith.casts) do
    minetest.register_craftitem("ws_blacksmith:cast_" .. id, {
        description = S(def.name),
        inventory_image = "ws_cast_" .. id .. ".png",
        stack_max = 1,
        groups = {cast = 1},
    })
end

-- ============================================================
--  SECTION 4: FORGED ITEMS (AUTO-GENERATED)
-- ============================================================

for id, def in pairs(ws_blacksmith.casts) do
    minetest.register_craftitem(def.output, {
        description = S("Forged " .. def.id:gsub("^%l", string.upper)),
        inventory_image = "ws_forged_" .. def.id .. ".png",
        stack_max = 99,
        groups = {forged_item = 1},
    })
end

-- ============================================================
--  SECTION 5: BASIC METAL PRODUCTS
-- ============================================================

-- Ingots
for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_craftitem("ws_blacksmith:ingot_" .. id, {
        description = S(def.name .. " Ingot"),
        inventory_image = "ws_ingot_" .. id .. ".png",
        groups = {metal_ingot = 1},
    })
end

-- Plates
for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_craftitem("ws_blacksmith:plate_" .. id, {
        description = S(def.name .. " Plate"),
        inventory_image = "ws_plate_" .. id .. ".png",
        groups = {metal_plate = 1},
    })
end

-- Rods
for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_craftitem("ws_blacksmith:rod_" .. id, {
        description = S(def.name .. " Rod"),
        inventory_image = "ws_rod_" .. id .. ".png",
        groups = {metal_rod = 1},
    })
end

-- Tool blanks
for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_craftitem("ws_blacksmith:tool_blank_" .. id, {
        description = S(def.name .. " Tool Blank"),
        inventory_image = "ws_tool_blank_" .. id .. ".png",
        groups = {tool_blank = 1},
    })
end

-- ============================================================
--  SECTION 6: SCRAP ITEMS (WASTELAND STYLE)
-- ============================================================

local scrap_items = {
    {id="iron_scrap",   name="Iron Scrap"},
    {id="copper_scrap", name="Copper Scrap"},
    {id="tin_scrap",    name="Tin Scrap"},
    {id="steel_scrap",  name="Steel Scrap"},
    {id="mixed_scrap",  name="Mixed Metal Scrap"},
}

for _, s in ipairs(scrap_items) do
    minetest.register_craftitem("ws_blacksmith:" .. s.id, {
        description = S(s.name),
        inventory_image = "ws_" .. s.id .. ".png",
        groups = {scrap_metal = 1},
    })
end
