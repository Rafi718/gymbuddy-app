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
        <option value="pending">Pending</option>
        <option value="confirmed">Confirmed</option>
        <option value="cancelled">Cancelled</option>
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
              <td class="py-4 px-6 text-sm">{{ b.member_name }}</td>
              <td class="py-4 px-6 text-sm text-gray-400">{{ b.session_title }}</td>
              <td class="py-4 px-6">
                <span :class="statusBadge(b.status)" class="text-[9px] px-3 py-1 rounded-full border font-black uppercase">{{ b.status }}</span>
              </td>
              <td class="py-4 px-6">
                <span v-if="b.payment_status === 'settlement'" class="text-green-400 text-xs font-bold">✓ Lunas</span>
                <span v-else-if="b.payment_status === 'pending'" class="text-yellow-400 text-xs font-bold">⏳ {{ b.payment_status }}</span>
                <span v-else class="text-red-400 text-xs font-bold">✕ {{ b.payment_status }}</span>
              </td>
              <td class="py-4 px-6 text-sm font-bold">{{ formatRupiah(b.payment_amount) }}</td>
              <td class="py-4 px-6 text-xs text-gray-400">
                <div class="flex items-center gap-1.5">
                  <span class="text-gray-500">{{ formatDateTime(b.session_start_time || b.createdAt) }}</span>
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
import { ref, onMounted, computed } from 'vue'
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

const statusBadge = (s) => {
  const map = { pending: 'bg-yellow-500/10 text-yellow-500 border-yellow-500/20', confirmed: 'bg-green-500/10 text-green-500 border-green-500/20', cancelled: 'bg-red-500/10 text-red-500 border-red-500/20' }
  return map[s?.toLowerCase()] || ''
}

const formatRupiah = (p) => p ? `Rp${Number(p).toLocaleString('id-ID')}` : 'Rp0'
const formatDateTime = (d) => {
  if (!d) return '-'
  const date = new Date(d)
  return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) +
    ' • ' + date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}

onMounted(fetchData)
</script>
