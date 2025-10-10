-- ws_radiation: Radiation system for Wastelands Survival

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

-- Radiation effects
radiation.effects = {
    [25] = {
        message = "Slight headache... feeling nauseous",
        effects = {"hunger"},
        hud_color = {r = 255, g = 255, b = 0}
    },
    [50] = {
        message = "Vision blurring, severe nausea",
        effects = {"hunger", "slow"},
        hud_color = {r = 255, g = 128, b = 0}
    },
    [80] = {
        message = "Losing consciousness... radiation poisoning!",
        effects = {"hunger", "slow", "weakness"},
        hud_color = {r = 255, g = 0, b = 0},
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

-- Apply radiation effects to player
function radiation.apply_effects(player_name, level)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    -- Find appropriate effect tier
    local current_effect = nil
    for threshold, effect in pairs(radiation.effects) do
        if level >= threshold and (not current_effect or threshold > current_effect.threshold) then
            current_effect = effect
            current_effect.threshold = threshold
        end
    end
    
    if current_effect then
        -- Apply status effects
        for _, effect in ipairs(current_effect.effects) do
            if effect == "hunger" then
                -- Would integrate with hunger mod here
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
        
        -- Update HUD
        radiation.update_hud(player_name, level, current_effect.hud_color)
    else
        -- Reset physics if no radiation effects
        player:set_physics_override({speed = 1.0, jump = 1.0})
        radiation.update_hud(player_name, level, {r = 0, g = 255, b = 0})
    end
end

-- Update radiation HUD
function radiation.update_hud(player_name, level, color)
    local player = minetest.get_player_by_name(player_name)
    if not player then return end
    
    -- Create or update HUD element
    if not radiation.players[player_name].hud_id then
        radiation.players[player_name].hud_id = player:hud_add({
            hud_elem_type = (core.get_version().proto_max < 44)
                and "statbar" or nil,
            type = "statbar",
            position = {x = 0.5, y = 1},
            size = {x = 24, y = 24},
            offset = {x = 0, y = -80},
            text = "ws_radiation_icon.png",
            number = level,
            alignment = {x = 0, y = 0},
            scale = {x = 1, y = 1},
            text2 = "",
        })
    else
        player:hud_change(radiation.players[player_name].hud_id, "number", level)
    end
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
            
            -- Apply effects
            radiation.apply_effects(player_name, data.level)
            
            -- Warning messages
            if data.level >= radiation.config.warning_threshold and 
               data.level - effective_radiation < radiation.config.warning_threshold then
                minetest.chat_send_player(player_name, "#FFAA00 Radiation warning: Leave contaminated area!")
            end
            
            -- Debug info (remove in production)
            if minetest.is_singleplayer() then
                minetest.debug("Radiation: " .. data.level .. " Protection: " .. protection)
            end
        end
    end
    
    minetest.after(radiation.config.check_interval, radiation.check_players)
end

-- Geiger counter functionality
minetest.register_craftitem("ws_radiation:geiger_counter", {
    description = "Geiger Counter\nRight-click to check radiation levels",
    inventory_image = "ws_radiation_geiger.png",
    groups = {tool = 1},
    
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        local data = radiation.players[player_name]
        if not data then return end
        
        local pos = user:get_pos()
        local current_rad = radiation.get_radiation_level(pos)
        local protection = radiation.get_protection_level(player_name)
        
        local messages = {
            "Click... click... (Low)",
            "Click-click... (Moderate)", 
            "CLICK-CLICK-CLICK! (High)",
            "BRRRZZZZZT! (DANGEROUS!)"
        }
        
        local msg_index = 1
        if current_rad > 70 then msg_index = 4
        elseif current_rad > 40 then msg_index = 3
        elseif current_rad > 15 then msg_index = 2
        end
        
        minetest.chat_send_player(player_name, "#FFFF00 " .. messages[msg_index] .. 
            " Radiation: " .. math.floor(current_rad) .. " Protection: " .. protection)
        
        return itemstack
    end
})

-- Radiation protection items
minetest.register_tool("ws_radiation:gas_mask", {
    description = "Gas Mask\nProvides radiation protection",
    inventory_image = "ws_radiation_gas_mask.png",
    groups = {armor_head = 1, radiation_protection = 1},
    
    on_use = function(itemstack, user, pointed_thing)
        minetest.chat_send_player(user:get_player_name(), "#AAAAFF Gas mask filters out some contaminants")
        return itemstack
    end
})

minetest.register_craftitem("ws_radiation:rad_pills", {
    description = "Radiation Pills\nTemporary radiation protection (10 minutes)",
    inventory_image = "ws_radiation_pills.png",
    
    on_use = function(itemstack, user, pointed_thing)
        local player_name = user:get_player_name()
        radiation.players[player_name].pills_active = true
        minetest.after(600, function() -- 10 minutes
            if radiation.players[player_name] then
                radiation.players[player_name].pills_active = false
                minetest.chat_send_player(player_name, "#FF5555 Radiation pills have worn off!")
            end
        end)
        minetest.chat_send_player(player_name, "#55FF55 Radiation pills activated!")
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

minetest.log("action", "[ws_radiation] Radiation system loaded")
