-- Custom Player API (api.lua)
-- Clean written version for Luanti / Minetest 5.x
-- Includes: attachment logic, animation system, model system, custom hotbar control

local API = {}
player_api = API  -- compatibility for mods expecting player_api

------------------------------------------------------------
-- INTERNAL TABLES
------------------------------------------------------------

API.models = {}
API.player_state = {}
API.player_attached = {}
API.hotbar_state = {}

local animation_blend = 0

------------------------------------------------------------
-- MODEL REGISTRATION
------------------------------------------------------------

function API.register_model(name, def)
    API.models[name] = {
        mesh = name,
        textures = def.textures or {},
        animations = def.animations or {},
        animation_speed = def.animation_speed or 30,
        visual_size = def.visual_size or {x = 1, y = 1},
        collisionbox = def.collisionbox or {-0.3, 0, -0.3, 0.3, 1.7, 0.3},
        stepheight = def.stepheight or 0.6,
        eye_height = def.eye_height or 1.47,
    }
end

------------------------------------------------------------
-- PLAYER STATE
------------------------------------------------------------

local function ensure_state(player)
    local name = player:get_player_name()
    local state = API.player_state[name]
    if not state then
        state = {
            model = nil,
            textures = nil,
            anim = nil,
            sneaking = false,
        }
        API.player_state[name] = state
    end
    return state
end

------------------------------------------------------------
-- ATTACHMENT LOGIC
------------------------------------------------------------

function API.set_attached(player, attached)
    local name = player:get_player_name()
    API.player_attached[name] = attached and true or false
end

function API.is_attached(player)
    local name = player:get_player_name()
    return API.player_attached[name] == true
end

------------------------------------------------------------
-- MODEL APPLICATION
------------------------------------------------------------

function API.set_model(player, model_name)
    local state = ensure_state(player)
    local model = API.models[model_name]

    if not model then
        player:set_properties({
            visual = "upright_sprite",
            textures = {"player.png", "player_back.png"},
            collisionbox = {-0.3, 0, -0.3, 0.3, 1.75, 0.3},
            stepheight = 0.6,
            eye_height = 1.625,
        })
        state.model = nil
        return
    end

    if state.model == model_name then
        return
    end

    state.model = model_name
    state.textures = state.textures or model.textures

    player:set_properties({
        mesh = model.mesh,
        visual = "mesh",
        textures = state.textures,
        visual_size = model.visual_size,
        collisionbox = model.collisionbox,
        stepheight = model.stepheight,
        eye_height = model.eye_height,
    })

    API.set_animation(player, "stand")
end

------------------------------------------------------------
-- TEXTURE APPLICATION
------------------------------------------------------------

function API.set_textures(player, textures)
    local state = ensure_state(player)
    local model = API.models[state.model]

    state.textures = textures or (model and model.textures)
    player:set_properties({textures = state.textures})
end

------------------------------------------------------------
-- ANIMATION HANDLING
------------------------------------------------------------

function API.set_animation(player, anim_name, speed)
    local state = ensure_state(player)
    local model = API.models[state.model]

    if not model then return end
    if state.anim == anim_name then return end

    local anim = model.animations[anim_name]
    if not anim then return end

    state.anim = anim_name
    player:set_animation(anim, speed or model.animation_speed, animation_blend)
end

function API.get_animation(player)
    local state = ensure_state(player)
    return {
        model = state.model,
        textures = state.textures,
        animation = state.anim,
    }
end

------------------------------------------------------------
-- HOTBAR CONTROL
------------------------------------------------------------

-- Default hotbar textures
API.hotbar_default = {
    bar = "gui_hotbar.png",
    selected = "gui_hotbar_selected.png",
}

function API.init_hotbar(player)
    local name = player:get_player_name()

    -- Remove engine hotbar
    local flags = player:hud_get_flags()
    flags.hotbar = false
    player:hud_set_flags(flags)

    -- Create custom hotbar HUD
    local ids = {}

    ids.bar = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -80},
        scale = {x = 1, y = 1},
        alignment = {x = 0, y = 0},
        text = API.hotbar_default.bar,
    })

    ids.selected = player:hud_add({
        hud_elem_type = "image",
        position = {x = 0.5, y = 1},
        offset = {x = -91 + (0 * 20), y = -80}, -- slot 0 highlight
        scale = {x = 1, y = 1},
        alignment = {x = 0, y = 0},
        text = API.hotbar_default.selected,
    })

    API.hotbar_state[name] = {
        ids = ids,
        selected = 0,
    }
end

function API.update_hotbar_selection(player, slot)
    local name = player:get_player_name()
    local state = API.hotbar_state[name]
    if not state then return end

    state.selected = slot

    player:hud_change(state.ids.selected, "offset", {
        x = -91 + (slot * 20),
        y = -80
    })
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    API.player_state[name] = nil
    API.player_attached[name] = nil
    API.hotbar_state[name] = nil
end)

------------------------------------------------------------
-- GLOBALSTEP ANIMATION LOOP
------------------------------------------------------------

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        if API.is_attached(player) then
            goto continue
        end

        local name = player:get_player_name()
        local state = API.player_state[name]
        if not state then goto continue end

        local model = API.models[state.model]
        if not model then goto continue end

        local ctrl = player:get_player_control()
        local walking = ctrl.up or ctrl.down or ctrl.left or ctrl.right
        local speed = model.animation_speed

        if ctrl.sneak then
            speed = speed * 0.5
        end

        if player:get_hp() <= 0 then
            API.set_animation(player, "lay")
        elseif walking then
            if ctrl.LMB then
                API.set_animation(player, "walk_mine", speed)
            else
                API.set_animation(player, "walk", speed)
            end
        elseif ctrl.LMB then
            API.set_animation(player, "mine")
        else
            API.set_animation(player, "stand", speed)
        end

        ::continue::
    end
end)
