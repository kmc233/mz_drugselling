let streetDeal = null;

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
    streetDeal = { offers, selected: offers[0], price: offers[0].optimal, submitted: false };
    const root = document.getElementById('main_container');
    root.innerHTML = `
        <section class="street-panel" aria-label="Street sale">
            <header class="street-header">
                <div><span class="street-kicker">STREET DEAL</span><h2>报价交易</h2></div>
                <button type="button" class="street-icon" id="street-close" title="取消交易" aria-label="取消交易">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </header>
            <div class="street-customer"><i class="fa-solid fa-user"></i><span id="street-personality"></span></div>
            <div class="street-label">选择药品</div>
            <div class="street-items" id="street-items"></div>
            <div class="street-pricing">
                <div><span>单件报价</span><strong id="street-price"></strong></div>
                <input type="range" id="street-range" step="1" aria-label="单件报价">
                <div class="street-scale"><span id="street-min"></span><span id="street-optimal"></span><span id="street-max"></span></div>
            </div>
            <button type="button" class="street-submit" id="street-submit">提交报价 <i class="fa-solid fa-arrow-right"></i></button>
        </section>`;
    document.getElementById('street-personality').textContent = data.type_label || '普通顾客';
    const items = document.getElementById('street-items');
    offers.forEach((offer) => {
        const button = document.createElement('button');
        button.type = 'button';
        button.className = 'street-item';
        button.textContent = `${offer.label} · ${offer.count} 件`;
        button.onclick = () => {
            streetDeal.selected = offer;
            streetDeal.price = offer.optimal;
            renderStreetSelection();
        };
        items.appendChild(button);
    });
    document.getElementById('street-range').oninput = (event) => {
        streetDeal.price = Number(event.target.value);
        document.getElementById('street-price').textContent = `$${streetDeal.price}`;
    };
    document.getElementById('street-close').onclick = () => {
        postStreetAction('street_cancel');
        closeStreetOffer();
    };
    document.getElementById('street-submit').onclick = () => {
        if (!streetDeal || streetDeal.submitted) return;
        streetDeal.submitted = true;
        postStreetAction('street_offer', {
            drug_id: streetDeal.selected.id,
            price: streetDeal.price
        });
        closeStreetOffer();
    };
    renderStreetSelection();
}

function renderStreetSelection() {
    const selected = streetDeal.selected;
    document.querySelectorAll('.street-item').forEach((button, index) => {
        button.classList.toggle('active', streetDeal.offers[index] === selected);
    });
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
        postStreetAction('street_cancel');
        closeStreetOffer();
    }
});
