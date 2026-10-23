--- @section Tables

local dealing_data = {}

--- @section Constants

local DEBUG <const> = debug_log
local POLICE_JOBS <const> = config.dealing.police.jobs
local REQUIRED_POLICE_COUNT <const> = config.dealing.police.required
local REQUIRE_ON_DUTY <const> = config.dealing.police.on_duty_required

--- @section Local functions

--- Fetch player data: inventory and skills
-- @param player_id number: The player's server ID.
-- @return table, table: The player's inventory and skills.
local function fetch_player_data(player_id)
    local player_skills = utils.skills.get_skill(player_id, 'drug_dealing') or { level = 1, current_xp = 0, required_xp = 1000 }
    return player_skills
end

--- Process player's drugs based on inventory and skills
-- @param player_skills table: The player's skills.
-- @return table: A table of the player's drugs with calculated prices and quantities.
local function process_player_drugs(_src, player_skills)
    local skill_config = config.skills.dealing.dealing
    local player_drugs = {}
    for _, drug in ipairs(config.drugs) do
        if drug.dealing then
            local inventory_item = utils.fw.get_item(_src, drug.id)
            local inventory_quantity = inventory_item and (inventory_item.quantity or inventory_item.count or inventory_item.amount) or 0
            if inventory_quantity > 0 and player_skills.level >= drug.dealing.required_level then
                local base_price = math.random(drug.dealing.price.min, drug.dealing.price.max)
                local price_multiplier = 1 + ((player_skills.level - 1) * skill_config.bonus_chance_multiplier)
                local adjusted_price = math.ceil(base_price * price_multiplier)
                local min_quantity = drug.dealing.quantity.min
                local max_quantity = math.min(drug.dealing.quantity.max, inventory_quantity)
                if max_quantity < min_quantity then
                    min_quantity = max_quantity
                end
                if min_quantity <= max_quantity then
                    local sell_quantity = math.random(min_quantity, max_quantity)
                    player_drugs[#player_drugs + 1] = {
                        id = drug.id,
                        label = drug.label,
                        image = drug.image,
                        required_level = drug.dealing.required_level,
                        price = adjusted_price,
                        quantity = sell_quantity
                    }
                end
            end
        end
    end
    return player_drugs
end

--- Select random drugs (max 3) from the player's available drugs
-- @param player_drugs table: The player's drugs.
-- @return table: A table of randomly selected drugs (max 3).
local function select_random_drugs(player_drugs)
    local selected_drugs = {}
    if #player_drugs > 3 then
        local selected_indices = {}
        while #selected_indices < 3 do
            local random_index = math.random(1, #player_drugs)
            if not selected_indices[random_index] then
                selected_indices[random_index] = true
                selected_drugs[#selected_drugs + 1] = player_drugs[random_index]
            end
        end
    else
        selected_drugs = player_drugs
    end
    return selected_drugs
end

--- @section Events

--- Main event to prepare sale data
RegisterServerEvent('boii_drugsales:sv:prepare_sale_data', function()
    local _src = source
    local police = get_police_players(POLICE_JOBS, REQUIRE_ON_DUTY)
    if #police < REQUIRED_POLICE_COUNT then
        send_notification(_src, lang.dealing.server.notifications.header, string.format(lang.dealing.server.notifications.not_enough_police, #police, REQUIRED_POLICE_COUNT), 'error', 3500)
        Wait(1000)
        TriggerClientEvent('boii_drugsales:cl:stop_dealing', _src)
        return
    end
    local player_skills = fetch_player_data(_src)
    local player_drugs = process_player_drugs(_src, player_skills)
    if #player_drugs == 0 then
        send_notification(_src, lang.dealing.server.notifications.header, lang.dealing.server.notifications.no_drugs, 'error', 3500)
        TriggerClientEvent('boii_drugsales:cl:stop_dealing', _src)
        return
    end
    local selected_drugs = select_random_drugs(player_drugs)
    local sale_id = GetPlayerName(_src) .. "_" .. os.time() .. "_" .. math.random(100000, 999999)
    dealing_data[sale_id] = { source = _src, drugs = selected_drugs, timestamp = os.time() }
    local failed = false
    local action_chance = math.random(1, 100)
    local failure_chance = config.dealing.chance.fail
    if math.random(1, 100) <= failure_chance then
        failed = true
    end
    TriggerClientEvent('boii_drugsales:cl:receive_sale_data', _src, sale_id, selected_drugs, failed, action_chance)
end)

--- Complete the sale of drugs.
--- @param data table: The sale data containing sale_id, drug_id, and amount.
RegisterServerEvent('boii_drugsales:sv:dealing_complete_sale', function(data)
    local _src = source
    local sale_id = data.sale_id
    local drug_id = data.drug_id
    local amount = data.amount
    local sale_data = dealing_data[sale_id]
    if not sale_data or sale_data.source ~= _src then DEBUG('err', lang.general.server.invalid_sale_data) return end
    local success = complete_sale(_src, sale_data, drug_id, amount)
    if success then
        reward_xp(_src, sale_data.drugs, amount, 'dealing')
        dealing_data[sale_id] = nil
        TriggerClientEvent('boii_drugsales:cl:complete_sale_anim', _src)
    end
end)

--- Take back the drugs from a failed sale
-- @param sale_id string: The sale ID for the transaction to retrieve the correct drugs.
RegisterServerEvent('boii_drugsales:sv:take_back_drugs', function(data)
    local _src = source
    local sale_id = data.sale_id
    local sale_data = dealing_data[sale_id]
    if not sale_data or sale_data.source ~= _src then DEBUG('err', lang.general.server.invalid_sale_data) return end
    for _, drug in ipairs(sale_data.drugs) do
        utils.fw.adjust_inventory(_src, {
            items = {{ item_id = drug.id, action = 'add', quantity = drug.quantity }},
            note = 'Drug Dealing: Reclaimed stolen drugs.',
            should_save = true
        })
    end
    send_notification(_src, lang.dealing.server.notifications.header, lang.dealing.server.notifications.reclaimed_drugs, 'success', 3500)
    TriggerClientEvent('boii_drugsales:cl:take_back_complete', _src)
    dealing_data[sale_id] = nil
end)

--- Remove the drugs from a failed sale
-- @param sale_id string: The sale ID for the transaction to remove the correct drugs.
RegisterServerEvent('boii_drugsales:sv:dealing_remove_drugs', function(sale_id)
    local _src = source
    local sale_data = dealing_data[sale_id]
    if not sale_data or sale_data.source ~= _src then DEBUG('err', lang.general.server.invalid_sale_data) return end
    for _, drug in ipairs(sale_data.drugs) do
        utils.fw.adjust_inventory(_src, {
            items = {{ item_id = drug.id, action = 'remove', quantity = drug.quantity }},
            note = 'Drug Dealing: Drugs stolen by target.',
            should_save = true
        })
    end
    send_notification(_src, lang.dealing.server.notifications.header, lang.dealing.server.notifications.drugs_stolen, 'error', 3500)
end)