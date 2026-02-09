-- ws_blacksmith/init.lua
-- Mini Tinkers-Style Smeltery Mod for Wastelands Survival (Luanti 5.14+)

ws_blacksmith = {}
local modname = "ws_blacksmith"

--==============================
-- 1. Materials & Alloys
--==============================
ws_materials = {
    {name="iron", durability=250, speed=6, damage=4},
    {name="copper", durability=100, speed=4, damage=2},
    {name="tin", durability=60, speed=3, damage=1},
    {name="steel", durability=500, speed=7, damage=5},
    {name="bronze", durability=200, speed=5, damage=3}
}

ws_alloys = {
    {ingredients={"iron","carbon"}, result="steel"},
    {ingredients={"copper","tin"}, result="bronze"}
}

function table.contains(tbl, val)
    for _,v in ipairs(tbl) do if v==val then return true end end
    return false
end

function combine_alloy(mats)
    for _, alloy in ipairs(ws_alloys) do
        local match = true
        for _, ing in ipairs(alloy.ingredients) do
            if not table.contains(mats, ing) then match = false break end
        end
        if match then return alloy.result end
    end
    return nil
end

--==============================
-- 2. Smeltery System
--==============================
ws_smeltery = {
    input_block = {ores={}},
    alloy_block = {},
    output_block = {result=nil},
    lava_tank = {amount=0, capacity=1000}
}

function ws_smeltery.input_block:add_ore(ore)
    table.insert(self.ores, ore)
end

function ws_smeltery.lava_tank:add_lava(amount)
    self.amount = math.min(self.amount + amount, self.capacity)
end

function ws_smeltery.lava_tank:use_lava(amount)
    if self.amount >= amount then
        self.amount = self.amount - amount
        return true
    else
        return false
    end
end

function ws_smeltery.alloy_block:combine(inv, meta)
    local ores = {}
    for i=1,inv:get_size("input") do
        local stack = inv:get_stack("input",i)
        if not stack:is_empty() then
            local name = stack:get_name()
            if name == "default:iron_lump" then table.insert(ores,"iron") end
            if name == "default:copper_lump" then table.insert(ores,"copper") end
            if name == "default:tin_lump" then table.insert(ores,"tin") end
            if name == "default:coal_lump" then table.insert(ores,"carbon") end
            stack:take_item(1)
            inv:set_stack("input",i,stack)
        end
    end

    if #ores>0 and meta:get_int("lava")>=50 then
        meta:set_int("lava", meta:get_int("lava")-50)
        local result = combine_alloy(ores) or ores[1]
        inv:set_stack("output",1,result.."")
    end
end

function ws_smeltery:pour_to_casting(inv, target)
    local stack = inv:get_stack("output",1)
    if not stack:is_empty() then
        ws_casting:add_metal(stack:get_name(),100,target)
        inv:set_stack("output",1,"")
    end
end

--==============================
-- 3. Casting System
--==============================
ws_stencils = {"blade","handle","extra"}
ws_molds = {}
ws_casting = {table={}, basin={}}

function create_mold(material, stencil)
    if not table.contains(ws_stencils, stencil) then return nil end
    local mold_name = material.."_"..stencil.."_mold"
    ws_molds[mold_name] = {material=material, stencil=stencil}
    return mold_name
end

function ws_casting:add_metal(type, amount, target)
    local storage = target=="table" and self.table or self.basin
    if not storage[type] then storage[type]=0 end
    storage[type] = storage[type] + amount
end

function ws_casting:cast_with_mold(mold, molten_material)
    if not ws_molds[mold] then return nil end
    local shape = ws_molds[mold].stencil
    local amount_needed = 50
    if self.table[molten_material] and self.table[molten_material]>=amount_needed then
        self.table[molten_material] = self.table[molten_material] - amount_needed
        return molten_material.."_"..shape
    end
    return nil
end

--==============================
-- 4. Tool Crafting
--==============================
function craft_tool(parts)
    local head_mat, handle_mat, extra_mat
    for _, mat in ipairs(ws_materials) do
        if parts.head and parts.head:find(mat.name) then head_mat=mat end
        if parts.handle and parts.handle:find(mat.name) then handle_mat=mat end
        if parts.extra and parts.extra:find(mat.name) then extra_mat=mat end
    end
    if not head_mat or not handle_mat then return nil end

    local durability = head_mat.durability + (handle_mat.durability*0.5)
    if extra_mat then durability = durability + (extra_mat.durability*0.25) end
    local speed = head_mat.speed*0.7 + handle_mat.speed*0.3
    local damage = head_mat.damage
    if extra_mat then damage = damage + extra_mat.damage*0.5 end

    return {name=parts.head.."_"..parts.handle.."_tool", durability=durability, speed=speed, damage=damage}
end

--==============================
-- 5. Node & Item Registration
--==============================

-- Smeltery Controller
minetest.register_node("ws_blacksmith:smeltery_input", {
    description = "Smeltery Controller",
    tiles = {"ws_smelt_bricks.png","ws_smelt_bricks.png","ws_smelt_bricks.png","ws_smelt_bricks.png","ws_smelt_bricks.png","ws_smelt_controller.png"},
    groups = {cracky=3, oddly_breakable_by_hand=2},
    paramtype2 = "facedir",
    on_place = minetest.rotate_node,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext","Smeltery Controller")
        meta:set_int("lava",0)
        local inv = meta:get_inventory()
        inv:set_size("input",9)
        inv:set_size("output",1)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local lava_percent = math.floor((meta:get_int("lava")/1000)*100)
        local output_item = inv:get_stack("output",1):get_name()
        if output_item=="" then output_item="Empty" end

        local formspec =
            "size[8,6]"..
            "label[0,0;Smeltery Controller]"..
            "list[context;input;0,1;3,3;]"..
            "list[context;output;5,2;1,1;]"..
            "label[5,1;Output]"..
            "label[0,4;Lava: "..lava_percent.."%]"..
            "button[0,5;2,1;smelt;Smelt]"..
            "button[2,5;3,1;pour_table;Pour to Table]"..
            "button[5,5;3,1;pour_basin;Pour to Basin]"..
            "list[current_player;main;0,6;8,1;]"

        meta:set_string("formspec", formspec)
    end,
})

-- Alloy, Output, Lava Tank, Casting Table & Basin
minetest.register_node(modname..":smeltery_alloy",{description="Smeltery Alloy Block",tiles={"smeltery_top.png","smeltery_bottom.png","smeltery_side.png","smeltery_side.png","smeltery_side.png","smeltery_side.png"},groups={cracky=3,oddly_breakable_by_hand=2}})
minetest.register_node(modname..":smeltery_output",{description="Smeltery Output Block",tiles={"smeltery_top.png","smeltery_bottom.png","smeltery_side.png","smeltery_side.png","smeltery_side.png","smeltery_side.png"},groups={cracky=3,oddly_breakable_by_hand=2}})
minetest.register_node(modname..":lava_tank",{description="Smeltery Lava Tank",tiles={"ws_tank.png","ws_tank.png","ws_tank.png","ws_tank.png","ws_tank.png","ws_tank.png"},groups={cracky=3,oddly_breakable_by_hand=2}})

-- Cast Items
minetest.register_craftitem(modname..":steel_blade",{description="Steel Blade",inventory_image="steel_blade.png"})
minetest.register_craftitem(modname..":wood_handle",{description="Wood Handle",inventory_image="wood_handle.png"})
minetest.register_craftitem(modname..":extra_part",{description="Extra Part",inventory_image="extra_part.png"})

-- Example Tool Recipes
minetest.register_craft({output="ws_blacksmith:custom_sword",recipe={{"ws_blacksmith:steel_blade",""},{"ws_blacksmith:wood_handle",""}}})
minetest.register_craft({output="ws_blacksmith:custom_sword_upgraded",recipe={{"ws_blacksmith:steel_blade","ws_blacksmith:extra_part"},{"ws_blacksmith:wood_handle",""}}})

--==============================
-- 6. Formspect Button Handling
--==============================
minetest.register_on_player_receive_fields(function(player, formname, fields)
    for _, pos in ipairs(minetest.find_nodes_in_area(vector.subtract(player:get_pos(),5), vector.add(player:get_pos(),5), modname..":smeltery_input")) do
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if fields.smelt then
            ws_smeltery.alloy_block:combine(inv,meta)
        end
        if fields.pour_table then
            ws_smeltery:pour_to_casting(inv,"table")
        end
        if fields.pour_basin then
            ws_smeltery:pour_to_casting(inv,"basin")
        end

        -- Update formspec
        local lava_percent = math.floor((meta:get_int("lava")/1000)*100)
        local output_item = inv:get_stack("output",1):get_name()
        if output_item=="" then output_item="Empty" end
        local formspec =
            "size[8,6]"..
            "label[0,0;Smeltery Controller]"..
            "list[context;input;0,1;3,3;]"..
            "list[context;output;5,2;1,1;]"..
            "label[5,1;Output]"..
            "label[0,4;Lava: "..lava_percent.."%]"..
            "button[0,5;2,1;smelt;Smelt]"..
            "button[2,5;3,1;pour_table;Pour to Table]"..
            "button[5,5;3,1;pour_basin;Pour to Basin]"..
            "list[current_player;main;0,6;8,1;]"
        meta:set_string("formspec", formspec)
    end
end)


--==============================
-- Crafting & Casting Stations
--==============================

-- Blacksmith Crafting Station (like normal crafting table)
minetest.register_node("ws_blacksmith:crafting_station",{
    description="Blacksmith Crafting Station",
    tiles={
        "ws_crafting_table_top.png",
        "cube_wood_oak.png",
        "ws_craft_station_side.png",
        "ws_craft_station_side.png",
        "ws_craft_station_side.png",
        "ws_craft_station_side.png"
    },
    groups={cracky=2, oddly_breakable_by_hand=2},
    paramtype2="facedir",
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext","Blacksmith Crafting Station")
        local inv = meta:get_inventory()
        inv:set_size("craft", 9)
        inv:set_size("result",1)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local formspec =
            "size[8,8]"..
            "label[0,0;Blacksmith Crafting Station]"..
            "list[context;craft;2,1;3,3;]"..
            "list[context;result;6,2;1,1;]"..
            "list[current_player;main;0,5;8,3;]"
        meta:set_string("formspec", formspec)
    end,
})

-- Casting Table (for molds)
minetest.register_node("ws_blacksmith:casting_table",{
    description="Casting Table",
    tiles={
        "casting_table_top.png",
        "casting_table_bottom.png",
        "casting_table_side.png",
        "casting_table_side.png",
        "casting_table_side.png",
        "casting_table_side.png"
    },
    groups={cracky=3, oddly_breakable_by_hand=2},
    paramtype2="facedir",
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext","Casting Table")
        local inv = meta:get_inventory()
        inv:set_size("molds",9)
        inv:set_size("metal",1)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local formspec =
            "size[8,6]"..
            "label[0,0;Casting Table]"..
            "list[context;molds;0,1;3,3;]"..
            "list[context;metal;5,2;1,1;]"..
            "list[current_player;main;0,5;8,1;]"
        meta:set_string("formspec", formspec)
    end,
})

-- Casting Basin (for molten metal)
minetest.register_node("ws_blacksmith:casting_basin",{
    description="Casting Basin",
    tiles={
        "casting_basin_top.png",
        "casting_basin_bottom.png",
        "casting_basin_side.png",
        "casting_basin_side.png",
        "casting_basin_side.png",
        "casting_basin_side.png"
    },
    groups={cracky=3, oddly_breakable_by_hand=2},
    paramtype2="facedir",
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext","Casting Basin")
        local inv = meta:get_inventory()
        inv:set_size("molten",1)
    end,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local formspec =
            "size[8,6]"..
            "label[0,0;Casting Basin]"..
            "list[context;molten;5,2;1,1;]"..
            "list[current_player;main;0,5;8,1;]"
        meta:set_string("formspec", formspec)
    end,
})
