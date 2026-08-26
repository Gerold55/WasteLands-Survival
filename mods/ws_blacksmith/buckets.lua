-- ============================================================
--  Wastelands: Survival - Molten Bucket System
--  Safe cooling, burning, puddles, and integration with ws_buckets
-- ============================================================

local S = minetest.get_translator("ws_blacksmith")
ws_blacksmith = ws_blacksmith or {}

local EMPTY_BUCKET = "ws_buckets:metal_empty"

-- ============================================================
--  SETTINGS
-- ============================================================

local COOL_TIME     = 20     -- seconds until molten bucket cools
local DAMAGE_AMOUNT = 2      -- damage per tick when held
local FIRE_DAMAGE   = 4      -- damage when standing in puddle
local TICK_INTERVAL = 1      -- globalstep tick

local molten_buckets = {}    -- tracks cooling timers per player

-- ============================================================
--  REGISTER MOLTEN BUCKET ITEMS
-- ============================================================

for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_craftitem("ws_blacksmith:bucket_molten_" .. id, {
        description = S("Molten " .. def.name .. " Bucket"),
        inventory_image = "ws_bucket_molten_" .. id .. ".png",
        stack_max = 1,
        groups = { molten_bucket = 1 },

        -- Right-click in air → empty bucket
        on_use = function(itemstack, user, pointed)
            return ItemStack(EMPTY_BUCKET)
        end,

        -- Place molten puddle
        on_place = function(itemstack, placer, pointed)
            if pointed.type == "node" then
                local pos = pointed.above
                minetest.set_node(pos, { name = "ws_blacksmith:molten_puddle_" .. id })
                return ItemStack(EMPTY_BUCKET)
            end
        end,
    })
end

-- ============================================================
--  REGISTER MOLTEN PUDDLE NODES
-- ============================================================

for id, def in pairs(ws_blacksmith.metals) do
    minetest.register_node("ws_blacksmith:molten_puddle_" .. id, {
        description = S("Molten " .. def.name .. " Puddle"),
        drawtype = "liquid",
        tiles = { def.fluid_tex or "ws_fluid_" .. id .. ".png" },
        liquidtype = "source",
        liquid_viscosity = 8,
        damage_per_second = FIRE_DAMAGE,
        groups = { molten_puddle = 1, hot = 1, liquid = 1 },
        walkable = false,
        pointable = true,
        buildable_to = true,
    })
end

-- ============================================================
--  GLOBALSTEP: COOLING + PLAYER DAMAGE
-- ============================================================

local tick = 0

minetest.register_globalstep(function(dtime)
    tick = tick + dtime
    if tick < TICK_INTERVAL then return end
    tick = 0

    for player_name, data in pairs(molten_buckets) do
        local player = minetest.get_player_by_name(player_name)
        if not player then
            molten_buckets[player_name] = nil
            goto continue
        end

        -- Reduce cooling timer
        data.time = data.time - 1

        -- Damage player if holding molten bucket
        local wield = player:get_wielded_item():get_name()
        if wield:find("ws_blacksmith:bucket_molten_") then
            player:set_hp(player:get_hp() - DAMAGE_AMOUNT)
        end

        -- Cooling finished → convert to empty bucket
        if data.time <= 0 then
            local inv = player:get_inventory()
            local stack = inv:get_stack("main", data.index)

            if stack:get_name():find("ws_blacksmith:bucket_molten_") then
                inv:set_stack("main", data.index, ItemStack(EMPTY_BUCKET))
                minetest.chat_send_player(player_name, "Your molten bucket has cooled.")
            end

            molten_buckets[player_name] = nil
        end

        ::continue::
    end
end)

-- ============================================================
--  INVENTORY TRACKING (SAFE)
-- ============================================================

minetest.register_on_player_inventory_action(function(player, action, inventory, info)
    -- Only track moves/puts
    if action ~= "put" and action ~= "move" then
        return
    end

    -- SAFETY CHECK: prevent nil crashes
    if not info or not info.list or not info.index then
        return
    end

    local name = player:get_player_name()
    local stack = inventory:get_stack(info.list, info.index)

    -- Only track molten buckets
    if stack:get_name():find("ws_blacksmith:bucket_molten_") then
        molten_buckets[name] = {
            time  = COOL_TIME,
            index = info.index,
        }
        minetest.chat_send_player(name, "This molten bucket will cool in " .. COOL_TIME .. " seconds.")
    end
end)

-- ============================================================
--  CLEANUP ON LEAVE
-- ============================================================

minetest.register_on_leaveplayer(function(player)
    molten_buckets[player:get_player_name()] = nil
end)
