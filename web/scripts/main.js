
let prog_timer = null;
let bulk_dealer = null;

window.addEventListener('message', function (event) {
    let data = event.data;
    if (data.action === 'open_bulk_dealer') {
        bulk_dealer = new BulkDealer();
        bulk_dealer.init(data.data);
    } else if (data.action === 'open_dealer_phone') {
        window.MZPhone.open(data.data);
    } else if (data.action === 'close_dealer_phone') {
        window.MZPhone.close();
    } else if (data.action === 'phone_mode_changed') {
        window.MZPhone.setMode(data.mode);
    } else if (data.action === 'delivery_orders') {
        window.MZPhone.updateDelivery(data.data);
    } else if (data.action === 'delivery_open_inbox') {
        window.MZPhone.openInbox();
    } else if (data.action === 'open_street_offer') {
        openStreetOffer(data.data);
    } else if (data.action === 'close_street_offer') {
        closeStreetOffer();
    }
 });
