let streetDeal = null;
let lastSelectedDrugId = null;

function postStreetAction(name, data) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {})
    });
}

function closeStreetOffer() {
    streetDeal = null;
    document.getElementById('main_container').replaceChildren();
}

function openStreetOffer(data) {
    const offers = Array.isArray(data.offers) ? data.offers : [];
    if (!offers.length) return;
    const locale = data.locale || {};
    const tr = (key, ...args) => String(locale[key] ?? key).replace(/%s/g, () => String(args.shift() ?? ''));
    const selected = offers.find((offer) => offer.id === lastSelectedDrugId) || offers[0];
    streetDeal = { offers, selected, price: selected.optimal, submitted: false,
        mode: data.mode || 'street', saleId: data.sale_id, tr };
    const root = document.getElementById('main_container');
    root.innerHTML = `
        <section class="street-panel" aria-label="${tr('sale')}">
            <header class="street-header">
                <div><span class="street-kicker">${streetDeal.mode === 'delivery' ? tr('delivery') : tr('sale')}</span><h2>${tr('title')}</h2></div>
                <button type="button" class="street-icon" id="street-close" title="${tr('cancel')}" aria-label="${tr('cancel')}">
                    ×
                </button>
            </header>
            <div class="street-customer"><i class="fa-solid fa-user"></i><span id="street-personality"></span></div>
            <label class="street-label" for="street-drug">${tr('choose_drug')}</label>
            <div class="street-select-wrap">
                <button type="button" class="street-select" id="street-drug" aria-expanded="false">${tr('choose_drug')}</button>
                <ul class="street-options" id="street-drug-options" hidden></ul>
            </div>
            <div class="street-pricing">
                <div><span>${tr('unit_price')}</span><strong id="street-price"></strong></div>
                <input type="range" id="street-range" step="1" aria-label="${tr('unit_price')}">
                <div class="street-scale"><span id="street-min"></span><span id="street-optimal"></span><span id="street-max"></span></div>
            </div>
            <button type="button" class="street-submit" id="street-submit">${tr('submit')} <i class="fa-solid fa-arrow-right"></i></button>
        </section>`;
    document.getElementById('street-personality').textContent = data.type_label || tr('customer');
    const drugSelect = document.getElementById('street-drug');
    const drugOptions = document.getElementById('street-drug-options');
    offers.forEach((offer) => {
        const option = document.createElement('li');
        option.className = 'street-option';
        option.dataset.value = offer.id;
        option.textContent = `${offer.label} · ${tr('count', offer.count)}`;
        option.onclick = () => selectStreetDrug(offer.id);
        drugOptions.appendChild(option);
    });
    drugSelect.replaceChildren();
    drugSelect.textContent = `${selected.label} · ${tr('count', selected.count)}`;
    drugSelect.onclick = () => {
        const open = drugOptions.hidden;
        drugOptions.hidden = !open;
        drugSelect.setAttribute('aria-expanded', open ? 'true' : 'false');
    };
    document.getElementById('street-range').oninput = (event) => {
        streetDeal.price = Number(event.target.value);
        document.getElementById('street-price').textContent = `$${streetDeal.price}`;
    };
    document.getElementById('street-close').onclick = () => {
        postStreetAction(streetDeal.mode === 'delivery' ? 'delivery_cancel' : 'street_cancel');
        closeStreetOffer();
    };
    document.getElementById('street-submit').onclick = () => {
        if (!streetDeal || streetDeal.submitted) return;
        streetDeal.submitted = true;
        postStreetAction(streetDeal.mode === 'delivery' ? 'delivery_offer' : 'street_offer', {
            drug_id: streetDeal.selected.id,
            price: streetDeal.price, sale_id: streetDeal.saleId
        });
        closeStreetOffer();
    };
    renderStreetSelection();
}

function renderStreetSelection() {
    const selected = streetDeal.selected;
    const tr = streetDeal.tr;
    const drugSelect = document.getElementById('street-drug');
    drugSelect.textContent = `${selected.label} · ${tr('count', selected.count)}`;
    document.querySelectorAll('.street-option').forEach((option) => {
        option.classList.toggle('selected', option.dataset.value === String(selected.id));
    });
    const range = document.getElementById('street-range');
    range.min = selected.min;
    range.max = selected.max;
    range.value = streetDeal.price;
    document.getElementById('street-price').textContent = `$${streetDeal.price}`;
    document.getElementById('street-min').textContent = `$${selected.min}`;
    document.getElementById('street-optimal').textContent = tr('suggested', selected.optimal);
    document.getElementById('street-max').textContent = `$${selected.max}`;
}

function selectStreetDrug(id) {
    const offer = streetDeal.offers.find((item) => String(item.id) === String(id));
    if (!offer) return;
    streetDeal.selected = offer;
    streetDeal.price = offer.optimal;
    lastSelectedDrugId = offer.id;
    renderStreetSelection();
    document.getElementById('street-drug-options').hidden = true;
    document.getElementById('street-drug').setAttribute('aria-expanded', 'false');
}

document.addEventListener('click', (event) => {
    if (!event.target.closest('.street-select-wrap')) {
        const options = document.getElementById('street-drug-options');
        const trigger = document.getElementById('street-drug');
        if (options && trigger) {
            options.hidden = true;
            trigger.setAttribute('aria-expanded', 'false');
        }
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && streetDeal) {
        postStreetAction(streetDeal.mode === 'delivery' ? 'delivery_cancel' : 'street_cancel');
        closeStreetOffer();
    }
});
