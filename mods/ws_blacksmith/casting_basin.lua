-- ============================================================
--  Wastelands: Survival - Casting Basin
--  Features:
--    - Cast slot (large casts)
--    - Molten bucket slot
--    - Output slot
--    - API-driven casting logic
--    - Heavy part casting (blocks, plates, components)
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")

ws_blacksmith = ws_blacksmith or {}

local EMPTY_BUCKET = "ws_buckets:metal_empty"

-- ============================================================
--  CASTING BASIN NODE
-- ============================================================

minetest.register_node("ws_blacksmith:casting_basin", {
    description = S("Casting Basin"),
    tiles = {
        "ws_casting_basin_top.png",
        "ws_casting_basin_bottom.png",
        "ws_casting_basin_side.png",
        "ws_casting_basin_side.png",
        "ws_casting_basin_side.png",
        "ws_casting_basin_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    -- --------------------------------------------------------
    --  On Construct
    -- --------------------------------------------------------
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Casting Basin (Idle)")

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
            "size[12,9]" ..
            "background[0,0;12,9;ws_casting_basin_gui.png]" ..

            "label[0.2,0.2;Casting Basin]" ..

            "label[0.2,1.0;Large Cast]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";cast;0.2,1.3;1,1;]" ..

            "label[2.0,1.0;Molten Bucket]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";bucket;2.0,1.3;1,1;]" ..

            "label[4.0,1.0;Output]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";output;4.0,1.3;1,1;]" ..

            "button[0.2,3.0;3,1;pour;Pour Heavy Cast]" ..

            "list[current_player;main;2,5;8,3;]" ..
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
            minetest.chat_send_player(player:get_player_name(), "You need a large cast and molten bucket.")
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

        meta:set_string("infotext", "Heavy Casting Complete")
        minetest.chat_send_player(player:get_player_name(), "You cast a "..output_item.."!")
    end,
})
