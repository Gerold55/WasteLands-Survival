local MODNAME = "ws_creative"

-- Per-player state
local player_page = {}
local player_search = {}
local ITEMS_PER_PAGE = 9 * 6  -- 9 columns x 6 rows

-- Detached inventory for creative items
local creative_inv = minetest.create_detached_inventory(MODNAME .. "_creative", {
    allow_move = function() return 0 end,
    allow_put  = function() return 0 end,
    allow_take = function() return 0 end,
})

----------------------------------------------------------------------
-- COLLECT ALL CREATIVE ITEMS
----------------------------------------------------------------------

local function get_all_items()
    local list = {}
    for name, def in pairs(minetest.registered_items) do
        if not def.groups.not_in_creative_inventory then
            list[#list + 1] = name
        end
    end
    table.sort(list)
    return list
end

----------------------------------------------------------------------
-- FILTER BY SEARCH
----------------------------------------------------------------------

local function filter_items(search)
    local all = get_all_items()
    if not search or search == "" then
        return all
    end

    local filtered = {}
    search = search:lower()

    for _, name in ipairs(all) do
        if name:lower():find(search, 1, true) then
            filtered[#filtered + 1] = name
        end
    end

    return filtered
end

----------------------------------------------------------------------
-- REFILL PAGE
----------------------------------------------------------------------

local function refill_page(player)
    local pname = player:get_player_name()
    local page = player_page[pname] or 1
    local search = player_search[pname] or ""

    local items = filter_items(search)
    local total_pages = math.max(1, math.ceil(#items / ITEMS_PER_PAGE))

    if page < 1 then page = 1 end
    if page > total_pages then page = total_pages end
    player_page[pname] = page

    creative_inv:set_size("main", ITEMS_PER_PAGE)

    local start_index = (page - 1) * ITEMS_PER_PAGE + 1
    for i = 1, ITEMS_PER_PAGE do
        local item_name = items[start_index + i - 1]
        if item_name then
            creative_inv:set_stack("main", i, ItemStack(item_name))
        else
            creative_inv:set_stack("main", i, ItemStack(""))
        end
    end

    return total_pages
end

----------------------------------------------------------------------
-- FORMSPEC (ADJUSTED)
----------------------------------------------------------------------

local function get_formspec(player)
    local pname = player:get_player_name()
    local page = player_page[pname] or 1
    local search = player_search[pname] or ""
    local total_pages = refill_page(player)

    return table.concat({
        "formspec_version[4]",
        "size[11.5,11.8]",
        "background[-0.5,-0.5;12,11.8;ws_creative_bg.png]",

        -- Title
        "label[0.05,0.14;All Creative Tabs (" .. page .. "/" .. total_pages .. ")]",
        "style_type[label;font=mono;color=#FFFFFF]",

        -- Page arrows
        "button[9,0.3;0.8,0.8;prev;<]",
        "button[10,0.3;0.8,0.8;next;>]",

        -- Search bar (spaced properly)
        "field[0.12,1.0;5,0.5;search;Search...;" .. search .. "]",
        "field_close_on_enter[search;false]",

        -- Creative grid (centered, spaced)
        "list[detached:" .. MODNAME .. "_creative;main;0.08,2.2;9,9;]",
        "listring[detached:" .. MODNAME .. "_creative;main]",
        "listring[current_player;main]",

        -- Hotbar (aligned)
        "list[current_player;main;0.08,10;9,1;]",
    })
end

----------------------------------------------------------------------
-- PLAYER JOIN
----------------------------------------------------------------------

minetest.register_on_joinplayer(function(player)
    local pname = player:get_player_name()
    player_page[pname] = 1
    player_search[pname] = ""

    player:hud_set_hotbar_itemcount(9)
    player:set_inventory_formspec(get_formspec(player))
end)

----------------------------------------------------------------------
-- HANDLE BUTTONS + SEARCH
----------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local pname = player:get_player_name()

    -- Page buttons
    if fields.prev then
        player_page[pname] = (player_page[pname] or 1) - 1
    elseif fields.next then
        player_page[pname] = (player_page[pname] or 1) + 1
    end

    -- Search bar
    if fields.search then
        player_search[pname] = fields.search
        player_page[pname] = 1  -- reset to first page when searching
    end

    player:set_inventory_formspec(get_formspec(player))
end)
