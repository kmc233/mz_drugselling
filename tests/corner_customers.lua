local events, threads, timers = {}, {}, {}
local positions, existing, walking = {}, {}, {}
local ambient = { 10 }
local created, deleted = 0, {}

local vector_mt = {}
vector_mt.__sub = function(a, b)
    return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, vector_mt)
end
vector_mt.__len = function(a)
    return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end
local function vec(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, vector_mt)
end

dealing_mode = 'corner'
config = { corner = { interval = 8, models = { 'a_m_m_business_01' } } }
lang = { dealing = { client = { notifications = { header = 'Sales' } } } }
dofile('client/utils.lua')
utils.requests.model = function() return true end
utils.requests.anim = function() end
send_notification = function() end
positions[1], positions[10] = vec(0, 0, 0), vec(15, 0, 0)
existing[1], existing[10] = true, true
RegisterNetEvent = function(name, handler) events[name] = handler end
RegisterNUICallback = function() end
AddEventHandler = function() end
CreateThread = function(handler) threads[#threads + 1] = handler end
SetTimeout = function(delay, handler) timers[#timers + 1] = { delay = delay, handler = handler } end
TriggerEvent = function(name, ...) events[name](...) end
TriggerServerEvent = function() end
GetGamePool = function() return ambient end
GetGameTimer = function() return 1000 end
GetEntityCoords = function(ped) return positions[ped] end
PlayerPedId = function() return 1 end
DoesEntityExist = function(ped) return existing[ped] == true end
IsPedAPlayer = function(ped) return ped == 1 end
IsPedHuman = function() return true end
IsPedDeadOrDying = function() return false end
IsPedInAnyVehicle = function() return false end
IsPedInCombat = function() return false end
GetPedType = function() return 4 end
IsEntityAMissionEntity = function() return false end
NetworkGetEntityIsNetworked = function() return true end
NetworkHasControlOfEntity = function() return true end
NetworkGetNetworkIdFromEntity = function(ped) return ped end
GetHashKey = function() return 123 end
GetSafeCoordForPed = function(x, y, z) return true, vec(x, y, z) end
RequestCollisionAtCoord = function() end
IsSphereVisible = function() return false end
CreatePed = function(_, _, x, y, z)
    created = created + 1
    local ped = 20 + created
    positions[ped], existing[ped] = vec(x, y, z), true
    return ped
end
DeletePed = function(ped) deleted[#deleted + 1] = ped; existing[ped] = false end
IsEntityOnScreen = function() return false end
SetEntityAsMissionEntity = function() end
SetModelAsNoLongerNeeded = function() end
TaskGoToEntity = function() end
TaskTurnPedToFaceEntity = function() end
TaskWanderStandard = function(ped) walking[ped] = true end
ClearPedTasksImmediately = function() end
ClearPedSecondaryTask = function() end
ClearPedTasks = function() end
SetPedKeepTask = function() end
SetBlockingOfNonTemporaryEvents = function() end
SetEntityHeading = function() end
GetHeadingFromVector_2d = function() return 0 end
TaskStandStill = function() end
SetNuiFocus = function() end
SendNUIMessage = function() end
Wait = function() end

dofile('client/scripts/dealing.lua')

start_corner_dealing()
assert(created == 0, 'ambient pedestrian should be used first')
positions[10] = vec(2, 0, 0)
threads[#threads]()
events['mz_drugselling:cl:street_result']({ outcome = 'refused' })
assert(walking[10] and #deleted == 0, 'ambient pedestrian must walk away and never be deleted')

ambient = {}
events['mz_drugselling:cl:spawn_corner_customer']()
assert(created == 1, 'fallback customer should be spawned')
local spawned = 21
positions[spawned] = vec(2, 0, 0)
threads[#threads]()
events['mz_drugselling:cl:street_result']({ outcome = 'refused' })
assert(walking[spawned] and #deleted == 0, 'spawned customer must walk away first')
positions[spawned] = vec(50, 0, 0)
threads[#threads]()
assert(#deleted == 1 and deleted[1] == spawned, 'only the spawned customer should be cleaned up')

print('corner_customers: ok')
