minetest.register_node("ws_blacksmith:heater", {
    description = "Melter Heater",
    tiles = {
        "ws_heater_top.png",
        "ws_heater_bottom.png",
        "ws_heater_side.png",
        "ws_heater_side.png",
        "ws_heater_side.png",
        "ws_heater_front.png"
    },
    groups = {cracky=2},
    paramtype2 = "facedir",

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_int("fuel", 0)
        meta:set_int("burn", 0)

        local inv = meta:get_inventory()
        inv:set_size("fuel", 1)
    end,

    can_dig = function(pos)
        local inv = minetest.get_meta(pos):get_inventory()
        return inv:is_empty("fuel")
    end,

    -------------------------------------------------------
    -- Heater GUI
    -------------------------------------------------------
    get_formspec = function(pos)
        local meta = minetest.get_meta(pos)
        local burn = meta:get_int("burn")

        local burn_h = (burn / 1000) * 3

        return
            "size[8,6]" ..
            "label[0,0;Heater]" ..

            "image[3,1;1,3;ws_fuel_bg.png]" ..
            "image[3,1+"..(3 - burn_h)..";1,"..burn_h..";ws_fuel_fluid.png]" ..

            "label[3,4.2;Fuel]" ..
            "list[nodemeta:"..pos.x..","..pos.y..","..pos.z..";fuel;3,4.7;1,1;]" ..

            "list[current_player;main;0,5;8,1;]"
    end,

    on_rightclick = function(pos, node, clicker)
        local formspec = minetest.registered_nodes[node.name].get_formspec(pos)
        minetest.show_formspec(clicker:get_player_name(), "ws_blacksmith:heater", formspec)
    end,

    -------------------------------------------------------
    -- Heater logic
    -------------------------------------------------------
    on_timer = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        local burn = meta:get_int("burn")

        -- If burning, decrease burn
        if burn > 0 then
            meta:set_int("burn", burn - 1)
            return true
        end

        -- If not burning, try to consume fuel
        local stack = inv:get_stack("fuel", 1)

        if stack:get_name() == "bucket:lava" then
            inv:set_stack("fuel", 1, ItemStack("bucket:bucket"))
            meta:set_int("burn", 1000)
            return true
        end

        if stack:get_name() == "default:coal_lump" then
            stack:take_item()
            inv:set_stack("fuel", 1, stack)
            meta:set_int("burn", 200)
            return true
        end

        return true
    end,
})
