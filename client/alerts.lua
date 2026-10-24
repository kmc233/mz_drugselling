
--- Sends notification, plays sound, and creates blip on alert.
-- @field player_coords: Coords for player who triggered alert.
-- @field label: String label to display on alert.
RegisterNetEvent('mz_drugselling:cl:alert_police', function(player_coords, label)
    send_notification('ALERT', label, 'police', 5000)
    PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
    utils.blips.create_blip_alpha({
        coords = player_coords,
        sprite = 161,
        colour = 1, 
        scale = 1.5, 
        label = label,
        alpha = 250,
        duration = 20,
        colour_palette = {1, 29} 
    })
end)
