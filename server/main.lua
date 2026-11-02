
--- Main script.
--- @script server/main.lua

--- @section Global variables

is_dealing = false
is_delivering = false
sale_modes = {}

--- @section Global functions.

--- Handles debug logging.
--- @function debug_log
--- @param type string: The type of debug message.
--- @param message string: The debug message.
function debug_log(type, message)
    if config.debug and utils.debug[type] then
        utils.debug[type](message)
    end
end

--- Send notifications.
--- @function send_notification
--- @param _src number: The source player ID.
--- @param header string: Notification header.
--- @param message string: Notification message.
--- @param type string: Notification type.
--- @param duration number: Notification duration in (ms).
function send_notification(_src, header, message, type, duration)
    utils.ui.notify(_src, {
        header = header,
        message = message,
        type = type,
        duration = duration
    })
end

--- Gets players with police jobs.
--- @param job_table table: Table of jobs to check.
--- @param on_duty boolean: Indicates if only on-duty police should be counted.
--- @return table: Table of player sources with the specified jobs.
function get_police_players(job_table, on_duty)
    local duty = on_duty or false
    local players = utils.fw.get_players()
    if not players then 
        return {}
    end
    local jobs = job_table
    local players_with_jobs = {}
    for _, player in pairs(players) do
        local player_source = type(player) == "table" and player.source or player
        if player_source then
            local player_has_job = utils.fw.player_has_job(player_source, jobs, duty)
            if player_has_job then 
                players_with_jobs[#players_with_jobs + 1] = player_source
            end
        end
    end

    return players_with_jobs
end

--- Validate and complete sales.
--- @param _src number: The source ID of the player.
--- @param sale_data table: The sale data containing information about the available drugs and their details.
--- @param drug_id string: The unique ID of the drug being sold.
--- @param amount number: The amount of the drug being sold.
--- @return boolean: Returns `true` if the sale was completed successfully `false` if there was an error or the sale could not be completed.
function complete_sale(_src, sale_data, drug_id, amount, sale_type)
    local payment_config = sale_type == 'delivery' and config.deliveries.payments or config.dealing.payments
    local payment_type = payment_config.type
    if type(amount) ~= 'number' or amount < 1 or amount ~= math.floor(amount) then return false end
    local drug_data = nil
    for _, drug in ipairs(sale_data.drugs) do
        if drug.id == drug_id then
            drug_data = drug
            break
        end
    end
    if not drug_data then
        debug_log('err', lang.general.server.invalid_drug_data)
        return false
    end
    if drug_data.quantity and amount ~= drug_data.quantity then return false end
    local inventory_item = utils.fw.get_item(_src, drug_id)
    local quantity = inventory_item and (inventory_item.quantity or inventory_item.count or inventory_item.amount) or 0
    if quantity < amount then
        send_notification(_src, sale_type == 'delivery' and lang.deliveries.client.notifications.header or lang.dealing.server.notifications.header, lang.dealing.server.notifications.not_enough_drugs, 'error', 3500)
        return false
    end
    if not utils.fw.adjust_inventory(_src, {
        items = {{ item_id = drug_data.id, action = 'remove', quantity = amount }},
        note = 'Drug Dealing: Sold drugs.',
        should_save = true
    }) then return false end
    local payment = math.ceil(drug_data.price * amount)
    if payment_type == 'balance' then
        if not utils.fw.adjust_balance(_src, {
            operations = {{ balance_type = payment_config.balance_type, action = 'add', amount = payment }},
            reason = 'Drug dealing: Received money.',
            should_save = true
        }) then
            utils.fw.adjust_inventory(_src, { items = {{ item_id = drug_id, action = 'add', quantity = amount }} })
            return false
        end
    elseif payment_type == 'item' then
        local item_config = payment_config.item
        local item_data = nil
        if item_config.data then
            local data_key = next(item_config.data)
            if data_key then
                item_data = { [data_key] = payment }
            end
        end
        if not utils.fw.adjust_inventory(_src, {
            items = {{ item_id = item_config.id, action = 'add', quantity = item_data and 1 or payment, data = item_data }},
            note = 'Drug Dealing: Received reward item.',
            should_save = true
        }) then
            utils.fw.adjust_inventory(_src, { items = {{ item_id = drug_id, action = 'add', quantity = amount }} })
            return false
        end
    end
    send_notification(_src, lang.dealing.server.notifications.header, string.format(lang.general.server.sold_drugs, payment, amount, drug_data.label), 'success', 3500)
    return true
end


--- Calculate and reward XP for completing a sale.
--- @param _src number: The players source ID.
--- @param drug_data table: The data of the drug sold.
--- @param amount number: The quantity of the drug sold.
--- @param sale_type string: The type of sale ('bulk' or 'delivery').
function reward_xp(_src, drug_data, amount, sale_type)
    local skill_config = config.skills[sale_type]
    if not skill_config then return end
    local base_xp = skill_config.base_xp or { min = 0, max = 0 }
    local xp_gain = math.floor(math.random(base_xp.min, base_xp.max))
    if sale_type == 'bulk' and skill_config.quantity_xp then
        local quantity_config = skill_config.quantity_xp
        local units = math.max(1, tonumber(quantity_config.units) or 1)
        local quantity_bonus = math.floor(math.max(0, tonumber(amount) or 0) / units) * (tonumber(quantity_config.amount) or 0)
        local maximum = tonumber(quantity_config.max)
        if maximum then quantity_bonus = math.min(quantity_bonus, maximum) end
        xp_gain = xp_gain + quantity_bonus
    end
    xp_gain = math.floor(xp_gain)
    utils.skills.modify_skill(_src, 'drug_dealing', xp_gain, 'add')
end

--- @section Callbacks

--- Server callback to provide dumpster and bin configurations to the client.
--- @param _src: The players server ID requesting the data.
--- @param data: Unused parameter for consistency with callback pattern.
--- @param cb: Callback function to return.
utils.callback.register('mz_drugselling:sv:request_config', function(_src, data, cb)
    local client_config = {}
    client_config.debug = config.debug
    client_config.target = config.target
    if config.bulk_dealer.enabled then
        client_config.bulk_dealer = config.bulk_dealer
    end
    client_config.corner = config.dealing.corner
    client_config.street_phone = config.dealing.street_phone
    client_config.ped_types = config.dealing.ped_types
    client_config.ped_model_types = config.dealing.ped_model_types
    cb(client_config)
end)

--- Perform a action from dealer phone.
-- If you customise the secret menus you should add to this.
--- @param _src: The players server ID requesting the data.
--- @param data: Unused parameter for consistency with callback pattern.
--- @param cb: Callback function to return.
utils.callback.register('mz_drugselling:sv:perform_phone_action', function(_src, data, cb)
    local action = type(data) == 'table' and data.action
    if not action then 
        debug_log('err', lang.general.server.action_missing)
        cb(false, lang.general.server.action_missing)
        return
    end
    if not utils.fw.has_item(_src, 'dealer_phone', 1) then
        debug_log('warn', lang.general.server.phone_action_exploit)
        DropPlayer(_src, lang.general.server.phone_action_exploit_kick_message)
        cb(false, lang.general.server.phone_action_exploit)
        return
    end
    if sale_modes[_src] then return cb(false, lang.dealing.server.notifications.mode_active) end
    local actions = {
        dealing = {
            header = lang.dealing.server.notifications.header,
            message = lang.dealing.server.notifications.cooldown_message,
            cooldown = 'drug_dealing',
            duration = 600
        },
        corner = {
            header = lang.dealing.server.notifications.header,
            message = lang.dealing.server.notifications.cooldown_message,
            cooldown = 'drug_corner',
            duration = 60
        }
    }
    local selected_action = actions[action]
    if not selected_action then
        debug_log('err', lang.general.server.action_missing, 'error', 3500)
        cb(false, lang.general.server.action_missing)
        return
    end

    if action == 'dealing' and not config.dealing.street_phone then
        cb(false, lang.general.server.action_missing)
        return
    end
    if utils.cooldowns.check(_src, selected_action.cooldown, false) then
        send_notification(_src, selected_action.header, selected_action.message, 'error', 3500)
        cb(false, lang.dealing.server.notifications.action_cooldown)
        return
    end
    utils.cooldowns.add(_src, selected_action.cooldown, selected_action.duration, false)
    sale_modes[_src] = action
    cb(true, lang.general.server.action_started)
end)

RegisterNetEvent('mz_drugselling:sv:stop_phone_action', function()
    sale_modes[source] = nil
end)

RegisterNetEvent('mz_drugselling:sv:stop_sales_mode', function()
    if sale_modes[source] == 'corner' or sale_modes[source] == 'dealing' then
        sale_modes[source] = nil
    end
end)

AddEventHandler('playerDropped', function()
    sale_modes[source] = nil
end)

--- @section Items

--- Register dealer phone as usable.
utils.fw.register_item('dealer_phone', function(_src)
    if _src and _src ~= 0 then
        TriggerClientEvent('mz_drugselling:cl:open_dealer_phone', _src)
    end
end)
