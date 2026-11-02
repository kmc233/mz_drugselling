class BulkDealer {
    constructor() {
        this.location = null;
        this.skills = { level: 1, current_xp: 0, required_xp: 1000 };
        this.drugs = [];
        this.currentDrug = null;
        this.quantity = 0;
        this.busy = false;
        this.locale = {};
    }

    tr(key, ...args) {
        return String(this.locale[key] ?? key).replace(/%s/g, () => String(args.shift() ?? ''));
    }

    init(data) {
        this.locale = data.locale || {};
        this.location = data.location;
        this.skills = data.skills || this.skills;
        this.drugs = Array.isArray(data.drugs) ? data.drugs : Object.values(data.drugs || {});
        this.drugs.sort((a, b) => (a.required_level || 1) - (b.required_level || 1));
        this.currentDrug = this.drugs[0] || null;
        this.render();
    }

    close() {
        document.getElementById('main_container').replaceChildren();
        fetch(`https://${GetParentResourceName()}/close_ui`, { method: 'POST', body: '{}' });
    }

    render() {
        const xp = this.skills.required_xp > 0 ? Math.min(100, (this.skills.current_xp / this.skills.required_xp) * 100) : 0;
        document.getElementById('main_container').innerHTML = `
            <section class="bulk-shell" aria-label="${this.tr('market')}">
                <header class="bulk-topbar">
                    <div><span class="bulk-kicker">${this.tr('market')}</span><h1>${this.tr('title')}</h1><p>${this.tr('description')}</p></div>
                    <button type="button" class="bulk-close" id="bulk-close" title="${this.tr('close')}" aria-label="${this.tr('close')}">×</button>
                </header>
                <div class="bulk-summary">
                    <div class="bulk-level"><span>${this.tr('level')}</span><strong>LV ${this.skills.level || 1}</strong></div>
                    <div class="bulk-xp"><div class="bulk-xp-label"><span>${this.tr('experience')}</span><span>${this.skills.current_xp || 0} / ${this.skills.required_xp || 0} XP</span></div><div class="bulk-xp-track"><i style="width:${xp}%"></i></div></div>
                </div>
                <div class="bulk-layout">
                    <div class="bulk-inventory"><div class="bulk-section-title"><h2>${this.tr('inventory')}</h2><span>${this.tr('drug_count', this.drugs.length)}</span></div><div class="bulk-grid" id="bulk-grid">${this.renderCards()}</div></div>
                    <aside class="bulk-order" id="bulk-order">${this.renderOrder()}</aside>
                </div>
            </section>`;
        this.bindEvents();
    }

    renderCards() {
        if (!this.drugs.length) return `<div class="bulk-empty">${this.tr('empty')}</div>`;
        return this.drugs.map((drug) => {
            const locked = (this.skills.level || 1) < (drug.required_level || 1);
            const empty = (drug.quantity || 0) < 1;
            const active = this.currentDrug && drug.id === this.currentDrug.id ? ' active' : '';
            return `<button type="button" class="bulk-card${active}" data-drug-id="${drug.id}" ${locked || empty ? 'disabled' : ''}>
                <div class="bulk-card-image">${drug.image ? `<img src="${drug.image}" alt="">` : `<span>${this.tr('drug_symbol')}</span>`}</div>
                <div class="bulk-card-info"><strong>${drug.label}</strong><small>${locked ? this.tr('required_level', drug.required_level) : this.tr('stock', drug.quantity)}</small></div><span class="bulk-card-arrow">›</span>
            </button>`;
        }).join('');
    }

    renderOrder() {
        const drug = this.currentDrug;
        if (!drug) return `<div class="bulk-empty">${this.tr('choose_drug')}</div>`;
        const locked = (this.skills.level || 1) < (drug.required_level || 1);
        const max = Math.max(0, drug.quantity || 0);
        const quantity = Math.min(this.quantity, max);
        const total = quantity * (drug.price || 0);
        return `<div class="bulk-order-heading"><span>${this.tr('details')}</span><span class="bulk-status ${locked ? 'locked' : ''}">${locked ? this.tr('locked') : this.tr('available')}</span></div>
            <div class="bulk-product"><div class="bulk-product-image">${drug.image ? `<img src="${drug.image}" alt="">` : `<span>${this.tr('drug_symbol')}</span>`}</div><div><h2>${drug.label}</h2><p>${this.tr('unit_price')} <strong>$${drug.price}</strong></p></div></div>
            <div class="bulk-order-rule"></div><div class="bulk-quantity-head"><label for="bulk-quantity">${this.tr('quantity')}</label><span>${this.tr('maximum', max)}</span></div>
            <div class="bulk-quantity"><button type="button" data-step="-1" ${locked ? 'disabled' : ''}>−</button><input id="bulk-quantity" type="number" min="0" max="${max}" value="${quantity}" ${locked ? 'disabled' : ''}><button type="button" data-step="1" ${locked ? 'disabled' : ''}>+</button></div>
            <input class="bulk-range" id="bulk-range" type="range" min="0" max="${max}" value="${quantity}" ${locked ? 'disabled' : ''}>
            <div class="bulk-total"><span>${this.tr('estimated')}</span><strong>$${total}</strong></div><button type="button" class="bulk-submit" id="bulk-submit" ${locked || quantity < 1 || this.busy ? 'disabled' : ''}>${this.tr('submit')} <span>→</span></button>`;
    }

    bindEvents() {
        document.getElementById('bulk-close').onclick = () => this.close();
        document.getElementById('bulk-grid').onclick = (event) => {
            const card = event.target.closest('[data-drug-id]');
            if (!card || card.disabled) return;
            this.currentDrug = this.drugs.find((drug) => String(drug.id) === String(card.dataset.drugId));
            this.quantity = 0;
            this.renderOrderOnly();
        };
        const order = document.getElementById('bulk-order');
        order.oninput = (event) => {
            if (event.target.id === 'bulk-quantity' || event.target.id === 'bulk-range') {
                this.quantity = this.clampQuantity(event.target.value);
                this.syncQuantityControls();
            }
        };
        order.onclick = (event) => {
            const step = event.target.closest('[data-step]');
            if (step) { this.quantity = this.clampQuantity(this.quantity + Number(step.dataset.step)); this.renderOrderOnly(); }
            else if (event.target.id === 'bulk-submit') this.sellDrug();
        };
    }

    renderOrderOnly() {
        document.getElementById('bulk-order').innerHTML = this.renderOrder();
        document.querySelectorAll('.bulk-card').forEach((card) => card.classList.toggle('active', String(card.dataset.drugId) === String(this.currentDrug?.id)));
    }

    syncQuantityControls() {
        const input = document.getElementById('bulk-quantity');
        const range = document.getElementById('bulk-range');
        const total = document.querySelector('.bulk-total strong');
        const submit = document.getElementById('bulk-submit');
        if (input) input.value = this.quantity;
        if (range) range.value = this.quantity;
        if (total) total.textContent = `$${this.quantity * (this.currentDrug?.price || 0)}`;
        if (submit) submit.disabled = this.busy || !this.currentDrug || this.quantity < 1 || (this.skills.level || 1) < (this.currentDrug.required_level || 1);
    }

    clampQuantity(value) {
        const max = Math.max(0, this.currentDrug?.quantity || 0);
        const parsed = Number.parseInt(value, 10);
        return Math.max(0, Math.min(max, Number.isFinite(parsed) ? parsed : 0));
    }

    sellDrug() {
        if (this.busy || !this.currentDrug || this.quantity < 1) return;
        this.busy = true;
        this.renderOrderOnly();
        fetch(`https://${GetParentResourceName()}/bulk_sell_drug`, { method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify({ location: this.location, drug_id: this.currentDrug.id, quantity: this.quantity }) })
            .then((response) => response.json()).then((result) => {
                if (result.success) { this.currentDrug.quantity = Math.max(0, this.currentDrug.quantity - this.quantity); this.skills = result.skills || this.skills; this.quantity = 0; }
                this.busy = false; this.render();
            }).catch(() => { this.busy = false; this.renderOrderOnly(); });
    }
}

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && document.querySelector('.bulk-shell')) window.bulk_dealer?.close();
});
