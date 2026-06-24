<template>
  <div class="p-6 lg:p-10 text-white overflow-y-auto">
    <div class="max-w-7xl mx-auto">

      <header class="mb-10 flex flex-col sm:flex-row sm:items-end justify-between gap-4 opacity-0 animate-fade-in">
        <div>
          <p class="text-red-500 text-[10px] font-black uppercase tracking-[0.2em] mb-2">{{ today }}</p>
          <h1 class="text-3xl md:text-4xl font-black text-white tracking-tight uppercase">Dashboard Admin</h1>
          <p class="text-gray-500 text-sm mt-2">
            Selamat datang, <span class="text-white font-semibold">{{ userName }}</span>.
            <span class="text-red-500/80 italic ml-1">Ringkasan data platform GymBuddy.</span>
          </p>
        </div>
      </header>

      <div v-if="loading" class="flex justify-center py-20 opacity-0 animate-fade-in">
        <div class="animate-pulse text-red-500 font-black uppercase tracking-widest text-xs">Memuat data...</div>
      </div>

      <template v-else>
        <!-- Stats Cards -->
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

        <!-- Role Distribution & Booking Status -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

          <!-- Role Distribution -->
          <div
            class="lg:col-span-7 bg-[#0f1115] rounded-[2rem] border border-white/5 p-6 lg:p-8 opacity-0 animate-fade-in"
            :style="{ animationDelay: '480ms' }"
          >
            <div class="flex justify-between items-center mb-6">
              <div>
                <h3 class="font-black text-sm uppercase tracking-widest text-white">Distribusi Peran Pengguna</h3>
                <p class="text-gray-500 text-xs mt-1">{{ totalUsers }} pengguna terdaftar</p>
              </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div
                v-for="role in roleDistribution"
                :key="role.role"
                class="group p-5 rounded-2xl bg-black/40 border border-white/5 hover:border-red-500/20 transition-all duration-300"
              >
                <div class="flex items-center gap-3 mb-4">
                  <div class="w-10 h-10 rounded-xl flex items-center justify-center" :class="roleStyle(role.role).bg">
                    <component :is="roleStyle(role.role).icon" class="w-5 h-5" :class="roleStyle(role.role).text" />
                  </div>
                  <p class="text-xs font-bold uppercase tracking-wider text-gray-500">{{ roleLabel(role.role) }}</p>
                </div>
                <p class="text-3xl font-black text-white tracking-tight">{{ role.count }}</p>
                <p class="text-gray-600 text-[10px] font-bold uppercase tracking-widest mt-1">
                  {{ totalUsers > 0 ? Math.round((role.count / totalUsers) * 100) : 0 }}% dari total
                </p>
              </div>
            </div>
          </div>

          <!-- Booking Status -->
          <div
            class="lg:col-span-5 bg-[#0f1115] rounded-[2rem] border border-white/5 p-6 lg:p-8 opacity-0 animate-fade-in"
            :style="{ animationDelay: '560ms' }"
          >
            <div class="flex justify-between items-center mb-6">
              <div>
                <h3 class="font-black text-sm uppercase tracking-widest text-white">Status Booking</h3>
                <p class="text-gray-500 text-xs mt-1">{{ totalBookings }} booking total</p>
              </div>
            </div>

            <div class="space-y-3">
              <div
                v-for="s in bookingStatus"
                :key="s.status"
                class="group flex items-center justify-between p-4 rounded-2xl bg-black/40 border border-white/5 hover:border-red-500/20 transition-all duration-300"
              >
                <div class="flex items-center gap-3">
                  <span class="text-[10px] px-2.5 py-1 rounded-full font-black uppercase tracking-wider" :class="statusBadgeClass(s.status)">
                    {{ bookingStatusLabel(s.status) }}
                  </span>
                </div>
                <div class="text-right">
                  <p class="text-2xl font-black text-white">{{ s.count }}</p>
                  <p class="text-gray-600 text-[10px] font-bold uppercase tracking-widest">
                    {{ totalBookings > 0 ? Math.round((s.count / totalBookings) * 100) : 0 }}%
                  </p>
                </div>
              </div>
            </div>
          </div>

        </div>
      </template>

    </div>

    <!-- Toast -->
    <Transition name="toast">
      <div
        v-if="toast.show"
        :class="toast.type === 'success' ? 'bg-green-500' : 'bg-red-500'"
        class="fixed bottom-6 right-6 px-6 py-4 rounded-2xl text-white font-bold text-sm shadow-2xl z-50"
      >
        {{ toast.message }}
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  UsersIcon,
  UserCogIcon,
  CalendarCheckIcon,
  WalletIcon,
  ShieldIcon,
  UserIcon,
  HelpCircleIcon
} from 'lucide-vue-next'
import api from '../../utils/api'

const loading = ref(true)
const stats = ref({})
const roleDistribution = ref([])
const bookingStatus = ref([])
const user = ref({})
const today = ref('')
const toast = ref({ show: false, message: '', type: 'success' })

const userName = computed(() => user.value.nama || 'Admin')

const showToast = (message, type = 'success') => {
  toast.value = { show: true, message, type }
  setTimeout(() => { toast.value.show = false }, 3000)
}

const totalUsers = computed(() => {
  return roleDistribution.value.reduce((acc, curr) => acc + curr.count, 0)
})

const totalBookings = computed(() => {
  return bookingStatus.value.reduce((acc, curr) => acc + curr.count, 0)
})

const statCards = computed(() => [
  { label: 'Total Pengguna', value: stats.value.totalUsers || 0, icon: UsersIcon },
  { label: 'Pelatih', value: stats.value.trainers || 0, icon: UserCogIcon },
  { label: 'Total Booking', value: stats.value.totalBookings || 0, icon: CalendarCheckIcon },
  { label: 'Pembayaran Lunas', value: stats.value.settledPayments || 0, icon: WalletIcon }
])

const roleLabel = (role) => {
  const map = { admin: 'Admin', trainer: 'Pelatih', customer: 'Pelanggan' }
  return map[role?.toLowerCase()] || role
}

const bookingStatusLabel = (status) => {
  const map = { pending: 'Menunggu', confirmed: 'Dikonfirmasi', cancelled: 'Dibatalkan', completed: 'Selesai' }
  return map[status?.toLowerCase()] || status
}
const roleStyle = (role) => {
  const map = {
    admin: { icon: ShieldIcon, bg: 'bg-red-500/10', text: 'text-red-500' },
    trainer: { icon: UserCogIcon, bg: 'bg-orange-400/10', text: 'text-orange-400' },
    customer: { icon: UserIcon, bg: 'bg-blue-400/10', text: 'text-blue-400' }
  }
  return map[role?.toLowerCase()] || { icon: HelpCircleIcon, bg: 'bg-gray-500/10', text: 'text-gray-500' }
}

const statusBadgeClass = (status) => {
  const map = {
    pending: 'bg-yellow-500/10 text-yellow-500 border border-yellow-500/20',
    confirmed: 'bg-green-500/10 text-green-500 border border-green-500/20',
    cancelled: 'bg-red-500/10 text-red-500 border border-red-500/20',
    completed: 'bg-gray-500/10 text-gray-500 border border-gray-500/20'
  }
  return map[status?.toLowerCase()] || 'bg-gray-500/10 text-gray-500 border border-gray-500/20'
}

const fetchStats = async () => {
  try {
    const [statsRes, meRes] = await Promise.all([
      api.get('/analytics/dashboard'),
      api.get('/auth/me').catch(() => ({ data: { data: {} } }))
    ])

    const data = statsRes.data?.data || {}

    const roles = ['admin', 'trainer', 'customer']
    roleDistribution.value = roles.map(role => {
      const found = data.roleDistribution?.find(r => r.role === role)
      return { role, count: found?.count ?? 0 }
    })

    const statuses = ['pending', 'confirmed', 'cancelled', 'completed']
    bookingStatus.value = statuses.map(status => {
      const found = data.bookingStatusDistribution?.find(b => b.status === status)
      return { status, count: found?.count ?? 0 }
    })

    const trainerCount = data.roleDistribution?.find(r => r.role === 'trainer')?.count ?? 0

    stats.value = {
      totalUsers: data.totalUsers ?? 0,
      trainers: trainerCount,
      totalBookings: data.totalBookings ?? 0,
      settledPayments: data.settledPayments ?? 0,
    }

    user.value = meRes.data?.data || {}
  } catch (err) {
    console.error('Fetch stats error:', err)
    showToast(err.response?.data?.error?.message || err.response?.data?.message || 'Gagal memuat data dashboard.', 'error')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  const now = new Date()
  today.value = now.toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' })
  fetchStats()
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
.toast-enter-active, .toast-leave-active { transition: all 0.4s ease; }
.toast-enter-from { opacity: 0; transform: translateX(100px); }
.toast-leave-to { opacity: 0; transform: translateY(20px); }
</style>
