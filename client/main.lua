
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
    local targets = {}

    if client_config.bulk_dealer then
        if client_config.bulk_dealer.blip then
            local b = client_config.bulk_dealer.blip
            utils.blips.create_blip({
                coords = b.coords,
                sprite = b.sprite,
                colour = b.colour,
                scale = b.scale,
                label = b.label,
                category = b.category,
                show = b.show
            })
        end
        if client_config.bulk_dealer.ped then
            local p = client_config.bulk_dealer.ped
            local ped_data = {
                base_data = {
                    id = p.id,
                    model = p.model,
                    coords = p.coords,
                    scenario = p.scenario,
                    category = p.category,
                    networked = p.networked
                }
            }
            local created_ped = utils.peds.create_ped(ped_data)
            if TARGET == 'qb-target' then
                local zone_name = 'zone_' .. p.id
                exports['qb-target']:AddEntityZone(zone_name, created_ped, {
                    name = zone_name,
                    heading = p.coords.w,
                    debugPoly = p.debug,
                }, {
                    distance = p.distance,
                    options = {
                        {
                            icon = p.actions[1].icon,
                            label = p.actions[1].label,
                            action = function()
                                TriggerEvent(p.actions[1].action, p.actions[1].params)
                            end
                        }
                    }
                })
            elseif TARGET == 'ox_target' then
                local zone_name = 'zone_' .. p.id
                exports.ox_target:addLocalEntity(created_ped, {
                    {
                        name = zone_name,
                        label = p.actions[1].label,
                        distance = p.distance,
                        onSelect = function()
                            TriggerEvent(p.actions[1].action, p.actions[1].params)
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
