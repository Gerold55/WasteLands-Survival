local modname = minetest.get_current_modname() or "ws_vault"

-- Table of all lights and their groups
local light_groups = {}  -- { [group_id] = {pos1, pos2, ...} }
local light_positions = {} -- maps position strings to group_id

local next_group_id = 0

-- Helper: serialize a vector to string for table keys
local function pos_to_str(pos)
    return pos.x..","..pos.y..","..pos.z
end

-- Helper: check adjacency in X/Z plane (Y same)
local function is_adjacent(pos1, pos2)
    local dx = math.abs(pos1.x - pos2.x)
    local dy = math.abs(pos1.y - pos2.y)
    local dz = math.abs(pos1.z - pos2.z)
    return dy == 0 and ((dx == 1 and dz == 0) or (dx == 0 and dz == 1))
end

-- Merge two groups
local function merge_groups(id1, id2)
    if id1 == id2 then return id1 end
    for _, pos in ipairs(light_groups[id2]) do
        table.insert(light_groups[id1], pos)
        light_positions[pos_to_str(pos)] = id1
    end
    light_groups[id2] = nil
    return id1
end

-- Assign light to a group
local function assign_light_group(pos)
    local group_id
    local neighbors = {}

    -- check existing lights for adjacency
    for str, gid in pairs(light_positions) do
        local parts = {}
        for n in string.gmatch(str, "[^,]+") do table.insert(parts, tonumber(n)) end
        local other = {x=parts[1], y=parts[2], z=parts[3]}
        if is_adjacent(pos, other) then
            table.insert(neighbors, gid)
        end
    end

    if #neighbors == 0 then
        -- no neighbors, create new group
        next_group_id = next_group_id + 1
        group_id = next_group_id
        light_groups[group_id] = {pos}
    else
        -- merge all neighbor groups
        group_id = neighbors[1]
        light_groups[group_id] = light_groups[group_id] or {pos}
        table.insert(light_groups[group_id], pos)
        for i=2,#neighbors do
            group_id = merge_groups(group_id, neighbors[i])
        end
    end
    light_positions[pos_to_str(pos)] = group_id
    return group_id
end

-- Flicker a group
local function flicker_group(group_id)
    local flicker_on = math.random() < 0.5
    for _, pos in ipairs(light_groups[group_id] or {}) do
        local node = minetest.get_node_or_nil(pos)
        if node then
            if flicker_on and node.name == modname..":vault_ceiling_light_off" then
                minetest.swap_node(pos, {name=modname..":vault_ceiling_light"})
            elseif not flicker_on and node.name == modname..":vault_ceiling_light" then
                minetest.swap_node(pos, {name=modname..":vault_ceiling_light_off"})
            end
        end
    end
    -- schedule next flicker with random delay
    minetest.after(math.random(0.2,0.6), function() flicker_group(group_id) end)
end

-- Register vault light nodes
local function register_vault_light(name, texture, light)
    minetest.register_node(name, {
        description = "Vault Ceiling Light",
        drawtype = "nodebox",
        tiles = {texture},
        paramtype = "light",
        light_source = light,
        sunlight_propagates = true,
        walkable = false,
        pointable = true,
        diggable = true,
        buildable_to = false,
        is_ground_content = false,
        groups = {oddly_breakable_by_hand=3, flammable=1},
        node_box = {
            type = "fixed",
            fixed = {{-0.5,0.45,-0.5,0.5,0.5,0.5}}, -- flush to ceiling
        },
        after_place_node = function(pos)
            local gid = assign_light_group(pos)
            minetest.after(math.random(0.1,0.5), function() flicker_group(gid) end)
        end,
        after_dig_node = function(pos)
            local str = pos_to_str(pos)
            local gid = light_positions[str]
            if gid and light_groups[gid] then
                -- remove from group
                for i, p in ipairs(light_groups[gid]) do
                    if vector.equals(p, pos) then
                        table.remove(light_groups[gid], i)
                        break
                    end
                end
                light_positions[str] = nil
            end
        end,
    })
end

-- Register nodes
register_vault_light(modname..":vault_ceiling_light", "ws_vault_light.png", 12)
register_vault_light(modname..":vault_ceiling_light_off", "ws_vault_light_off.png", 0)
minetest.override_item(modname..":vault_ceiling_light_off", {
    groups={oddly_breakable_by_hand=3, flammable=1, not_in_creative_inventory=1}
})

-- LBM: register all pre-placed lights
minetest.register_lbm({
    name = modname..":register_vault_lights",
    nodenames = {modname..":vault_ceiling_light", modname..":vault_ceiling_light_off"},
    run_at_every_load = true,
    action = function(pos, node)
        -- Reset to ON
        if node.name == modname..":vault_ceiling_light_off" then
            minetest.set_node(pos, {name=modname..":vault_ceiling_light"})
        end
        -- assign to group and start flicker if not already tracked
        local str = pos_to_str(pos)
        if not light_positions[str] then
            local gid = assign_light_group(pos)
            minetest.after(math.random(0.1,0.5), function() flicker_group(gid) end)
        end
    end,
})

minetest.log("action","["..modname.."] Vault ceiling lights loaded with grouped flicker.")
