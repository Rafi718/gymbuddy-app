<template>
  <main class="p-6 lg:p-10 text-white overflow-y-auto">
    <div class="max-w-7xl mx-auto">

      <header class="mb-10 flex flex-col sm:flex-row sm:items-end justify-between gap-4 opacity-0 animate-fade-in">
        <div>
          <p class="text-red-500 text-[10px] font-black uppercase tracking-[0.2em] mb-2">{{ today }}</p>
          <h1 class="text-3xl md:text-4xl font-black text-white tracking-tight uppercase">Dashboard Trainer</h1>
          <p class="text-gray-500 text-sm mt-2">
            Selamat datang, <span class="text-white font-semibold">{{ trainerName }}</span>.
            <span class="text-red-500/80 italic ml-1">Latih memberimu.</span>
          </p>
        </div>
        <div class="hidden sm:block">
          <router-link
            to="/trainer/sessions"
            class="inline-flex items-center gap-2 bg-red-500 text-black px-5 py-3 rounded-xl font-black text-xs uppercase tracking-wider hover:bg-red-400 transition-all shadow-lg shadow-red-500/10 active:scale-[0.98]"
          >
            <PlusIcon class="w-4 h-4" />
            Buat Sesi
          </router-link>
        </div>
      </header>

      <div v-if="loading" class="flex justify-center py-20 opacity-0 animate-fade-in">
        <div class="animate-pulse text-red-500 font-black uppercase tracking-widest text-xs">Memuat data...</div>
      </div>

      <template v-else>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5 mb-8">
          <div
            v-for="(stat, index) in statCards"
            :key="stat.label"
            class="group bg-[#0f1115] rounded-3xl p-6 border border-white/5 hover:border-red-500/20 transition-all duration-300 opacity-0 animate-fade-in"
            :style="{ animationDelay: `${(index + 1) * 80}ms` }"
          >
            <div class="w-11 h-11 rounded-2xl bg-red-500/10 flex items-center justify-center text-red-500 mb-5 group-hover:scale-110 group-hover:bg-red-500 group-hover:text-black transition-all duration-300">
              <component :is="stat.icon" class="w-5 h-5" />
            </div>
            <p class="text-3xl font-black text-white tracking-tight">{{ stat.value }}</p>
            <p class="text-gray-500 text-[10px] font-bold uppercase tracking-[0.2em] mt-1">{{ stat.label }}</p>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

          <div
            class="lg:col-span-7 bg-[#0f1115] rounded-[2rem] border border-white/5 p-6 lg:p-8 opacity-0 animate-fade-in"
            :style="{ animationDelay: '480ms' }"
          >
            <div class="flex justify-between items-center mb-6">
              <div>
                <h3 class="font-black text-sm uppercase tracking-widest text-white">Sesi Saya</h3>
                <p class="text-gray-500 text-xs mt-1">{{ mySessions.length }} sesi dibuat</p>
              </div>
              <router-link to="/trainer/sessions" class="text-red-500 text-[10px] font-black uppercase tracking-wider hover:text-red-400 transition-colors">Lihat Semua</router-link>
            </div>

            <div v-if="mySessions.length === 0" class="flex flex-col items-center justify-center py-14 border border-dashed border-white/10 rounded-2xl">
              <div class="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center text-gray-500 mb-3">
                <CalendarIcon class="w-6 h-6" />
              </div>
              <p class="text-gray-500 text-xs font-bold uppercase tracking-widest">Belum ada sesi dibuat</p>
              <router-link to="/trainer/sessions" class="mt-4 text-red-500 text-[10px] font-black uppercase tracking-wider hover:underline">Buat sesi pertama</router-link>
            </div>

            <div v-else class="space-y-3">
              <div
                v-for="session in mySessions.slice(0, 5)"
                :key="session.id"
                class="group flex items-center gap-4 p-4 rounded-2xl bg-black/40 border border-white/5 hover:border-red-500/20 hover:bg-black/60 transition-all duration-300"
              >
                <div class="w-12 h-12 rounded-xl bg-red-500/10 flex items-center justify-center text-red-500 flex-shrink-0 group-hover:bg-red-500 group-hover:text-black transition-all">
                  <DumbbellIcon class="w-5 h-5" />
                </div>

                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 mb-1">
                    <h4 class="font-bold text-white text-sm uppercase truncate group-hover:text-red-500 transition-colors">{{ session.title }}</h4>
                    <span v-if="session.status" class="text-[9px] px-2 py-0.5 rounded-full font-black uppercase tracking-wider" :class="statusClass(session.status)">
                      {{ session.status }}
                    </span>
                  </div>
                  <p class="text-gray-500 text-xs font-medium flex items-center gap-1">
                    <ClockIcon class="w-3 h-3" /> {{ formatDateTime(session.start_time) }}
                  </p>
                </div>

                <div class="text-right flex-shrink-0">
                  <p class="text-sm font-black text-white">{{ formatRupiah(session.price) }}</p>
                  <p class="text-[10px] text-gray-500 uppercase font-bold tracking-wider mt-0.5">{{ session.total_bookings || 0 }} pemesan</p>
                </div>
              </div>
            </div>
          </div>

          <div
            class="lg:col-span-5 bg-[#0f1115] rounded-[2rem] border border-white/5 p-6 lg:p-8 opacity-0 animate-fade-in"
            :style="{ animationDelay: '560ms' }"
          >
            <div class="flex justify-between items-center mb-6">
              <div>
                <h3 class="font-black text-sm uppercase tracking-widest text-white">Status Sesi</h3>
                <p class="text-gray-500 text-xs mt-1">Distribusi sesi Anda</p>
              </div>
            </div>

            <div v-if="mySessions.length === 0" class="flex flex-col items-center justify-center py-14 border border-dashed border-white/10 rounded-2xl">
              <div class="w-12 h-12 rounded-full bg-white/5 flex items-center justify-center text-gray-500 mb-3">
                <ActivityIcon class="w-6 h-6" />
              </div>
              <p class="text-gray-500 text-xs font-bold uppercase tracking-widest">Belum ada data</p>
            </div>

            <div v-else class="space-y-3">
              <div
                v-for="item in statusBreakdown"
                :key="item.label"
                class="p-4 rounded-2xl bg-black/40 border border-white/5"
              >
                <div class="flex justify-between items-center mb-2">
                  <div class="flex items-center gap-2">
                    <component :is="item.icon" class="w-4 h-4" :class="item.color" />
                    <span class="text-xs font-bold uppercase tracking-wider text-gray-300">{{ item.label }}</span>
                  </div>
                  <span class="text-sm font-black text-white">{{ item.count }}</span>
                </div>
                <div class="h-1.5 rounded-full bg-white/5 overflow-hidden">
                  <div
                    class="h-full rounded-full transition-all duration-500"
                    :class="item.barColor"
                    :style="{ width: `${item.percent}%` }"
                  ></div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </template>

    </div>
  </main>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  CalendarIcon,
  CalendarDaysIcon,
  UsersIcon,
  DumbbellIcon,
  ActivityIcon,
  PlusIcon,
  ClockIcon,
  CheckCircleIcon,
  XCircleIcon,
  PlayCircleIcon
} from 'lucide-vue-next'
import api from '../../utils/api'
import { useAuthStore } from '../../stores/authStore'

const authStore = useAuthStore()
const loading = ref(true)
const sessions = ref([])
const user = ref({})
const today = ref('')

const trainerName = computed(() => user.value.nama || 'Trainer')

const mySessions = computed(() => {
  const trainerId = String(user.value.id || '')
  return sessions.value.filter(s => String(s.trainer_id) === trainerId)
})

const stats = computed(() => {
  const mine = mySessions.value
  const now = new Date()
  const weekStart = new Date(now)
  weekStart.setDate(now.getDate() - now.getDay())
  weekStart.setHours(0, 0, 0, 0)
  const weekEnd = new Date(weekStart)
  weekEnd.setDate(weekStart.getDate() + 7)

  return {
    totalSessions: mine.length,
    thisWeek: mine.filter(s => {
      const d = new Date(s.start_time)
      return d >= weekStart && d <= weekEnd
    }).length,
    totalBookers: mine.reduce((acc, s) => acc + (Number(s.total_bookings) || 0), 0),
    completed: mine.filter(s => s.status?.toLowerCase() === 'completed').length
  }
})

const statCards = computed(() => [
  { label: 'Total Sesi', value: stats.value.totalSessions, icon: DumbbellIcon },
  { label: 'Minggu Ini', value: stats.value.thisWeek, icon: CalendarDaysIcon },
  { label: 'Total Pemesan', value: stats.value.totalBookers, icon: UsersIcon },
  { label: 'Selesai', value: stats.value.completed, icon: ActivityIcon }
])

const statusBreakdown = computed(() => {
  const mine = mySessions.value
  const total = mine.length || 1
  const counts = {
    scheduled: mine.filter(s => s.status?.toLowerCase() === 'scheduled').length,
    ongoing: mine.filter(s => s.status?.toLowerCase() === 'ongoing').length,
    completed: mine.filter(s => s.status?.toLowerCase() === 'completed').length,
    cancelled: mine.filter(s => s.status?.toLowerCase() === 'cancelled').length
  }
  return [
    { label: 'Terjadwal', count: counts.scheduled, percent: (counts.scheduled / total) * 100, icon: CalendarIcon, color: 'text-blue-400', barColor: 'bg-blue-400' },
    { label: 'Berlangsung', count: counts.ongoing, percent: (counts.ongoing / total) * 100, icon: PlayCircleIcon, color: 'text-red-500', barColor: 'bg-red-500' },
    { label: 'Selesai', count: counts.completed, percent: (counts.completed / total) * 100, icon: CheckCircleIcon, color: 'text-green-500', barColor: 'bg-green-500' },
    { label: 'Dibatalkan', count: counts.cancelled, percent: (counts.cancelled / total) * 100, icon: XCircleIcon, color: 'text-gray-500', barColor: 'bg-gray-500' }
  ]
})

const formatRupiah = (price) => {
  if (!price) return 'Rp0'
  return `Rp${Number(price).toLocaleString('id-ID')}`
}

const formatDateTime = (dateStr) => {
  if (!dateStr) return '--'
  const d = new Date(dateStr)
  return `${d.toLocaleDateString('id-ID', { day: 'numeric', month: 'short' })}, ${d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}`
}

const statusClass = (status) => {
  const map = {
    scheduled: 'bg-blue-400/10 text-blue-400 border border-blue-400/20',
    ongoing: 'bg-red-500/10 text-red-500 border border-red-500/20',
    completed: 'bg-green-500/10 text-green-500 border border-green-500/20',
    cancelled: 'bg-gray-500/10 text-gray-500 border border-gray-500/20'
  }
  return map[status?.toLowerCase()] || 'bg-gray-500/10 text-gray-500 border border-gray-500/20'
}

const fetchDashboardData = async () => {
  try {
    await authStore.init()
    user.value = authStore.user || {}

    const res = await api.get('/sessions')
    sessions.value = res.data?.data || []
  } catch (err) {
    console.error('Trainer dashboard fetch error:', err)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  const now = new Date()
  today.value = now.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
  fetchDashboardData()
})
</script>

<style scoped>
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in {
  animation: fadeIn 0.5s cubic-bezier(0.4, 0, 0.2, 1) forwards;
}
</style>
