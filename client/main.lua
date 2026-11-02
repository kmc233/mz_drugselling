
--- Hobo life main functions.
-- @script client/main.lua

--- Stores client side relevant config options retrieved from server.
config = config or {}

--- Target System
TARGET = nil

--- @section Global variables

phone_prop = nil
is_dealing = false
dealing_mode = nil
is_delivering = false
delivery_receiving = false
delivery_ped = nil
delivery_blip = nil
dealing_target, target_coords = nil, nil

--- @section Global functions.

--- Handles debug logging.
-- @function debug_log
-- @param type string: The type of debug message.
-- @param message string: The debug message.
function debug_log(type, message)
    if config.debug and utils.debug[type] then
        utils.debug[type](message)
    end
end

--- Send notifications.
-- @function send_notification
-- @param header string: Notification header.
-- @param message string: Notification message.
-- @param type string: Notification type.
-- @param duration number: Notification duration in (ms).
function send_notification(header, message, type, duration)
    utils.ui.notify({
        header = header,
        message = message,
        type = type,
        duration = duration
    })
end

--- @section Local functions

--- Sets up interaction zones for targets based on configured methods.
-- @lfunction script_setup
local function script_setup(client_config)
    if client_config.bulk_dealer then
        local p = client_config.bulk_dealer.ped
        if p and client_config.bulk_dealer.blip and client_config.bulk_dealer.blip.enabled then
            local b = client_config.bulk_dealer.blip
            utils.blips.create_blip({
                coords = p.coords,
                sprite = b.sprite,
                colour = b.colour,
                scale = b.scale,
                label = lang.bulk_dealer.client.blip_label,
                category = 'drug_sales'
            })
        end
        if p then
            local ped_data = {
                base_data = {
                    model = p.model,
                    coords = p.coords,
                    scenario = p.scenario,
                    category = 'drug_sales'
                }
            }
            local created_ped = utils.peds.create_ped(ped_data)
            if not created_ped then return end
            if TARGET == 'qb-target' then
                local zone_name = 'zone_bulk_dealer'
                exports['qb-target']:AddEntityZone(zone_name, created_ped, {
                    name = zone_name,
                    heading = p.coords.w,
                    debugPoly = false,
                }, {
                    distance = p.distance,
                    options = {
                        {
                            icon = 'fa-solid fa-store',
                            label = lang.bulk_dealer.client.target_label,
                            action = function()
                                TriggerEvent('mz_drugselling:cl:open_bulk_sales', { location = p.coords })
                            end
                        }
                    }
                })
            elseif TARGET == 'ox_target' then
                local zone_name = 'zone_bulk_dealer'
                exports.ox_target:addLocalEntity(created_ped, {
                    {
                        name = zone_name,
                        label = lang.bulk_dealer.client.target_label,
                        distance = p.distance,
                        onSelect = function()
                            TriggerEvent('mz_drugselling:cl:open_bulk_sales', { location = p.coords })
                        end
                    }
                })
            end
        end
    end

end

--- @section NUI Callbacks

--- Removes nui focus on ui close.
RegisterNUICallback('close_ui', function(_, cb)
    local player_ped = PlayerPedId()
    ClearPedTasks(player_ped)
    SetNuiFocus(false, false)
    if phone_prop and DoesEntityExist(phone_prop) then
        DeleteObject(phone_prop)
        phone_prop = nil
    end
    cb(true)
end)

--- @section Callbacks

--- Fetches and sets up target zones upon callback.
-- @param config table: The configuration data for targets received from the server.
utils.callback.cb('mz_drugselling:sv:request_config', {}, function(client_config)
    config = client_config
    config.target = config.target
    config.delivery_peds = config.delivery_peds
    config.bulk_ped = config.bulk_dealer and config.bulk_dealer.ped and config.bulk_dealer.ped.model or nil
    CreateThread(function()
        while not (config and config.target) do Wait(100) end
        TARGET = config.target
        while not TARGET do Wait(100) end
        script_setup(client_config)
        if not config.street_phone then setup_street_target() end
    end)
end)

--- Event handler for resource stop to clean up any spawned props.
AddEventHandler('onResourceStop', function(res)
    if GetCurrentResourceName() ~= res then
        return
    end
    utils.blips.remove_blips_by_categories({ 'drug_sales' })
    utils.peds.remove_peds_by_categories({ 'drug_sales' })
    if phone_prop and DoesEntityExist(phone_prop) then
        DeleteObject(phone_prop)
    end

    if ped_phone_prop and DoesEntityExist(ped_phone_prop) then
        DeleteObject(ped_phone_prop)
    end

end)
