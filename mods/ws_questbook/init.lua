-- ws_questbook/init.lua
ws_questbook = {}

--------------------------------------------------
-- STORAGE
--------------------------------------------------
local storage = core.get_mod_storage()

ws_questbook.quests = storage:get_string("quests")
if ws_questbook.quests == "" then
    ws_questbook.quests = {}
else
    ws_questbook.quests = core.deserialize(ws_questbook.quests) or {}
end

ws_questbook.player_data = {}

--------------------------------------------------
-- UTILS
--------------------------------------------------
local function split_lines(str)
    local t = {}
    for line in (str or ""):gmatch("[^\r\n]+") do
        table.insert(t, line)
    end
    return t
end

local function save_quests()
    storage:set_string("quests", core.serialize(ws_questbook.quests))
end

--------------------------------------------------
-- PLAYER DATA
--------------------------------------------------
local function pdata(name)
    if not ws_questbook.player_data[name] then
        ws_questbook.player_data[name] = {
            active = {},
            progress = {},
            completed = {}
        }
    end
    return ws_questbook.player_data[name]
end

--------------------------------------------------
-- QUESTBOOK UI (LIST)
--------------------------------------------------
function ws_questbook.show_quest_list(name)
    local fs = "size[12,8]"
    fs = fs .. "label[0.3,0.2;Quest Book]"

    local y = 0.8
    for id, q in pairs(ws_questbook.quests) do
        fs = fs .. "button[0.3,"..y..";6,0.8;open_"..id..";"..q.title.."]"
        y = y + 0.9
    end

    core.show_formspec(name, "ws_questbook:list", fs)
end

--------------------------------------------------
-- QUEST VIEW
--------------------------------------------------
function ws_questbook.show_quest(name, id)
    local q = ws_questbook.quests[id]
    if not q then return end

    local data = pdata(name)
    data.active[id] = true
    data.progress[id] = data.progress[id] or {}

    local fs = "size[16,9]"
    fs = fs .. "label[0.2,0.2;"..q.title.."]"
    fs = fs .. "textarea[0.3,0.8;7.5,3.5;;;"..q.description.."]"

    fs = fs .. "label[0.3,4.5;Rewards]"
    local y = 5
    for _,r in ipairs(q.rewards.fixed or {}) do
        fs = fs .. "item_image[0.3,"..y..";1,1;"..r.item.."]"
        fs = fs .. "label[1.5,"..(y+0.3)..";x"..r.amount.."]"
        y = y + 1
    end

    fs = fs .. "box[8,0;0.05,9;#000]"
    fs = fs .. "label[8.3,0.2;Tasks]"

    local ty = 0.8
    for i,t in ipairs(q.tasks) do
        local done = data.progress[id][i] or 0
        fs = fs .. "label[8.3,"..ty..";"..t.name.."]"
        fs = fs .. "label[8.3,"..(ty+0.5)..";"..done.." / "..t.amount.."]"
        ty = ty + 1.2
    end

    fs = fs .. "button[0.3,8;2.5,0.8;back;Back]"
    core.show_formspec(name, "ws_questbook:view:"..id, fs)
end

--------------------------------------------------
-- QUEST EDITOR
--------------------------------------------------
function ws_questbook.show_editor(name, id)
    local q = ws_questbook.quests[id] or {
        title = "",
        description = "",
        tasks = {},
        rewards = { fixed={} },
        icon = ""
    }

    local fs = table.concat({
  "size[18,10]",

  -- Background panels
  "box[0,0;18,10;#2a2a2acc]",

  -- LEFT: Quest Meta
  "box[0.2,0.2;7.2,9.6;#3a3a3aff]",
  "label[0.4,0.3;Edit Quest]",
  "field[0.4,1.2;6.8,0.8;title;Title;]",
  "field[0.4,2.2;6.8,0.8;qid;Quest ID;]",
  "textarea[0.4,3.4;6.8,3;desc;Description;]",

  "label[0.4,6.6;Rewards]",
  "textarea[0.4,7.2;6.8,1.8;rewards;item amount;]",

  -- MIDDLE: Tasks
  "box[7.6,0.2;5,9.6;#333333ff]",
  "label[7.8,0.3;Tasks]",

  -- Example task row
  "item_image[7.8,1.2;1,1;default:tree]",
  "label[9,1.3;Any tree]",
  "label[9,1.8;0 / 10]",

  "button[7.8,8.8;2.2,0.8;add_task;Add Task]",

  -- RIGHT: Item Browser
  "box[12.8,0.2;4.8,9.6;#2f2f2fff]",
  "label[13,0.3;Items]",
  "field[13,1.1;3.6,0.8;search;Search;]",
  "textlist[13,2;4.4,5.8;itemlist;default:tree,default:chest]",
  "item_image[13,8;1.2,1.2;default:tree]",
  "button[14.4,8.2;2.8,0.8;use_icon;Use for Icon]",

  -- Bottom buttons
  "button[6.5,9.2;2.5,0.8;save;Save]",
  "button[9.5,9.2;2.5,0.8;cancel;Cancel]"
})
    core.show_formspec(name, "ws_questbook:edit:"..(id or "new"), fs)
end

--------------------------------------------------
-- FORMSPEC HANDLER
--------------------------------------------------
core.register_on_player_receive_fields(function(player, form, fields)
    local name = player:get_player_name()

    if form == "ws_questbook:list" then
        for f in pairs(fields) do
            if f:sub(1,5) == "open_" then
                ws_questbook.show_quest(name, f:sub(6))
            end
        end
    end

    if form:find("ws_questbook:view:") then
        if fields.back then
            ws_questbook.show_quest_list(name)
        end
    end

    if form:find("ws_questbook:edit:") and fields.save then
        local id = fields.id ~= "" and fields.id or fields.title:gsub("%s","_"):lower()
        local quest = {
            title = fields.title,
            description = fields.desc,
            tasks = {},
            rewards = { fixed={} }
        }

        for _,line in ipairs(split_lines(fields.tasks)) do
            local t,n,a = line:match("([^:]+):([^=]+)=([^=]+)")
            if t then
                table.insert(quest.tasks, {
                    type=t, name=n, amount=tonumber(a) or 1
                })
            end
        end

        for _,line in ipairs(split_lines(fields.rewards)) do
            local item, amt = line:match("([^%s]+)%s+(%d+)")
            if item then
                table.insert(quest.rewards.fixed, {
                    item=item, amount=tonumber(amt)
                })
            end
        end

        ws_questbook.quests[id] = quest
        save_quests()
        core.chat_send_player(name, "Quest saved: "..id)
    end
end)

--------------------------------------------------
-- CHAT COMMANDS
--------------------------------------------------
core.register_chatcommand("questbook", {
    description = "Open quest book",
    func = function(name)
        ws_questbook.show_quest_list(name)
    end
})

core.register_chatcommand("questeditor", {
    privs = {server=true},
    description = "Open quest editor",
    func = function(name)
        ws_questbook.show_editor(name)
    end
})
