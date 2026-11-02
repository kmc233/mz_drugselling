Locales = Locales or {}

Locales.en = {
    general = {
        client = {
            no_valid_target = 'No valid interaction target found.',
            unknown_area = 'Unknown area'
        },
        server = {
            missing_drug_config = 'This drug is not configured.',
            insufficient_quantity = 'Not enough items in your inventory.',
            action_missing = 'Action data is missing.',
            action_started = 'Action %s started.',
            phone_action_exploit = 'Player %s was kicked for using the dealer phone without a phone.',
            phone_action_exploit_kick_message = 'You were kicked for exploiting an event.',
            invalid_sale_data = 'Invalid sale data.',
            invalid_drug_data = 'Invalid drug data.',
            sold_drugs = 'You sold drugs for $%d: %dx %s.'
        }
    },
    bulk_dealer = {
        client = {
            blip_label = 'Bulk Dealer',
            target_label = 'Speak to Madrazo',
            dialogue = {
                header = 'Bulk Dealer',
                make_deal = 'Make a deal',
                ask_offer = 'What are you buying?',
                offer_description = 'Sell in bulk for a lower price per item.',
                goodbye = 'Maybe later. Goodbye.',
                greeting = 'Got a large shipment to move? I can take it.',
                answer = { 'I can buy the whole lot, but the price needs to be right.', 'You can make more on the street, if you have the time.' },
                back = 'Back to previous questions'
            },
            ui = {
                market = 'Bulk Sales', title = 'Bulk Deal', description = 'Choose drugs from your inventory to sell in bulk.',
                close = 'Close', level = 'Dealing Level', experience = 'Experience', inventory = 'Available Inventory',
                drug_count = '%s drugs', empty = 'No drugs available to sell', drug_symbol = 'Drug',
                required_level = 'Requires level %s', stock = '%s in stock', choose_drug = 'Choose a drug',
                details = 'Sale Details', locked = 'Level too low', available = 'Available', unit_price = 'Unit price',
                quantity = 'Quantity', maximum = 'Max %s', estimated = 'Estimated earnings', submit = 'Confirm sale'
            }
        },
        server = {
            notification_header = 'Bulk Dealer',
            bulk_sell_notification = 'Bulk sale for $%d: %dx %s.'
        }
    },
    dealing = {
        client = {
            notifications = {
                header = 'Drug Dealing',
                stopped = 'You stopped dealing.',
                started = 'You started dealing. Talk to people nearby.',
                corner_started = 'Corner dealing started. Customers will approach you.',
                unavailable = 'You cannot deal with this customer right now.',
                refused = 'The customer refused the deal.',
                start_failed = 'Unable to start dealing.',
                is_delivering = 'Stop all deliveries before you start dealing.',
                not_dealing = 'You are not dealing right now.',
                already_tried = 'You already tried this person. Find someone else.'
            },
            target = {
                sales = { label = 'Sell Drugs', main_icon = 'fa-solid fa-comment', action_icon = 'fa-solid fa-cannabis' },
                retrieve = { label = 'Recover Drugs', main_icon = 'fa-solid fa-user-secret', action_icon = 'fa-solid fa-user-secret' }
            },
            personalities = {
                normal = 'Customer', party = 'Partygoer', addicted = 'Addict', gang = 'Gang Member',
                snitch = 'Informant', dealer = 'Street Dealer', rich = 'Wealthy Customer', junkie = 'Junkie', undercover = 'Undercover Officer'
            },
            offer_ui = {
                sale = 'Street Deal', delivery = 'Delivery Deal', title = 'Make an Offer', cancel = 'Cancel Deal',
                customer = 'Customer', choose_drug = 'Choose a drug', unit_price = 'Unit price', submit = 'Submit offer',
                count = '%s units', suggested = 'Suggested $%s'
            },
            dialogue = {
                header = { message = 'Customer', icon = 'fa-solid fa-user-secret' },
                conversation = {
                    sale_icon = 'fa-solid fa-hand-holding-dollar', sale_message = 'Sell %dx %s for $%d',
                    exit_icon = 'fa-solid fa-door-open', exit_message = 'Maybe another day. Goodbye!',
                    buy_1_message = 'Do you have %s for sale?',
                    buy_2_message = 'Do you have %s or %s for sale?',
                    buy_3_message = 'Do you have %s, %s, or %s for sale?'
                }
            }
        },
        server = {
            notifications = {
                header = 'Drug Dealing',
                mode_active = 'Stop the current sales mode first.',
                phone_not_required = 'Active selling does not require the phone.',
                action_cooldown = 'This action is on cooldown.',
                cooldown_message = 'Wait a while before you start dealing again.',
                not_enough_police = 'Not enough police in the city. Current: %d Required: %d',
                no_drugs = 'You have no drugs to sell.',
                not_enough_drugs = 'You do not have enough drugs for this deal.',
                reclaimed_drugs = 'You recovered the stolen drugs.',
                drugs_stolen = 'Your drugs were stolen.'
            },
            alerts = { code = '10-66', message = 'Suspicious activity reported in the area' }
        }
    },
    deliveries = {
        client = {
            notifications = {
                header = 'Drug Delivery',
                stopped = 'You stopped receiving deliveries.',
                started = 'You are receiving deliveries. Wait for your first order.',
                is_dealing = 'Stop dealing before you start deliveries.',
                not_delivering = 'You are not delivering right now.',
                delivery_received = 'New delivery order received. The GPS location is marked.'
            },
            phone = {
                brand = 'MZ Phone', network = 'MZ NETWORK', home_title = 'Sales Terminal', delivery_title = 'Delivery Orders',
                section_sales_modes = 'Sales Modes', mode_dealing = 'Active Selling', mode_corner = 'Corner Dealing', mode_delivery = 'Delivery Orders',
                state_active = 'Active', state_delivery = 'Delivering', state_not_started = 'Not Started', state_receiving = 'Receiving', state_not_receiving = 'Not Receiving',
                state_pending = 'Awaiting Reply', state_completed = 'Completed', state_expired = 'Expired', state_cancelled = 'Cancelled',
                select = 'Select', close = 'Close', back = 'Back', stop_receiving = 'Stop Receiving', receive_messages = 'Receive Messages', cancel_order = 'Cancel Order',
                accept_order = 'Accept', start = 'Start', stop = 'Stop', message_count = '%d messages', waiting_messages = 'Waiting for new orders', no_messages = 'No order messages',
                accept_with_location = 'Accept and get location',
                cooldown = 'Available in %s', deliver_order = 'Deliver Order', delivery_point = 'Delivery Point', title = 'Contact',
                running = 'Running', other_mode = 'Another sales mode is active', not_started = 'Not Started', no_action = 'No Action',
                navigation = 'Navigation keys', up = 'Up', down = 'Down', left = 'Left', right = 'Right', confirm = 'Confirm'
            },
            sms_dialogue = {
                request = {
                    'I heard you deliver. I need %d %s.',
                    'Hey, can you bring me %d %s?',
                    'A friend gave me your number. I need %d %s.',
                    'I need %d %s soon. Can you take the order?'
                },
                offer = {
                    '$%d each, $%d total. Can you deliver to %s?',
                    'The price is $%d each, $%d altogether. Meet me in %s?',
                    '$%d per item, $%d total. Bring them to %s.',
                    'I have $%d each ready, $%d total. Deliver to %s.'
                },
                accept = {
                    'Sure. Send me the location.', 'No problem. Send the address.',
                    'I will take it. Share your location.', 'On my way. Send me the location.'
                },
                location = {
                    'Sent you the location. Do not be late.', 'Location sent. Travel safe.',
                    'Here is the spot. Call when you arrive.', 'I sent the location. Come soon.'
                },
                cancel = {
                    'I cannot take this order.', 'Sorry, I have to cancel.',
                    'Something came up. I am cancelling.', 'No delivery this time. Order cancelled.'
                },
                completed = {
                    'Got the goods. Talk soon.', 'Everything looks good. Thanks.',
                    'Received it. I will call again.', 'Deal complete. Until next time.'
                },
                closed = {
                    'This order is closed.', 'Order closed. Talk another time.',
                    'This order has ended.', 'This one is off. Maybe next time.'
                }
            },
            contacts = {
                'Jay', 'Night Shift', 'Southside Contact', 'Unknown Number', 'Regular', 'Lin', 'Dock Contact', 'Party Guest',
                'Kai', 'Zhou', 'Bar Owner', 'Eastside Regular', 'Friend of a Friend', 'Daytime Client', 'Midnight Contact', 'Chen',
                'Apartment Resident', 'Racetrack Guest', 'Warehouse Contact', 'Hao', 'Club Manager', 'The Last Guy', 'Ma', 'Anonymous Client'
            },
            target = { label = 'Deliver Drugs', main_icon = 'fa-solid fa-comment', action_icon = 'fa-solid fa-cannabis' },
            dialogue = {
                header = { message = 'Delivery Customer', icon = 'fa-solid fa-user-secret' },
                conversation = {
                    sale_icon = 'fa-solid fa-hand-holding-dollar', sale_message = 'Sell %dx %s for $%d',
                    exit_icon = 'fa-solid fa-door-open', exit_message = 'Maybe another day. Goodbye!',
                    buy_1_message = 'Did you bring my %s?',
                    buy_2_message = 'Did you bring my %s and %s?',
                    buy_3_message = 'Did you bring my %s, %s, and %s?'
                }
            }
        },
        server = {
            notifications = {
                cooldown_message = 'Wait a while before starting deliveries again.',
                not_enough_police = 'Not enough police on duty.',
                no_drugs = 'You have no drugs to sell.',
                not_enough_drugs = 'You do not have enough drugs for this deal.',
                new_order = 'You received a new order message.',
                no_orders = 'No delivery orders are available right now.',
                timed_out = 'Delivery order timed out.',
                cancelled = 'Order cancelled.',
                insufficient_delivery = 'You need %d %s. Not enough in inventory.',
                delivery_failed = 'Delivery failed. Check your inventory and payment capacity.'
            },
            alerts = { code = '10-66', message = 'Suspicious activity reported in the area' }
        }
    }
}
