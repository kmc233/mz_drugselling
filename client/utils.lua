utils = { blips = {}, callback = {}, debug = {}, entities = {}, peds = {}, requests = {}, ui = {} }

local blips = {}
local peds = {}

for _, level in ipairs({ 'err', 'warn', 'info' }) do
    utils.debug[level] = function(message)
        print(('[mz_drugselling] %s: %s'):format(level, tostring(message)))
    end
end

function utils.callback.cb(name, data, callback)
    lib.callback(name, false, function(...)
        callback(...)
    end, data)
end

function utils.ui.notify(data)
    lib.notify({
        title = data.header, description = data.message,
        type = data.type == 'police' and 'warning' or data.type,
        duration = data.duration
    })
end

function utils.requests.model(name)
    local model = type(name) == 'number' and name or GetHashKey(name)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do Wait(0) end
    return HasModelLoaded(model)
end

function utils.requests.anim(name)
    RequestAnimDict(name)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(name) and GetGameTimer() < deadline do Wait(0) end
    return HasAnimDictLoaded(name)
end

function utils.blips.create_blip(data)
    local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.colour)
    SetBlipScale(blip, data.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)
    blips[#blips + 1] = { handle = blip, category = data.category }
    return blip
end

function utils.blips.create_blip_alpha(data)
    local blip = utils.blips.create_blip(data)
    SetBlipAlpha(blip, data.alpha or 255)
    if data.duration then
        SetTimeout(data.duration * 1000, function()
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end)
    end
    return blip
end

function utils.blips.remove_blips_by_categories(categories)
    for _, entry in ipairs(blips) do
        for _, category in ipairs(categories) do
            if entry.category == category and DoesBlipExist(entry.handle) then RemoveBlip(entry.handle) end
        end
    end
end

function utils.peds.create_ped(data)
    local base = data.base_data
    if not utils.requests.model(base.model) then return nil end
    local coords = base.coords
    local model = type(base.model) == 'number' and base.model or GetHashKey(base.model)
    local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0,
        coords.w or 0.0, base.networked == true, false)
    SetModelAsNoLongerNeeded(model)
    if ped == 0 then return nil end
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if base.scenario then TaskStartScenarioInPlace(ped, base.scenario, 0, true) end
    peds[#peds + 1] = { handle = ped, category = base.category }
    return ped
end

function utils.peds.spawn_safe(model_name, attempts, candidate, options)
    options = options or {}
    for attempt = 1, attempts do
        local x, y, z, heading = candidate(attempt)
        RequestCollisionAtCoord(x, y, z)
        local found, safe = GetSafeCoordForPed(x, y, z, true, 16)
        if found and safe and (not options.accept or options.accept(safe)) then
            if not utils.requests.model(model_name) then return nil end
            local model = type(model_name) == 'number' and model_name or GetHashKey(model_name)
            if options.valid and not options.valid() then
                SetModelAsNoLongerNeeded(model)
                return nil
            end
            local ped = CreatePed(4, model, safe.x, safe.y, safe.z, heading or 0.0,
                options.networked == true, true)
            SetModelAsNoLongerNeeded(model)
            if not ped or ped == 0 or not DoesEntityExist(ped) then return nil end
            SetEntityAsMissionEntity(ped, true, true)
            return ped, safe
        end
    end
end

function utils.peds.remove_peds_by_categories(categories)
    for _, entry in ipairs(peds) do
        for _, category in ipairs(categories) do
            if entry.category == category and DoesEntityExist(entry.handle) then DeletePed(entry.handle) end
        end
    end
end

function utils.peds.schedule_departure_cleanup(ped, on_cleanup)
    CreateThread(function()
        local expires = GetGameTimer() + 90000
        while DoesEntityExist(ped) and GetGameTimer() < expires do
            if #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) > 40.0
                and not IsEntityOnScreen(ped) then break end
            Wait(2000)
        end
        if DoesEntityExist(ped) then DeletePed(ped) end
        if on_cleanup then on_cleanup() end
    end)
end

function utils.entities.get_closest_ped(coords, radius)
    local closest, distance = nil, radius
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local current = #(GetEntityCoords(ped) - coords)
            if current < distance then closest, distance = ped, current end
        end
    end
    return closest, closest and GetEntityCoords(closest) or nil
end

function utils.entities.get_target_ped(player, range, radius)
    local origin = GetEntityCoords(player)
    local forward = GetEntityForwardVector(player)
    local point = origin + forward * range
    local ray = StartShapeTestRay(origin.x, origin.y, origin.z + 0.5,
        point.x, point.y, point.z + 0.5, 12, player, 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    if hit == 1 and entity ~= 0 and IsEntityAPed(entity) and not IsPedAPlayer(entity) then
        return entity
    end
    return utils.entities.get_closest_ped(origin + forward * math.min(range, 5.0), radius)
end
