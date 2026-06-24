<template>
  <div class="p-8 text-white">
    <header class="mb-8 flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-black uppercase tracking-tighter">Booking & Pembayaran</h1>
        <p class="text-gray-500 text-sm mt-1">Manajemen booking dan pembayaran</p>
      </div>
    </header>

    <!-- Filter -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <select v-model="statusFilter" @change="fetchData"
              class="bg-[#0f1115] border border-gray-800 p-3 rounded-xl text-sm outline-none">
        <option value="">Semua Status</option>
        <option value="pending">Menunggu</option>
        <option value="confirmed">Dikonfirmasi</option>
        <option value="cancelled">Dibatalkan</option>
      </select>
      <select v-model="paymentFilter" @change="fetchData"
              class="bg-[#0f1115] border border-gray-800 p-3 rounded-xl text-sm outline-none">
        <option value="">Semua Pembayaran</option>
        <option value="settlement">Lunas</option>
        <option value="pending">Menunggu</option>
        <option value="expire">Kadaluarsa</option>
      </select>
    </div>

    <!-- Table -->
    <div class="bg-[#0f1115] rounded-2xl border border-gray-900 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="bg-black/20">
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">#</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">Anggota</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">Sesi</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">Status</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">Pembayaran</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">Jumlah</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase">Tanggal & Waktu</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="b in filteredBookings" :key="b.id" class="border-b border-gray-900/50 hover:bg-white/[0.02]">
              <td class="py-4 px-6 text-sm text-gray-500">#{{ b.id }}</td>
              <td class="py-4 px-6 text-sm">{{ b.member_nama || '-' }}</td>
              <td class="py-4 px-6 text-sm text-gray-400">{{ b.session_title }}</td>
              <td class="py-4 px-6">
                <span :class="statusBadge(b.status)" class="text-[9px] px-3 py-1 rounded-full border font-black uppercase">{{ bookingStatusLabel(b.status) }}</span>
              </td>
              <td class="py-4 px-6">
                <span v-if="b.payment_status === 'settlement'" class="text-green-400 text-xs font-bold">✓ Lunas</span>
                <span v-else-if="b.payment_status === 'pending'" class="text-yellow-400 text-xs font-bold">⏳ Menunggu</span>
                <span v-else class="text-red-400 text-xs font-bold">✕ {{ paymentStatusLabel(b.payment_status) }}</span>
              </td>
              <td class="py-4 px-6 text-sm font-bold">
                {{ formatRupiah(b.session_price) }}
                <span v-if="b.session_price !== b.payment_amount" class="block text-[10px] text-gray-500 font-normal">
                  (Dibayar: {{ formatRupiah(b.payment_amount) }})
                </span>
              </td>
              <td class="py-4 px-6 text-xs text-gray-400">
                <div class="flex flex-col gap-0.5">
                  <span class="text-gray-300">{{ formatSessionSchedule(b.session_start_time, b.session_end_time) }}</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import api from '../../utils/api'

const bookings = ref([])
const statusFilter = ref('')
const paymentFilter = ref('')

const filteredBookings = computed(() => {
  return bookings.value.filter(b => {
    if (statusFilter.value && b.status?.toLowerCase() !== statusFilter.value) return false
    if (paymentFilter.value && b.payment_status !== paymentFilter.value) return false
    return true
  })
})

const fetchData = async () => {
  try {
    const res = await api.get('/bookings')
    bookings.value = res.data?.data || []
  } catch (err) { console.error(err) }
}

const handleVisibility = () => {
  if (document.visibilityState === 'visible') fetchData()
}

const statusBadge = (s) => {
  const map = { pending: 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20', confirmed: 'bg-green-500/10 text-green-500 border-green-500/20', cancelled: 'bg-red-500/10 text-red-500 border-red-500/20' }
  return map[s?.toLowerCase()] || ''
}

const bookingStatusLabel = (s) => {
  const map = { pending: 'Menunggu', confirmed: 'Dikonfirmasi', cancelled: 'Dibatalkan', completed: 'Selesai' }
  return map[s?.toLowerCase()] || s
}

const paymentStatusLabel = (s) => {
  const map = { settlement: 'Lunas', pending: 'Menunggu', cancel: 'Dibatalkan', expire: 'Kadaluarsa' }
  return map[s?.toLowerCase()] || s
}

const formatRupiah = (p) => p ? `Rp${Number(p).toLocaleString('id-ID')}` : 'Rp0'

const toUTCDate = (d) => {
  if (!d) return null
  let str = d.toString().replace(' ', 'T')
  // Jika tidak ada timezone info, asumsikan UTC (tambah 'Z')
  if (!str.endsWith('Z') && !str.includes('+') && !str.match(/-\d{2}:\d{2}$/)) {
    str += 'Z'
  }
  const date = new Date(str)
  return isNaN(date.getTime()) ? null : date
}

const TZ = 'Asia/Jakarta'

const formatSessionSchedule = (startStr, endStr) => {
  const start = toUTCDate(startStr)
  if (!start) return '-'
  const datePart = start.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', timeZone: TZ })
  const startTime = start.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', timeZone: TZ })
  const end = toUTCDate(endStr)
  if (end) {
    const endTime = end.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', timeZone: TZ })
    return `${datePart} • ${startTime} - ${endTime}`
  }
  return `${datePart} • ${startTime}`
}

onMounted(() => {
  fetchData()
  document.addEventListener('visibilitychange', handleVisibility)
})
onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibility)
})
</script>
