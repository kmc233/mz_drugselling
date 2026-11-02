local callbacks, events, server_events, nui_messages = {}, {}, {}, {}
local corner_stops = 0

is_dealing = true
dealing_mode = 'corner'
is_delivering = false
delivery_receiving = false
config = { street_phone = false }
lang = {
    dealing = { client = { notifications = { header = 'Sales', stopped = 'Stopped' } } },
    deliveries = { client = { notifications = { header = 'Delivery', started = 'Started', stopped = 'Stopped' } } }
}

RegisterNUICallback = function(name, handler) callbacks[name] = handler end
RegisterNetEvent = function(name, handler) events[name] = handler end
TriggerServerEvent = function(name) server_events[#server_events + 1] = name end
SendNUIMessage = function(message) nui_messages[#nui_messages + 1] = message end
send_notification = function() end
stop_corner_dealing = function() corner_stops = corner_stops + 1 end
PlayerPedId = function() return 1 end

dofile('client/scripts/dealer_phone.lua')

callbacks.dealer_phone_action({ action = 'delivery_start' }, function() end)
assert(is_dealing and dealing_mode == 'corner' and delivery_receiving)
assert(server_events[#server_events] == 'mz_drugselling:sv:request_delivery')

events['mz_drugselling:cl:delivery_receiving_rejected']()
assert(not delivery_receiving and nui_messages[#nui_messages].receiving == false)
callbacks.dealer_phone_action({ action = 'delivery_start' }, function() end)
assert(delivery_receiving)

callbacks.dealer_phone_action({ action = 'delivery_stop' }, function() end)
assert(is_dealing and dealing_mode == 'corner' and not delivery_receiving)
assert(server_events[#server_events] == 'mz_drugselling:sv:pause_delivery')

events['mz_drugselling:cl:delivery_accepted']()
assert(not is_dealing and dealing_mode == nil and is_delivering and corner_stops == 1)
assert(server_events[#server_events] == 'mz_drugselling:sv:pause_delivery')
assert(nui_messages[#nui_messages].mode == 'delivery')
print('delivery_parallel: ok')
