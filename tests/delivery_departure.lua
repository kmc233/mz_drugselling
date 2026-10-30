local events, threads, deleted = {}, {}, {}
local removed_target, removed_blip, wandering = false, false, false
local timer_reads = 0

delivery_ped = 10
delivery_blip = 7
TARGET = 'ox_target'
dofile('client/utils.lua')
utils.requests.anim = function() end
exports = { ox_target = { removeLocalEntity = function(_, ped, name)
    assert(ped == 10 and name == 'mz_drugselling_delivery')
    removed_target = true
end } }

RegisterNetEvent = function(name, handler) events[name] = handler end
RegisterNUICallback = function() end
AddEventHandler = function(name, handler) events[name] = handler end
SendNUIMessage = function() end
PlayerPedId = function() return 1 end
TaskPlayAnim = function() end
Wait = function() end
RemoveAnimDict = function() end
RemoveBlip = function(blip) assert(blip == 7); removed_blip = true end
DoesEntityExist = function(ped) return ped == 10 and not deleted[ped] end
DeletePed = function(ped) deleted[ped] = true end
ClearPedTasks = function() end
SetPedKeepTask = function() end
SetBlockingOfNonTemporaryEvents = function() end
SetEntityInvincible = function() end
TaskWanderStandard = function(ped) assert(ped == 10); wandering = true end
CreateThread = function(handler) threads[#threads + 1] = handler end
GetGameTimer = function()
    timer_reads = timer_reads + 1
    return timer_reads == 1 and 1000 or 92000
end

dofile('client/scripts/deliveries.lua')
events['mz_drugselling:cl:completed_delivery']()
assert(removed_target and removed_blip and wandering)
assert(delivery_ped == nil and delivery_blip == nil and not deleted[10])
events['mz_drugselling:cl:clear_delivery']()
assert(not deleted[10])

threads[1]()
assert(deleted[10])
print('delivery_departure: ok')
