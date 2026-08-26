-- ============================================================
--  Wastelands: Survival - Blacksmithing API
--  Author: Brandon & Copilot
--  Purpose:
--    - Provide a stable, easy-to-use API for all blacksmithing
--      systems: melter, cooler, anvil, casting, alloys, etc.
--    - Allow modders to add new metals, casts, and recipes
--      without touching core code.
-- ============================================================

ws_blacksmith = ws_blacksmith or {}

-- ============================================================
--  SECTION 1: METAL DEFINITIONS
-- ============================================================
--  Each metal has:
--    id        = "iron"
--    name      = "Iron"
--    color     = "#d8d8d8" (optional)
--    bucket    = "ws_bucket_molten_iron"
--    fluid_tex = "ws_fluid_iron.png"
--    amount    = 100 (mB per ingot)
-- ============================================================

ws_blacksmith.metals = {}

function ws_blacksmith.register_metal(def)
    assert(def.id, "Metal must have an id")
    assert(def.name, "Metal must have a name")
    assert(def.fluid_tex, "Metal must have a fluid texture")

    ws_blacksmith.metals[def.id] = {
        id        = def.id,
        name      = def.name,
        color     = def.color or "#ffffff",
        bucket    = def.bucket or ("ws_bucket_molten_" .. def.id),
        fluid_tex = def.fluid_tex,
        amount    = def.amount or 100,
    }
end

-- Example metals (you can add more in other mods)
ws_blacksmith.register_metal({
    id        = "iron",
    name      = "Iron",
    fluid_tex = "ws_fluid_iron.png",
})

ws_blacksmith.register_metal({
    id        = "copper",
    name      = "Copper",
    fluid_tex = "ws_fluid_copper.png",
})

ws_blacksmith.register_metal({
    id        = "tin",
    name      = "Tin",
    fluid_tex = "ws_fluid_tin.png",
})

-- ============================================================
--  SECTION 2: MELTING RECIPES
-- ============================================================
--  scrap → molten metal
-- ============================================================

ws_blacksmith.melt_recipes = {}

function ws_blacksmith.register_melt_recipe(item, fluid, amount)
    ws_blacksmith.melt_recipes[item] = {
        fluid  = fluid,
        amount = amount or ws_blacksmith.metals[fluid].amount,
    }
end

-- Example:
-- ws_blacksmith.register_melt_recipe("default:iron_lump", "iron", 100)

-- ============================================================
--  SECTION 3: CAST DEFINITIONS
-- ============================================================
--  Casts define what molten metal can become:
--    id        = "ingot"
--    name      = "Ingot Cast"
--    output    = "ws_ingot_iron"
--    amount    = 100 (mB required)
-- ============================================================

ws_blacksmith.casts = {}

function ws_blacksmith.register_cast(def)
    assert(def.id, "Cast must have an id")
    assert(def.output, "Cast must define an output item")

    ws_blacksmith.casts[def.id] = {
        id     = def.id,
        name   = def.name or (def.id .. " Cast"),
        output = def.output,
        amount = def.amount or 100,
    }
end

-- Example:
-- ws_blacksmith.register_cast({
--     id     = "ingot",
--     output = "ws_ingot_iron",
--     amount = 100,
-- })

-- ============================================================
--  SECTION 4: FLUID TANK API
-- ============================================================
--  Used by melter, cooler, casting table, basin, etc.
-- ============================================================

-- Get fluid layers
function ws_blacksmith.get_fluids(meta)
    return minetest.deserialize(meta:get_string("fluids")) or {}
end

-- Save fluid layers
function ws_blacksmith.set_fluids(meta, fluids)
    meta:set_string("fluids", minetest.serialize(fluids))
end

-- Add fluid to tank
function ws_blacksmith.add_fluid(meta, fluid, amount)
    local fluids = ws_blacksmith.get_fluids(meta)

    for _, f in ipairs(fluids) do
        if f.fluid == fluid then
            f.amount = f.amount + amount
            ws_blacksmith.set_fluids(meta, fluids)
            return true
        end
    end

    table.insert(fluids, {fluid = fluid, amount = amount})
    ws_blacksmith.set_fluids(meta, fluids)
    return true
end

-- Remove fluid from tank
function ws_blacksmith.remove_fluid(meta, fluid, amount)
    local fluids = ws_blacksmith.get_fluids(meta)

    for i, f in ipairs(fluids) do
        if f.fluid == fluid and f.amount >= amount then
            f.amount = f.amount - amount

            if f.amount <= 0 then
                table.remove(fluids, i)
            end

            ws_blacksmith.set_fluids(meta, fluids)
            return true
        end
    end

    return false
end

-- Total fluid amount
function ws_blacksmith.total_fluid(meta)
    local fluids = ws_blacksmith.get_fluids(meta)
    local sum = 0
    for _, f in ipairs(fluids) do sum = sum + f.amount end
    return sum
end

-- ============================================================
--  SECTION 5: FORGING API (Anvil)
-- ============================================================
--  Used by the anvil to forge items from molten buckets + casts
-- ============================================================

-- Validate forging attempt
function ws_blacksmith.can_forge(bucket_fluid, cast_id)
    local cast = ws_blacksmith.casts[cast_id]
    if not cast then return false end

    -- Cast requires a specific amount of molten metal
    if not ws_blacksmith.metals[bucket_fluid] then
        return false
    end

    return true
end

-- Perform forging
function ws_blacksmith.forge_item(bucket_fluid, cast_id)
    local cast = ws_blacksmith.casts[cast_id]
    if not cast then return nil end

    -- Output item depends on cast
    return cast.output
end

-- ============================================================
--  SECTION 6: BUCKET API
-- ============================================================
--  Convert molten metal → bucket and back
-- ============================================================

function ws_blacksmith.fill_bucket(fluid)
    return "ws_bucket_molten_" .. fluid
end

function ws_blacksmith.empty_bucket()
    return "ws_bucket_empty"
end

-- ============================================================
--  SECTION 7: MACHINE COMPATIBILITY
-- ============================================================
--  Allows cooler/pump/casting table/basin to pull molten metal
-- ============================================================

function ws_blacksmith.pull_fluid_from_node(pos, fluid, amount)
    local meta = minetest.get_meta(pos)
    return ws_blacksmith.remove_fluid(meta, fluid, amount)
end

function ws_blacksmith.push_fluid_to_node(pos, fluid, amount)
    local meta = minetest.get_meta(pos)
    return ws_blacksmith.add_fluid(meta, fluid, amount)
end
