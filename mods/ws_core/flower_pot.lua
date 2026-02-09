-- ws_core/flower_pot.lua
ws_core = ws_core or {}

-- Simple wood sound (keeps consistency)
ws_core.node_sound_wood_defaults = function()
    return {
        footstep = {name = "ws_core_wood_footstep", gain = 0.5},
        dig = {name = "ws_core_wood_dig", gain = 1.0},
        dug = {name = "ws_core_wood_dug", gain = 1.0},
        place = {name = "ws_core_wood_place", gain = 1.0},
    }
end

-- Helper: is itemstack a flower? (group:flower)
local function is_flower_itemstack(itemstack)
    if not itemstack or itemstack:is_empty() then return false end
    local name = itemstack:get_name()
    local def = minetest.registered_items[name]
    if not def then return false end
    if def.groups and def.groups.flower then return true end
    return false
end

-- Helper: attempt to pick a single flower name from the itemstack
local function flower_name_from_stack(itemstack)
    if not itemstack or itemstack:is_empty() then return nil end
    local name = itemstack:get_name()
    local def = minetest.registered_items[name]
    if def and def.groups and def.groups.flower then
        return name
    end
    return nil
end

-- NOTE:
-- This implementation stores the planted flower type in node metadata so we can return the same flower when removed.
-- Because we're using two separate meshes (one baked with flower visuals), the in-world appearance will always be the
-- flowered mesh regardless of which exact flower was planted — that's acceptable if you bake a generic flower into the mesh.
-- But metadata will still remember which flower item to give back.

-- Empty flower pot node (single mesh + single texture)
minetest.register_node("ws_core:flower_pot_empty", {
    description = "Flower Pot (Empty)",
    drawtype = "mesh",
    mesh = "WLS_flower_pot.gltf",         -- mesh with pot only (single material)
    tiles = {"ws_flower_pot.png"},
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = {
        type = "fixed",
        fixed = {-0.2, -0.5, -0.2, 0.2, 0, 0.2},
    },
    groups = {choppy=2, dig_immediate=3, flammable=1},
    sounds = ws_core.node_sound_wood_defaults(),

    -- Right-click with a flower to plant it in the pot (stores the flower type in metadata)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker then return itemstack end
        if is_flower_itemstack(itemstack) then
            -- Save the flower type in node metadata so we can return it on removal
            local meta = minetest.get_meta(pos)
            local flower_name = flower_name_from_stack(itemstack) or ""
            meta:set_string("flower_item", flower_name)

            -- Replace node with flowered mesh node
            minetest.set_node(pos, {name = "ws_core:flower_pot"})
            -- Consume one flower (unless creative)
            if not minetest.is_creative_enabled(clicker:get_player_name()) then
                itemstack:take_item(1)
            end
            return itemstack
        end
        return itemstack
    end,

    -- When dug, drop just the empty pot
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- nothing special; default drop (node drops defined by registration)
    end,
})

-- Flowered pot node (single mesh + single texture baked with flower visuals)
minetest.register_node("ws_core:flower_pot", {
    description = "Flower Pot (With Flower)",
    drawtype = "mesh",
    mesh = "WLS_flower_pot_w_flowers.gltf",        -- mesh baked with flower visuals
    tiles = {"ws_flower_pot.png"},
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    selection_box = {
        type = "fixed",
        fixed = {-0.2, -0.5, -0.2, 0.2, 0.3, 0.2},
    },
    groups = {choppy=2, dig_immediate=3, flammable=1, not_in_creative_inventory=0},
    sounds = ws_core.node_sound_wood_defaults(),

    -- Right-click removes the flower and returns the flower item (if possible),
    -- then converts node back to empty pot.
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker then return itemstack end
        local meta = minetest.get_meta(pos)
        local planted_flower = meta:get_string("flower_item") or ""

        -- Determine what to give back: if we know the planted flower, give that; otherwise give a fallback.
        local give_name = nil
        if planted_flower ~= "" and minetest.registered_items[planted_flower] then
            give_name = planted_flower
        else
            -- fallback: try some common flower names (change as desired)
            if minetest.registered_items["flowers:rose"] then
                give_name = "flowers:rose"
            elseif minetest.registered_items["flowers:tulip"] then
                give_name = "flowers:tulip"
            else
                -- final fallback: nothing; just convert to empty pot
                give_name = nil
            end
        end

        -- Give item back to player inventory or drop at pos
        if give_name then
            local inv = clicker:get_inventory()
            if inv:room_for_item("main", give_name) then
                inv:add_item("main", give_name)
            else
                minetest.add_item(pos, give_name)
            end
        end

        -- Clear metadata and set node to empty pot
        meta:set_string("flower_item", "")
        minetest.set_node(pos, {name = "ws_core:flower_pot_empty"})
        return itemstack
    end,

    -- When dug, try to drop the planted flower plus the empty pot
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local meta = minetest.get_meta(pos)
        local planted_flower = meta:get_string("flower_item") or ""
        if planted_flower ~= "" and minetest.registered_items[planted_flower] then
            -- drop the flower item into the world at pos
            minetest.add_item(pos, planted_flower)
        end
        -- empty pot will be dropped by node's drop setting (default)
    end,
})

-- Make sure digging the nodes yields reasonable items
-- You can customize drop to drop empty pot (and optionally flower)
minetest.override_item("ws_core:flower_pot_empty", {
    drop = "ws_core:flower_pot_empty",
})
minetest.override_item("ws_core:flower_pot", {
    drop = "ws_core:flower_pot_empty", -- flower is returned via after_dig_node to avoid duplication
})

-- Crafting: empty pot
minetest.register_craft({
    output = "ws_core:flower_pot_empty",
    recipe = {
        {"group:stone", "", "group:stone"},
        {"group:stone", "", "group:stone"},
        {"", "", ""},
    }
})

-- Shapeless: empty pot + any flower -> flowered pot (this sets metadata too, but we can't set metadata via crafting;
-- we will just produce the flowered node without metadata. When removed, code will fall back to a default)
minetest.register_craft({
    type = "shapeless",
    output = "ws_core:flower_pot",
    recipe = {"ws_core:flower_pot_empty", "group:flower"}
})
