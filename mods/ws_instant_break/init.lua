-- ws_instant_break/init.lua
local modname = minetest.get_current_modname() or "ws_instant_break"

-- CONFIG
local protect_check = true
local spawn_drops = true
local show_effect = true
local excluded_nodes = {["ignore"]=true}

-- WS core node list
local ws_core_nodes = {
  -- (all your ws_core nodes here, same as before)
  ["ws_core:grass_block"]=true, ["ws_core:dirt"]=true, ["ws_core:dirt_dry"]=true,
  ["ws_core:dirt_coarse"]=true, ["ws_core:dirt_rocky"]=true, ["ws_core:dirt_dry_forest"]=true,
  ["ws_core:clay"]=true, ["ws_core:clay_blue"]=true, ["ws_core:clay_red"]=true,
  ["ws_core:clay_dirt"]=true, ["ws_core:sandy_dirt"]=true, ["ws_core:gravel"]=true,
  ["ws_core:stone"]=true, ["ws_core:cobble"]=true, ["ws_core:mossycobble"]=true,
  ["ws_core:stone_block"]=true, ["ws_core:stonebrick"]=true, ["ws_core:stonebrick_cracked"]=true,
  ["ws_core:basalt"]=true, ["ws_core:basalt_cobble"]=true, ["ws_core:slate"]=true,
  ["ws_core:slate_cobble"]=true, ["ws_core:slate_polished"]=true, ["ws_core:slate_bricks"]=true,
  ["ws_core:andesite"]=true, ["ws_core:andesite_polished"]=true, ["ws_core:granite"]=true,
  ["ws_core:diorite"]=true, ["ws_core:salt_block"]=true, ["ws_core:limestone"]=true,
  ["ws_core:lime_cobble"]=true, ["ws_core:lime_brick"]=true, ["ws_core:lime_polished"]=true,
  ["ws_core:marble"]=true, ["ws_core:marble_cobble"]=true, ["ws_core:path_stone"]=true,
  ["ws_core:stalactites"]=true,
  -- Ores
  ["ws_core:stone_with_coal"]=true, ["ws_core:stone_with_coal_dense"]=true, ["ws_core:coal_block"]=true,
  ["ws_core:stone_with_gold"]=true, ["ws_core:stone_with_gold_dense"]=true,
  ["ws_core:stone_with_iron"]=true, ["ws_core:stone_with_iron_dense"]=true,
  ["ws_core:stone_with_copper"]=true, ["ws_core:stone_with_copper_dense"]=true,
  -- Woods
  ["ws_core:log_oak_dry"]=true, ["ws_core:log_oak_stripped_dry"]=true, ["ws_core:planks_oak_dry"]=true,
  ["ws_core:log_oak"]=true, ["ws_core:log_oak_stripped"]=true, ["ws_core:planks_oak"]=true,
  ["ws_core:log_balsa"]=true, ["ws_core:log_balsa_stripped"]=true, ["ws_core:planks_balsa"]=true,
  ["ws_core:log_balsa_dry"]=true, ["ws_core:planks_balsa_dry"]=true, ["ws_core:log_balsa_stripped_dry"]=true,
  ["ws_core:ladder_wood"]=true, ["ws_core:planks_old"]=true,
  -- Plants
  ["ws_core:gorse"]=true, ["ws_core:dry_shrub"]=true, ["ws_core:dry_papyrus"]=true,
  ["ws_core:sand_with_cattails"]=true, ["ws_core:cattail_top"]=true, ["ws_core:sand_with_spoison"]=true,
  ["ws_core:brain_skeleton"]=true, ["ws_core:skeleton_brain"]=true,
  -- Non-natural / misc
  ["ws_core:bookshelf"]=true, ["ws_core:carpet1"]=true, ["ws_core:glass"]=true,
  ["ws_core:shingle_brown"]=true, ["ws_core:shingle_brown_slope"]=true,
  ["ws_core:shingle_brown_slope2"]=true, ["ws_core:shingle_brown_slope3"]=true,
  ["ws_core:shingle_gray_slope"]=true, ["ws_core:shingle_gray_slope2"]=true, ["ws_core:shingle_gray_slope3"]=true,
  ["ws_core:bone"]=true, ["ws_core:straw"]=true,
  ["ws_core:plaster"]=true, ["ws_core:plaster_square"]=true, ["ws_core:plaster_straight"]=true,
  ["ws_core:plaster_cross"]=true,
}

-- Beds
local bed_nodes = {
  ["beds:fancy_bed"]=true, ["beds:fancy_bed_bottom"]=true, ["beds:fancy_bed_top"]=true,
  ["beds:straw_bed"]=true, ["beds:straw_bed_bottom"]=true, ["beds:straw_bed_top"]=true,
}
local bed_drop_map = {
  ["beds:fancy_bed"]="beds:fancy_bed", ["beds:fancy_bed_bottom"]="beds:fancy_bed", ["beds:fancy_bed_top"]="beds:fancy_bed",
  ["beds:straw_bed"]="beds:straw_bed", ["beds:straw_bed_bottom"]="beds:straw_bed", ["beds:straw_bed_top"]="beds:straw_bed",
}
for k,v in pairs(bed_nodes) do ws_core_nodes[k]=v end

-- Feedback particles/sound
local function feedback(pos)
	if not show_effect then return end
	if minetest.add_particlespawner then
		pcall(function()
			minetest.add_particlespawner({
				amount=6, time=0.06,
				minpos={x=pos.x-0.25,y=pos.y-0.25,z=pos.z-0.25},
				maxpos={x=pos.x+0.25,y=pos.y+0.25,z=pos.z+0.25},
				minvel={x=-1,y=1.5,z=-1}, maxvel={x=1,y=3,z=1},
				minacc={x=0,y=-9,z=0}, maxacc={x=0,y=-9,z=0},
				minexptime=0.2, maxexptime=0.45, minsize=1, maxsize=2,
			})
		end)
	end
	if minetest.sound_play then
		pcall(function()
			minetest.sound_play("ws_instant_break_dig",{pos=pos,gain=0.6,max_hear_distance=16})
		end)
	end
end

-- Break a single block with auto-pickup
minetest.register_on_punchnode(function(pos, node, puncher)
	if not puncher or not puncher:is_player() then return end
	if not node or not node.name then return end
	if excluded_nodes[node.name] then return end
	if not ws_core_nodes[node.name] then return end

	local pname = puncher:get_player_name()
	if protect_check and minetest.is_protected and minetest.is_protected(pos,pname) then return end

	local def = minetest.registered_nodes[node.name] or {}
	if def.groups and def.groups.unbreakable==1 then return end
	if def.liquidtype and def.liquidtype~="none" then return end  -- skip liquids entirely

	local function break_node_at(p)
		local n = minetest.get_node_or_nil(p)
		if not n or not n.name then return end
		if excluded_nodes[n.name] then return end
		if not ws_core_nodes[n.name] then return end
		local def2 = minetest.registered_nodes[n.name] or {}
		if def2.groups and def2.groups.unbreakable==1 then return end
		if def2.liquidtype and def2.liquidtype~="none" then return end

		-- Beds
		if bed_drop_map[n.name] then
			if minetest.set_node then minetest.set_node(p,{name="air"}) else minetest.remove_node(p) end
			-- remove adjacent bed piece
			for _, offset in ipairs({{1,0,0},{-1,0,0},{0,0,1},{0,0,-1}}) do
				local pos2={x=p.x+offset[1],y=p.y+offset[2],z=p.z+offset[3]}
				local n2=minetest.get_node_or_nil(pos2)
				if n2 and bed_drop_map[n2.name]==bed_drop_map[n.name] then
					if minetest.set_node then minetest.set_node(pos2,{name="air"}) else minetest.remove_node(pos2) end
				end
			end
			if spawn_drops then
				local inv = puncher:get_inventory()
				if inv then inv:add_item("main", bed_drop_map[n.name]) end
			end
			feedback(p)
			return
		end

		-- Regular drops
		local drops = {}
		if minetest.get_node_drops then
			local wield = puncher:get_wielded_item()
			local wield_name = wield and wield:get_name() or ""
			drops = minetest.get_node_drops(n.name, wield_name) or {}
		end
		if #drops==0 then drops={n.name} end

		if minetest.set_node then minetest.set_node(p,{name="air"}) else minetest.remove_node(p) end
		if spawn_drops then
			local inv = puncher:get_inventory()
			if inv then
				for _, item in ipairs(drops) do
					if item~="" then inv:add_item("main", item) end
				end
			end
		end
		feedback(p)
	end

	break_node_at(pos)
end)

-- Safe hunger HUD disabling (skipped in creative)
local function disable_hunger_huds()
	for _, player in ipairs(minetest.get_connected_players()) do
		if minetest.check_player_privs(player, {creative=true}) then
			return -- skip HUD hiding in creative
		end
	end

	-- hudbars
	if minetest.get_modpath("hudbars") and type(hudbars)=="table" then
		pcall(function()
			if type(hudbars.remove_bar_by_player)=="function" then
				for _, player in ipairs(minetest.get_connected_players()) do
					for _, id in ipairs({"hunger","food","thirst"}) do
						pcall(function() hudbars.remove_bar_by_player(player,id) end)
					end
				end
			end
		end)
	end

	-- ws_hunger
	if minetest.get_modpath("ws_hunger") and type(ws_hunger)=="table" then
		pcall(function()
			if type(ws_hunger.disable)=="function" then pcall(ws_hunger.disable) end
		end)
	end

	-- hunger
	if minetest.get_modpath("hunger") and type(hunger)=="table" then
		pcall(function()
			if type(hunger.disable)=="function" then pcall(hunger.disable) end
			if type(hunger.enable_hunger)=="function" then pcall(function() hunger.enable_hunger(false) end) end
		end)
	end
end

-- Run on join + server start
minetest.register_on_joinplayer(function(player)
	minetest.after(0.5, disable_hunger_huds)
end)
minetest.after(1, disable_hunger_huds)

minetest.log("action","["..modname.."] Loaded: instant-break active; auto-pickup enabled; hunger HUD hiding active (skipped in creative).")
