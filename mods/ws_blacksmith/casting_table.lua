-- ============================================================
--  Wastelands: Survival - Casting Table
--  Features:
--    - Cast slot
--    - Molten bucket slot
--    - Output slot
--    - API-driven casting logic
--    - Wasteland-style machine
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")

ws_blacksmith = ws_blacksmith or {}

local EMPTY_BUCKET = "ws_buckets:metal_empty"

-- ============================================================
--  CASTING TABLE NODE
-- ============================================================

minetest.register_node("ws_blacksmith:casting_table", {
    description = S("Casting Table"),
    tiles = {
        "ws_casting_table_top.png",
        "ws_casting_table_bottom.png",
        "ws_casting_table_side.png",
        "ws_casting_table_side.png",
        "ws_casting_table_side.png",
        "ws_casting_table_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    -- --------------------------------------------------------
    --  On Construct
    -- --------------------------------------------------------
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Casting Table (Idle)")

        local inv = meta:get_inventory()
        inv:set_size("cast", 1)
        inv:set_size("bucket", 1)
        inv:set_size("output", 1)
    end,

    -- --------------------------------------------------------
    --  GUI
    -- --------------------------------------------------------
    get_formspec = function(pos)
        return
            "size[10,8]" ..
            "background[0,0;10,8;ws_casting_table_gui.png]" ..

            "label[0.2,0.2;Casting Table]" ..

            "label[0.2,1.0;Cast]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";cast;0.2,1.3;1,1;]" ..

            "label[2.0,1.0;Molten Bucket]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";bucket;2.0,1.3;1,1;]" ..

            "label[4.0,1.0;Output]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";output;4.0,1.3;1,1;]" ..

            "button[0.2,3.0;3,1;pour;Pour Metal]" ..

            "list[current_player;main;1,5;8,3;]" ..
            "listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";cast]" ..
            "listring[current_player;main]"
    end,

    -- --------------------------------------------------------
    --  Button Handler
    -- --------------------------------------------------------
    on_receive_fields = function(pos, formname, fields, player)
        if not fields.pour then return end

        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()

        local cast_stack   = inv:get_stack("cast", 1)
        local bucket_stack = inv:get_stack("bucket", 1)

        -- Must have cast + molten bucket
        if cast_stack:is_empty() or bucket_stack:is_empty() then
            minetest.chat_send_player(player:get_player_name(), "You need a cast and molten bucket.")
            return
        end

        local cast_name = cast_stack:get_name()
        local bucket_name = bucket_stack:get_name()

        -- Extract cast ID
        local cast_id = cast_name:gsub("ws_blacksmith:cast_", "")

        -- Extract fluid ID
        local fluid_id = bucket_name:gsub("ws_blacksmith:bucket_molten_", "")

        -- Validate casting attempt
        if not ws_blacksmith.can_forge(fluid_id, cast_id) then
            minetest.chat_send_player(player:get_player_name(), "This molten metal cannot be used with this cast.")
            return
        end

        -- Perform casting
        local output_item = ws_blacksmith.forge_item(fluid_id, cast_id)
        inv:set_stack("output", 1, ItemStack(output_item))

        -- Consume molten bucket → empty bucket
        inv:set_stack("bucket", 1, ItemStack(EMPTY_BUCKET))

        -- Consume cast
        inv:set_stack("cast", 1, nil)

        meta:set_string("infotext", "Casting Complete")
        minetest.chat_send_player(player:get_player_name(), "You cast a "..output_item.."!")
    end,
})
