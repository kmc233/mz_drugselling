local active_deals = {}
local used_peds = {}
local stolen_drugs = {}

local function unavailable(player, reason)
    TriggerClientEvent('mz_drugselling:cl:street_result', player, { outcome = 'unavailable', reason = reason })
end

local function chance(percent)
    return math.random(1, 10000) <= math.max(0, math.min(100, percent or 0)) * 100
end

local function get_ped(player, net_id)
    if type(net_id) ~= 'number' or net_id < 1 then return nil end
    local ped = NetworkGetEntityFromNetworkId(net_id)
    for _ = 1, 5 do
        if ped ~= 0 and DoesEntityExist(ped) then break end
        Wait(100)
        ped = NetworkGetEntityFromNetworkId(net_id)
    end
    local player_ped = GetPlayerPed(player)
    if ped == 0 or player_ped == 0 or not DoesEntityExist(ped) then return nil end
    if GetEntityType(ped) ~= 1 or IsPedAPlayer(ped) then return nil end
    if #(GetEntityCoords(ped) - GetEntityCoords(player_ped)) > 6.0 then return nil end
    return ped
end

local function get_offers(player)
    local skill = utils.skills.get_skill(player, 'drug_dealing') or { level = 1 }
    local offers = {}
    for _, drug in ipairs(config.drugs) do
        local settings = drug.dealing
        if settings and skill.level >= settings.required_level then
            local item = utils.fw.get_item(player, drug.id)
            local count = item and (item.quantity or item.count or item.amount) or 0
            if count > 0 then
                offers[#offers + 1] = {
                    id = drug.id,
                    label = drug.label,
                    count = count,
                    min = settings.price.min,
                    optimal = settings.price.optimal or math.floor((settings.price.min + settings.price.max) / 2),
                    max = settings.price.max
                }
            end
        end
    end
    return offers
end

RegisterNetEvent('mz_drugselling:sv:prepare_street_sale', function(net_id)
    local player = source
    local mode = sale_modes[player] or (not config.dealing.street_phone and 'direct')
    if mode ~= 'dealing' and mode ~= 'corner' and mode ~= 'direct' then return unavailable(player) end
    if active_deals[player] then return unavailable(player) end
    local ped = get_ped(player, net_id)
    if not ped then return unavailable(player) end
    used_peds[player] = used_peds[player] or {}
    if used_peds[player][net_id] and os.time() - used_peds[player][net_id] < 30 then
        return unavailable(player)
    end

    local police = get_police_players(config.dealing.police.jobs, config.dealing.police.on_duty_required) or {}
    if #police < config.dealing.police.required then
        send_notification(player, lang.dealing.server.notifications.header,
            string.format(lang.dealing.server.notifications.not_enough_police, #police, config.dealing.police.required), 'error', 3500)
        unavailable(player, 'police')
        return
    end
    local offers = get_offers(player)
    if #offers == 0 then
        send_notification(player, lang.dealing.server.notifications.header, lang.dealing.server.notifications.no_drugs, 'error', 3500)
        unavailable(player, 'no_drugs')
        return
    end

    local type_id = config.dealing.ped_models[GetEntityModel(ped)] or 'normal'
    local personality = config.dealing.ped_types[type_id]
    used_peds[player][net_id] = os.time()
    if chance(personality.refuse) then
        if chance(personality.alert) then alert_police(player, 'dealing') end
        TriggerClientEvent('mz_drugselling:cl:street_result', player, { outcome = 'refused', early = true })
        return
    end

    active_deals[player] = { ped = net_id, type_id = type_id, offers = offers, created = os.time(), mode = mode }
    TriggerClientEvent('mz_drugselling:cl:open_street_offer', player, {
        type_label = personality.label,
        offers = offers
    })
end)

RegisterNetEvent('mz_drugselling:sv:cancel_street_sale', function()
    active_deals[source] = nil
end)

AddEventHandler('mz_drugselling:sv:stop_phone_action', function()
    active_deals[source] = nil
    used_peds[source] = nil
end)

RegisterNetEvent('mz_drugselling:sv:submit_street_offer', function(drug_id, asking_price)
    local player = source
    local deal = active_deals[player]
    if not deal then return end
    active_deals[player] = nil
    local mode = sale_modes[player] or (not config.dealing.street_phone and 'direct')
    if mode ~= deal.mode or os.time() - deal.created > 60 or not get_ped(player, deal.ped) then
        return unavailable(player)
    end

    local price = tonumber(asking_price)
    if not price or price ~= math.floor(price) then return unavailable(player) end
    local selected
    for _, offer in ipairs(deal.offers) do
        if offer.id == drug_id then selected = offer break end
    end
    if not selected or price < selected.min or price > selected.max then return unavailable(player) end

    local drug
    for _, entry in ipairs(config.drugs) do
        if entry.id == drug_id then drug = entry break end
    end
    if not drug or not drug.dealing then return unavailable(player) end
    local item = utils.fw.get_item(player, drug_id)
    local count = item and (item.quantity or item.count or item.amount) or 0
    if count < 1 then return unavailable(player) end
    local maximum = math.min(count, drug.dealing.quantity.max)
    local minimum = math.min(maximum, drug.dealing.quantity.min)
    local amount = math.random(minimum, maximum)

    local personality = config.dealing.ped_types[deal.type_id]
    local influence = config.dealing.price_influence or 30
    local buy = personality.buy
    if price < selected.optimal then
        buy = buy + influence * (selected.optimal - price) / math.max(1, selected.optimal - selected.min)
    elseif price > selected.optimal then
        buy = buy - influence * (price - selected.optimal) / math.max(1, selected.max - selected.optimal)
    end
    local steal = math.max(0, math.min(100, personality.steal))
    buy = math.max(0, math.min(100 - steal, buy))
    local roll = math.random(1, 10000) / 100
    local result = { amount = amount, drug_id = drug_id }
    if roll <= steal then
        if not utils.fw.adjust_inventory(player, {
            items = {{ item_id = drug_id, action = 'remove', quantity = amount }},
            note = 'Street sale: stolen drugs.', should_save = true
        }) then return unavailable(player) end
        stolen_drugs[player] = stolen_drugs[player] or {}
        stolen_drugs[player][deal.ped] = { drug_id = drug_id, amount = amount }
        result.outcome = 'stolen'
    elseif roll <= steal + buy then
        local sale = { drugs = {{ id = drug_id, label = drug.label, price = price, quantity = amount }} }
        if not complete_sale(player, sale, drug_id, amount, 'dealing') then return unavailable(player) end
        utils.skills.modify_skill(player, 'drug_dealing', personality.xp, 'add')
        result.outcome = 'sold'
        result.total = price * amount
    else
        result.outcome = 'refused'
    end
    if chance(personality.alert) then alert_police(player, 'dealing') end
    TriggerClientEvent('mz_drugselling:cl:street_result', player, result)
end)

RegisterNetEvent('mz_drugselling:sv:recover_stolen_drugs', function(net_id)
    local player = source
    local stolen = stolen_drugs[player] and stolen_drugs[player][net_id]
    if not stolen then return end
    local ped = get_ped(player, net_id)
    if not ped or GetEntityHealth(ped) > 0 then return end
    stolen_drugs[player][net_id] = nil
    utils.fw.adjust_inventory(player, {
        items = {{ item_id = stolen.drug_id, action = 'add', quantity = stolen.amount }},
        note = 'Street sale: recovered stolen drugs.', should_save = true
    })
    send_notification(player, lang.dealing.server.notifications.header,
        lang.dealing.server.notifications.reclaimed_drugs, 'success', 3500)
end)

AddEventHandler('playerDropped', function()
    active_deals[source] = nil
    used_peds[source] = nil
    stolen_drugs[source] = nil
end)
