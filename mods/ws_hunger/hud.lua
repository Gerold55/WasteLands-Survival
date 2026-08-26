local cfg = ws_hunger.cfg

-- Detect a thirst API (optional)
local thirst_api = rawget(_G, "ws_thirst") or rawget(_G, "thirst")

local function thirst_get(player)
  if not thirst_api then return nil end
  if thirst_api.get_thirst then
    return thirst_api.get_thirst(player)
  elseif thirst_api.get_level then
    return thirst_api.get_level(player)
  end

  -- Fallback: try player meta commonly used by simple thirst mods
  local m = player:get_meta()
  if m:contains("ws_thirst:thirst") then
    return m:get_int("ws_thirst:thirst")
  elseif m:contains("thirst:level") then
    return m:get_int("thirst:level")
  end
  return nil
end

local function thirst_max()
  if not thirst_api then return nil end
  if thirst_api.get_max then
    return thirst_api.get_max()
  end
  if thirst_api.cfg then
    return thirst_api.cfg.max or thirst_api.cfg.max_thirst or 30
  end
  return 30
end

-- Helper: check creative mode
local function is_creative(player)
  return minetest.is_creative_enabled(player:get_player_name())
end

-- HUDBars integration (if available)
if cfg.use_hudbars and rawget(_G, "hb") and hb.register_hudbar then

  hb.register_hudbar("ws_satiation", 0xFFFFFF, "Hunger",
    {icon="ws_hunger_bread.png", bgicon="ws_hunger_bread_bg.png", bar="ws_hunger_bar.png"},
    cfg.start, cfg.max, false)

  local has_thirst = (thirst_api ~= nil)
  if has_thirst then
    local tmax = thirst_max() or 30
    hb.register_hudbar("ws_thirst", 0x87CEFA, "Thirst",
      {icon="ws_thirst_drop.png", bgicon="ws_thirst_drop_bg.png", bar="ws_thirst_bar.png"},
      tmax, tmax, false)
  end

  function ws_hunger.hud_init(player)
    if is_creative(player) then return end

    hb.init_hudbar(player, "ws_satiation", ws_hunger.get_satiation(player))

    if thirst_api then
      local t = thirst_get(player) or (thirst_max() or 30)
      hb.init_hudbar(player, "ws_thirst", t, thirst_max() or 30)
    end
  end

  function ws_hunger.hud_update(player)
    if is_creative(player) then return end

    hb.change_hudbar(player, "ws_satiation", ws_hunger.get_satiation(player))

    if thirst_api then
      local t = thirst_get(player)
      if t then
        hb.change_hudbar(player, "ws_thirst", t)
      end
    end
  end

else
  -- Minimal fallback HUD (text)
  local ids = {}  -- name -> {hunger_id=..., thirst_id=...}

  function ws_hunger.hud_init(player)
    if is_creative(player) then return end

    local name = player:get_player_name()
    ids[name] = ids[name] or {}

    local h_id = player:hud_add({
      hud_elem_type="text",
      position={x=0.5,y=0.95},
      offset={x=0,y=0},
      text="Hunger: "..ws_hunger.get_satiation(player).."/"..cfg.max,
      alignment={x=0,y=0},
      number=0xFFFFFF,
      scale={x=100,y=20}
    })
    ids[name].hunger_id = h_id

    if thirst_api then
      local t = thirst_get(player) or (thirst_max() or 30)
      local t_id = player:hud_add({
        hud_elem_type="text",
        position={x=0.5,y=0.98},
        offset={x=0,y=0},
        text="Thirst: "..t.."/"..(thirst_max() or 30),
        alignment={x=0,y=0},
        number=0x87CEFA,
        scale={x=100,y=20}
      })
      ids[name].thirst_id = t_id
    end
  end

  function ws_hunger.hud_update(player)
    if is_creative(player) then return end

    local name = player:get_player_name()
    local entry = ids[name]
    if not entry then return end

    if entry.hunger_id then
      player:hud_change(entry.hunger_id, "text",
        "Hunger: "..ws_hunger.get_satiation(player).."/"..cfg.max)
    end

    if entry.thirst_id and thirst_api then
      local t = thirst_get(player)
      if t then
        player:hud_change(entry.thirst_id, "text",
          "Thirst: "..t.."/"..(thirst_max() or 30))
      end
    end
  end
end
