Locales = Locales or {}

Locales.zh = {
    general = {
    client = {
        no_valid_target = '未找到有效的交互目标。',
        unknown_area = '未知区域'
    },
    server = {
        missing_drug_config = '配置中未找到该药物。',
        insufficient_quantity = '库存数量不足',
        action_missing = '数据中缺少动作信息。',
        action_started = '动作 %s 已开始。',
        phone_action_exploit = '有玩家因未持有经销商手机却执行手机操作而被踢出。',
        phone_action_exploit_kick_message = '你因事件漏洞利用已被服务器踢出。',
        invalid_sale_data = '无效的销售数据。',
        invalid_drug_data = '无效的药物数据。',
        sold_drugs = '你以 $%d 的价格出售了 %dx %s。',
    }
    },
    bulk_dealer = {
    client = {
        blip_label = '批量经销商',
        target_label = '与马德拉索交易',
        ui = {
            market = '批量交易', title = '大宗交易', description = '基础收购价约为建议街头单价的 %s%%。',
            close = '关闭', level = '交易等级', level_bonus = '每升 1 级，收购价加成 %s%%', experience = '经验值', inventory = '可出售库存',
            drug_count = '%s 种药品', empty = '暂无可出售药品', drug_symbol = '药',
            required_level = '需要等级 %s', stock = '库存 %s 件', choose_drug = '请选择药品',
            details = '出售详情', locked = '等级不足', available = '可交易', unit_price = '单价',
            quantity = '出售数量', maximum = '最多 %s 件', estimated = '预计收入', submit = '确认出售'
        }
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
            corner_started = '街角交易已开启，顾客会主动走来。',
            unavailable = '当前无法和这名顾客交易。',
            refused = '顾客拒绝了交易。',
            start_failed = '无法开启销售。',
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
        personalities = {
            normal = '普通顾客', party = '派对顾客', addicted = '成瘾者', gang = '帮派成员',
            snitch = '告密者', dealer = '街头商人', rich = '有钱人', junkie = '瘾君子', undercover = '卧底'
        },
        offer_ui = {
            sale = '街头交易', delivery = '送货交易', title = '报价交易', cancel = '取消交易',
            customer = '普通顾客', choose_drug = '选择药品', unit_price = '单件报价', submit = '提交报价',
            count = '%s 件', suggested = '建议 $%s'
        },
    },
    server = {
        notifications = {
            header = '毒品交易',
            mode_active = '请先停止当前销售模式。',
            action_cooldown = '操作尚在冷却中。',
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
            section_sales_modes = '销售方式', mode_dealing = '主动街卖', mode_corner = '街角交易', mode_delivery = '送货订单',
            state_active = '进行中', state_delivery = '配送中', state_not_started = '未开启', state_receiving = '接收中', state_not_receiving = '未接收',
            state_pending = '待回复', state_completed = '已完成', state_expired = '已失效', state_cancelled = '已取消',
            select = '选择', close = '关闭', back = '返回', stop_receiving = '停止接收', receive_messages = '接收短信', cancel_order = '取消订单',
            accept_order = '接单', start = '开始', stop = '停止', message_count = '%d 条短信', waiting_messages = '等待新订单短信', no_messages = '暂无订单短信',
            accept_with_location = '接单，发位置',
            cooldown = '%s 后可接', deliver_order = '交付订单', delivery_point = '配送交货点', title = '联系人',
            running = '正在运行', other_mode = '其他销售方式进行中', not_started = '尚未开启', no_action = '无操作',
            navigation = '导航键', up = '向上', down = '向下', left = '向左', right = '向右', confirm = '确认'
        },
        sms_dialogue = {
            request = {
                '听说你能送货。我需要 %d 个%s。',
                '你好，我想要 %d 个%s，现在方便送吗？',
                '朋友说你能送货，我需要 %d 个%s。',
                '我这边急着要 %d 个%s，能接这一单吗？'
            },
            offer = {
                '每个 $%d，总共 $%d。送到%s，能接吗？',
                '价格是每个 $%d，一共 $%d。地点在%s，可以吗？',
                '这批货每个 $%d，总价 $%d，送到%s。你能赶过来吗？',
                '我准备好 $%d 一份了，总共 $%d，送到%s就行。'
            },
            accept = {
                '可以，发位置。', '没问题，把位置发给我。', '这单我接了，发定位吧。', '行，我马上过去，位置发来。'
            },
            location = {
                '位置发你了，别迟到。', '定位发过去了，路上小心点。', '地点就在这，到了联系我。', '我把位置发你了，尽快过来。'
            },
            cancel = {
                '这单我不接了。', '算了，这次先取消。', '我临时有事，这单不要了。', '不用送了，订单取消。'
            },
            completed = {
                '收到货了，下次再联系。', '货没问题，合作愉快。', '东西收到了，有需要再找你。', '交易完成，下一单再聊。'
            },
            closed = {
                '这单已经结束。', '订单已关闭，改天再联系。', '这次的订单结束了。', '这单作废了，之后有需要再说。'
            }
        },
        contacts = {
            '阿杰', '夜班客', '南区熟人', '陌生号码', '老客户', '小林', '码头联系人', '派对客',
            '阿凯', '小周', '酒吧老板', '东区熟客', '朋友介绍', '白天客户', '午夜联系人', '老陈',
            '公寓住客', '赛车场客人', '仓库联系人', '阿豪', '俱乐部经理', '上次那个人', '小马', '匿名客户'
        },
        target = {
            label = '出售毒品',
            main_icon = 'fa-solid fa-comment',
            action_icon = 'fa-solid fa-cannabis',
        },
    },
    server = {
        notifications = {
            cooldown_message = '你还不能再次开始配送，请先等待一段时间..',
            not_enough_police = '警察人数不足。',
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
