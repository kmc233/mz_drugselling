
--- Drug Dealer Dialogues.
-- @script client/dialogues.lua

--- @section Tables

local dialogues = dialogues or {}
local text = lang.bulk_dealer.client.dialogue

--- @section Dialogue conversations

--- Bulk dealer.
dialogues.bulk_dealer = {
    header = {
        message = text.header,
        icon = 'fa-solid fa-cannabis',
    },
    conversation = {
        {
            id = 1,
            response = text.greeting,
            options = {
                {
                    icon = 'fa-solid fa-store',
                    message = text.make_deal,
                    next_id = nil,
                    should_end = true,
                    action_type = 'client',
                    action = 'mz_drugselling:cl:open_bulk_sales',
                    params = {}
                },
                {
                    icon = 'fa-solid fa-question-circle',
                    message = text.ask_offer,
                    next_id = 2,
                    should_end = false
                },
                {
                    icon = 'fa-solid fa-door-open',
                    message = text.goodbye,
                    next_id = nil,
                    should_end = true
                }
            }
        },
        {
            id = 2,
            response = text.answer,
            options = {
                {
                    icon = 'fa-solid fa-store',
                    message = text.make_deal,
                    next_id = nil,
                    should_end = true,
                    action_type = 'client',
                    action = 'mz_drugselling:cl:open_bulk_sales',
                    params = {}
                },
                {
                    icon = 'fa-solid fa-arrow-left',
                    message = text.back,
                    next_id = 1,
                    should_end = false
                },
                {
                    icon = 'fa-solid fa-door-open',
                    message = text.goodbye,
                    next_id = nil,
                    should_end = true
                }
            }
        }
    }
}


--- Event handler to launch dialogue based on store type.
-- @param data table: Data 
RegisterNetEvent('mz_drugselling:cl:start_conversation', function(data)
    if not data or data.dialogue ~= 'bulk_dealer' then return end
    local location = data.location
    lib.registerContext({
        id = 'mz_drugselling_bulk_dealer',
        title = dialogues.bulk_dealer.header.message,
        options = {
            {
                title = text.make_deal, icon = 'store',
                onSelect = function()
                    TriggerEvent('mz_drugselling:cl:open_bulk_sales', {
                        location = vector3(location.x, location.y, location.z)
                    })
                end
            },
            {
                title = text.ask_offer, icon = 'circle-question',
                description = text.offer_description
            }
        }
    })
    lib.showContext('mz_drugselling_bulk_dealer')
end)
