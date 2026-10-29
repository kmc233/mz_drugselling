import { createApp } from 'vue';
import App from './Phone.vue';
import './phone.css';

const phone = createApp(App).mount('#phone-root');

window.MZPhone = {
  open: (data) => phone.open(data),
  close: () => phone.close(),
  setMode: (mode) => phone.setMode(mode),
  updateDelivery: (data) => phone.updateDelivery(data),
  openInbox: () => phone.openInbox()
};

if (import.meta.env.DEV) {
  document.body.classList.add('phone-preview');
  phone.open({ street_phone: false, active_mode: null });
}
