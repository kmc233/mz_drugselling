class BulkDealer {
    constructor() {
        this.location = null;
        this.skills = null;
        this.drugs = null;
        this.current_drug = null;
        $(document).ready(() => {
            $(document).keyup((e) => this.handle_exit(e));
        });
    }

    handle_exit(e) {
        if (e.key === "Escape" && $('.bulk_dealer_header').length) {
            this.close();
        }
    }

    close() {
        $('#main_container').empty();
        $.post(`https://${GetParentResourceName()}/close_ui`, JSON.stringify({}));
    }

    init(data) {
        this.location = data.location;
        this.drugs = data.drugs;
        this.skills = data.skills;
        this.build();
    }

    build() {
        const xp_percent = (this.skills.current_xp / this.skills.required_xp) * 100;
        const content = `
            <div class="bulk_dealer_header">
                <div class="bulk_dealer_header_title">Bulk Dealer</div>
                <div class="bulk_dealer_header_buttons">
                    <button id="close_btn" class="close_button"><i class="fa-solid fa-right-from-bracket"></i></button>  
                </div>
            </div>

            <div class="bulk_dealer_body">
                <div class="drugs_header"> 
                    <div class="xp_bar_container" id="xp_progress_bar">
                        <div class="xp_progress_bar" style="position: relative;">
                            <div class="xp_bar" style="width: ${xp_percent}%;">
                                <div class="xp_tooltip">Tooltip text</div>
                            </div>
                        </div>
                        <span class="level_indicator">${this.skills.level}</span>
                    </div>
                </div>
                <div class="bulk_dealer_grid" id="bulk_dealer_grid">
                    ${this.render_drugs()}
                </div>
                <div id="drug_details" class="drug_details"></div>
            </div>
        `;
        $('#main_container').html(content);
        this.setup_events();
    }

    render_drugs() {
        let drug_cards = '';
        const drugs_array = Object.values(this.drugs);
        drugs_array.sort((a, b) => a.required_level - b.required_level);
        drugs_array.forEach(drug => {
            const level_class = this.skills.level < drug.required_level ? "level disabled" : "level";
            drug_cards += `
                <div class="drug_card" data-drug-id="${drug.id}">
                    <img src="./assets/images/${drug.image}" alt="${drug.label}" class="drug_image">
                    <div class="drug_info">
                        <h3>${drug.label}</h3>
                        <div class="drug_badges">
                            <div class="drug_badge price">Price: ${drug.price}</div>
                            <div class="drug_badge ${level_class}">Level: ${drug.required_level}</div>
                            <div class="drug_badge quantity">Quantity: <span class="quantity_value" id="quantity_${drug.id}"> ${drug.quantity}</span></div>
                        </div>
                    </div>
                </div>
            `;
        });
        return drug_cards;
    }

    setup_events() {
        const self = this;

        $('#close_btn').off('click').on('click', function() {
            self.close();
        });

        $('.xp_bar_container').off('mouseenter mouseleave').hover(
            function() {
                const content = `${self.skills.current_xp}/${self.skills.required_xp} XP`;
                $('.xp_tooltip').text(content).fadeIn(150);
            },
            function() {
                $(this).find('.xp_tooltip').fadeOut(150);
            }
        );

        $('.bulk_dealer_grid').off('click').on('click', '.drug_card', function() {
            const drug_id = $(this).data('drug-id');
            self.open_drug_details(drug_id);
        });
    }

    open_drug_details(drug_id) {
        const self = this;
        const drugs_array = Object.values(this.drugs);
        const drug = drugs_array.find(c => c.id === drug_id);
        if (!drug) {
            console.error('drug not found:', drug_id);
            return;
        }
        this.current_drug = drug;
        const detail_content = `
            <div class="drug">
                <button id="close_drug"><i class="fa-solid fa-right-from-bracket"></i></button>
                <div class="drug_header">
                    <img src="./assets/images/${drug.image}" alt="${drug.label}" class="drug_image">
                    <div class="drug_info">
                        <h3>${drug.label}</h3>
                        <div class="drug_badges">
                            <div class="drug_badge price">Price: ${drug.price}</div>
                            <div class="drug_badge quantity">Quantity: <span class="quantity_value" id="remaining_quantity"> ${drug.quantity}</span></div>
                        </div>
                    </div>
                </div>
                <div class="drug_body">
                    <div class="profit_counter">
                        <label for="profit">Profit:</label>
                        <span id="profit_value">$0</span>
                    </div>
                    <div class="quantity_input">
                        <label for="quantity">Quantity:</label>
                        <input type="number" id="quantity_input" min="1" max="${drug.quantity}" value="0">
                    </div>
                </div>
                <div class="sell_button_container">
                    ${drug.quantity > 0 && this.skills.level >= drug.required_level ? '<button id="sell_button" class="sell_button">Sell</button>' : ''}
                </div>
            </div>
        `;
        $('#drug_details').html(detail_content);
    
        $('#close_drug').off('click').on('click', function() {
            $('#drug_details').empty();
            self.current_drug = null;
        });

        $('#quantity_input').off('input').on('input', function() {
            const quantity = parseInt($(this).val(), 10);
            const profit = quantity * drug.price;
            $('#profit_value').text(`$${profit}`);
            const remaining_quantity = drug.quantity - quantity;
            $('#remaining_quantity').text(remaining_quantity);
        });

        $('#sell_button').off('click').on('click', function() {
            const quantity = parseInt($('#quantity_input').val(), 10);
            console.log('clicked sell button with amount: ' + quantity);
            self.sell_drug(self.location, drug.id, quantity);
        });
    }
    
    sell_drug(location, drug_id, quantity) {
        console.log(`Selling ${quantity} units of drug ID: ${drug_id}`);
        fetch(`https://${GetParentResourceName()}/bulk_sell_drug`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                location: location,
                drug_id: drug_id,
                quantity: quantity
            })
        })
        .then(resp => resp.json())
        .then(data => {
            if (data.success) {
                console.log('Bulk sell success:', data.message);
                this.update_drug_quantity(drug_id, quantity);
                this.update_xp(data.skills);
            } else {
                console.error('Bulk sell failed:', data.message);
            }
        })
        .catch(err => console.error('Failed to validate payment:', err));
    }

    update_drug_quantity(drug_id, quantity_sold) {
        const drug = this.drugs.find(d => d.id === drug_id);
        if (drug) {
            drug.quantity -= quantity_sold;
            if (drug.quantity < 0) {
                drug.quantity = 0; // Prevent negative quantity
            }
            $(`#quantity_${drug.id}`).text(drug.quantity);
            if (this.current_drug && this.current_drug.id === drug_id) {
                $('#remaining_quantity').text(drug.quantity);
                $('#quantity_input').attr('max', drug.quantity);
                $('#quantity_input').val('0');
                $('#profit_value').text('$0');
            }
        }
    }

    update_xp(data) {
        this.skills.current_xp = data.current_xp;
        this.skills.required_xp = data.required_xp;
        this.skills.level = data.level;
        const xp_percent = (data.current_xp / data.required_xp) * 100;
        $('.xp_bar').css('width', `${xp_percent}%`);
        $('.xp_tooltip').text(`${data.current_xp}/${data.required_xp} XP`);
        $('.level_indicator').text(data.level);
    }
}

/*
const bulk_test_data = {
    skills: {
        level: 1,
        current_xp: 650,
        required_xp: 1000
    },
    drugs: [
        { 
            id: 'ounce_ketamine',
            label: 'Ketamine: 1oz',
            image: 'ounce_ketamine.png',
            required_level: 1,
            price: 200,
            quantity: 100
        },
        { 
            id: 'ounce_heroin',
            label: 'Heroin: 1oz',
            image: 'ounce_heroin.png',
            required_level: 2,
            price: 200,
            quantity: 100
        },
        { 
            id: 'ounce_crack',
            label: 'Crack: 1oz',
            image: 'ounce_crack.png',
            required_level: 3,
            price: 200,
            quantity: 100
        },
        { 
            id: 'ounce_cocaine',
            label: 'Cocaine: 1oz',
            image: 'ounce_cocaine.png',
            required_level: 5,
            price: 300,
            quantity: 1000
        },
        { 
            id: 'ounce_meth',
            label: 'Meth: 1oz',
            image: 'ounce_meth.png',
            required_level: 4,
            price: 200,
            quantity: 100
        },
    ]
}

const test_bulkdealer = new BulkDealer();
test_bulkdealer.init(bulk_test_data);
*/
