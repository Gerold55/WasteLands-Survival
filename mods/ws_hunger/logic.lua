local cfg = ws_hunger.cfg

local passive_timer = 0
local regen_timer = 0
local starve_timer = 0
local move_timer = 0
local poison_timer = 0

local function player_is_moving(p)
  local v = p:get_velocity()
  return v and (math.abs(v.x)+math.abs(v.y)+math.abs(v.z)) > 0.1
end

minetest.register_on_joinplayer(function(player)
  local pn = player:get_player_name()
  ws_hunger._exhaust[pn] = 0
  ws_hunger.get_satiation(player)
  ws_hunger.hud_init(player)
  -- Migration from hbhunger inventory stack if present
  local inv = player:get_inventory()
  if inv and inv:get_size("hunger") > 0 then
    local c = inv:get_stack("hunger", 1):get_count()
    if c > 0 then
      local sat = math.max(0, math.min(cfg.max, c-1))
      ws_hunger.set_satiation(player, sat)
    end
  end
end)

minetest.register_on_respawnplayer(function(player)
  ws_hunger.set_satiation(player, cfg.start)
  ws_hunger._exhaust[player:get_player_name()] = 0
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
  if digger and digger.is_fake_player ~= true then
    ws_hunger.add_exhaustion(digger, "dig", cfg.cost_dig)
  end
end)

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
  if placer and placer.is_fake_player ~= true then
    ws_hunger.add_exhaustion(placer, "place", cfg.cost_place)
  end
end)

minetest.register_globalstep(function(dtime)
  passive_timer = passive_timer + dtime
  regen_timer   = regen_timer + dtime
  starve_timer  = starve_timer + dtime
  move_timer    = move_timer + dtime
  poison_timer  = poison_timer + dtime

  if move_timer >= 0.5 then
    for _, p in ipairs(minetest.get_connected_players()) do
      if player_is_moving(p) then
        ws_hunger.add_exhaustion(p, "move", cfg.cost_move_tick)
      end
    end
    move_timer = 0
  end

  if passive_timer >= cfg.passive_interval then
    for _, p in ipairs(minetest.get_connected_players()) do
      ws_hunger.add_satiation(p, -1)
    end
    passive_timer = 0
  end

  if regen_timer >= cfg.regen_interval then
    for _, p in ipairs(minetest.get_connected_players()) do
      local sat = ws_hunger.get_satiation(p)
      if sat >= cfg.regen_threshold and p:get_hp() > 0 and p:get_breath() > 0 then
        p:set_hp(p:get_hp() + cfg.regen_amount)
      end
    end
    regen_timer = 0
  end

  if starve_timer >= cfg.starve_interval then
    for _, p in ipairs(minetest.get_connected_players()) do
      local sat = ws_hunger.get_satiation(p)
      if sat <= cfg.starve_threshold then
        local hp = p:get_hp()
        if hp > 0 then
          p:set_hp(math.max(0, hp - cfg.starve_damage))
        end
      end
    end
    starve_timer = 0
  end

  if poison_timer >= 1 then
    for _, p in ipairs(minetest.get_connected_players()) do
      local pn = p:get_player_name()
      local st = ws_hunger._poison[pn]
      if st and st.time_left and st.time_left > 0 then
        local hp = p:get_hp()
        if hp > 1 then
          p:set_hp(math.max(1, hp - (st.dps or 1)))
        end
        st.time_left = st.time_left - 1
      end
    end
    poison_timer = 0
  end
end)
