
local dispatch_resources = {
    'cd_dispatch',
    'codem-dispatch',
    'origen_police',
    'ps-dispatch',
    'rcore_dispatch'
}

local function selected_dispatch()
    local configured = config.dispatch or 'auto'
    if configured == 'auto' then
        for _, resource in ipairs(dispatch_resources) do
            if GetResourceState(resource) == 'started' then return resource end
        end
        return nil
    end

    if configured == 'codem_dispatch' then configured = 'codem-dispatch' end
    if configured == 'none' then return nil end
    for _, resource in ipairs(dispatch_resources) do
        if configured == resource and GetResourceState(resource) == 'started' then
            return resource
        end
    end
    return nil
end

--- Alert police with an action
-- @param action string: The action to alert the police about.
function alert_police(_src, action)
    if not _src or not action then return end

    local settings = action == 'delivery' and config.deliveries.police or config.dealing.police
    local police = get_police_players(settings.jobs, settings.on_duty_required)
    if not police or #police == 0 then return end

    local alert_data = {
        dealing = {
            code = lang.dealing.server.alerts.code,
            message = lang.dealing.server.alerts.message
        },
        delivery = {
            code = lang.deliveries.server.alerts.code,
            message = lang.deliveries.server.alerts.message
        }
    }

    if not alert_data[action] then return end
    local dispatch = selected_dispatch()
    if not dispatch then return end

    local alert = alert_data[action]
    TriggerClientEvent('mz_drugselling:cl:send_dispatch', _src, dispatch, alert.code, alert.message)
end
