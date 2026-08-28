-- ws_manual/init.lua
local modname  = minetest.get_current_modname()
local modpath  = minetest.get_modpath(modname)
local content  = dofile(modpath .. "/manual_content.lua")

local has_blacksmith = minetest.get_modpath("ws_blacksmith")
local has_lab        = minetest.get_modpath("ws_lab")

------------------------------------------------------------
-- BUILD PAGE LIST
-- Page 0 = Cover
-- Page 1 = Introduction
------------------------------------------------------------
local pages = {}

-- Page 0: Cover
pages[0] = content.cover

-- Page 1+: Core pages (Introduction first)
local idx = 1
for _, p in ipairs(content.core) do
    pages[idx] = p
    idx = idx + 1
end

-- Optional modules
if has_blacksmith then
    pages[idx] = content.blacksmithing
    idx = idx + 1
end

if has_lab then
    pages[idx] = content.dna
    idx = idx + 1
end

-- Recipes last
pages[idx] = content.recipes

local function esc(s)
    return minetest.formspec_escape(s or "")
end

------------------------------------------------------------
-- COVER PAGE (Page 0)
------------------------------------------------------------
local function build_cover_formspec()
    return table.concat({
        "formspec_version[6]",
        "size[10,10]",
        "bgcolor[#00000000]",

        -- Full book cover image
        "image[0,0;10,10;ws_manual_book_cover.png]",

        -- Next button → goes to Page 1 (Introduction)
        "image_button[7,8.5;1.5,1;ws_manual_arrow_right.png;next;]"
    }, "")
end

------------------------------------------------------------
-- MAIN MANUAL PAGE (Page 1+)
------------------------------------------------------------
local function build_manual_formspec(player_name, page_index)
    -- Page 0 = cover
    if page_index == 0 then
        return build_cover_formspec()
    end

    -- Clamp page index
    page_index = math.max(1, math.min(page_index, #pages))
    local page = pages[page_index]

    local title = esc(page.title or ("Page " .. page_index))
    local body  = esc(page.body or "")

    local fs = {
        "formspec_version[6]",
        "size[25.75,12.5]",
        "bgcolor[#00000000]",

        -- Book background
        "background[0,0;25.75,12.5;ws_manual_book_bg.png]",

        -- Title
        "label[4.5,0.6;" .. title .. "]",

        -- Left page text
        "textarea[0.8,1.3;6.2,7.2;;;" .. body .. "]",

        -- Right page area
        "box[7.2,1.2;6.2,7.2;#00000000]"
    }

    ------------------------------------------------------------
    -- IMAGES (right page thumbnails)
    ------------------------------------------------------------
    if page.images then
        local y = 1.4
        for i, img in ipairs(page.images) do
            local id = "ws_manual_view_img:" .. page_index .. ":" .. i
            table.insert(fs,
                string.format("image_button[7.4,%0.2f;5.2,2.6;%s;%s;]", y, img, id))
            y = y + 2.8
        end
    end

    ------------------------------------------------------------
    -- ITEM ICONS
    ------------------------------------------------------------
    if page.items then
        local y = 1.4 + ((page.images and #page.images or 0) * 2.8)
        for j, itemname in ipairs(page.items) do
            local id = "ws_manual_view_item:" .. page_index .. ":" .. j
            table.insert(fs,
                string.format("item_image_button[7.8,%0.2f;1.2,1.2;%s;%s;]", y, itemname, id))
            table.insert(fs,
                string.format("label[9.2,%0.2f;%s]", y + 0.3, esc(itemname)))
            y = y + 1.6
        end
    end

    ------------------------------------------------------------
    -- Navigation buttons
    ------------------------------------------------------------
    table.insert(fs, "image_button[4.0,10.5;1,1;ws_manual_arrow_left.png;prev;]")
    table.insert(fs, "image_button[9.0,10.5;1,1;ws_manual_arrow_right.png;next;]")
    table.insert(fs, string.format("label[6.5,10.6;Page %d / %d]", page_index, #pages))

    return table.concat(fs, "")
end

------------------------------------------------------------
-- REGISTER MANUAL ITEM
------------------------------------------------------------
minetest.register_craftitem("ws_manual:manual", {
    description = "Wastelands Survival Manual",
    inventory_image = "ws_manual_book.png",
    stack_max = 1,

    on_use = function(itemstack, user)
        local name = user:get_player_name()
        user:get_meta():set_int("ws_manual:page", 0)
        minetest.show_formspec(name, "ws_manual:manual_fs", build_cover_formspec())
        return itemstack
    end
})

------------------------------------------------------------
-- FORMSPEC HANDLER
------------------------------------------------------------
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ws_manual:manual_fs" then return end

    local name = player:get_player_name()
    local meta = player:get_meta()
    local page = meta:get_int("ws_manual:page") or 0

    -- Cover → Next → Page 1 (Introduction)
    if fields.next and page == 0 then
        page = 1
        meta:set_int("ws_manual:page", page)
        minetest.show_formspec(name, "ws_manual:manual_fs", build_manual_formspec(name, page))
        return
    end

    -- Navigation
    if fields.next then
        page = page + 1
        if page > #pages then page = 1 end
    elseif fields.prev then
        page = page - 1
        if page < 1 then page = #pages end
    end

    meta:set_int("ws_manual:page", page)

    if fields.next or fields.prev then
        minetest.after(0.05, function()
            minetest.show_formspec(name, "ws_manual:manual_fs", build_manual_formspec(name, page))
        end)
        return
    end

    -- Image / item viewer
    for k in pairs(fields) do
        local pidx, idx

        if k:find("ws_manual_view_img:") then
            _, _, pidx, idx = k:find("ws_manual_view_img:(%d+):(%d+)")
            pidx = tonumber(pidx); idx = tonumber(idx)
            local img = pages[pidx].images[idx]
            minetest.show_formspec(name, "ws_manual:image_viewer", build_image_viewer_formspec(img, false))
            return
        end

        if k:find("ws_manual_view_item:") then
            _, _, pidx, idx = k:find("ws_manual_view_item:(%d+):(%d+)")
            pidx = tonumber(pidx); idx = tonumber(idx)
            local item = pages[pidx].items[idx]
            minetest.show_formspec(name, "ws_manual:image_viewer", build_image_viewer_formspec(item, true))
            return
        end
    end
end)

------------------------------------------------------------
-- GIVE MANUAL ON FIRST JOIN
------------------------------------------------------------
minetest.register_on_newplayer(function(player)
    local inv = player:get_inventory()
    if not inv:contains_item("main", "ws_manual:manual") then
        inv:add_item("main", "ws_manual:manual")
    end
end)

------------------------------------------------------------
-- /manual COMMAND
------------------------------------------------------------
minetest.register_chatcommand("manual", {
    description = "Open the Wastelands Survival Manual",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end
        player:get_meta():set_int("ws_manual:page", 0)
        minetest.show_formspec(name, "ws_manual:manual_fs", build_cover_formspec())
        return true, "Manual opened."
    end
})

------------------------------------------------------------
-- OPTIONAL JOIN HINTS
------------------------------------------------------------
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    if not has_blacksmith then
        minetest.chat_send_player(name,
            minetest.colorize("#c0c0c0", "[Manual] Tip: Install ws_blacksmith to unlock blacksmithing instructions."))
    end
    if not has_lab then
        minetest.chat_send_player(name,
            minetest.colorize("#c0c0c0", "[Manual] Tip: Install ws_lab to get DNA Analyzer instructions."))
    end
end)
