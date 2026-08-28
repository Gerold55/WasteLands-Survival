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

----------------------------------------------------------------------
-- FIX: DISABLE FALLBACK HUD COMPLETELY
-- ws_hud now handles ALL hunger + thirst visuals
----------------------------------------------------------------------

function ws_hunger.hud_init(player)
  -- Do nothing. HUD handled by ws_hud.
end

function ws_hunger.hud_update(player)
  -- Do nothing. HUD handled by ws_hud.
end
