-- ============================================================
--  Wastelands: Survival - Forging Anvil
--  Features:
--    - Cast slot
--    - Molten bucket slot
--    - Hammering mini-game
--    - Forging output
--    - API-driven forging logic
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")

ws_blacksmith = ws_blacksmith or {}

-- ============================================================
--  SETTINGS
-- ============================================================

local HAMMER_STEPS = 6      -- number of hammer strikes required
local DAMAGE_ON_FAIL = 2    -- damage if player hammers wrong
local FORGE_HEAT_TIME = 10  -- molten bucket cools after forging

-- ============================================================
--  ANVIL NODE
-- ============================================================

minetest.register_node("ws_blacksmith:anvil", {
    description = S("Wasteland Anvil"),
    tiles = {
        "ws_anvil_top.png",
        "ws_anvil_bottom.png",
        "ws_anvil_side.png",
        "ws_anvil_side.png",
        "ws_anvil_side.png",
        "ws_anvil_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    -- --------------------------------------------------------
    --  On Construct
    -- --------------------------------------------------------
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", "Wasteland Anvil (Idle)")
        meta:set_int("hammer_progress", 0)

        local inv = meta:get_inventory()
        inv:set_size("cast", 1)
        inv:set_size("bucket", 1)
        inv:set_size("output", 1)
    end,

    -- --------------------------------------------------------
    --  GUI
    -- --------------------------------------------------------
    get_formspec = function(pos)
        local meta = minetest.get_meta(pos)
        local progress = meta:get_int("hammer_progress")

        return
            "size[10,8]" ..
            "background[0,0;10,8;ws_anvil_gui.png]" ..

            "label[0.2,0.2;Wasteland Anvil]" ..

            "label[0.2,1.0;Cast]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";cast;0.2,1.3;1,1;]" ..

            "label[2.0,1.0;Molten Bucket]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";bucket;2.0,1.3;1,1;]" ..

            "label[4.0,1.0;Output]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";output;4.0,1.3;1,1;]" ..

            "label[0.2,3.0;Hammer Progress: "..progress.."/"..HAMMER_STEPS.."]" ..

            "button[0.2,4.0;3,1;hammer;Hammer]" ..

            "list[current_player;main;1,5;8,3;]" ..
            "listring[nodemeta:"..pos.x..","..pos.y..","..pos.z..";cast]" ..
            "listring[current_player;main]"
    end,

    -- --------------------------------------------------------
    --  Button Handler
    -- --------------------------------------------------------
    on_receive_fields = function(pos, formname, fields, player)
        if not fields.hammer then return end

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

        -- Validate forging attempt
        if not ws_blacksmith.can_forge(fluid_id, cast_id) then
            minetest.chat_send_player(player:get_player_name(), "This molten metal cannot be used with this cast.")
            player:set_hp(player:get_hp() - DAMAGE_ON_FAIL)
            return
        end

        -- Increase hammer progress
        local progress = meta:get_int("hammer_progress") + 1
        meta:set_int("hammer_progress", progress)

        minetest.chat_send_player(player:get_player_name(), "You strike the anvil... ("..progress.."/"..HAMMER_STEPS..")")

        -- Not finished yet
        if progress < HAMMER_STEPS then
            return
        end

        -- Finished forging
        meta:set_int("hammer_progress", 0)

        -- Create forged item
        local output_item = ws_blacksmith.forge_item(fluid_id, cast_id)
        inv:set_stack("output", 1, ItemStack(output_item))

        -- Consume molten bucket → empty bucket
        inv:set_stack("bucket", 1, ItemStack("ws_buckets:metal_empty"))

        -- Consume cast
        inv:set_stack("cast", 1, nil)

        minetest.chat_send_player(player:get_player_name(), "You forged a "..output_item.."!")
    end,
})
