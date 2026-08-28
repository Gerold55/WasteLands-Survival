local cfg = ws_moon.cfg

local has_climate = minetest.get_modpath("climate_api") ~= nil
local has_skylayer = minetest.get_modpath("skylayer") ~= nil

-- Colors per phase (night_tints). Feel free to adjust.
local night_sky = {
  "#1d293aff", "#1c4b8dff", "#203a6aff", "#579dffff",
  "#203a6aff", "#1c4b8dff", "#1d293aff", "#000000ff"
}
local night_hz = {
  "#243347ff", "#235fb3ff", "#2a4a7cff", "#73aeffff",
  "#2a4a7cff", "#3079dfff", "#173154ff", "#000000ff"
}

local function style_for(player)
  local meta = player:get_meta()
  local s = meta:get_string("ws_moon:style")
  if s ~= "classic" and s ~= "realistic" then s = cfg.default_style end
  return s
end

-- Apply sky and moon for a single player
function ws_moon._apply_sky(player, phase)
  if not (player and player.is_player and player:is_player()) then return end
  local texture = string.format("moon_%d_%s.png", phase, style_for(player))

  local sky = {
    sky_data = {
      type = "regular",
      sky_color = {
        night_sky = night_sky[phase],
        night_horizon = night_hz[phase]
      },
    },
    moon_data = {
      visible = true,
      texture = texture,
      scale = 0.8,
    }
  }

  local name = "ws_moon:cycle"
  local playername = player:get_player_name()

  if has_climate and climate_api and climate_api.skybox then
    sky.priority = 0
    climate_api.skybox.add(playername, name, sky)
  elseif has_skylayer and skylayer and skylayer.add_layer then
    sky.name = name
    skylayer.add_layer(playername, sky)
  else
    player:set_sky(sky.sky_data)
    player:set_moon(sky.moon_data)
  end
end

-- Update all players
function ws_moon._broadcast_phase(phase)
  for _, player in ipairs(minetest.get_connected_players()) do
    ws_moon._apply_sky(player, phase)
  end
end
