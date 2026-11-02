local blip, ped_data, target, opened
local coords = { x = 146.253845, y = 324.968170, z = 112.138855, w = 204.901550 }
local client_config = {
    target = 'ox_target', street_phone = true,
    bulk_dealer = {
        blip = { enabled = true, sprite = 51, colour = 5, scale = 0.7 },
        ped = { model = 'cs_martinmadrazo', coords = coords, scenario = 'WORLD_HUMAN_SMOKING', distance = 2.5 }
    }
}

lang = { bulk_dealer = { client = { blip_label = 'Dealer', target_label = 'Trade' } } }
utils = {
    callback = { cb = function(_, _, handler) handler(client_config) end },
    blips = { create_blip = function(data) blip = data end },
    peds = { create_ped = function(data) ped_data = data; return 9 end }
}
exports = { ox_target = { addLocalEntity = function(_, entity, options)
    assert(entity == 9)
    target = options[1]
end } }
RegisterNUICallback = function() end
AddEventHandler = function() end
CreateThread = function(handler) handler() end
TriggerEvent = function(name, data) opened = { name = name, data = data } end

dofile('client/main.lua')
assert(blip.coords == coords and blip.category == 'drug_sales')
assert(ped_data.base_data.coords == coords and ped_data.base_data.model == 'cs_martinmadrazo')
assert(target.label == 'Trade' and target.distance == 2.5)
target.onSelect()
assert(opened.name == 'mz_drugselling:cl:open_bulk_sales' and opened.data.location == coords)
client_config.bulk_dealer.blip.enabled = false
blip, ped_data, target, opened = nil, nil, nil, nil
dofile('client/main.lua')
assert(blip == nil and ped_data.base_data.coords == coords and target.label == 'Trade')
target.onSelect()
assert(opened.name == 'mz_drugselling:cl:open_bulk_sales')
print('bulk_dealer_setup: ok')
