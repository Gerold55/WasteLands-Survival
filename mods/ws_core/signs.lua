-- ws_core: Minecraft‑style writable sign with visible text
-- Single‑file version

-- Nodebox model (Minecraft‑like sign + post)
local sign_nodebox = {
    -- Post
    { -0.0625, -0.5, -0.0625, 0.0625, 0.125, 0.0625 },

    -- Board
    { -0.5, 0.125, -0.0625, 0.5, 0.375, 0.0625 }
}

-- Entity that displays text on the sign
minetest.register_entity("ws_core:sign_text", {
    initial_properties = {
        visual = "upright_sprite",
        textures = {"ws_sign_text_placeholder.png"},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = true,
        glow = 0,
    },

    text = "",

    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            self.text = staticdata
        end
        self.object:set_properties({
            infotext = self.text,
            textures = { "ws_core_textgen:" .. minetest.formspec_escape(self.text) }
        })
    end,

    get_staticdata = function(self)
        return self.text
    end,
})

-- Helper: spawn text entity
local function update_sign_text(pos, text)
    -- Remove old text entities
    local objs = minetest.get_objects_inside_radius(pos, 0.5)
    for _, obj in ipairs(objs) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "ws_core:sign_text" then
            obj:remove()
        end
    end

    -- Spawn new text entity
    local obj = minetest.add_entity({
        x = pos.x,
        y = pos.y + 0.32,
        z = pos.z
    }, "ws_core:sign_text")

    if obj then
        local ent = obj:get_luaentity()
        ent.text = text
        obj:set_properties({
            textures = { "ws_core_textgen:" .. minetest.formspec_escape(text) }
        })
    end
end

-- Register the sign node
minetest.register_node("ws_core:sign", {
    description = "Wasteland Sign",
    drawtype = "nodebox",
    node_box = {
        type = "fixed",
        fixed = sign_nodebox
    },
    tiles = {"ws_sign_wood.png"},
    paramtype = "light",
    sunlight_propagates = true,
    groups = {choppy = 2, oddly_breakable_by_hand = 2},
    drop = "ws_core:sign",

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("text", "")
        meta:set_string("infotext", "")
        update_sign_text(pos, "")
    end,

    after_place_node = function(pos)
        update_sign_text(pos, "")
    end,

    on_destruct = function(pos)
        -- Remove text entity
        local objs = minetest.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "ws_core:sign_text" then
                obj:remove()
            end
        end
    end,

    on_rightclick = function(pos, node, clicker)
        local meta = minetest.get_meta(pos)
        local t = meta:get_string("text")
        local lines = t:split("\n")

        minetest.show_formspec(
            clicker:get_player_name(),
            "ws_core:sign_editor",
            "size[10,6]" ..
            "label[0,0;Edit Sign]" ..
            "field[0.5,1;9,1;line1;Line 1:;" .. minetest.formspec_escape(lines[1] or "") .. "]" ..
            "field[0.5,2;9,1;line2;Line 2:;" .. minetest.formspec_escape(lines[2] or "") .. "]" ..
            "field[0.5,3;9,1;line3;Line 3:;" .. minetest.formspec_escape(lines[3] or "") .. "]" ..
            "field[0.5,4;9,1;line4;Line 4:;" .. minetest.formspec_escape(lines[4] or "") .. "]" ..
            "button_exit[4,5;2,1;save;Save]"
        )

        ws_core_sign_edit_pos = pos
    end,
})

-- Handle saving the sign text
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ws_core:sign_editor" then return end
    if not fields.save then return end

    local pos = ws_core_sign_edit_pos
    if not pos then return end

    local meta = minetest.get_meta(pos)

    local text = table.concat({
        fields.line1 or "",
        fields.line2 or "",
        fields.line3 or "",
        fields.line4 or ""
    }, "\n")

    meta:set_string("text", text)
    meta:set_string("infotext", text)

    update_sign_text(pos, text)

    ws_core_sign_edit_pos = nil
end)

-- Optional crafting recipe (Minecraft‑style)
minetest.register_craft({
    output = "ws_core:sign",
    recipe = {
        {"ws_core:wood", "ws_core:wood", "ws_core:wood"},
        {"ws_core:wood", "ws_core:stick", "ws_core:wood"},
        {"", "ws_core:stick", ""}
    }
})
