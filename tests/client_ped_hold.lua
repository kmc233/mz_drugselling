local events, nui, timers = {}, {}, {}
local kept, blocked, standing, wandering = {}, {}, {}, {}
local game_time = 0

dealing_mode = 'dealing'
config = { street_phone = true }
TARGET = 'ox_target'
dofile('client/utils.lua')
utils.requests.anim = function() end
RegisterNetEvent = function(name, handler) events[name] = handler end
RegisterNUICallback = function(name, handler) nui[name] = handler end
AddEventHandler = function() end
DoesEntityExist = function() return true end
IsPedAPlayer = function() return false end
IsPedDeadOrDying = function() return false end
NetworkGetEntityIsNetworked = function() return true end
NetworkHasControlOfEntity = function() return true end
NetworkGetNetworkIdFromEntity = function() return 501 end
GetGameTimer = function() return game_time end
GetEntityCoords = function(entity)
    return entity == 1 and { x = 1, y = 0, z = 0 } or { x = 0, y = 0, z = 0 }
end
PlayerPedId = function() return 2 end
GetHeadingFromVector_2d = function() return 90 end
SetEntityHeading = function(_, heading) assert(heading == 90) end
ClearPedTasksImmediately = function() end
ClearPedSecondaryTask = function() end
ClearPedTasks = function(ped) standing[ped] = false end
SetPedKeepTask = function(ped, value) kept[ped] = value end
SetBlockingOfNonTemporaryEvents = function(ped, value) blocked[ped] = value end
TaskStandStill = function(ped, duration) assert(duration == -1) standing[ped] = true end
TaskWanderStandard = function(ped) wandering[ped] = true end
TaskPlayAnim = function() end
SetNuiFocus = function() end
SendNUIMessage = function() end
TriggerServerEvent = function() end
Wait = function() end
CreateThread = function(handler) handler() end
SetTimeout = function(delay, handler) timers[#timers + 1] = { delay = delay, handler = handler } end

dofile('client/scripts/dealing.lua')

start_street_sale(1)
assert(kept[1] and blocked[1] and standing[1] and not wandering[1])
events['mz_drugselling:cl:open_street_offer']({ offers = {{ id = 'water' }} })
assert(standing[1] and blocked[1])
nui.street_cancel({}, function() end)
assert(not kept[1] and not blocked[1] and not standing[1] and wandering[1])

game_time = 31000
wandering[1] = false
start_street_sale(1)
assert(kept[1] and blocked[1] and standing[1])
events['mz_drugselling:cl:street_result']({ outcome = 'sold' })
assert(kept[1] and blocked[1])
start_street_sale(3)
assert(kept[3] and blocked[3] and standing[3])
for _, timer in ipairs(timers) do
    if timer.delay == 1800 then timer.handler() end
end
assert(not kept[1] and not blocked[1] and wandering[1])
assert(kept[3] and blocked[3] and standing[3])
for _, timer in ipairs(timers) do
    if timer.delay == 65000 then timer.handler() end
end
assert(not kept[3] and not blocked[3] and wandering[3])
print('client_ped_hold: ok')
