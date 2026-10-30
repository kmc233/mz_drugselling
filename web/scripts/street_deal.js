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
    const selected = offers.find((offer) => offer.id === lastSelectedDrugId) || offers[0];
    streetDeal = { offers, selected, price: selected.optimal, submitted: false,
        mode: data.mode || 'street', saleId: data.sale_id };
    const root = document.getElementById('main_container');
    root.innerHTML = `
        <section class="street-panel" aria-label="Street sale">
            <header class="street-header">
                <div><span class="street-kicker">${streetDeal.mode === 'delivery' ? 'DELIVERY' : 'STREET DEAL'}</span><h2>报价交易</h2></div>
                <button type="button" class="street-icon" id="street-close" title="取消交易" aria-label="取消交易">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </header>
            <div class="street-customer"><i class="fa-solid fa-user"></i><span id="street-personality"></span></div>
            <label class="street-label" for="street-drug">选择药品</label>
            <select class="street-select" id="street-drug"></select>
            <div class="street-pricing">
                <div><span>单件报价</span><strong id="street-price"></strong></div>
                <input type="range" id="street-range" step="1" aria-label="单件报价">
                <div class="street-scale"><span id="street-min"></span><span id="street-optimal"></span><span id="street-max"></span></div>
            </div>
            <button type="button" class="street-submit" id="street-submit">提交报价 <i class="fa-solid fa-arrow-right"></i></button>
        </section>`;
    document.getElementById('street-personality').textContent = data.type_label || '普通顾客';
    const drugSelect = document.getElementById('street-drug');
    offers.forEach((offer) => {
        const option = document.createElement('option');
        option.value = offer.id;
        option.textContent = `${offer.label} · ${offer.count} 件`;
        drugSelect.appendChild(option);
    });
    drugSelect.onchange = (event) => {
        const offer = streetDeal.offers.find((item) => item.id === event.target.value);
        if (!offer) return;
        streetDeal.selected = offer;
        streetDeal.price = offer.optimal;
        lastSelectedDrugId = offer.id;
        renderStreetSelection();
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
    document.getElementById('street-drug').value = selected.id;
    const range = document.getElementById('street-range');
    range.min = selected.min;
    range.max = selected.max;
    range.value = streetDeal.price;
    document.getElementById('street-price').textContent = `$${streetDeal.price}`;
    document.getElementById('street-min').textContent = `$${selected.min}`;
    document.getElementById('street-optimal').textContent = `建议 $${selected.optimal}`;
    document.getElementById('street-max').textContent = `$${selected.max}`;
}

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && streetDeal) {
        postStreetAction(streetDeal.mode === 'delivery' ? 'delivery_cancel' : 'street_cancel');
        closeStreetOffer();
    }
});
