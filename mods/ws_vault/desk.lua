local modname = minetest.get_current_modname() or "ws_vault"

minetest.register_node(modname..":vault_desk", {
    description = "Vault Desk",
    drawtype = "mesh",
    mesh = "WLS_desk.obj",
    tiles = {"ws_desk.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    visual_scale = 1.5,
    walkable = true,
    diggable = true,
    groups = {choppy=3, oddly_breakable_by_hand=3, dig_immediate=3},

    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.45, -0.5, 0.5, 0.55, 0.5},
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.45, -0.5, 0.5, 0.55, 0.5},
    },

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local node = minetest.get_node(pos)
        local dir = placer:get_look_dir()
        local yaw = math.floor((math.atan2(dir.z, dir.x) / (math.pi * 2) + 0.5) * 4)
        node.param2 = yaw
        minetest.swap_node(pos, node)
    end,
})
