local client_events, sent_to_clients, sent_to_servers = {}, {}, {}
local started = {}
local export_calls = {}

config = {
    dispatch = 'auto',
    dealing = { police = { jobs = { 'police' }, on_duty_required = false } },
    deliveries = { police = { jobs = { 'police' }, on_duty_required = false } }
}
lang = {
    dealing = { server = { alerts = { code = '10-66', message = 'Street sale' } } },
    deliveries = { server = { alerts = { code = '10-67', message = 'Delivery' } } }
}
get_police_players = function() return { 2, 3 } end
GetResourceState = function(resource) return started[resource] and 'started' or 'missing' end
GetEntityCoords = function() return { x = 1, y = 2, z = 3 } end
PlayerPedId = function() return 4 end
TriggerClientEvent = function(name, target, ...)
    sent_to_clients[#sent_to_clients + 1] = { name = name, target = target, args = { ... } }
end
TriggerServerEvent = function(name, data)
    sent_to_servers[#sent_to_servers + 1] = { name = name, data = data }
end
RegisterNetEvent = function(name, handler) client_events[name] = handler end
exports = {
    cd_dispatch = { GetPlayerInfo = function()
        return { coords = { x = 1 }, unique_id = 'test' }
    end },
    ['codem-dispatch'] = { CustomDispatch = function(_, data)
        export_calls[#export_calls + 1] = { name = 'codem', data = data }
    end },
    ['ps-dispatch'] = { DrugSale = function()
        export_calls[#export_calls + 1] = { name = 'ps' }
    end },
    rcore_dispatch = { GetPlayerData = function()
        return { coords = { x = 1 } }
    end }
}

dofile('server/alerts.lua')
dofile('client/alerts.lua')

local function clear()
    sent_to_clients, sent_to_servers, export_calls = {}, {}, {}
end

local function send(resource, action)
    clear()
    config.dispatch = resource
    started[resource] = true
    alert_police(1, action or 'dealing')
    assert(#sent_to_clients == 1, 'expected one dispatch request')
    local event = sent_to_clients[1]
    assert(event.name == 'mz_drugselling:cl:send_dispatch' and event.target == 1)
    client_events[event.name](unpack(event.args))
end

send('cd_dispatch')
assert(#sent_to_servers == 1 and sent_to_servers[1].name == 'cd_dispatch:AddNotification')
assert(sent_to_servers[1].data.job_table[1] == 'police')
assert(sent_to_servers[1].data.unique_id == 'test')

send('codem-dispatch')
assert(#export_calls == 1 and export_calls[1].name == 'codem')
assert(export_calls[1].data.code == '10-66')

send('origen_police', 'delivery')
assert(#sent_to_servers == 1 and sent_to_servers[1].name == 'SendAlert:police')
assert(sent_to_servers[1].data.message == 'Delivery')

send('ps-dispatch')
assert(#export_calls == 1 and export_calls[1].name == 'ps')

send('rcore_dispatch')
assert(#sent_to_servers == 1 and sent_to_servers[1].name == 'rcore_dispatch:server:sendAlert')
assert(sent_to_servers[1].data.code == '10-66')

clear()
config.dispatch = 'auto'
alert_police(1, 'dealing')
assert(#sent_to_clients == 1 and sent_to_clients[1].args[1] == 'cd_dispatch')

clear()
config.dispatch = 'missing_dispatch'
alert_police(1, 'dealing')
assert(#sent_to_clients == 0)

print('dispatch: ok')
