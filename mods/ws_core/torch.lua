-- ws_core/torch.lua

-- Support for MT game translation

local function on_flood(pos, oldnode, newnode)
    -- Removed automatic torch placement here
    -- Optional: Play flame-extinguish sound if needed
    local nodedef = minetest.registered_items[newnode.name]
    if not (nodedef and nodedef.groups and nodedef.groups.igniter and nodedef.groups.igniter > 0) then
        minetest.sound_play(
            "ws_core_cool_lava",  -- replace with a ws_core sound
            {pos = pos, max_hear_distance = 16, gain = 0.1},
            true
        )
    end
    return false
end

-- Table to track temporary lights per player
local player_light_nodes = {}

-- Simple wood sound definition for ws_core nodes
ws_core = ws_core or {}
ws_core.node_sound_wood_defaults = function()
    return {
        footstep = {name = "ws_core_wood_footstep", gain = 0.5},
        dig = {name = "ws_core_wood_dig", gain = 1.0},
        dug = {name = "ws_core_wood_dug", gain = 1.0},
        place = {name = "ws_core_wood_place", gain = 1.0},
    }
end

-- Light and smoke emission when carrying the torch
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local wielded_item = player:get_wielded_item():get_name()
        local pos = player:get_pos()
        if pos then
            local light_pos = {x=math.floor(pos.x+0.5), y=math.floor(pos.y+1), z=math.floor(pos.z+0.5)}

            local prev_pos = player_light_nodes[player_name]
            if prev_pos and (prev_pos.x ~= light_pos.x or prev_pos.y ~= light_pos.y or prev_pos.z ~= light_pos.z) then
                local node = minetest.get_node(prev_pos)
                if node.name == "ws_core:temporary_light" then
                    minetest.remove_node(prev_pos)
                end
                player_light_nodes[player_name] = nil
            end

            if wielded_item == "ws_core:torch" then
                -- Flame particles
                minetest.add_particlespawner({
                    amount = 10,
                    time = 0.25,
                    minpos = {x=pos.x-0.5, y=pos.y+1.5, z=pos.z-0.5},
                    maxpos = {x=pos.x+0.5, y=pos.y+2, z=pos.z+0.5},
                    minvel = {x=0, y=0.1, z=0},
                    maxvel = {x=0, y=0.2, z=0},
                    minacc = {x=0, y=0, z=0},
                    maxacc = {x=0, y=0.01, z=0},
                    minexptime = 0.5,
                    maxexptime = 1.0,
                    minsize = 1,
                    maxsize = 2,
                    collisiondetection = false,
                    vertical = true,
                    texture = "ws_torch_flame.png",
                })

                -- Gray smoke
                minetest.add_particlespawner({
                    amount = 4,
                    time = 0.25,
                    minpos = {x=pos.x-0.3, y=pos.y+1.5, z=pos.z-0.3},
                    maxpos = {x=pos.x+0.3, y=pos.y+2.0, z=pos.z+0.3},
                    minvel = {x=0, y=0.2, z=0},
                    maxvel = {x=0, y=0.4, z=0},
                    minacc = {x=0, y=0.01, z=0},
                    maxacc = {x=0, y=0.02, z=0},
                    minexptime = 0.5,
                    maxexptime = 1.2,
                    minsize = 1,
                    maxsize = 2,
                    collisiondetection = false,
                    vertical = false,
                    texture = "ws_torch_smoke.png",
                })

                -- Set temporary light
                local node = minetest.get_node(light_pos)
                if node.name ~= "ws_core:temporary_light" then
                    minetest.set_node(light_pos, {name="ws_core:temporary_light", param2=0})
                    player_light_nodes[player_name] = light_pos
                end
            else
                if prev_pos then
                    local node = minetest.get_node(prev_pos)
                    if node.name == "ws_core:temporary_light" then
                        minetest.remove_node(prev_pos)
                    end
                    player_light_nodes[player_name] = nil
                end
            end
        end
    end
end)

-- Register the temporary light node
minetest.register_node("ws_core:temporary_light", {
    description = "Temporary Light",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 10,
    walkable = false,
    groups = {not_in_creative_inventory=1},
})

-- Spawn gray smoke for placed torches
local function spawn_torch_smoke(pos)
    minetest.add_particlespawner({
        amount = 2,
        time = 0.25,
        minpos = {x=pos.x-0.1, y=pos.y+0.5, z=pos.z-0.1},
        maxpos = {x=pos.x+0.1, y=pos.y+1.0, z=pos.z+0.1},
        minvel = {x=0, y=0.1, z=0},
        maxvel = {x=0, y=0.3, z=0},
        minacc = {x=0, y=0.01, z=0},
        maxacc = {x=0, y=0.02, z=0},
        minexptime = 0.5,
        maxexptime = 1.5,
        minsize = 1,
        maxsize = 2,
        collisiondetection = false,
        vertical = false,
        texture = "ws_torch_smoke.png",
    })
end

-- Torch node
minetest.register_node("ws_core:torch", {
    description = "Torch",
    drawtype = "mesh",
    mesh = "torch_floor.obj",
    inventory_image = "ws_torch.png",
    wield_image = "ws_torch.png",
    tiles = {"ws_torch.png"},
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    liquids_pointable = false,
    light_source = 10,
    groups = {choppy=2, dig_immediate=3, flammable=1, attached_node=1, torch=1},
    drop = "ws_core:torch",
    selection_box = {
        type = "wallmounted",
        wall_bottom = {-1/8, -1/2, -1/8, 1/8, 2/16, 1/8},
    },
    sounds = ws_core.node_sound_wood_defaults(),
    on_place = function(itemstack, placer, pointed_thing)
        local under = pointed_thing.under
        local node = minetest.get_node(under)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_rightclick and
            not (placer and placer:is_player() and
            placer:get_player_control().sneak) then
            return def.on_rightclick(under, node, placer, itemstack, pointed_thing) or itemstack
        end

        local above = pointed_thing.above
        local wdir = minetest.dir_to_wallmounted(vector.subtract(under, above))
        local fakestack = itemstack
        if wdir == 1 then
            fakestack:set_name("ws_core:torch")
        else
            fakestack:set_name("ws_core:torch_wall")
        end

        itemstack = minetest.item_place(fakestack, placer, pointed_thing, wdir)
        itemstack:set_name("ws_core:torch")

        return itemstack
    end,
    floodable = true,
    on_flood = on_flood,
    on_rotate = false,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.5)
    end,
    on_timer = function(pos, elapsed)
        spawn_torch_smoke(pos)
        return true
    end,
})

-- Wall-mounted torch node
minetest.register_node("ws_core:torch_wall", {
    drawtype = "mesh",
    mesh = "torch_wall.obj",
    tiles = {"ws_torch.png"},
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    light_source = 10,
    groups = {choppy=2, dig_immediate=3, flammable=1, not_in_creative_inventory=1, attached_node=1, torch=1},
    drop = "ws_core:torch",
    selection_box = {
        type = "wallmounted",
        wall_side = {-1/2, -1/2, -1/8, -1/8, 1/8, 1/8},
    },
    sounds = ws_core.node_sound_wood_defaults(),
    floodable = true,
    on_flood = on_flood,
    on_rotate = false,
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.5)
    end,
    on_timer = function(pos, elapsed)
        spawn_torch_smoke(pos)
        return true
    end,
})

-- LBM to convert older torch nodes
minetest.register_lbm({
    name = "ws_core:3dtorch",
    nodenames = {"ws_core:torch", "torches:floor", "torches:wall"},
    action = function(pos, node)
        if node.param2 == 1 then
            minetest.set_node(pos, {name = "ws_core:torch", param2 = node.param2})
        else
            minetest.set_node(pos, {name = "ws_core:torch_wall", param2 = node.param2})
        end
    end
})

-- Crafting recipes
minetest.register_craft({
    output = "ws_core:torch 4",
    recipe = {
        {"ws_core:coal"},
        {"group:stick"},
    }
})

minetest.register_craft({
    type = "fuel",
    recipe = "ws_core:torch",
    burntime = 4,
})
