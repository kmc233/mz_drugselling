local events, threads = {}, {}
local collision_requests, safe_calls, created = 0, 0, 0
local coords = { x = 10, y = 20, z = 30 }

local function vec(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, {
        __sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end,
        __len = function(a) return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z) end
    })
end

delivery_ped = nil
delivery_blip = nil
is_delivering = true
TARGET = 'ox_target'
config = { ped_models = { party = { 'party_model' }, gang = { 'gang_model' } } }
lang = { deliveries = { client = { phone = { delivery_point = 'Point', deliver_order = 'Deliver' }, target = { action_icon = 'icon' } } } }
dofile('client/utils.lua')
utils.requests.model = function(model)
    assert(model == 'party_model' or model == 'gang_model')
    return true
end
exports = { ox_target = { addLocalEntity = function() end, removeLocalEntity = function() end } }
RegisterNetEvent = function(name, handler) events[name] = handler end
RegisterNUICallback = function() end
AddEventHandler = function() end
CreateThread = function(handler) threads[#threads + 1] = handler end
PlayerPedId = function() return 1 end
GetEntityCoords = function() return vec(10, 20, 30) end
vector3 = vec
Wait = function() end
AddBlipForCoord = function() return 7 end
SetBlipSprite = function() end
SetBlipColour = function() end
SetBlipScale = function() end
BeginTextCommandSetBlipName = function() end
AddTextComponentString = function() end
EndTextCommandSetBlipName = function() end
SetBlipRoute = function() end
SetBlipRouteColour = function() end
RemoveBlip = function() end
RequestCollisionAtCoord = function() collision_requests = collision_requests + 1 end
GetSafeCoordForPed = function(x, y)
    safe_calls = safe_calls + 1
    if safe_calls <= 8 then return false, nil end
    return true, vec(x, y, 31.5)
end
GetHashKey = function() return 123 end
SetModelAsNoLongerNeeded = function() end
CreatePed = function(_, _, x, y, z)
    created = created + 1
    assert(x == 10 and y == 20 and z == 30.5)
    return 9
end
SetEntityAsMissionEntity = function() end
SetEntityInvincible = function() end
SetBlockingOfNonTemporaryEvents = function() end
TaskStartScenarioInPlace = function() end
SetBlipCoords = function(_, x, y, z) assert(x == 10 and y == 20 and z == 30.5) end
DoesEntityExist = function() return true end
DeletePed = function() end

dofile('client/scripts/deliveries.lua')
events['mz_drugselling:cl:spawn_delivery_ped']({ x = 10, y = 20, z = 30, radius = 0 })
threads[1]()
assert(collision_requests == 9 and created == 1)
events['mz_drugselling:cl:clear_delivery']()
assert(delivery_ped == nil)
events['mz_drugselling:cl:spawn_delivery_ped'](coords)
events['mz_drugselling:cl:clear_delivery']()
threads[2]()
assert(created == 1)
print('delivery_spawn: ok')
