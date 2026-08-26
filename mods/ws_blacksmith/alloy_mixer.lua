-- ============================================================
--  Wastelands: Survival - Alloy Mixer
--  Features:
--    - Pull molten metals from melter
--    - Store multiple molten metals internally
--    - Mix metals into alloys
--    - Output molten alloy bucket
--    - API-driven alloy recipes
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")

ws_blacksmith = ws_blacksmith or {}

local EMPTY_BUCKET = "ws_buckets:metal_empty"

-- ============================================================
--  SECTION 1: ALLOY RECIPES
-- ============================================================
--  Format:
--    ws_blacksmith.register_alloy({
--        id = "steel",
--        name = "Steel",
--        output_bucket = "ws_blacksmith:bucket_molten_steel",
--        recipe = {
--            iron = 200,
--            carbon = 50,
--        }
--    })
-- ============================================================

ws_blacksmith.alloys = {}

function ws_blacksmith.register_alloy(def)
    assert(def.id, "Alloy must have an id")
    assert(def.recipe, "Alloy must define recipe amounts")
    assert(def.output_bucket, "Alloy must define output bucket")

    ws_blacksmith.alloys[def.id] = {
        id            = def.id,
        name          = def.name or def.id,
        recipe        = def.recipe,
        output_bucket = def.output_bucket,
    }
end

-- Example alloys
ws_blacksmith.register_alloy({
    id = "steel",
    name = "Steel",
    output_bucket = "ws_blacksmith:bucket_molten_steel",
    recipe = {
        iron = 200,
        carbon = 50,
    }
})

ws_blacksmith.register_alloy({
    id = "bronze",
    name = "Bronze",
    output_bucket = "ws_blacksmith:bucket_molten_bronze",
    recipe = {
        copper = 150,
        tin    = 50,
    }
})

ws_blacksmith.register_alloy({
    id = "brass",
    name = "Brass",
    output_bucket = "ws_blacksmith:bucket_molten_brass",
    recipe = {
        copper = 150,
        zinc   = 50,
    }
})

-- ============================================================
--  SECTION 2: ALLOY MIXER NODE
-- ============================================================

minetest.register_node("ws_blacksmith:alloy_mixer", {
    description = S("Alloy Mixer"),
    tiles = {
        "ws_alloy_mixer_top.png",
        "ws_alloy_mixer_bottom.png",
        "ws_alloy_mixer_side.png",
        "ws_alloy_mixer_side.png",
        "ws_alloy_mixer_side.png",
        "ws_alloy_mixer_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    -- --------------------------------------------------------
    --  On Construct
    -- --------------------------------------------------------
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Alloy Mixer (Idle)")

        -- Internal molten metal storage
        meta:set_string("fluids", minetest.serialize({}))

        local inv = meta:get_inventory()
        inv:set_size("bucket", 1)
        inv:set_size("output", 1)
    end,

    -- --------------------------------------------------------
    --  GUI
    -- --------------------------------------------------------
    get_formspec = function(pos)
        local meta = minetest.get_meta(pos)
        local fluids = ws_blacksmith.get_fluids(meta)

        local fluid_list = "None"
        if #fluids > 0 then
            local parts = {}
            for _, f in ipairs(fluids) do
                table.insert(parts, f.fluid .. " (" .. f.amount .. "mB)")
            end
            fluid_list = table.concat(parts, ", ")
        end

        return
            "size[12,9]" ..
            "background[0,0;12,9;ws_alloy_mixer_gui.png]" ..

            "label[0.2,0.2;Alloy Mixer]" ..
            "label[0.2,1.0;Stored Fluids: " .. fluid_list .. "]" ..

            "label[0.2,2.0;Molten Bucket]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";bucket;0.2,2.3;1,1;]" ..

            "label[2.0,2.0;Output]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";output;2.0,2.3;1,1;]" ..

            "button[0.2,4.0;3,1;pull;Pull Metal]" ..
            "button[3.5,4.0;3,1;mix;Mix Alloy]" ..

            "list[current_player;main;2,6;8,3;]"
    end,

    -- --------------------------------------------------------
    --  Button Handler
    -- --------------------------------------------------------
    on_receive_fields = function(pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()

        local name = player:get_player_name()

        -- ----------------------------------------------------
        --  PULL METAL FROM MELTER
        -- ----------------------------------------------------
        if fields.pull then
            local dirs = {
                {x=1,y=0,z=0},
                {x=-1,y=0,z=0},
                {x=0,y=0,z=1},
                {x=0,y=0,z=-1},
            }

            local melter_pos = nil
            for _, d in ipairs(dirs) do
                local p = vector.add(pos, d)
                if minetest.get_node(p).name:find("melter") then
                    melter_pos = p
                    break
                end
            end

            if not melter_pos then
                minetest.chat_send_player(name, "Alloy mixer must be next to a melter.")
                return
            end

            local melter_meta = minetest.get_meta(melter_pos)
            local fluids = ws_blacksmith.get_fluids(melter_meta)

            if #fluids == 0 then
                minetest.chat_send_player(name, "Melter tank is empty.")
                return
            end

            local fluid = fluids[1].fluid

            -- Add fluid to mixer
            ws_blacksmith.add_fluid(meta, fluid, 100)

            -- Remove fluid from melter
            ws_blacksmith.remove_fluid(melter_meta, fluid, 100)

            minetest.chat_send_player(name, "Pulled 100mB of "..fluid.." into alloy mixer.")
            return
        end

        -- ----------------------------------------------------
        --  MIX ALLOY
        -- ----------------------------------------------------
        if fields.mix then
            local fluids = ws_blacksmith.get_fluids(meta)

            if #fluids == 0 then
                minetest.chat_send_player(name, "Mixer is empty.")
                return
            end

            -- Try every alloy recipe
            for alloy_id, alloy_def in pairs(ws_blacksmith.alloys) do
                local can_make = true

                -- Check if mixer has required fluids
                for metal, amt in pairs(alloy_def.recipe) do
                    local found = false
                    for _, f in ipairs(fluids) do
                        if f.fluid == metal and f.amount >= amt then
                            found = true
                            break
                        end
                    end
                    if not found then
                        can_make = false
                        break
                    end
                end

                if can_make then
                    -- Consume ingredients
                    for metal, amt in pairs(alloy_def.recipe) do
                        ws_blacksmith.remove_fluid(meta, metal, amt)
                    end

                    -- Output molten alloy bucket
                    inv:set_stack("output", 1, ItemStack(alloy_def.output_bucket))

                    minetest.chat_send_player(name, "Created alloy: "..alloy_def.name)
                    return
                end
            end

            minetest.chat_send_player(name, "No valid alloy recipe found with current fluids.")
        end
    end,
})
