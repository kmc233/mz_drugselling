/*
     ____   ____ _____ _____   _   _____  ________      ________ _      ____  _____  __  __ ______ _   _ _______ 
    |  _ \ / __ \_   _|_   _| | | |  __ \|  ____\ \    / /  ____| |    / __ \|  __ \|  \/  |  ____| \ | |__   __|
    | |_) | |  | || |   | |   | | | |  | | |__   \ \  / /| |__  | |   | |  | | |__) | \  / | |__  |  \| |  | |   
    |  _ <| |  | || |   | |   | | | |  | |  __|   \ \/ / |  __| | |   | |  | |  ___/| |\/| |  __| | . ` |  | |   
    | |_) | |__| || |_ _| |_  | | | |__| | |____   \  /  | |____| |___| |__| | |    | |  | | |____| |\  |  | |   
    |____/ \____/_____|_____| | | |_____/|______|   \/   |______|______\____/|_|    |_|  |_|______|_| \_|  |_|   
                              | |                                                                                
                              |_|               DRUG SALES
*/

let prog_timer = null;
let bulk_dealer = null;
let dealer_phone = null;

window.addEventListener('message', function (event) {
    let data = event.data;
    if (data.action === 'open_bulk_dealer') {
        bulk_dealer = new BulkDealer();
        bulk_dealer.init(data.data);
    } else if (data.action === 'open_dealer_phone') {
        dealer_phone = new DealerPhone();
        dealer_phone.init();
    } else if (data.action === 'close_dealer_phone') {
        if (dealer_phone) {
            dealer_phone.close();
        }
    }
 });