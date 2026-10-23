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

--- Main script.
--- @script server/main.lua

--- @section Dependencies

--- Import utility library
utils = exports.boii_utils:get_utils()

--- @section Version check

--- Version check options
--- @field resource_name: The name of the resource to check, you can set a value here or use the current resource.
--- @field url_path: The path to your json file.
--- @field callback: Callback to invoking resource version check details *optional*
local opts = {
    resource_name = 'boii_drugsales',
    url_path = 'boiidevelopment/fivem_resource_versions/main/versions.json',
}
utils.version.check(opts)

--- @section Global variables

is_dealing = false
is_delivering = false

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
        print("No players found") 
        return 
    end
    local jobs = job_table
    local players_with_jobs = {}
    for _, player in pairs(players) do
        local player_source = type(player) == "table" and player.source or player
        if player_source then
            print('player_source: '.. player_source)
            local player_has_job = utils.fw.player_has_job(player_source, jobs, duty)
            if player_has_job then 
                print('player_has_job')
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
function complete_sale(_src, sale_data, drug_id, amount)
    local payment_type = config.dealing.payments.type
    local drug_data = nil
    for _, drug in ipairs(sale_data.drugs) do
        if drug.id == drug_id then
            drug_data = drug
            break
        end
    end
    if not drug_data then
        DEBUG('err', lang.general.server.invalid_drug_data)
        return false
    end
    local inventory_item = utils.fw.get_item(_src, drug_id)
    local quantity = inventory_item and (inventory_item.quantity or inventory_item.count or inventory_item.amount) or 0
    if quantity < amount then
        send_notification(_src, lang.dealing.server.notifications.header, lang.dealing.server.notifications.not_enough_drugs, 'error', 3500)
        Wait(1000)
        TriggerClientEvent('boii_drugsales:cl:stop_dealing', _src)
        return false
    end
    utils.fw.adjust_inventory(_src, {
        items = {{ item_id = drug_data.id, action = 'remove', quantity = amount }},
        note = 'Drug Dealing: Sold drugs.',
        should_save = true
    })
    local payment = math.ceil(drug_data.price * amount)
    if payment_type == 'balance' then
        total_value = payment
        utils.fw.adjust_balance(_src, {
            operations = {{ balance_type = config.dealing.payments.balance_type, action = 'add', amount = payment }},
            reason = 'Drug dealing: Received money.',
            should_save = true
        })
    elseif payment_type == 'item' then
        local item_config = config.dealing.payments.item
        local item_data = nil
        if item_config.data then
            local data_key = next(item_config.data)
            if data_key then
                item_data = { [data_key] = payment }
            end
        end
        utils.fw.adjust_inventory(_src, {
            items = {{ item_id = item_config.id, action = 'add', quantity = item_data and 1 or payment, data = item_data }},
            note = 'Drug Dealing: Received reward item.',
            should_save = true
        })
    end
    send_notification(_src, lang.dealing.server.notifications.header, string.format(lang.general.server.sold_drugs, amount, drug_data.label, payment), 'success', 3500)
    return true
end


--- Calculate and reward XP for completing a sale.
--- @param _src number: The players source ID.
--- @param drug_data table: The data of the drug sold.
--- @param amount number: The quantity of the drug sold.
--- @param sale_type string: The type of sale ('bulk' or 'dealing').
function reward_xp(_src, drug_data, amount, sale_type)
    local skill_config = config.skills.dealing[sale_type]
    if not skill_config then
        skill_config = config.skills.dealing.dealing
    end
    local player_skill = utils.skills.get_skill(_src, 'drug_dealing') or { level = 1, current_xp = 0 }
    local base_xp_gain = math.floor(math.random(skill_config.success.min, skill_config.success.max))
    local xp_gain = base_xp_gain
    if player_skill.level > skill_config.bonus_threshold then
        local bonus_levels = player_skill.level - skill_config.bonus_threshold
        local xp_multiplier = 1 + (bonus_levels * skill_config.bonus_chance_multiplier)
        xp_gain = base_xp_gain * xp_multiplier
    end
    xp_gain = math.floor(xp_gain)
    utils.skills.modify_skill(_src, 'drug_dealing', xp_gain, 'add')
end

--- @section Callbacks

--- Server callback to provide dumpster and bin configurations to the client.
--- @param _src: The players server ID requesting the data.
--- @param data: Unused parameter for consistency with callback pattern.
--- @param cb: Callback function to return.
utils.callback.register('boii_drugsales:sv:request_config', function(_src, data, cb)
    local client_config = {}
    client_config.debug = config.debug
    client_config.target = config.target
    if config.bulk_dealer.enabled then
        client_config.bulk_dealer = config.bulk_dealer
    end
    cb(client_config)
end)

--- Perform a action from dealer phone.
-- If you customise the secret menus you should add to this.
--- @param _src: The players server ID requesting the data.
--- @param data: Unused parameter for consistency with callback pattern.
--- @param cb: Callback function to return.
utils.callback.register('boii_drugsales:sv:perform_phone_action', function(_src, data, cb)
    local action = data.action
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
    local actions = {
        dealing = {
            header = lang.dealing.server.notifications.header,
            message = lang.dealing.server.notifications.cooldown_message,
            cooldown = 'drug_dealing',
            duration = 600
        },
        delivery = {
            header = lang.deliveries.server.notifications.header,
            message = lang.deliveries.server.notifications.cooldown_message,
            cooldown = 'drug_deliveries',
            duration = 600
        }
    }
    local selected_action = actions[action]
    if not selected_action then
        debug_log('err', lang.general.server.action_missing, 'error', 3500)
        cb(false, lang.general.server.action_missing)
        return
    end
    if utils.cooldowns.check(_src, selected_action.cooldown, false) then
        send_notification(_src, selected_action.header, selected_action.message, 'error', 3500)
        cb(false, 'action on cooldown')
        return
    end
    utils.cooldowns.add(_src, selected_action.cooldown, selected_action.duration, false)
    cb(true, lang.general.server.action_started)
end)

--- @section Items

--- Hang script until framework is not nil
--- For some reason this was not ready at time of creating items causing an error, messy but it works.
local framework = utils.fw.get_framework()
if framework == nil then
    repeat
        Wait(100)
        framework = utils.fw.get_framework()
    until framework ~= nil
end

--- Register dealer phone as usable through utils.
utils.fw.register_item('dealer_phone', function(_src)
    if _src and _src ~= 0 then
        TriggerClientEvent('boii_drugsales:cl:open_dealer_phone', _src)
    end
end)