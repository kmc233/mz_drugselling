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

--- Opens bulk dealer UI
-- @field params: Parameters table.
RegisterNetEvent('boii_drugsales:cl:open_bulk_sales', function(params)
    local location = params.location
    utils.callback.cb('boii_drugsales:sv:get_bulk_dealer_data', nil, function(bulk_data, message)
        if bulk_data then
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'open_bulk_dealer',
                data = {
                    location = location,
                    skills = bulk_data.skills,
                    drugs = bulk_data.drugs
                }
            })
        else
            print(message)
        end
    end)
end)

--- Callback to bulk sell drugs
RegisterNUICallback('bulk_sell_drug', function(data, cb)
    local bulk_location = data.location
    local drug = data.drug_id
    local amount = data.quantity
    utils.callback.cb('boii_drugsales:sv:bulk_sell_drugs', { location = bulk_location, drug = drug, quantity = amount }, function(success, message, skills)
        if success then
            cb({ success = success, message = message, skills = skills })
        else
            cb({ success = success, message = message })
        end
    end)
end)