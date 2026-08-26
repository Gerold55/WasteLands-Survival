-- ws_radiation: Radiation system for Wastelands Survival (HUD-only, left-side meter)

local radiation = {}
radiation.players = {}
radiation.zones = {}
radiation.effects = {}

-- Radiation configuration
radiation.config = {
    check_interval = 5.0, -- seconds
    max_radiation = 100,
    natural_recovery_rate = 1, -- points per minute when safe
    warning_threshold = 25,
    danger_threshold = 50,
    lethal_threshold = 80
}

-- Radiation zones (defined by coordinates and radius)
radiation.zones = {
    {
        pos = {x = 0, y = 0, z = 0},
        radius = 50,
        intensity = 30,
        name = "Contaminated River"
    },
    {
        pos = {x = 100, y = 0, z = 100},
        radius = 30,
        intensity = 60,
        name = "Crater Site"
    },
    {
        pos = {x = -50, y = 0, z = -50},
        radius = 40,
        intensity = 45,
        name = "Old Factory"
    }
}

-- Radiation effects (logic only; HUD handles visuals)
radiation.effects = {
    [25] = {
        effects = {"hunger"},
    },
    [50] = {
        effects = {"hunger", "slow"},
    },
    [80] = {
        effects = {"hunger", "slow", "weakness"},
        damage = 1
    }
}

-- Get radiation level at position
function radiation.get_radiation_level(pos)
    local total_radiation = 0

    for _, zone in ipairs(radiation.zones) do
        local distance = vector.distance(pos, zone.pos)
        if distance <= zone.radius then
            local intensity = zone.intensity * (1 - (distance / zone.radius))
            total_radiation = total_radiation + intensity
        end
    end

    -- Random environmental radiation
    if math.random(1, 100) <= 5 then -- 5% chance of random spike
        total_radiation = total_radiation + math.random(5, 15)
    end

    return math.min(total_radiation, radiation.config.max_radiation)
end

-- Radiation HUD update (TOP RIGHT)
function radiation.update_hud(player_name, level, color)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end

    local pdata = radiation.players[player_name]
    if not pdata then return end

    -- ICON (image HUD)
    if not pdata.hud_icon then
        pdata.hud_icon = player:hud_add({
            hud_elem_type = "image",
            position = {x = 1, y = 0}, -- TOP RIGHT
            offset = {x = -80, y = 20},
            scale = {x = 1, y = 1},
            text = "ws_radiation_icon.png",
        })
    end

    -- NUMBER (text HUD)
    if not pdata.hud_number then
        pdata.hud_number = player:hud_add({
            hud_elem_type = "text",
            position = {x = 1, y = 0}, -- TOP RIGHT
            offset = {x = -40, y = 20},
            scale = {x = 100, y = 100},
            text = tostring(level),
            alignment = {x = 1, y = 0},
            number = 0,
            color = color,
        })
    else
        player:hud_change(pdata.hud_number, "text", tostring(level))
        player:hud_change(pdata.hud_number, "color", color)
    end
end

-- Apply radiation effects to player
function radiation.apply_effects(player_name, level)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end

    -- Find appropriate effect tier
    local current_effect = nil
    local current_threshold = nil
    for threshold, effect in pairs(radiation.effects) do
        if level >= threshold and (not current_threshold or threshold > current_threshold) then
            current_effect = effect
            current_threshold = threshold
        end
    end

    -- Reset physics by default
    player:set_physics_override({speed = 1.0, jump = 1.0})

    if current_effect then
        -- Apply status effects
        for _, effect in ipairs(current_effect.effects) do
            if effect == "hunger" then
                -- Integrate with hunger mod here
            elseif effect == "slow" then
                player:set_physics_override({speed = 0.7, jump = 0.8})
            elseif effect == "weakness" then
                -- Apply mining weakness, etc.
            end
        end

        -- Apply damage
        if current_effect.damage then
            player:set_hp(player:get_hp() - current_effect.damage)
        end
    end

    -- HUD color based on severity
    local hud_color = {r = 0, g = 255, b = 0} -- safe
    if level >= radiation.config.lethal_threshold then
        hud_color = {r = 255, g = 0, b = 0}   -- lethal
    elseif level >= radiation.config.danger_threshold then
        hud_color = {r = 255, g = 128, b = 0} -- danger
    elseif level >= radiation.config.warning_threshold then
        hud_color = {r = 255, g = 255, b = 0} -- warning
    end

    radiation.update_hud(player_name, level, hud_color)
end

-- Radiation protection system
radiation.protection_items = {
    ["ws_radiation:hazmat_helmet"] = 15,
    ["ws_radiation:hazmat_chestplate"] = 25,
    ["ws_radiation:hazmat_leggings"] = 20,
    ["ws_radiation:hazmat_boots"] = 10,
    ["ws_radiation:gas_mask"] = 30,
    ["ws_radiation:rad_pills"] = 40, -- Temporary protection
}

function radiation.get_protection_level(player_name)
    local player = minetest.get_player_by_name(player_name)
    if not player then return 0 end

    local protection = 0
    local inv = player:get_inventory()

    -- Check armor slots
    for i = 1, 4 do
        local stack = inv:get_stack("armor", i)
        if not stack:is_empty() then
            protection = protection + (radiation.protection_items[stack:get_name()] or 0)
        end
    end

    -- Check main inventory for temporary protection
    local main_inv = inv:get_list("main")
    for _, stack in ipairs(main_inv) do
        if stack:get_name() == "ws_radiation:rad_pills" then
            protection = protection + radiation.protection_items["ws_radiation:rad_pills"]
            break
        end
    end

    return math.min(protection, 100)
end

-- Main radiation check function
function radiation.check_players()
    for player_name, data in pairs(radiation.players) do
        local player = minetest.get_player_by_name(player_name)
        if player then
            local pos = player:get_pos()
            local raw_radiation = radiation.get_radiation_level(pos)
            local protection = radiation.get_protection_level(player_name)

            -- Apply protection
            local effective_radiation = math.max(0, raw_radiation - protection)

            -- Natural recovery when in safe areas
            if effective_radiation < 10 then
                data.level = math.max(0, data.level - radiation.config.natural_recovery_rate)
            else
                data.level = math.min(radiation.config.max_radiation, data.level + effective_radiation / 10)
            end

            -- Apply effects + HUD update
            radiation.apply_effects(player_name, data.level)
        end
    end

    minetest.after(radiation.config.check_interval, radiation.check_players)
end

-- Geiger counter functionality (HUD feedback only)
minetest.register_craftitem("ws_radiation:geiger_counter", {
    description = "Geiger Counter\nRight-click to check radiation levels",
    inventory_image = "ws_radiation_geiger.png",
    groups = {tool = 1},

    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local data = radiation.players[player_name]
        if not data then return itemstack end

        local pos = user:get_pos()
        local current_rad = radiation.get_radiation_level(pos)

        -- Flash HUD white briefly to indicate reading
        radiation.update_hud(player_name, current_rad, {r = 255, g = 255, b = 255})
        minetest.after(0.4, function()
            local pdata = radiation.players[player_name]
            if pdata then
                -- Restore HUD based on stored level
                radiation.apply_effects(player_name, pdata.level)
            end
        end)

        return itemstack
    end
})

-- Radiation protection items
minetest.register_tool("ws_radiation:gas_mask", {
    description = "Gas Mask\nProvides radiation protection",
    inventory_image = "ws_radiation_gas_mask.png",
    groups = {armor_head = 1, radiation_protection = 1},

    on_use = function(itemstack, user, pointed_thing)
        -- No radiation chat messages; item still usable
        return itemstack
    end
})

minetest.register_craftitem("ws_radiation:rad_pills", {
    description = "Radiation Pills\nTemporary radiation protection (10 minutes)",
    inventory_image = "ws_radiation_pills.png",

    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        if not radiation.players[player_name] then
            radiation.players[player_name] = {
                level = 0,
                hud_id = nil,
                pills_active = false
            }
        end

        radiation.players[player_name].pills_active = true
        minetest.after(600, function() -- 10 minutes
            if radiation.players[player_name] then
                radiation.players[player_name].pills_active = false
            end
        end)

        itemstack:take_item()
        return itemstack
    end
})

-- Player management
minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    radiation.players[player_name] = {
        level = 0,
        hud_id = nil,
        pills_active = false
    }

    -- Initialize HUD as safe
    radiation.update_hud(player_name, 0, {r = 0, g = 255, b = 0})
end)

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    radiation.players[player_name] = nil
end)

-- Start radiation checking
minetest.after(0, radiation.check_players)

-- Achievements integration
if minetest.get_modpath("ws_achievements") then
    ws_achievements.register_achievement("radiation_survivor", {
        title = "Radiation Survivor",
        description = "Survive your first high-radiation zone",
        category = "survival",
        icon = "ws_achievements_radiation.png"
    })

    -- Check for achievement
    minetest.register_globalstep(function(dtime)
        for player_name, data in pairs(radiation.players) do
            if data.level >= 60 and not ws_achievements.has_achievement(player_name, "radiation_survivor") then
                ws_achievements.grant_achievement(player_name, "radiation_survivor")
            end
        end
    end)
end

-- Journal integration
if minetest.get_modpath("ws_story") then
    local triggers = journal.require("triggers")

    triggers.register_on_join({
        id = "ws_radiation:warning",
        call_once = true,
        call = function(data)
            minetest.after(60, function()
                local entries = journal.require("entries")
                entries.add_entry(data.playerName, "ws_story:survivor",
                    "Found some glowing areas today. The water and ground still carry the poison. " ..
                    "I should avoid those spots or find some protection.", true)
            end)
        end,
    })
end

minetest.log("action", "[ws_radiation] Radiation system loaded (HUD-only, left-side meter)")
