<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import {
  ArrowLeft, Check, ChevronRight, MapPin, Phone, PhoneOff,
  Radio, ShoppingBag, X, Clock3
} from 'lucide-vue-next';

const visible = ref(false);
const streetPhone = ref(false);
const activeMode = ref(null);
const deliveryReceiving = ref(false);
const view = ref('home');
const selectedIndex = ref(0);
const busy = ref(false);
const deliveryData = ref({ orders: [], active_id: null, cooldown_until: 0, server_time: 0 });
const locale = ref({});
const smsDialogue = ref({});
const t = (key) => locale.value[key] ?? key;
const format = (value, ...args) => String(value).replace(/%[sd]/g, () => String(args.shift() ?? ''));
function dialogue(key, order) {
  const variants = smsDialogue.value[key];
  if (!Array.isArray(variants) || !variants.length) return '';
  return variants[(Number(order?.id || 0) - 1) % variants.length];
}
const selectedOrderId = ref(null);
const now = ref(Math.floor(Date.now() / 1000));
let clockTimer;
let serverOffset = 0;

const modes = computed(() => [
  ...(streetPhone.value ? [{ id: 'dealing', title: t('mode_dealing'), icon: ShoppingBag, accent: 'teal' }] : []),
  { id: 'corner', title: t('mode_corner'), icon: Radio, accent: 'orange' },
  { id: 'delivery', title: t('mode_delivery'), icon: MapPin, accent: 'red' }
]);
const selectedMode = computed(() => modes.value.find((mode) => mode.id === view.value));
const orders = computed(() => deliveryData.value.orders || []);
const selectedOrder = computed(() => orders.value.find((order) => order.id === selectedOrderId.value));
const activeOrder = computed(() => orders.value.find((order) => order.id === deliveryData.value.active_id));
const leftLabel = computed(() => {
  if (view.value === 'home') return t('select');
  if (view.value === 'delivery_inbox') return deliveryReceiving.value ? t('stop_receiving') : t('receive_messages');
  if (view.value === 'delivery_thread') {
    if (selectedOrder.value?.status === 'accepted' && selectedOrder.value.expires_at > now.value) return t('cancel_order');
    return selectedOrder.value?.status === 'pending' && !activeOrder.value &&
      selectedOrder.value.expires_at > now.value && deliveryData.value.cooldown_until <= now.value ? t('accept_order') : '';
  }
  return activeMode.value && activeMode.value !== view.value ? '' : activeMode.value === view.value ? t('stop') : t('start');
});
const rightLabel = computed(() => view.value === 'home' ? t('close') : t('back'));
const screenState = computed(() => {
  if (view.value === 'delivery_inbox') return activeOrder.value ? t('state_delivery') : deliveryReceiving.value ? t('state_receiving') : t('state_not_receiving');
  if (view.value === 'dealing' || view.value === 'corner') return activeMode.value === view.value ? t('state_active') : activeMode.value === 'delivery' ? t('state_delivery') : t('state_not_started');
  return '';
});
const statusText = computed(() => ({ pending: t('state_pending'), accepted: t('state_delivery'), completed: t('state_completed'), expired: t('state_expired'), cancelled: t('state_cancelled') }));
function orderStatus(order) {
  return (order.status === 'pending' || order.status === 'accepted') && order.expires_at <= now.value
    ? t('state_expired') : statusText.value[order.status];
}
function remaining(timestamp) {
  const seconds = Math.max(0, timestamp - now.value);
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}
function updateDelivery(data = {}) {
  deliveryData.value = data;
  serverOffset = (data.server_time || Math.floor(Date.now() / 1000)) - Math.floor(Date.now() / 1000);
  now.value = Math.floor(Date.now() / 1000) + serverOffset;
}
async function postDelivery(action, data = {}) {
  if (busy.value || typeof GetParentResourceName !== 'function') return;
  busy.value = true;
  try {
    await fetch(`https://${GetParentResourceName()}/${action}`, {
      method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data)
    });
  } catch (error) {
    console.error('Delivery action failed', error);
  } finally { busy.value = false; }
}
function openInbox() { view.value = 'delivery_inbox'; selectedIndex.value = 0; }
function openThread(order) { selectedOrderId.value = order.id; view.value = 'delivery_thread'; selectedIndex.value = 0; }

function open(data = {}) {
  locale.value = data.phone_locale || locale.value;
  smsDialogue.value = data.sms_dialogue || smsDialogue.value;
  streetPhone.value = data.street_phone === true;
  activeMode.value = data.active_mode || null;
  deliveryReceiving.value = data.delivery_receiving === true;
  view.value = 'home';
  selectedIndex.value = 0;
  busy.value = false;
  updateDelivery(data.delivery_orders || {});
  visible.value = true;
}

function close() {
  if (!visible.value) return;
  visible.value = false;
  busy.value = false;
  if (typeof GetParentResourceName === 'function') {
    fetch(`https://${GetParentResourceName()}/close_ui`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: '{}'
    }).catch(() => {});
  }
}

function setMode(mode) {
  activeMode.value = mode || null;
}
function setReceiving(receiving) { deliveryReceiving.value = receiving === true; }

function selectMode(mode) {
  view.value = mode.id === 'delivery' ? 'delivery_inbox' : mode.id;
  selectedIndex.value = 0;
}

function goBack() {
  if (view.value === 'delivery_thread') {
    openInbox();
  } else if (view.value === 'delivery_inbox') {
    view.value = 'home';
    selectedIndex.value = 0;
  } else if (view.value !== 'home') {
    view.value = 'home';
    selectedIndex.value = 0;
  } else {
    close();
  }
}

async function submit(intent, mode = view.value) {
  if (busy.value) return;
  if (mode !== 'delivery' && intent === 'start' && activeMode.value && activeMode.value !== mode) return;
  if (mode !== 'delivery' && intent === 'stop' && activeMode.value !== mode) return;
  const name = `${mode === 'dealing' ? 'dealing' : mode}_${intent}`;
  if (typeof GetParentResourceName !== 'function') {
    if (mode === 'delivery') {
      deliveryReceiving.value = intent === 'start';
    } else {
      setMode(intent === 'start' ? mode : null);
    }
    return;
  }
  busy.value = true;
  try {
    await fetch(`https://${GetParentResourceName()}/dealer_phone_action`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({ action: name })
    });
  } catch (error) {
    console.error('Phone action failed', error);
  } finally {
    busy.value = false;
  }
}

function softLeft() {
  if (!leftLabel.value || busy.value) return;
  if (view.value === 'home') return confirmSelection();
  if (view.value === 'delivery_inbox') return submit(deliveryReceiving.value ? 'stop' : 'start', 'delivery');
  if (view.value === 'delivery_thread') {
    if (leftLabel.value === t('accept_order')) return postDelivery('delivery_accept', { id: selectedOrder.value.id });
    if (leftLabel.value === t('cancel_order')) return postDelivery('delivery_cancel_order');
    return;
  }
  submit(activeMode.value === view.value ? 'stop' : 'start');
}

function confirmSelection() {
  if (view.value === 'home') {
    const mode = modes.value[selectedIndex.value];
    if (mode) selectMode(mode);
  } else if (view.value === 'delivery_inbox') {
    const order = orders.value[selectedIndex.value];
    if (order) openThread(order);
  } else if (view.value === 'delivery_thread') {
    softLeft();
  } else {
    softLeft();
  }
}

function navigate(direction) {
  const count = view.value === 'home' ? modes.value.length : view.value === 'delivery_inbox' ? orders.value.length : 0;
  if (!count || view.value === 'delivery_thread') {
    if (direction === 'left') goBack();
    return;
  }
  if (direction === 'up' || direction === 'down') {
    const step = direction === 'up' ? -1 : 1;
    selectedIndex.value = (selectedIndex.value + step + count) % count;
  } else if (view.value === 'home') {
    const step = direction === 'left' ? -1 : 1;
    selectedIndex.value = (selectedIndex.value + step + count) % count;
  } else if (direction === 'left') {
    goBack();
  } else {
    confirmSelection();
  }
}

function onKeydown(event) {
  if (!visible.value) return;
  const directions = { ArrowUp: 'up', ArrowDown: 'down', ArrowLeft: 'left', ArrowRight: 'right' };
  if (directions[event.key]) {
    event.preventDefault();
    navigate(directions[event.key]);
  } else if (event.key === 'Enter') {
    event.preventDefault();
    confirmSelection();
  } else if (event.key === 'Escape') {
    event.preventDefault();
    close();
  } else if (event.key === 'Backspace') {
    event.preventDefault();
    goBack();
  }
}

onMounted(() => {
  window.addEventListener('keydown', onKeydown);
  clockTimer = setInterval(() => { now.value = Math.floor(Date.now() / 1000) + serverOffset; }, 1000);
});
onUnmounted(() => { window.removeEventListener('keydown', onKeydown); clearInterval(clockTimer); });
defineExpose({ open, close, setMode, setReceiving, updateDelivery, openInbox });
</script>

<template>
  <div v-if="visible" class="mz-phone" :aria-label="t('brand')">
    <div class="phone-shell">
      <div class="shell-top"><span class="earpiece"></span><strong>MUZIA</strong></div>
      <div class="phone-screen">
        <div class="screen-status"><span>09:41</span><span class="status-icons"><Radio :size="13" /><span class="battery"><span></span></span></span></div>
        <div class="screen-heading">
          <button v-if="view !== 'home'" class="screen-back" type="button" :title="t('back')" :aria-label="t('back')" @click="goBack"><ArrowLeft :size="20" /></button>
          <div><span v-if="view === 'home'" class="screen-eyebrow">{{ t('network') }}</span><h1>{{ view === 'home' ? t('home_title') : view === 'delivery_inbox' ? t('delivery_title') : view === 'delivery_thread' ? selectedOrder?.contact : selectedMode?.title }}</h1></div>
          <span v-if="screenState" class="screen-state">{{ screenState }}</span>
        </div>
        <div class="screen-body">
          <template v-if="view === 'home'">
            <div class="section-caption">{{ t('section_sales_modes') }}</div>
            <div class="mode-list">
              <button v-for="(mode, index) in modes" :key="mode.id" type="button" class="mode-row"
                :class="[{ focused: selectedIndex === index }, mode.accent]"
                @click="selectMode(mode)" @mouseenter="selectedIndex = index">
                <span class="mode-icon"><component :is="mode.icon" :size="22" /></span>
                <span class="mode-name">{{ mode.title }}<small v-if="mode.id === 'delivery' ? activeOrder || deliveryReceiving : activeMode === mode.id">{{ mode.id === 'delivery' ? activeOrder ? t('state_delivery') : t('state_receiving') : t('state_active') }}</small></span>
                <ChevronRight :size="18" class="row-arrow" />
              </button>
            </div>
          </template>
          <template v-else-if="view === 'delivery_inbox'">
            <div class="inbox-toolbar"><span>{{ format(t('message_count'), orders.length) }}</span></div>
            <div v-if="!orders.length" class="inbox-empty">{{ deliveryReceiving ? t('waiting_messages') : t('no_messages') }}</div>
            <div class="order-list">
              <button v-for="(order, index) in orders" :key="order.id" type="button" class="order-row" :class="{ focused: selectedIndex === index, active: order.id === deliveryData.active_id }" @click="openThread(order)" @mouseenter="selectedIndex = index">
                <span class="order-row-top"><strong>{{ order.contact }}</strong><small>{{ orderStatus(order) }}</small></span>
                <span class="order-row-item">{{ order.label }} × {{ order.quantity }} · ${{ order.total }}</span>
                <span class="order-row-bottom"><span>{{ order.area }}</span><span v-if="order.status === 'pending' || order.status === 'accepted'"><Clock3 :size="11" />{{ remaining(order.expires_at) }}</span></span>
              </button>
            </div>
          </template>
          <template v-else-if="view === 'delivery_thread' && selectedOrder">
            <div class="thread-meta"><span>{{ orderStatus(selectedOrder) }}</span><span v-if="selectedOrder.status === 'pending' || selectedOrder.status === 'accepted'">{{ remaining(selectedOrder.expires_at) }}</span></div>
            <div class="thread-messages">
              <p class="message incoming">{{ format(dialogue('request', selectedOrder), selectedOrder.quantity, selectedOrder.label) }}</p>
              <p class="message incoming">{{ format(dialogue('offer', selectedOrder), selectedOrder.price, selectedOrder.total, selectedOrder.area) }}</p>
              <template v-if="selectedOrder.status !== 'pending'"><p v-if="selectedOrder.accepted_at" class="message outgoing">{{ dialogue('accept', selectedOrder) }}</p><p v-if="selectedOrder.accepted_at" class="message incoming">{{ dialogue('location', selectedOrder) }}</p><p v-if="selectedOrder.status === 'cancelled'" class="message outgoing">{{ dialogue('cancel', selectedOrder) }}</p><p v-if="selectedOrder.status !== 'accepted'" class="message incoming">{{ selectedOrder.status === 'completed' ? dialogue('completed', selectedOrder) : dialogue('closed', selectedOrder) }}</p></template>
            </div>
            <div class="thread-actions">
              <button v-if="selectedOrder.status === 'pending' && !activeOrder && selectedOrder.expires_at > now" type="button" :disabled="busy || deliveryData.cooldown_until > now" @click="postDelivery('delivery_accept', { id: selectedOrder.id })"><Check :size="15" /> {{ deliveryData.cooldown_until > now ? format(t('cooldown'), remaining(deliveryData.cooldown_until)) : t('accept_with_location') }}</button>
              <button v-if="selectedOrder.status === 'accepted' && selectedOrder.expires_at > now" type="button" :disabled="busy" @click="postDelivery('delivery_cancel_order')"><X :size="15" /> {{ t('cancel_order') }}</button>
            </div>
          </template>
          <template v-else-if="view !== 'delivery_thread'">
            <div class="mode-status"><span :class="{ running: activeMode === view }"></span>{{ activeMode === view ? t('running') : activeMode === 'delivery' ? t('state_delivery') : activeMode ? t('other_mode') : t('not_started') }}</div>
            <button v-if="leftLabel" type="button" class="mode-command" :disabled="busy" @click="softLeft"><component :is="activeMode === view ? X : Check" :size="17" />{{ activeMode === view ? t('stop') : t('start') }}{{ selectedMode?.title }}</button>
          </template>
        </div>
        <div class="screen-footer"><button type="button" :disabled="!leftLabel || busy" @click="softLeft">{{ leftLabel }}</button><button type="button" @click="goBack">{{ rightLabel }}</button></div>
      </div>
      <div class="phone-controls">
        <div class="control-cluster">
          <div class="side-keys">
            <button type="button" class="utility-key" :title="leftLabel || t('no_action')" :aria-label="leftLabel || t('no_action')" :disabled="!leftLabel || busy" @click="softLeft"><span class="soft-key-mark"></span></button>
            <span class="call-key answer-key" aria-hidden="true"><Phone :size="17" /></span>
          </div>
          <div class="direction-pad" :aria-label="t('navigation')">
            <button type="button" class="nav-key up" :title="t('up')" :aria-label="t('up')" @click="navigate('up')"><span class="direction-mark"></span></button>
            <button type="button" class="nav-key left" :title="t('left')" :aria-label="t('left')" @click="navigate('left')"><span class="direction-mark"></span></button>
            <button type="button" class="nav-key center" :title="t('confirm')" :aria-label="t('confirm')" @click="confirmSelection"><Check :size="19" /></button>
            <button type="button" class="nav-key right" :title="t('right')" :aria-label="t('right')" @click="navigate('right')"><span class="direction-mark"></span></button>
            <button type="button" class="nav-key down" :title="t('down')" :aria-label="t('down')" @click="navigate('down')"><span class="direction-mark"></span></button>
          </div>
          <div class="side-keys">
            <button type="button" class="utility-key" :title="rightLabel" :aria-label="rightLabel" @click="goBack"><span class="soft-key-mark"></span></button>
            <span class="call-key decline-key" aria-hidden="true"><PhoneOff :size="17" /></span>
          </div>
        </div>
        <div class="number-pad" aria-hidden="true">
          <span>1<small></small></span><span>2<small>ABC</small></span><span>3<small>DEF</small></span>
          <span>4<small>GHI</small></span><span>5<small>JKL</small></span><span>6<small>MNO</small></span>
          <span>7<small>PQRS</small></span><span>8<small>TUV</small></span><span>9<small>WXYZ</small></span>
          <span>*<small></small></span><span>0<small>+</small></span><span>#<small></small></span>
        </div>
      </div>
      <div class="shell-bottom"></div>
    </div>
  </div>
</template>
