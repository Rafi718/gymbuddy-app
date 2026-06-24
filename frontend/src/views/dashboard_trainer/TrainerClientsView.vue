<template>
  <main class="flex-grow p-8 text-white overflow-y-auto bg-[#0a0b10] min-h-screen">
    <header class="mb-8">
      <h2 class="text-3xl font-black uppercase tracking-tighter italic text-white">Daftar Booker</h2>
      <p class="text-gray-500 text-[10px] font-bold uppercase tracking-widest mt-1">
        Manajemen data peserta berdasarkan riwayat booking
      </p>
    </header>

    <div class="bg-[#161920] p-6 rounded-2xl border border-gray-900 mb-8">
      <input v-model="searchQuery" type="text" placeholder="Cari nama member..." 
             class="w-full bg-black/40 border border-gray-800 rounded-xl px-5 py-3 text-xs focus:border-red-500 outline-none transition-all">
    </div>

    <div class="bg-[#161920] rounded-[2rem] border border-gray-900 overflow-hidden shadow-2xl">
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="bg-black/20">
              <th class="py-5 px-8 text-[10px] font-black text-gray-600 uppercase tracking-widest">Anggota</th>
              <th class="py-5 px-8 text-[10px] font-black text-gray-600 uppercase tracking-widest">Detail Sesi</th>
              <th class="py-5 px-8 text-[10px] font-black text-gray-600 uppercase tracking-widest text-center">Status</th>
              <th class="py-5 px-8 text-[10px] font-black text-gray-600 uppercase tracking-widest text-center">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="4" class="py-20 text-center text-red-500 font-black text-xs animate-pulse uppercase tracking-widest">Menghubungkan ke Database...</td>
            </tr>
            <tr v-for="booker in filteredBookers" :key="booker.id" class="border-b border-gray-900/50 hover:bg-white/[0.02]">
              <td class="py-6 px-8">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 bg-red-500/10 border border-red-500/20 rounded-full flex items-center justify-center font-black text-red-500 text-xs">
                    {{ getInitials(booker.member_nama) }}
                  </div>
                  <div>
                    <p class="text-xs font-black uppercase">{{ booker.member_nama || 'Anggota' }}</p>
                    <p class="text-[9px] text-gray-600 lowercase">{{ booker.member_email || '-' }}</p>
                  </div>
                </div>
              </td>
              
              <td class="py-6 px-8">
                <p class="text-[10px] text-gray-200 font-black uppercase italic">{{ booker.session_title || 'Sesi Umum' }}</p>
                <p class="text-[9px] text-gray-600 font-bold mt-1 uppercase">{{ formatDate(booker.session_start_time, booker.session_end_time) }}</p>
              </td>

              <td class="py-6 px-8 text-center">
                <span :class="getStatusClass(booker.status)"
                      class="text-[8px] px-4 py-1.5 rounded-full border font-black uppercase tracking-widest inline-block">
                  {{ statusLabel(booker.status) }}
                </span>
              </td>
              <td class="py-6 px-8 text-center">
                <button @click="openModal(booker)"
                        class="bg-red-500 hover:bg-red-500 text-black px-4 py-2 rounded-lg text-[9px] font-black uppercase transition-all shadow-lg shadow-red-500/20">
                  + Progress
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal Progress -->
    <div v-if="showModal" class="fixed inset-0 bg-black/90 backdrop-blur-md flex items-center justify-center p-4 z-50">
      <div class="bg-[#161920] border border-gray-900 w-full max-w-md rounded-[2.5rem] p-8 shadow-2xl">
        <h2 class="text-xl font-black uppercase italic mb-1">Catat Progress</h2>
        <p class="text-[10px] text-gray-500 font-bold uppercase mb-6 tracking-widest">Anggota: {{ selectedMember?.member_nama }}</p>
        <form @submit.prevent="saveProgress" class="space-y-4">
          <div>
            <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Aktivitas</label>
            <input v-model="progressForm.activity" type="text" placeholder="Bench Press, Squat, dll" 
                   class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none" required>
          </div>
          <div>
            <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Durasi (menit)</label>
            <input v-model.number="progressForm.duration" type="number" placeholder="60"
                   class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none" required>
          </div>
          <div>
            <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Catatan</label>
            <textarea v-model="progressForm.note" placeholder="Tulis catatan latihan..." 
                      class="w-full bg-black/40 border border-gray-900 rounded-2xl px-4 py-4 text-xs focus:border-red-500 outline-none h-24 transition-all"></textarea>
          </div>
          <div class="flex gap-3 pt-2">
            <button type="button" @click="showModal = false" class="flex-1 py-4 bg-white/5 rounded-2xl text-[9px] font-black uppercase border border-gray-800">Batal</button>
            <button type="submit" class="flex-1 py-4 bg-red-500 text-black rounded-2xl text-[9px] font-black uppercase hover:bg-red-500">Simpan</button>
          </div>
        </form>
      </div>
    </div>
  </main>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import api from '../../utils/api'

const bookers = ref([])
const loading = ref(true)
const searchQuery = ref('')
const showModal = ref(false)
const selectedMember = ref(null)
const progressForm = ref({ activity: '', duration: 30, note: '' })

const filteredBookers = computed(() => {
  if (!searchQuery.value) return bookers.value
  return bookers.value.filter(b => 
    (b.member_nama || '').toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

const getInitials = (n) => n ? n.split(' ').map(i => i[0]).join('').toUpperCase().slice(0, 2) : 'M'

const toUTCDate = (d) => {
  if (!d) return null
  let str = d.toString().replace(' ', 'T')
  if (!str.endsWith('Z') && !str.includes('+') && !str.match(/-\d{2}:\d{2}$/)) {
    str += 'Z'
  }
  const date = new Date(str)
  return isNaN(date.getTime()) ? null : date
}

const TZ = 'Asia/Jakarta'

const formatDate = (startStr, endStr) => {
  const start = toUTCDate(startStr)
  if (!start) return '--'
  const datePart = start.toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', timeZone: TZ })
  const startTime = start.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', timeZone: TZ })
  const end = toUTCDate(endStr)
  if (end) {
    return `${datePart} • ${startTime} - ${end.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', timeZone: TZ })}`
  }
  return `${datePart} • ${startTime}`
}

const getStatusClass = (status) => {
  if (status === 'pending') return 'bg-yellow-400/10 text-yellow-400 border-yellow-400/20'
  if (status === 'cancelled') return 'bg-red-400/10 text-red-400 border-red-400/20'
  return 'bg-green-500/10 text-green-500 border-green-500/20'
}

const statusLabel = (status) => {
  const map = { pending: 'Menunggu', confirmed: 'Dikonfirmasi', cancelled: 'Dibatalkan', completed: 'Selesai' }
  return map[status?.toLowerCase()] || 'Menunggu'
}

const fetchBookers = async () => {
  loading.value = true
  try {
    const res = await api.get('/bookings/my')
    const rawData = res.data?.data || []
    bookers.value = Array.isArray(rawData) ? rawData : []
  } catch (err) {
    console.error("Gagal fetch:", err)
  } finally {
    loading.value = false
  }
}

const openModal = (booker) => {
  selectedMember.value = booker
  progressForm.value = { activity: '', duration: 30, note: '' }
  showModal.value = true
}

const saveProgress = async () => {
  try {
    await api.post('/progress', {
      booking_id: selectedMember.value.id,
      activity: progressForm.value.activity,
      duration: progressForm.value.duration,
      note: progressForm.value.note
    })
    alert('Progress Tersimpan!')
    showModal.value = false
  } catch (err) {
    alert('Gagal simpan: ' + (err.response?.data?.message || 'Error server'))
  }
}

onMounted(fetchBookers)
</script>
