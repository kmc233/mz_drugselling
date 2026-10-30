<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import {
  ArrowLeft, Check, ChevronRight, MapPin, Phone, PhoneOff,
  Radio, ShoppingBag, X, RefreshCw, Clock3
} from 'lucide-vue-next';

const visible = ref(false);
const streetPhone = ref(false);
const activeMode = ref(null);
const deliveryReceiving = ref(false);
const view = ref('home');
const selectedIndex = ref(0);
const busy = ref(false);
const deliveryData = ref({ orders: [], active_id: null, refresh_at: 0, server_time: 0 });
const selectedOrderId = ref(null);
const now = ref(Math.floor(Date.now() / 1000));
let clockTimer;
let serverOffset = 0;

const modes = computed(() => [
  ...(streetPhone.value ? [{ id: 'dealing', title: '主动街卖', icon: ShoppingBag, accent: 'teal' }] : []),
  { id: 'corner', title: '站街模式', icon: Radio, accent: 'orange' },
  { id: 'delivery', title: '送货订单', icon: MapPin, accent: 'red' }
]);
const selectedMode = computed(() => modes.value.find((mode) => mode.id === view.value));
const orders = computed(() => deliveryData.value.orders || []);
const selectedOrder = computed(() => orders.value.find((order) => order.id === selectedOrderId.value));
const activeOrder = computed(() => orders.value.find((order) => order.id === deliveryData.value.active_id));
const canRefresh = computed(() => activeMode.value === 'delivery' && !activeOrder.value &&
  deliveryReceiving.value &&
  !orders.value.some((order) => order.status === 'pending' && order.expires_at > now.value) &&
  deliveryData.value.refresh_at <= now.value);
const leftLabel = computed(() => {
  if (view.value === 'home') return '选择';
  if (view.value === 'delivery_inbox') return activeMode.value && activeMode.value !== 'delivery'
    ? '' : deliveryReceiving.value ? '停止接收' : '接收短信';
  if (view.value === 'delivery_thread') {
    if (selectedOrder.value?.status === 'accepted' && selectedOrder.value.expires_at > now.value) return '取消订单';
    return selectedOrder.value?.status === 'pending' && !activeOrder.value &&
      selectedOrder.value.expires_at > now.value && deliveryData.value.refresh_at <= now.value ? '接单' : '';
  }
  return activeMode.value && activeMode.value !== view.value ? '' : activeMode.value === view.value ? '停止' : '开始';
});
const rightLabel = computed(() => view.value === 'home' ? '关闭' : '返回');
const screenState = computed(() => {
  if (view.value === 'delivery_inbox') return activeOrder.value ? '配送中' : deliveryReceiving.value ? '接收中' : activeMode.value === 'delivery' ? '已暂停' : '未接收';
  if (view.value === 'dealing' || view.value === 'corner') return activeMode.value === view.value ? '进行中' : '未开启';
  return '';
});
const statusText = { pending: '待回复', accepted: '配送中', completed: '已完成', expired: '已失效', cancelled: '已取消' };
function orderStatus(order) {
  return (order.status === 'pending' || order.status === 'accepted') && order.expires_at <= now.value
    ? '已失效' : statusText[order.status];
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
  if (intent === 'start' && activeMode.value && activeMode.value !== mode) return;
  if (intent === 'stop' && activeMode.value !== mode) return;
  const name = `${mode === 'dealing' ? 'dealing' : mode}_${intent}`;
  if (typeof GetParentResourceName !== 'function') {
    if (mode === 'delivery') {
      deliveryReceiving.value = intent === 'start';
      setMode('delivery');
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
    if (leftLabel.value === '接单') return postDelivery('delivery_accept', { id: selectedOrder.value.id });
    if (leftLabel.value === '取消订单') return postDelivery('delivery_cancel_order');
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
  <div v-if="visible" class="mz-phone" aria-label="MZ 手机">
    <div class="phone-shell">
      <div class="shell-top"><span class="earpiece"></span><strong>MUZIA</strong></div>
      <div class="phone-screen">
        <div class="screen-status"><span>09:41</span><span class="status-icons"><Radio :size="13" /><span class="battery"><span></span></span></span></div>
        <div class="screen-heading">
          <button v-if="view !== 'home'" class="screen-back" type="button" title="返回" aria-label="返回" @click="goBack"><ArrowLeft :size="20" /></button>
          <div><span v-if="view === 'home'" class="screen-eyebrow">MZ NETWORK</span><h1>{{ view === 'home' ? '销售终端' : view === 'delivery_inbox' ? '送货订单' : view === 'delivery_thread' ? selectedOrder?.contact : selectedMode?.title }}</h1></div>
          <span v-if="screenState" class="screen-state">{{ screenState }}</span>
        </div>
        <div class="screen-body">
          <template v-if="view === 'home'">
            <div class="section-caption">销售方式</div>
            <div class="mode-list">
              <button v-for="(mode, index) in modes" :key="mode.id" type="button" class="mode-row"
                :class="[{ focused: selectedIndex === index }, mode.accent]"
                @click="selectMode(mode)" @mouseenter="selectedIndex = index">
                <span class="mode-icon"><component :is="mode.icon" :size="22" /></span>
                <span class="mode-name">{{ mode.title }}<small v-if="activeMode === mode.id">{{ mode.id === 'delivery' && !deliveryReceiving ? '已暂停' : '进行中' }}</small></span>
                <ChevronRight :size="18" class="row-arrow" />
              </button>
            </div>
          </template>
          <template v-else-if="view === 'delivery_inbox'">
            <div class="inbox-toolbar"><span>{{ orders.length }} 条短信</span><button type="button" title="刷新订单" aria-label="刷新订单" :disabled="!canRefresh || busy" @click="postDelivery('delivery_refresh')"><RefreshCw :size="15" /></button></div>
            <div v-if="!orders.length" class="inbox-empty">{{ deliveryReceiving ? '等待新订单短信' : '暂无订单短信' }}</div>
            <div class="order-list">
              <button v-for="(order, index) in orders" :key="order.id" type="button" class="order-row" :class="{ focused: selectedIndex === index, active: order.id === deliveryData.active_id }" @click="openThread(order)" @mouseenter="selectedIndex = index">
                <span class="order-row-top"><strong>{{ order.contact }}</strong><small>{{ orderStatus(order) }}</small></span>
                <span class="order-row-item">{{ order.label }} × {{ order.quantity }} · ${{ order.total }}</span>
                <span class="order-row-bottom"><span>{{ order.area }}</span><span v-if="order.status === 'pending' || order.status === 'accepted'"><Clock3 :size="11" />{{ remaining(order.expires_at) }}</span></span>
              </button>
            </div>
            <div v-if="!canRefresh && deliveryData.refresh_at > now && !activeOrder" class="inbox-wait">{{ remaining(deliveryData.refresh_at) }} 后可刷新</div>
          </template>
          <template v-else-if="view === 'delivery_thread' && selectedOrder">
            <div class="thread-meta"><span>{{ orderStatus(selectedOrder) }}</span><span v-if="selectedOrder.status === 'pending' || selectedOrder.status === 'accepted'">{{ remaining(selectedOrder.expires_at) }}</span></div>
            <div class="thread-messages">
              <p class="message incoming">听说你能送货。我需要 {{ selectedOrder.quantity }} 个{{ selectedOrder.label }}。</p>
              <p class="message incoming">每个 ${{ selectedOrder.price }}，总共 ${{ selectedOrder.total }}。送到{{ selectedOrder.area }}，能接吗？</p>
              <template v-if="selectedOrder.status !== 'pending'"><p class="message outgoing">{{ selectedOrder.status === 'cancelled' ? '这单我不接了。' : '可以，发位置。' }}</p><p class="message incoming">{{ selectedOrder.status === 'accepted' ? '位置发你了，别迟到。' : selectedOrder.status === 'completed' ? '收到货了，下次再联系。' : '这单已经结束。' }}</p></template>
            </div>
            <div class="thread-actions">
              <button v-if="selectedOrder.status === 'pending' && !activeOrder && selectedOrder.expires_at > now" type="button" :disabled="busy || deliveryData.refresh_at > now" @click="postDelivery('delivery_accept', { id: selectedOrder.id })"><Check :size="15" /> {{ deliveryData.refresh_at > now ? `${remaining(deliveryData.refresh_at)} 后可接` : '接单，发位置' }}</button>
              <button v-if="selectedOrder.status === 'accepted' && selectedOrder.expires_at > now" type="button" :disabled="busy" @click="postDelivery('delivery_cancel_order')"><X :size="15" /> 取消订单</button>
            </div>
          </template>
          <template v-else-if="view !== 'delivery_thread'">
            <div class="mode-status"><span :class="{ running: activeMode === view }"></span>{{ activeMode === view ? '正在运行' : activeMode ? '其他销售方式进行中' : '尚未开启' }}</div>
            <button v-if="leftLabel" type="button" class="mode-command" :disabled="busy" @click="softLeft"><component :is="activeMode === view ? X : Check" :size="17" />{{ activeMode === view ? '停止' : '开始' }}{{ selectedMode?.title }}</button>
          </template>
        </div>
        <div class="screen-footer"><button type="button" :disabled="!leftLabel || busy" @click="softLeft">{{ leftLabel }}</button><button type="button" @click="goBack">{{ rightLabel }}</button></div>
      </div>
      <div class="phone-controls">
        <div class="control-cluster">
          <div class="side-keys">
            <button type="button" class="utility-key" :title="leftLabel || '无操作'" :aria-label="leftLabel || '无操作'" :disabled="!leftLabel || busy" @click="softLeft"><span class="soft-key-mark"></span></button>
            <span class="call-key answer-key" aria-hidden="true"><Phone :size="17" /></span>
          </div>
          <div class="direction-pad" aria-label="导航键">
            <button type="button" class="nav-key up" title="向上" aria-label="向上" @click="navigate('up')"><span class="direction-mark"></span></button>
            <button type="button" class="nav-key left" title="向左" aria-label="向左" @click="navigate('left')"><span class="direction-mark"></span></button>
            <button type="button" class="nav-key center" title="确认" aria-label="确认" @click="confirmSelection"><Check :size="19" /></button>
            <button type="button" class="nav-key right" title="向右" aria-label="向右" @click="navigate('right')"><span class="direction-mark"></span></button>
            <button type="button" class="nav-key down" title="向下" aria-label="向下" @click="navigate('down')"><span class="direction-mark"></span></button>
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
