local MODNAME = "ws_creative"

local PLAYER_STATE = {}

local COLS = 9
local ROWS = 8
local PAGE_SIZE = COLS * ROWS

----------------------------------------------------------------------
-- Build per-player creative state and detached inventory
----------------------------------------------------------------------

local function init_player(player)
    local name = player:get_player_name()

    if PLAYER_STATE[name] then
        return PLAYER_STATE[name]
    end

    local state = {
        start_i = 0,
        filter = "",
        items = {},
    }
    PLAYER_STATE[name] = state

    -- Create detached inventory for this player
    local inv = minetest.create_detached_inventory("creative_" .. name, {
        allow_move = function() return 0 end,
        allow_put  = function() return 0 end,
        allow_take = function(inv, listname, index, stack, player2)
            return stack:get_count()
        end,
    })

    -- Collect all creative items
    local items = {}
    for item, def in pairs(minetest.registered_items) do
        if not def.groups.not_in_creative_inventory then
            items[#items+1] = item
        end
    end
    table.sort(items)

    state.items = items

    -- Fill detached inventory ONCE with full list
    inv:set_size("main", #items)
    inv:set_list("main", items)

    return state
end

----------------------------------------------------------------------
-- Build formspec
----------------------------------------------------------------------

local function get_formspec(player)
    local name = player:get_player_name()
    local st = init_player(player)

    local total = #st.items
    local page = math.floor(st.start_i / PAGE_SIZE) + 1
    local max_page = math.max(1, math.ceil(total / PAGE_SIZE))

    return table.concat({
        "formspec_version[4]",
        "size[14,13]",

        "label[0.4,0.4;Page " .. page .. " / " .. max_page .. "]",
        "button[10.5,0.2;1,0.8;prev;<]",
        "button[11.7,0.2;1,0.8;next;>]",

        -- Creative grid: window into detached inventory using start_i
        "list[detached:creative_" .. name .. ";main;0.4,1.4;9,8;" .. st.start_i .. "]",
        "listring[detached:creative_" .. name .. ";main]",
        "listring[current_player;main]",

        -- Search field
        "field[0.4,10.4;7.5,0.8;search;Search...;" .. st.filter .. "]",
        "field_close_on_enter[search;false]",

        -- Hotbar
        "list[current_player;main;0.4,11.4;9,1;]",
    })
end

----------------------------------------------------------------------
-- Override inventory on join
----------------------------------------------------------------------

minetest.register_on_joinplayer(function(player)
    init_player(player)
    player:hud_set_hotbar_itemcount(9)
    player:set_inventory_formspec(get_formspec(player))
end)

----------------------------------------------------------------------
-- Handle formspec input
----------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
    local name = player:get_player_name()
    local st = init_player(player)

    -- Close → immediately restore creative inventory
    if fields.quit then
        minetest.after(0, function()
            player:set_inventory_formspec(get_formspec(player))
        end)
        return
    end

    local total = #st.items

    -- Paging with arrows
    if fields.prev then
        st.start_i = st.start_i - PAGE_SIZE
        if st.start_i < 0 then
            st.start_i = math.max(0, total - PAGE_SIZE)
        end
    elseif fields.next then
        st.start_i = st.start_i + PAGE_SIZE
        if st.start_i >= total then
            st.start_i = 0
        end
    end

    -- Search
    if fields.search then
        st.filter = fields.search
        st.start_i = 0

        -- Rebuild filtered list
        local filtered = {}
        for _, item in ipairs(st.items) do
            if item:lower():find(st.filter:lower(), 1, true) then
                filtered[#filtered+1] = item
            end
        end

        local inv = minetest.get_inventory({type = "detached", name = "creative_" .. name})
        inv:set_size("main", #filtered)
        inv:set_list("main", filtered)

        st.items = filtered
        total = #st.items
    end

    -- Redraw formspec after any change
    player:set_inventory_formspec(get_formspec(player))
end)
