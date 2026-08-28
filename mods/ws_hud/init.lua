-- ws_hud/init.lua
-- Non-flickering HUD with half-icons, safe thirst/breath logic, and creative-mode skip

ws_hud = {}
ws_hud.players = {}

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------

local ICON_SCALE = 1.5
local SEGMENT_SPACING = 22

local HEALTH_X = -265
local HEALTH_Y = -80

local ARMOR_X = -200
local ARMOR_Y = -110

local RIGHT_X = 20
local THIRST_Y = -120
local HUNGER_Y = -85

local BREATH_X = -200
local BREATH_Y = -130

local RAD_X = -120
local RAD_Y = 20

local TEMP_X = -120
local TEMP_Y = 50

----------------------------------------------------------------------
-- ICONS
----------------------------------------------------------------------

local ICONS = {
    health_full = "hudbars_icon_health.png",
    health_half = "hudbars_icon_health_half.png",

    hunger_full = "ws_hunger_bread.png",
    hunger_half = "ws_hunger_bread_half.png",

    thirst_full = "thirst_hud_icon.png", -- full only

    breath_full = "hudbars_icon_breath.png",
    breath_half = "hudbars_icon_breath_half.png",

    armor_full = "",
    armor_half = "",
}

local BG_TEXTURES = {
    health = "hudbars_bgicon_health.png",
    hunger = "ws_hunger_bread_bg.png",
    thirst = "thirst_hud_bg.png",
    breath = "hudbars_bgicon_breath.png",
    armor = "",
}

----------------------------------------------------------------------
-- SAFE THIRST API DETECTION
----------------------------------------------------------------------

local thirst_api = rawget(_G, "ws_thirst") or rawget(_G, "thirst")

local function thirst_get(playername)
    if not thirst_api then return 0 end
    if thirst_api.get_thirst then
        return thirst_api.get_thirst(playername)
    end
    return 0
end

----------------------------------------------------------------------
-- BREATH LOGIC
----------------------------------------------------------------------

local function is_underwater_clean(player)
    local pos = player:get_pos()
    local node = minetest.get_node(pos)
    local def = minetest.registered_nodes[node.name]
    return def and def.groups and def.groups.water
end

----------------------------------------------------------------------
-- HUD UTILITIES
----------------------------------------------------------------------

local function add_image(player, texture, x, y)
    return player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 1},
        offset = {x = x, y = y},
        text = texture,
        scale = {x = ICON_SCALE, y = ICON_SCALE},
    })
end

local function update_image(player, id, texture)
    player:hud_change(id, "text", texture)
end

local function create_slots(player, bg_texture, icon_count, x, y)
    local bg_ids = {}
    local icon_ids = {}

    for i = 1, icon_count do
        local px = x + (i * SEGMENT_SPACING)

        bg_ids[i] = add_image(player, bg_texture, px, y)
        icon_ids[i] = add_image(player, "", px, y)
    end

    return bg_ids, icon_ids
end

local function update_half_row(player, icon_ids, full_icon, half_icon, value)
    for i = 1, 10 do
        local segment_value = value - ((i - 1) * 2)

        if segment_value >= 2 then
            update_image(player, icon_ids[i], full_icon)
        elseif segment_value == 1 and half_icon then
            update_image(player, icon_ids[i], half_icon)
        else
            update_image(player, icon_ids[i], "")
        end
    end
end

----------------------------------------------------------------------
-- HUD UPDATE
----------------------------------------------------------------------

function ws_hud.update(player)
    local name = player:get_player_name()

    -- ⭐ CREATIVE MODE SKIP
    if minetest.is_creative_enabled(name) then
        return
    end

    local p = ws_hud.players[name]
    if not p then return end

    ------------------------------------------------------------------
    -- HEALTH
    ------------------------------------------------------------------
    update_half_row(player, p.health.icon,
        ICONS.health_full, ICONS.health_half,
        player:get_hp())

    ------------------------------------------------------------------
    -- ARMOR
    ------------------------------------------------------------------
    local inv = player:get_inventory()
    local armor = 0

    if inv:contains_item("armor", "ws_helmet") then armor = armor + 2 end
    if inv:contains_item("armor", "ws_chestplate") then armor = armor + 6 end
    if inv:contains_item("armor", "ws_leggings") then armor = armor + 5 end
    if inv:contains_item("armor", "ws_boots") then armor = armor + 2 end

    update_half_row(player, p.armor.icon,
        ICONS.armor_full, ICONS.armor_half,
        armor)

    ------------------------------------------------------------------
    -- THIRST (full icons only)
    ------------------------------------------------------------------
    local t = thirst_get(name)

    update_half_row(player, p.thirst.icon,
        ICONS.thirst_full,
        ICONS.thirst_full, -- no half icon
        t)

    ------------------------------------------------------------------
    -- HUNGER
    ------------------------------------------------------------------
    local h = ws_hunger.get_satiation(player)

    update_half_row(player, p.hunger.icon,
        ICONS.hunger_full, ICONS.hunger_half,
        h)

    ------------------------------------------------------------------
    -- BREATH (only underwater)
    ------------------------------------------------------------------
    local underwater = is_underwater_clean(player)
    local breath = math.min(player:get_breath(), 20)

    for i = 1, 10 do
        if underwater then
            update_image(player, p.breath.bg[i], BG_TEXTURES.breath)
        else
            update_image(player, p.breath.bg[i], "")
        end
    end

    update_half_row(player, p.breath.icon,
        ICONS.breath_full, ICONS.breath_half,
        underwater and breath or 0)

    ------------------------------------------------------------------
    -- RADIATION
    ------------------------------------------------------------------
    player:hud_change(p.radiation, "text", "Radiation: 0")

    ------------------------------------------------------------------
    -- TEMPERATURE
    ------------------------------------------------------------------
    player:hud_change(p.temperature, "text", "0°C")
end

----------------------------------------------------------------------
-- INIT
----------------------------------------------------------------------

function ws_hud.init(player)
    local name = player:get_player_name()

    -- ⭐ CREATIVE MODE SKIP
    if minetest.is_creative_enabled(name) then
        return
    end

    local flags = player:hud_get_flags()
    flags.healthbar = false
    flags.breathbar = false
    player:hud_set_flags(flags)

    ws_hud.players[name] = {}
    local p = ws_hud.players[name]

    -- Create backgrounds + icon slots
    p.health = {}
    p.health.bg, p.health.icon =
        create_slots(player, BG_TEXTURES.health, 10, HEALTH_X, HEALTH_Y)

    p.armor = {}
    p.armor.bg, p.armor.icon =
        create_slots(player, BG_TEXTURES.armor, 10, ARMOR_X, ARMOR_Y)

    p.thirst = {}
    p.thirst.bg, p.thirst.icon =
        create_slots(player, BG_TEXTURES.thirst, 10, RIGHT_X, THIRST_Y)

    p.hunger = {}
    p.hunger.bg, p.hunger.icon =
        create_slots(player, BG_TEXTURES.hunger, 10, RIGHT_X, HUNGER_Y)

    p.breath = {}
    p.breath.bg, p.breath.icon =
        create_slots(player, BG_TEXTURES.breath, 10, BREATH_X, BREATH_Y)

    -- Radiation + temperature
    p.radiation = player:hud_add({
        hud_elem_type = "text",
        position = {x = 1, y = 0},
        offset = {x = RAD_X, y = RAD_Y},
        text = "Radiation: 0",
        number = 0xFF0000,
    })

    p.temperature = player:hud_add({
        hud_elem_type = "text",
        position = {x = 1, y = 0},
        offset = {x = TEMP_X, y = TEMP_Y},
        text = "0°C",
        number = 0xFFFFFF,
    })

    ws_hud.update(player)
end

----------------------------------------------------------------------
-- REMOVE
----------------------------------------------------------------------

function ws_hud.remove(player)
    local name = player:get_player_name()
    ws_hud.players[name] = nil
end

----------------------------------------------------------------------
-- GLOBALSTEP
----------------------------------------------------------------------

minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        ws_hud.update(player)
    end
end)

minetest.register_on_joinplayer(ws_hud.init)
minetest.register_on_leaveplayer(ws_hud.remove)
