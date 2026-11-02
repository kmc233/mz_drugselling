Locales = Locales or {}

Locales.zh = {
    general = {
    client = {
        no_valid_target = '未找到有效的交互目标。'
    },
    server = {
        missing_drug_config = '配置中未找到该药物。',
        insufficient_quantity = '库存数量不足',
        action_missing = '数据中缺少动作信息。',
        action_started = '动作 %s 已开始。',
        phone_action_exploit = '玩家: %s 因在没有手机的情况下执行经销商电话动作而被踢出。',
        phone_action_exploit_kick_message = '你因事件漏洞利用已被服务器踢出。',
        invalid_sale_data = '无效的销售数据。',
        invalid_drug_data = '无效的药物数据。',
        sold_drugs = '你以 $%d 的价格出售了 %dx %s。',
    }
    },
    bulk_dealer = {
    client = {

    },
    server = {
        notification_header = '批量经销商',
        bulk_sell_notification = '你以 $%d 的价格批量出售了 %dx %s。',
    }
    },
    dealing = {
    client = {
        notifications = {
            header = '毒品交易',
            stopped = '你已停止交易。',
            started = '你已开始交易，去和当地人交谈吧。',
            is_delivering = '你需要先停止所有配送才能开始交易..',
            not_dealing = '你当前未在交易。',
            already_tried = '你已经尝试过这个人了.. 换一个试试..',
        },
        target = {
            sales = {
                label = '出售毒品',
                main_icon = 'fa-solid fa-comment',
                action_icon = 'fa-solid fa-cannabis',
            },
            retrieve = {
                label = '取回毒品',
                main_icon = 'fa-solid fa-user-secret',
                action_icon = 'fa-solid fa-user-secret',
            }
        },
        dialogue = {
            header = {
                message = '毒品交易顾客',
                icon = 'fa-solid fa-user-secret',
            },
            conversation = {
                sale_icon = 'fa-solid fa-hand-holding-dollar',
                sale_message = '出售 %dx %s 换取 $%d',
                exit_icon = 'fa-solid fa-door-open',
                exit_message = '也许改天吧，再见！',
                buy_1_message = '你有 %s 卖吗？',
                buy_2_message = '你有 %s 或者 %s 卖吗？',
                buy_3_message = '你有 %s、%s 或者 %s 卖吗？',
            }
        }
    },
    server = {
        notifications = {
            header = '毒品交易',
            cooldown_message = '你还不能再次开始交易，请先等待一段时间..',
            not_enough_police = '城市中警察数量不足。当前: %d 所需: %d',
            no_drugs = '你没有可出售的毒品..',
            not_enough_drugs = '你的毒品数量不足以完成交易..',
            reclaimed_drugs = '你已取回被盗的毒品。',
            drugs_stolen = '你的毒品已被偷走。'
        },
        alerts = {
            code = '10-66',
            message = '该地区有可疑活动'
        }
    }
    },
    deliveries = {
    client = {
        notifications = {
            header = '毒品配送',
            stopped = '你已停止接收配送。',
            started = '你已开始接收配送，请等待第一个任务。',
            is_dealing = '你需要先停止交易才能开始配送..',
            not_delivering = '你当前未在配送。',
            delivery_received = '你收到了新的配送任务，GPS 已标记位置。',
        },
        phone = {
            brand = 'MZ 手机', network = 'MZ NETWORK', home_title = '销售终端', delivery_title = '送货订单',
            section_sales_modes = '销售方式', mode_dealing = '主动街卖', mode_corner = '站街模式', mode_delivery = '送货订单',
            state_active = '进行中', state_delivery = '配送中', state_not_started = '未开启', state_receiving = '接收中', state_not_receiving = '未接收',
            state_pending = '待回复', state_completed = '已完成', state_expired = '已失效', state_cancelled = '已取消',
            select = '选择', close = '关闭', back = '返回', stop_receiving = '停止接收', receive_messages = '接收短信', cancel_order = '取消订单',
            accept_order = '接单', start = '开始', stop = '停止', message_count = '%d 条短信', waiting_messages = '等待新订单短信', no_messages = '暂无订单短信',
            incoming_request = '听说你能送货。我需要 %d 个%s。', incoming_total = '每个 $%d，总共 $%d。送到%s，能接吗？',
            outgoing_accept = '可以，发位置。', outgoing_cancel = '这单我不接了。', incoming_location = '位置发你了，别迟到。',
            incoming_completed = '收到货了，下次再联系。', incoming_closed = '这单已经结束。', accept_with_location = '接单，发位置',
            cooldown = '%s 后可接', deliver_order = '交付订单', delivery_point = '配送交货点', title = '联系人'
            ,running = '正在运行', other_mode = '其他销售方式进行中', not_started = '尚未开启', no_action = '无操作'
        },
        target = {
            label = '出售毒品',
            main_icon = 'fa-solid fa-comment',
            action_icon = 'fa-solid fa-cannabis',
        },
        dialogue = {
            header = {
                message = '毒品配送顾客',
                icon = 'fa-solid fa-user-secret',
            },
            conversation = {
                sale_icon = 'fa-solid fa-hand-holding-dollar',
                sale_message = '出售 %dx %s 换取 $%d',
                exit_icon = 'fa-solid fa-door-open',
                exit_message = '也许改天吧，再见！',
                buy_1_message = '你把我的 %s 带来了吗？',
                buy_2_message = '你把我的 %s 和 %s 带来了吗？',
                buy_3_message = '你把我的 %s、%s 和 %s 带来了吗？',
            }
        }
    },
    server = {
        notifications = {
            cooldown_message = '你还不能再次开始配送，请先等待一段时间..',
            not_enough_police = '城市中警察数量不足。当前: %d 所需: %d',
            no_drugs = '你没有可出售的毒品..',
            not_enough_drugs = '你的毒品数量不足以完成交易..',
            new_order = '收到一条新的订单短信。',
            no_orders = '目前没有可提供的配送订单。',
            timed_out = '配送订单已超时。',
            cancelled = '订单已取消。',
            insufficient_delivery = '需要 %d 个 %s，当前库存不足。',
            delivery_failed = '交货失败，请检查库存和收款空间后重试。',
        },
        alerts = {
            code = '10-66',
            message = '该地区有可疑活动'
        }
    }
    }
}
