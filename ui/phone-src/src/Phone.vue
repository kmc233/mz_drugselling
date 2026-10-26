<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue';
import {
  ArrowDown, ArrowLeft, ArrowRight, ArrowUp, Check, ChevronRight,
  House, MapPin, Phone, PhoneOff, Radio, RotateCcw, ShoppingBag, X
} from 'lucide-vue-next';

const visible = ref(false);
const streetPhone = ref(false);
const activeMode = ref(null);
const view = ref('home');
const selectedIndex = ref(0);
const busy = ref(false);

const modes = computed(() => [
  ...(streetPhone.value ? [{ id: 'dealing', title: '主动街卖', icon: ShoppingBag, accent: 'teal' }] : []),
  { id: 'corner', title: '站街模式', icon: Radio, accent: 'orange' },
  { id: 'delivery', title: '请求送货', icon: MapPin, accent: 'red' }
]);
const selectedMode = computed(() => modes.value.find((mode) => mode.id === view.value));
const actions = computed(() => [
  { id: 'start', label: '开始', icon: Check, disabled: activeMode.value === view.value || Boolean(activeMode.value) },
  { id: 'stop', label: '停止', icon: X, disabled: activeMode.value !== view.value }
]);

function open(data = {}) {
  streetPhone.value = data.street_phone === true;
  activeMode.value = data.active_mode || null;
  view.value = 'home';
  selectedIndex.value = 0;
  busy.value = false;
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

function selectMode(mode, index) {
  view.value = mode.id;
  selectedIndex.value = 0;
}

function goBack() {
  if (view.value !== 'home') {
    view.value = 'home';
    selectedIndex.value = 0;
  } else {
    close();
  }
}

function goHome() {
  if (view.value === 'home') close();
  else {
    view.value = 'home';
    selectedIndex.value = 0;
  }
}

async function submit(intent) {
  if (busy.value) return;
  const action = actions.value.find((item) => item.id === intent);
  if (!action || action.disabled) return;
  const mode = view.value;
  const name = `${mode === 'dealing' ? 'dealing' : mode}_${intent}`;
  if (typeof GetParentResourceName !== 'function') {
    setMode(intent === 'start' ? mode : null);
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

function confirmSelection() {
  if (view.value === 'home') {
    const mode = modes.value[selectedIndex.value];
    if (mode) selectMode(mode, selectedIndex.value);
  } else {
    const action = actions.value[selectedIndex.value];
    if (action) submit(action.id);
  }
}

function navigate(direction) {
  const count = view.value === 'home' ? modes.value.length : actions.value.length;
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
  } else if (event.key === 'Escape' || event.key === 'Backspace') {
    event.preventDefault();
    goBack();
  }
}

onMounted(() => window.addEventListener('keydown', onKeydown));
onUnmounted(() => window.removeEventListener('keydown', onKeydown));
defineExpose({ open, close, setMode });
</script>

<template>
  <div v-if="visible" class="mz-phone" aria-label="MZ 手机">
    <div class="phone-shell">
      <div class="shell-top"><span class="earpiece"></span><strong>MZ</strong><span class="model-mark">105</span></div>
      <div class="phone-screen">
        <div class="screen-status"><span>09:41</span><span class="status-icons"><Radio :size="13" /><span class="battery"><span></span></span></span></div>
        <div class="screen-heading">
          <button v-if="view !== 'home'" class="screen-back" type="button" title="返回" aria-label="返回" @click="goBack"><ArrowLeft :size="20" /></button>
          <div><span class="screen-eyebrow">MZ NETWORK</span><h1>{{ view === 'home' ? '销售终端' : selectedMode?.title }}</h1></div>
          <span v-if="activeMode" class="active-dot" title="销售模式进行中"></span>
        </div>
        <div class="screen-body">
          <template v-if="view === 'home'">
            <div class="section-caption">销售方式</div>
            <div class="mode-list">
              <button v-for="(mode, index) in modes" :key="mode.id" type="button" class="mode-row"
                :class="[{ focused: selectedIndex === index }, mode.accent]"
                @click="selectMode(mode, index)" @mouseenter="selectedIndex = index">
                <span class="mode-icon"><component :is="mode.icon" :size="22" /></span>
                <span class="mode-name">{{ mode.title }}<small v-if="activeMode === mode.id">进行中</small></span>
                <ChevronRight :size="18" class="row-arrow" />
              </button>
            </div>
          </template>
          <template v-else>
            <div class="mode-detail" :class="selectedMode?.accent">
              <div class="detail-icon"><component :is="selectedMode?.icon" :size="30" /></div>
              <div class="detail-title">{{ selectedMode?.title }}</div>
              <div class="detail-state"><span :class="{ running: activeMode === view }"></span>{{ activeMode === view ? '进行中' : '未开启' }}</div>
            </div>
            <div class="section-caption">操作</div>
            <div class="action-list">
              <button v-for="(action, index) in actions" :key="action.id" type="button" class="action-row"
                :class="{ focused: selectedIndex === index }" :disabled="action.disabled || busy"
                @click="submit(action.id)" @mouseenter="selectedIndex = index">
                <component :is="action.icon" :size="18" /><span>{{ action.label }}</span><ChevronRight :size="17" />
              </button>
            </div>
          </template>
        </div>
        <div class="screen-footer"><span>{{ activeMode ? '销售中' : '待机' }}</span><span>{{ view === 'home' ? 'MZ' : '返回' }}</span></div>
      </div>
      <div class="phone-controls">
        <div class="control-cluster">
          <div class="side-keys">
            <button type="button" class="utility-key" title="返回" aria-label="返回" @click="goBack"><RotateCcw :size="18" /></button>
            <span class="call-key answer-key" aria-hidden="true"><Phone :size="17" /></span>
          </div>
          <div class="direction-pad" aria-label="导航键">
            <button type="button" class="nav-key up" title="向上" aria-label="向上" @click="navigate('up')"><ArrowUp :size="18" /></button>
            <button type="button" class="nav-key left" title="向左" aria-label="向左" @click="navigate('left')"><ArrowLeft :size="18" /></button>
            <button type="button" class="nav-key center" title="确认" aria-label="确认" @click="confirmSelection"><Check :size="19" /></button>
            <button type="button" class="nav-key right" title="向右" aria-label="向右" @click="navigate('right')"><ArrowRight :size="18" /></button>
            <button type="button" class="nav-key down" title="向下" aria-label="向下" @click="navigate('down')"><ArrowDown :size="18" /></button>
          </div>
          <div class="side-keys">
            <button type="button" class="utility-key" title="主页" aria-label="主页" @click="goHome"><House :size="18" /></button>
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
