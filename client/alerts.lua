--[[
     ____   ____ _____ _____   _   _____  ________      ________ _      ____  _____  __  __ ______ _   _ _______ 
    |  _ \ / __ \_   _|_   _| | | |  __ \|  ____\ \    / /  ____| |    / __ \|  __ \|  \/  |  ____| \ | |__   __|
    | |_) | |  | || |   | |   | | | |  | | |__   \ \  / /| |__  | |   | |  | | |__) | \  / | |__  |  \| |  | |   
    |  _ <| |  | || |   | |   | | | |  | |  __|   \ \/ / |  __| | |   | |  | |  ___/| |\/| |  __| | . ` |  | |   
    | |_) | |__| || |_ _| |_  | | | |__| | |____   \  /  | |____| |___| |__| | |    | |  | | |____| |\  |  | |   
    |____/ \____/_____|_____| | | |_____/|______|   \/   |______|______\____/|_|    |_|  |_|______|_| \_|  |_|   
                              | |                                                                                
                              |_|               DRUG SALES
]]

--- Sends notification, plays sound, and creates blip on alert.
-- @field player_coords: Coords for player who triggered alert.
-- @field label: String label to display on alert.
RegisterNetEvent('boii_drugsales:cl:alert_police', function(player_coords, label)
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
