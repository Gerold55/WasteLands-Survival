-- ============================================================
--  WS Blacksmith - WASTELAND MELTER (Multi-Fluid Tank)
-- ============================================================

local CAPACITY   = 1800      -- Total tank capacity (mB)
local INGOT_MB   = 100       -- 1 ingot = 100 mB
local MELT_STEPS = 4         -- Steps to fully melt one item

ws_blacksmith          = ws_blacksmith or {}
ws_blacksmith.recipes  = ws_blacksmith.recipes or {}
ws_blacksmith.recipes.melter = ws_blacksmith.recipes.melter or {}

-- ------------------------------------------------------------
--  MELTING RECIPES (add more as needed)
-- ------------------------------------------------------------
ws_blacksmith.recipes.melter["ws_core:iron_lump"]   = {fluid="iron",   amount=INGOT_MB}
ws_blacksmith.recipes.melter["ws_core:copper_lump"] = {fluid="copper", amount=INGOT_MB}
ws_blacksmith.recipes.melter["ws_core:tin_lump"]    = {fluid="tin",    amount=INGOT_MB}

-- ============================================================
--  NODE: Wasteland Melter
-- ============================================================
minetest.register_node("ws_blacksmith:wasteland_melter", {
    description = "Wasteland Melter",
    tiles = {
        "ws_waste_melter_top.png",
        "ws_waste_melter_bottom.png",
        "ws_waste_melter_side.png",
        "ws_waste_melter_side.png",
        "ws_waste_melter_side.png",
        "ws_waste_melter_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    -- --------------------------------------------------------
    --  On Construct
    -- --------------------------------------------------------
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Wasteland Melter (Idle)")

        -- Multi-fluid tank: list of {fluid=string, amount=int}
        meta:set_string("fluids", minetest.serialize({}))

        -- Per-slot progress
        meta:set_int("progress_1", 0)
        meta:set_int("progress_2", 0)
        meta:set_int("progress_3", 0)

        local inv = meta:get_inventory()
        inv:set_size("input", 3)
        inv:set_size("output", 3)
    end,

    -- --------------------------------------------------------
    --  Can Dig
    -- --------------------------------------------------------
    can_dig = function(pos)
        local inv = minetest.get_meta(pos):get_inventory()
        return inv:is_empty("input") and inv:is_empty("output")
    end,

    -- ============================================================
    --  FORMSPEC (Wasteland GUI, multi-fluid tank)
    -- ============================================================
    get_formspec = function(pos)
        local meta   = minetest.get_meta(pos)
        local fluids = minetest.deserialize(meta:get_string("fluids")) or {}

        -- --------------------------------------------------------
        --  WASTELAND UI COORDINATES (TWEAK THESE FREELY)
        -- --------------------------------------------------------

        -- Input slots (right side)
        local SLOT_X  = 2.2
        local SLOT_Y1 = 1.2
        local SLOT_Y2 = 2.4
        local SLOT_Y3 = 3.6

        -- Heat bars (left of slots)
        local BAR_X = SLOT_X - 0.55
        local BAR_W = 0.45
        local BAR_H = 3.0

        -- Tank (center)
        local TANK_X = 5.0
        local TANK_Y = 1.0
        local TANK_W = 2.2
        local TANK_H = 4.2

        -- Output slots (bottom center)
        local OUT_X = 5.0
        local OUT_Y = 6.5

        -- Player inventory
        local INV_X = 2.0
        local INV_Y = 7.5

        -- Progress per slot → bar height
        local p1 = meta:get_int("progress_1")
        local p2 = meta:get_int("progress_2")
        local p3 = meta:get_int("progress_3")

        local h1 = (p1 / MELT_STEPS) * BAR_H
        local h2 = (p2 / MELT_STEPS) * BAR_H
        local h3 = (p3 / MELT_STEPS) * BAR_H

        -- --------------------------------------------------------
        --  Build tank fluid layers (multi-metal)
        -- --------------------------------------------------------
        local tank_layers = ""
        local total_amount = 0
        for _, f in ipairs(fluids) do
            total_amount = total_amount + f.amount
        end

        local current_y = TANK_Y + TANK_H

        for _, f in ipairs(fluids) do
            local h = 0
            if total_amount > 0 then
                h = TANK_H * (f.amount / CAPACITY)
            end

            if h > 0.01 then
                current_y = current_y - h
                tank_layers = tank_layers ..
                    "image["..TANK_X..","..current_y..";"..TANK_W..","..h..";ws_fluid_"..f.fluid..".png]"
            end
        end

        -- --------------------------------------------------------
        --  Fluid status label
        -- --------------------------------------------------------
        local status = "Fluids: "
        if #fluids == 0 then
            status = status .. "None (0 mB)"
        else
            local parts = {}
            for _, f in ipairs(fluids) do
                table.insert(parts, f.fluid .. " " .. f.amount .. "mB")
            end
            status = status .. table.concat(parts, ", ")
        end

        -- --------------------------------------------------------
        --  Formspect string
        -- --------------------------------------------------------
        return
            "size[12,10]" ..
            "background[0,0;12,10;wasteland_melter_gui.png]" ..

            "label[0.2,0.2;" .. minetest.formspec_escape(status) .. "]" ..

            -- Input slots (right)
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";input;"..SLOT_X..","..SLOT_Y1..";1,1;0]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";input;"..SLOT_X..","..SLOT_Y2..";1,1;1]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";input;"..SLOT_X..","..SLOT_Y3..";1,1;2]" ..

            -- Heat bars (left of slots)
            "image["..BAR_X..","..SLOT_Y1..";"..BAR_W..","..BAR_H..";ws_waste_bar_bg.png]" ..
            "image["..BAR_X..","..(SLOT_Y1 + (BAR_H - h1))..";"..BAR_W..","..h1..";ws_waste_bar_fill.png]" ..

            "image["..BAR_X..","..SLOT_Y2..";"..BAR_W..","..BAR_H..";ws_waste_bar_bg.png]" ..
            "image["..BAR_X..","..(SLOT_Y2 + (BAR_H - h2))..";"..BAR_W..","..h2..";ws_waste_bar_fill.png]" ..

            "image["..BAR_X..","..SLOT_Y3..";"..BAR_W..","..BAR_H..";ws_waste_bar_bg.png]" ..
            "image["..BAR_X..","..(SLOT_Y3 + (BAR_H - h3))..";"..BAR_W..","..h3..";ws_waste_bar_fill.png]" ..

            -- Tank background + layers + overlay
            "image["..TANK_X..","..TANK_Y..";"..TANK_W..","..TANK_H..";ws_waste_tank_bg.png]" ..
            tank_layers ..
            "image["..TANK_X..","..TANK_Y..";"..TANK_W..","..TANK_H..";ws_tank_overlay.png]" ..

            -- Output slots
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";output;"..OUT_X..","..OUT_Y..";3,1;]" ..

            -- Player inventory
            "list[current_player;main;"..INV_X..","..INV_Y..";8,4;]" ..
            "listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";input]" ..
            "listring[current_player;main]"
    end,

    -- --------------------------------------------------------
    --  Right-click to open GUI
    -- --------------------------------------------------------
    on_rightclick = function(pos, node, clicker)
        local formspec = minetest.registered_nodes[node.name].get_formspec(pos)
        minetest.show_formspec(clicker:get_player_name(), "ws_blacksmith:wasteland_melter", formspec)
    end,

    -- ============================================================
    --  MELTING LOGIC (Heater-powered, multi-fluid tank)
    -- ============================================================
    on_timer = function(pos)
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()

        -- Heater below
        local below       = {x=pos.x, y=pos.y-1, z=pos.z}
        local node_below  = minetest.get_node(below)

        if node_below.name ~= "ws_blacksmith:heater" then
            meta:set_string("infotext", "Wasteland Melter (Needs Heater)")
            return true
        end

        local hmeta = minetest.get_meta(below)
        local burn  = hmeta:get_int("burn")

        if burn <= 0 then
            meta:set_string("infotext", "Wasteland Melter (Heater Empty)")
            return true
        end

        local fluids = minetest.deserialize(meta:get_string("fluids")) or {}

        -- Helper: total amount in tank
        local function total_amount()
            local sum = 0
            for _, f in ipairs(fluids) do
                sum = sum + f.amount
            end
            return sum
        end

        -- Process each input slot
        for i = 1, 3 do
            local stack = inv:get_stack("input", i)
            local pkey  = "progress_" .. i

            if not stack:is_empty() then
                local item   = stack:get_name()
                local recipe = ws_blacksmith.recipes.melter[item]

                if not recipe then
                    meta:set_string("infotext", "Cannot melt this scrap")
                    return true
                end

                -- Capacity check
                if total_amount() + recipe.amount > CAPACITY then
                    meta:set_string("infotext", "Tank Overflow")
                    return true
                end

                -- Progress
                local progress = meta:get_int(pkey) + 1
                meta:set_int(pkey, progress)

                if progress < MELT_STEPS then
                    return true
                end

                -- Finished melting
                inv:set_stack("input", i, nil)
                meta:set_int(pkey, 0)

                -- Add fluid to tank (multi-layer)
                local found = false
                for _, f in ipairs(fluids) do
                    if f.fluid == recipe.fluid then
                        f.amount = f.amount + recipe.amount
                        found = true
                        break
                    end
                end

                if not found then
                    table.insert(fluids, {fluid = recipe.fluid, amount = recipe.amount})
                end

                meta:set_string("fluids", minetest.serialize(fluids))
                meta:set_string("infotext", "Wasteland Melter (Tank: "..total_amount().." mB)")
                return true
            else
                meta:set_int(pkey, 0)
            end
        end

        return true
    end,
})
