-- ws_manual/init.lua
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)
local content = dofile(modpath .. "/manual_content.lua")

local has_blacksmith = minetest.get_modpath("ws_blacksmith") ~= nil
local has_lab = minetest.get_modpath("ws_lab") ~= nil

-- Build pages list based on detected mods
local pages = {}
for _, p in ipairs(content.core) do table.insert(pages, p) end
if has_blacksmith then table.insert(pages, content.blacksmithing) end
if has_lab then table.insert(pages, content.dna) end
table.insert(pages, content.recipes)

-- Helper to escape text for formspec textarea or label
local function esc(s)
    return minetest.formspec_escape(s or "")
end

-- Builds the main manual page formspec for given page index.
-- We layout: Title (label), body (textarea-like with limited height), thumbnails (images/item_image),
-- Prev/Next buttons, page indicator, and icon.
local function build_manual_formspec(player_name, page_index)
    page_index = page_index or 1
    if page_index < 1 then page_index = 1 end
    if page_index > #pages then page_index = #pages end
    local page = pages[page_index]
    local title = esc(page.title or ("Page " .. page_index))
    local body = esc(page.body or "")

    -- We'll render body in a textarea sized to allow comfortable reading.
    -- Thumbnails area: we reserve a right-side column to show images and item icons stacked vertically.
    local formspec_parts = {}

    table.insert(formspec_parts, "formspec_version[6]")
    table.insert(formspec_parts, "size[12,8]")
    table.insert(formspec_parts, "bgcolor[#000000aa]")
    table.insert(formspec_parts, "label[0.5,0.4;Wastelands Survival Manual]")
    table.insert(formspec_parts, "box[0.4,0.85;10.8,6.2;#111111dd]")

    -- Title and body
    table.insert(formspec_parts, "label[0.6,0.95;" .. title .. "]")
    table.insert(formspec_parts, "textarea[0.6,1.35;8.6,5.1;manual_body;;" .. body .. "]")

    -- Right column for thumbnails (images and items)
    local thumb_x = 9.3
    local thumb_y = 1.35
    local thumb_w = 2.2
    local thumb_h = 1.6
    local pad = 0.15

    -- Add image thumbnails
    if page.images then
        for i, img in ipairs(page.images) do
            local y = thumb_y + (i - 1) * (thumb_h + pad)
            -- Each thumbnail is an image_button so it can be clicked to view bigger
            -- id format: ws_manual_view_img:<page_index>:<i>
            local id = "ws_manual_view_img:" .. page_index .. ":" .. i
            table.insert(formspec_parts,
                string.format("image_button[%0.3f,%0.3f;%0.3f,%0.3f;%s;%s;]", thumb_x, y, thumb_w, thumb_h, img, id))
        end
    end

    -- Add item icons below images (if any)
    if page.items then
        for j, itemname in ipairs(page.items) do
            local idx = (page.images and #page.images or 0) + j
            local y = thumb_y + (idx - 1) * (thumb_h + pad)
            local id = "ws_manual_view_item:" .. page_index .. ":" .. j
            -- Use item_image to render registered item/creative icon
            table.insert(formspec_parts,
                string.format("item_image_button[%0.3f,%0.3f;%0.9f,%0.9f;%s;%s;]", thumb_x + 0.65, y + 0.35, 1.0, 1.0, itemname, id))
            -- add a small label beneath
            table.insert(formspec_parts,
                string.format("label[%0.3f,%0.3f;%s]", thumb_x + 0.05, y + 1.15, esc(itemname)))
        end
    end

    -- Prev / Next / Close buttons & page indicator
    table.insert(formspec_parts, string.format("button[3.4,6.9;1.6,0.6;prev;Prev]"))
    table.insert(formspec_parts, string.format("button[5.2,6.9;1.6,0.6;next;Next]"))
    table.insert(formspec_parts, string.format("button_exit[8.5,6.9;1.8,0.6;close;Close]"))
    table.insert(formspec_parts, string.format("label[7.0,6.9;Page %d / %d]", page_index, #pages))

    -- small icon top-right
    table.insert(formspec_parts,
        string.format("image[10.8,0.2;1.2,1.2;ws_manual_icon.png]"))

    return table.concat(formspec_parts, "")
end

-- Build image viewer formspec (larger view). id format used in on_receive_fields to detect which image/item to view.
local function build_image_viewer_formspec(img_path_or_item, is_item)
    local body
    if is_item then
        -- We'll show an item_image for larger view
        body = string.format("size[6,6]image[0.6,0.6;5,4.5;%s]\nbutton_exit[2.2,5.4;1.6,0.6;close;Close]", img_path_or_item)
        -- Note: item_image does not accept item_image alone outside of item_image element;
        -- use item_image for icons: item_image is used as part of element, but for simplicity,
        -- we fallback to itemstring label + image_button if needed.
        -- Use item_image_button with same item to show big icon:
        return ("formspec_version[6]size[6,6]bgcolor[#000000aa]item_image_button[0.8,0.6;4.4,4.4;" .. img_path_or_item .. ";_ws_manual_img_view;]")
               .. "button_exit[2.2,5.2;1.6,0.6;close;Close]"
    else
        return ("formspec_version[6]size[8,6]bgcolor[#000000aa]image[0.6,0.6;7.0,4.8;" .. img_path_or_item .. "]")
               .. "button_exit[3.1,5.2;1.6,0.6;close;Close]"
    end
end

-- Register manual craftitem (same as before)
minetest.register_craftitem("ws_manual:manual", {
    description = "Wastelands Survival Manual",
    inventory_image = "ws_manual_book.png",
    stack_max = 1,

    on_use = function(itemstack, user)
        local player = user
        local name = player:get_player_name()
        local page_index = player:get_meta():get_int("ws_manual:page") or 1
        local formspec = build_manual_formspec(name, page_index)
        minetest.show_formspec(name, "ws_manual:manual_fs", formspec)
        return itemstack
    end
})

-- Handle formspec interactions
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "ws_manual:manual_fs" then
        local name = player:get_player_name()
        local meta = player:get_meta()
        local page = meta:get_int("ws_manual:page") or 1

        -- Prev / Next
        if fields.next then
            page = page + 1
            if page > #pages then page = 1 end
            meta:set_int("ws_manual:page", page)
            minetest.after(0.05, function() -- small delay to avoid UI race
                minetest.show_formspec(name, "ws_manual:manual_fs", build_manual_formspec(name, page))
            end)
            return
        elseif fields.prev then
            page = page - 1
            if page < 1 then page = #pages end
            meta:set_int("ws_manual:page", page)
            minetest.after(0.05, function()
                minetest.show_formspec(name, "ws_manual:manual_fs", build_manual_formspec(name, page))
            end)
            return
        end

        -- Clicked image thumbnail? fields keys look like: ws_manual_view_img:<page>:<i>
        for k, v in pairs(fields) do
            if k:sub(1,18) == "ws_manual_view_img:" then
                -- parse page and index
                local _, _, pidx, idx = k:find("ws_manual_view_img:(%d+):(%d+)")
                pidx = tonumber(pidx); idx = tonumber(idx)
                if pages[pidx] and pages[pidx].images and pages[pidx].images[idx] then
                    local img = pages[pidx].images[idx]
                    minetest.show_formspec(name, "ws_manual:image_viewer", build_image_viewer_formspec(img, false))
                    return
                end
            elseif k:sub(1,19) == "ws_manual_view_item:" then
                local _, _, pidx, idx = k:find("ws_manual_view_item:(%d+):(%d+)")
                pidx = tonumber(pidx); idx = tonumber(idx)
                if pages[pidx] and pages[pidx].items and pages[pidx].items[idx] then
                    local item = pages[pidx].items[idx]
                    minetest.show_formspec(name, "ws_manual:image_viewer", build_image_viewer_formspec(item, true))
                    return
                end
            end
        end
    end

    -- If the image viewer formspec is used, nothing special needed: closing will return.
end)

-- Give manual on new player spawn (optional)
minetest.register_on_newplayer(function(player)
    local inv = player:get_inventory()
    if not inv:contains_item("main", "ws_manual:manual") then
        inv:add_item("main", "ws_manual:manual")
    end
end)

-- Chat command to open manual
minetest.register_chatcommand("manual", {
    params = "",
    description = "Open the Wastelands Survival Manual",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        player:get_meta():set_int("ws_manual:page", 1)
        minetest.show_formspec(name, "ws_manual:manual_fs", build_manual_formspec(name, 1))
        return true, "Manual opened."
    end
})

-- Optional join hints
minetest.register_on_joinplayer(function(player)
    if not has_blacksmith then
        minetest.chat_send_player(player:get_player_name(),
            minetest.colorize("#c0c0c0", "[Manual] Tip: Install ws_blacksmith to unlock blacksmithing instructions."))
    end
    if not has_lab then
        minetest.chat_send_player(player:get_player_name(),
            minetest.colorize("#c0c0c0", "[Manual] Tip: Install ws_lab to get DNA Analyzer instructions."))
    end
end)
