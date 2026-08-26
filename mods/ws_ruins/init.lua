local ruins = {}

-- Loot tables stay exactly as before
ruins.loot_tables = {
    small_house = {
        items = {
            {name = "ws_core:stick", chance = 80, min_count = 1, max_count = 5},
            {name = "ws_core:planks_oak_dry", chance = 60, min_count = 1, max_count = 3},
            {name = "ws_core:bone", chance = 40, min_count = 1, max_count = 2},
            {name = "ws_core:straw", chance = 30, min_count = 1, max_count = 3}
        },
        description = "Abandoned House Storage"
    },

    guard_tower = {
        items = {
            {name = "ws_core:stone", chance = 70, min_count = 1, max_count = 3},
            {name = "ws_core:cobble", chance = 50, min_count = 1, max_count = 2},
            {name = "ws_core:apple", chance = 50, min_count = 1, max_count = 2}
        },
        description = "Guard Tower Storage"
    },

    bunker = {
        items = {
            {name = "ws_core:stone", chance = 90, min_count = 2, max_count = 8},
            {name = "ws_core:coal_block", chance = 80, min_count = 1, max_count = 3},
            {name = "ws_core:cobble", chance = 40, min_count = 1, max_count = 2}
        },
        description = "Bunker Storage"
    },

    farmhouse = {
        items = {
            {name = "ws_core:planks_oak", chance = 90, min_count = 3, max_count = 12},
            {name = "ws_core:straw", chance = 70, min_count = 1, max_count = 4},
            {name = "ws_core:apple", chance = 60, min_count = 1, max_count = 4}
        },
        description = "Farmhouse Supplies"
    },

    radio_tower = {
        items = {
            {name = "ws_core:stone", chance = 95, min_count = 5, max_count = 15},
            {name = "ws_core:cobble", chance = 80, min_count = 3, max_count = 10},
            {name = "ws_core:marble", chance = 30, min_count = 1, max_count = 2}
        },
        description = "Radio Tower Equipment"
    }
}

-- Place schematic
function ruins.place_schematic(pos, name)
    local path = minetest.get_modpath("ws_ruins") .. "/schematics/" .. name .. ".mts"
    minetest.place_schematic(pos, path, "random", nil, true)
end

-- Add loot chest
function ruins.add_loot(pos, ruin_type)
    local loot = ruins.loot_tables[ruin_type]
    if not loot then return end

    minetest.set_node(pos, {name = "ws_core:bookshelf"}) -- your chest substitute

    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    inv:set_list("main", {})

    for _, item in ipairs(loot.items) do
        if math.random(1, 100) <= item.chance then
            local stack = ItemStack(item.name .. " " .. math.random(item.min_count, item.max_count))
            inv:add_item("main", stack)
        end
    end

    meta:set_string("infotext", loot.description)
end

-- Optional debris
function ruins.add_debris(pos)
    local debris = {
        "ws_core:stone",
        "ws_core:cobble",
        "ws_core:stick",
        "ws_core:bone",
        "ws_core:gravel",
        "air"
    }

    for x = -4, 4 do
        for z = -4, 4 do
            if math.random(1, 100) <= 30 then
                local dpos = {x = pos.x + x, y = pos.y, z = pos.z + z}
                local node = debris[math.random(#debris)]
                if node ~= "air" then
                    minetest.set_node(dpos, {name = node})
                end
            end
        end
    end
end

-- Build ruin
function ruins.build_ruin(ruin_type, pos)
    ruins.place_schematic(pos, ruin_type)
    ruins.add_debris(pos)
    ruins.add_loot(vector.add(pos, {x = 0, y = 1, z = 0}), ruin_type)
end

-- Chat command
minetest.register_chatcommand("build_ruin", {
    params = "<type>",
    description = "Place a ruin schematic at your position",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end

        local pos = vector.round(player:get_pos())

        ruins.build_ruin(param, pos)
        return true, "Placed ruin: " .. param
    end
})

ws_ruins = ruins
