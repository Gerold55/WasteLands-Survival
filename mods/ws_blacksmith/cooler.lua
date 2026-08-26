-- ============================================================
--  Wastelands: Survival - Cooler / Pump
--  Features:
--    - Pulls molten metal from melter
--    - Pushes molten metal into casting table or basin
--    - Can fill molten buckets
--    - API-driven fluid routing
--    - Wasteland-style machine
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")

ws_blacksmith = ws_blacksmith or {}

local EMPTY_BUCKET = "ws_buckets:metal_empty"

-- ============================================================
--  SETTINGS
-- ============================================================

local TRANSFER_AMOUNT = 100   -- mB per operation (1 ingot)
local TICK_TIME       = 1     -- seconds between operations

-- ============================================================
--  HELPER: Find adjacent node
-- ============================================================

local function get_adjacent_node(pos)
    local dirs = {
        {x=1, y=0, z=0},
        {x=-1, y=0, z=0},
        {x=0, y=0, z=1},
        {x=0, y=0, z=-1},
    }

    for _, d in ipairs(dirs) do
        local p = vector.add(pos, d)
        local node = minetest.get_node(p)
        if node and node.name then
            return node.name, p
        end
    end

    return nil, nil
end

-- ============================================================
--  COOLER NODE
-- ============================================================

minetest.register_node("ws_blacksmith:cooler", {
    description = S("Molten Metal Cooler"),
    tiles = {
        "ws_cooler_top.png",
        "ws_cooler_bottom.png",
        "ws_cooler_side.png",
        "ws_cooler_side.png",
        "ws_cooler_side.png",
        "ws_cooler_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    -- --------------------------------------------------------
    --  On Construct
    -- --------------------------------------------------------
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Cooler (Idle)")

        local inv = meta:get_inventory()
        inv:set_size("bucket", 1)
    end,

    -- --------------------------------------------------------
    --  GUI
    -- --------------------------------------------------------
    get_formspec = function(pos)
        return
            "size[8,6]" ..
            "background[0,0;8,6;ws_cooler_gui.png]" ..

            "label[0.2,0.2;Cooler / Pump]" ..

            "label[0.2,1.0;Bucket]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";bucket;0.2,1.3;1,1;]" ..

            "button[0.2,3.0;3,1;pull;Pull Metal]" ..
            "button[3.5,3.0;3,1;push;Push Metal]" ..

            "list[current_player;main;0.5,4;8,2;]"
    end,

    -- --------------------------------------------------------
    --  Button Handler
    -- --------------------------------------------------------
    on_receive_fields = function(pos, formname, fields, player)
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()

        local node_name, node_pos = get_adjacent_node(pos)
        if not node_name then
            minetest.chat_send_player(player:get_player_name(), "No machine connected.")
            return
        end

        -- ----------------------------------------------------
        --  PULL METAL FROM MELTER
        -- ----------------------------------------------------
        if fields.pull then
            if not node_name:find("melter") then
                minetest.chat_send_player(player:get_player_name(), "Cooler must be next to a melter.")
                return
            end

            local melter_meta = minetest.get_meta(node_pos)
            local fluids = ws_blacksmith.get_fluids(melter_meta)

            if #fluids == 0 then
                minetest.chat_send_player(player:get_player_name(), "Melter tank is empty.")
                return
            end

            local fluid = fluids[1].fluid

            -- Fill bucket
            inv:set_stack("bucket", 1, ItemStack("ws_blacksmith:bucket_molten_" .. fluid))

            -- Remove fluid from melter
            ws_blacksmith.remove_fluid(melter_meta, fluid, TRANSFER_AMOUNT)

            minetest.chat_send_player(player:get_player_name(), "Pulled "..TRANSFER_AMOUNT.." mB of "..fluid..".")
            return
        end

        -- ----------------------------------------------------
        --  PUSH METAL INTO CASTING MACHINE
        -- ----------------------------------------------------
        if fields.push then
            local bucket_stack = inv:get_stack("bucket", 1)
            if bucket_stack:is_empty() then
                minetest.chat_send_player(player:get_player_name(), "Insert molten bucket first.")
                return
            end

            local bucket_name = bucket_stack:get_name()
            local fluid_id = bucket_name:gsub("ws_blacksmith:bucket_molten_", "")

            -- Casting Table
            if node_name == "ws_blacksmith:casting_table" then
                local cast_inv = minetest.get_meta(node_pos):get_inventory()
                if cast_inv:is_empty("cast") then
                    minetest.chat_send_player(player:get_player_name(), "Casting table needs a cast.")
                    return
                end

                -- Fill casting table bucket slot
                cast_inv:set_stack("bucket", 1, bucket_stack)
                inv:set_stack("bucket", 1, ItemStack(EMPTY_BUCKET))

                minetest.chat_send_player(player:get_player_name(), "Pushed molten "..fluid_id.." into casting table.")
                return
            end

            -- Casting Basin
            if node_name == "ws_blacksmith:casting_basin" then
                local cast_inv = minetest.get_meta(node_pos):get_inventory()
                if cast_inv:is_empty("cast") then
                    minetest.chat_send_player(player:get_player_name(), "Casting basin needs a large cast.")
                    return
                end

                -- Fill basin bucket slot
                cast_inv:set_stack("bucket", 1, bucket_stack)
                inv:set_stack("bucket", 1, ItemStack(EMPTY_BUCKET))

                minetest.chat_send_player(player:get_player_name(), "Pushed molten "..fluid_id.." into casting basin.")
                return
            end

            minetest.chat_send_player(player:get_player_name(), "Connected machine cannot accept molten metal.")
        end
    end,
})
