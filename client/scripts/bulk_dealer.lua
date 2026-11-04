
RegisterNetEvent('mz_drugselling:cl:open_bulk_sales', function(params)
    local location = params.location
    utils.callback.cb('mz_drugselling:sv:get_bulk_dealer_data', nil, function(bulk_data, message)
        if bulk_data then
            SetNuiFocus(true, true)
            SendNUIMessage({
                action = 'open_bulk_dealer',
                data = {
                    location = location,
                    skills = bulk_data.skills,
                    drugs = bulk_data.drugs,
                    price_multiplier = bulk_data.price_multiplier,
                    price_per_level = bulk_data.price_per_level,
                    locale = lang.bulk_dealer.client.ui
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
    utils.callback.cb('mz_drugselling:sv:bulk_sell_drugs', { location = bulk_location, drug = drug, quantity = amount }, function(success, message, skills)
        if success then
            cb({ success = success, message = message, skills = skills })
        else
            cb({ success = success, message = message })
        end
    end)
end)
