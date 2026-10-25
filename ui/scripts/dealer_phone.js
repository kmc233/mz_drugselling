class DealerPhone {
    constructor() {
        this.screen_content = '';
        this.current_screen = 'main';
        this.sequence_buffer = '';
        this.secret_codes = {
            '5801': 'secret_menu_1',
            '2312': 'secret_menu_2',
        };
        $(document).ready(() => {
            $(document).keyup((e) => this.handle_exit(e));
        });
    }

    handle_exit(e) {
        if (e.key === "Escape" && $('.dealer_phone_container').length) {
            this.close();
        }
    }

    close() {
        $('#main_container').empty();
        $.post(`https://${GetParentResourceName()}/close_ui`, JSON.stringify({}));
    }

    init(data = {}) {
        this.street_phone = data.street_phone === true;
        this.build();
    }

    build() {
        const content = `
            <div class="dealer_phone_container">
                <div class="dealer_phone_screen_container">
                    <div class="dealer_phone_header">
                        <div class="phone_speaker"></div>    
                        <div class="phone_name">MZ</div>
                    </div>
                    <div class="dealer_phone_screen">
                        <div class="signal_bars">
                            <div class="signal_bar"></div>
                            <div class="signal_bar"></div>
                            <div class="signal_bar"></div>
                            <div class="signal_bar"></div>
                            <div class="signal_bar"></div>
                            <div class="signal_icon"><i class="fa-solid fa-tower-broadcast"></i></div>
                            
                        </div>
                        <div class="battery_bars">
                            <div class="battery_bar"></div>
                            <div class="battery_bar"></div>
                            <div class="battery_bar"></div>
                            <div class="battery_bar"></div>
                            <div class="battery_bar"></div>
                            <div class="battery_icon"><i class="fa-solid fa-battery-full fa-rotate-270"></i></div>
                        </div>
                        <div class="screen_content" id="screen_content">${this.get_screen_content()}</div>
                    </div>
                </div>
                <div class="dealer_phone_keypad">
                    <button class="key" data-key="1">1<span class="letters">&#9903</span></button>
                    <button class="key" data-key="2">2 <span class="letters">ABC</span></button>
                    <button class="key" data-key="3">3 <span class="letters">DEF</span></button>
                    <button class="key" data-key="4">4 <span class="letters">GHI</span></button>
                    <button class="key" data-key="5">5 <span class="letters">JKL</span></button>
                    <button class="key" data-key="6">6 <span class="letters">MNO</span></button>
                    <button class="key" data-key="7">7 <span class="letters">PQRS</span></button>
                    <button class="key" data-key="8">8 <span class="letters">TUV</span></button>
                    <button class="key" data-key="9">9 <span class="letters">WXYZ</span></button>
                    <button class="key" data-key="*">*</button>
                    <button class="key" data-key="0">0<span class="letters">+</span></button>
                    <button class="key" data-key="#">#</button>
                </div>
                <div class="dealer_phone_footer">
                    <div class="phone_speaker2"></div>    
                </div> 
            </div>
        `;
        $('#main_container').html(content);
        this.setup_events();
    }

    setup_events() {
        const self = this;
        $('.key').off('click').on('click', function() {
            const key = $(this).data('key');
            self.handle_key_press(key);
        });
    }

    get_screen_content() {
        if (this.current_screen === 'main') {
            return this.street_phone
                ? `<span class="line">1 - 主动街卖</span><br><span class="line">2 - 站街模式</span><br><span class="line">3 - 请求送货</span><br><span class="line"># - 关闭</span>`
                : `<span class="line">1 - 站街模式</span><br><span class="line">2 - 请求送货</span><br><span class="line"># - 关闭</span>`;
        } else if (this.current_screen === 'street_sell') {
            return `<span class="line">主动街卖</span><br><span class="line">1 - 开始</span><br><span class="line">2 - 停止</span><br><span class="line">* - 返回</span><br><span class="line"># - 关闭</span>`;
        } else if (this.current_screen === 'request_delivery') {
            return `<span class="line">请求送货</span><br><span class="line">1 - 开始</span><br><span class="line">2 - 停止</span><br><span class="line">* - 返回</span><br><span class="line"># - 关闭</span>`;
        } else if (this.current_screen === 'corner_sell') {
            return `<span class="line">站街模式</span><br><span class="line">1 - 开始</span><br><span class="line">2 - 停止</span><br><span class="line">* - 返回</span><br><span class="line"># - 关闭</span>`;
        } else if (this.current_screen === 'confirmation') {
            return `<span class="line">已确认</span>`;
        } else if (this.current_screen === 'cancellation') {
            return `<span class="line">已取消</span>`;
        } else if (this.current_screen === 'code_entry') {
            return `<span class="line">输入代码：</span><br><span class="line">${this.sequence_buffer}</span><br><span class="line"># - 确认</span><br><span class="line">* - 返回</span>`;
        } else if (this.current_screen === 'invalid_code') {
            return `<span class="line">代码无效</span>`;
        } else if (this.current_screen === 'secret_menu_1') {
            return `<span class="line">隐藏菜单 1</span><br><span class="line">1 - 选项 1</span><br><span class="line">2 - 选项 2</span><br><span class="line">* - 返回</span><br><span class="line"># - 关闭</span>`;
        } else if (this.current_screen === 'secret_menu_2') {
            return `<span class="line">隐藏菜单 2</span><br><span class="line">1 - 选项 A</span><br><span class="line">2 - 选项 B</span><br><span class="line">* - 返回</span><br><span class="line"># - 关闭</span>`;
        }
    }

    handle_key_press(key) {
        key = String(key);
        if (this.current_screen === 'main') {
            if (key === '1') {
                this.current_screen = this.street_phone ? 'street_sell' : 'corner_sell';
            } else if (key === '2') {
                this.current_screen = this.street_phone ? 'corner_sell' : 'request_delivery';
            } else if (key === '3' && this.street_phone) {
                this.current_screen = 'request_delivery';
            } else if (key === '*') {
                this.current_screen = 'code_entry';
            } else if (key === '#') {
                this.close();
            }
        } else if (this.current_screen === 'street_sell') {
            if (key === '1') {
                this.confirm_action('dealing_start');
            } else if (key === '2') {
                this.cancel_action('dealing_stop');
            } else if (key === '#') {
                this.close();
            } else if (key === '*') {
                this.go_home();
            }
        } else if (this.current_screen === 'request_delivery') {
            if (key === '1') {
                this.confirm_action('delivery_start');
            } else if (key === '2') {
                this.cancel_action('delivery_stop');
            } else if (key === '#') {
                this.close();
            } else if (key === '*') {
                this.go_home();
            }
        } else if (this.current_screen === 'corner_sell') {
            if (key === '1') {
                this.confirm_action('corner_start');
            } else if (key === '2') {
                this.cancel_action('corner_stop');
            } else if (key === '#') {
                this.close();
            } else if (key === '*') {
                this.go_home();
            }
        } else if (this.current_screen === 'code_entry') {
            if (key === '#') {
                if (this.secret_codes[this.sequence_buffer]) {
                    this.current_screen = this.secret_codes[this.sequence_buffer];
                } else {
                    this.current_screen = 'invalid_code';
                    setTimeout(() => {
                        this.current_screen = 'main';
                        this.update_screen();
                    }, 2000);
                }
                this.sequence_buffer = '';
            } else if (key === '*') {
                this.go_home();
            } else {
                this.sequence_buffer += key;
            }
        } else if (this.current_screen.startsWith('secret_menu')) {
            if (key === '1') {
                this.confirm_action('secret_option_1');
            } else if (key === '2') {
                this.confirm_action('secret_option_2');
            } else if (key === '#') {
                this.close();
            } else if (key === '*') {
                this.go_home();
            }
        }
        this.update_screen();
    }

    confirm_action(action_id) {
        console.log('Action Confirmed:', action_id);
        this.send_action_to_server(action_id);
        this.current_screen = 'confirmation';
        this.update_screen();
        setTimeout(() => {
            this.current_screen = 'main';
            this.update_screen();
        }, 2000);
    }

    cancel_action(action_id) {
        console.log('Action Confirmed:', action_id);
        this.send_action_to_server(action_id);
        this.current_screen = 'cancellation';
        this.update_screen();
        setTimeout(() => {
            this.current_screen = 'main';
            this.update_screen();
        }, 2000);
    }

    send_action_to_server(action_id) {
        console.log(`Sending action to server: ${action_id}`);
        $.post(`https://${GetParentResourceName()}/dealer_phone_action`, JSON.stringify({ action: action_id }), (response) => {
            console.log(`Server response: ${response}`);
        });
    }

    go_home() {
        this.current_screen = 'main';
        this.sequence_buffer = '';
        this.update_screen();
    }

    update_screen() {
        $('#screen_content').html(this.get_screen_content());
    }
}

/*
const test_phone_data = {};

const test_dealer_phone = new DealerPhone();
test_dealer_phone.init(test_phone_data);
*/
