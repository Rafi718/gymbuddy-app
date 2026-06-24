<template>
  <main class="flex-grow p-8 text-white overflow-y-auto bg-[#0a0b10] min-h-screen">
    <header class="mb-8 flex justify-between items-center">
      <div>
        <h2 class="text-3xl font-black uppercase tracking-tighter italic">Kelola Sesi</h2>
        <p class="text-gray-500 text-xs font-bold uppercase tracking-widest mt-1">Atur dan pantau jadwal latihan kamu</p>
      </div>
      <button @click="openCreateModal"
              class="bg-red-500 hover:bg-red-500 text-black px-6 py-3 rounded-xl text-[10px] font-black uppercase transition-all shadow-lg shadow-red-500/10">
        + Tambah Sesi Baru
      </button>
    </header>

    <div v-if="loading" class="flex justify-center py-20">
      <div class="animate-pulse text-red-500 font-black uppercase text-xs tracking-widest">Memuat Data...</div>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="session in sessions" :key="session.id" class="bg-[#161920] border border-gray-900 p-6 rounded-[2rem] hover:border-red-500/30 transition-all group shadow-2xl">
        <div class="flex justify-between items-start mb-4">
          <span class="px-3 py-1 bg-red-500/10 text-red-500 rounded-full text-[10px] font-black uppercase tracking-widest border border-red-500/20">
            {{ formatRupiah(session.price) }}
          </span>
          <span class="text-[10px] text-gray-700 font-mono italic">#{{ session.id }}</span>
        </div>

        <h3 class="text-md font-black mb-1 uppercase italic group-hover:text-red-500 transition-colors tracking-tight">{{ session.title }}</h3>
        <p class="text-gray-500 text-[10px] mb-6 line-clamp-2 font-medium leading-relaxed">{{ session.deskripsi || 'Tidak ada deskripsi' }}</p>

        <div class="space-y-2 mb-8">
          <div class="flex items-center text-[10px] text-gray-400 gap-2">
            <CalendarIcon class="w-3 h-3 text-red-500 opacity-50" /> {{ formatDate(session.start_time) }}
          </div>
          <div class="flex items-center text-[10px] text-gray-400 gap-2">
            <ClockIcon class="w-3 h-3 text-red-500 opacity-50" /> {{ formatTime(session.start_time) }} - {{ formatTime(session.end_time) }}
          </div>
          <div class="flex items-center text-[10px] text-gray-400 gap-2">
            <ActivityIcon class="w-3 h-3 text-red-500 opacity-50" /> Status: {{ session.status }}
          </div>
          <div v-if="session.booking_count > 0" class="flex items-center text-[10px] text-amber-400 gap-2">
            <UsersIcon class="w-3 h-3 text-amber-500 opacity-50" /> {{ session.booking_count }} booking aktif
          </div>
        </div>

        <div class="flex gap-2 pt-6 border-t border-gray-800">
          <button @click="openEditModal(session)" class="flex-1 py-3 bg-white/5 border border-gray-800 rounded-xl text-[9px] font-black uppercase tracking-widest hover:bg-white hover:text-black transition-all">Edit</button>
          <button
            v-if="session.booking_count > 0"
            @click="showCannotDelete(session)"
            class="px-4 py-3 bg-amber-500/10 text-amber-500 rounded-xl text-[9px] font-black uppercase border border-amber-500/20 hover:bg-amber-500 hover:text-white transition-all"
            title="Sesi ini sudah memiliki booking"
          >
            Hapus
          </button>
          <button
            v-else
            @click="deleteSession(session.id)"
            class="px-4 py-3 bg-red-500/10 text-red-500 rounded-xl text-[9px] font-black uppercase border border-red-500/20 hover:bg-red-500 hover:text-white transition-all"
          >
            Hapus
          </button>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-black/90 backdrop-blur-md flex items-center justify-center p-4 z-50">
      <div class="bg-[#161920] border border-gray-900 w-full max-w-lg rounded-[2rem] p-8 shadow-2xl">
        <h2 class="text-xl font-black uppercase italic mb-6 tracking-tighter">{{ isEdit ? 'Update Sesi' : 'Buat Sesi Baru' }}</h2>
        
        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Judul Sesi</label>
            <input v-model="form.title" type="text" class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none transition-all" required>
          </div>
          <div>
            <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Deskripsi</label>
            <textarea v-model="form.deskripsi" class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none transition-all h-24"></textarea>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Mulai</label>
              <input v-model="form.start_time" type="datetime-local" class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none" required>
            </div>
            <div>
              <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Selesai</label>
              <input v-model="form.end_time" type="datetime-local" class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none">
            </div>
          </div>
          <div>
            <label class="text-[9px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Harga (Rp)</label>
            <input v-model.number="form.price" type="number" placeholder="150000" class="w-full bg-black/40 border border-gray-900 rounded-xl px-4 py-3 text-xs focus:border-red-500 outline-none">
          </div>

          <div class="flex gap-3 mt-8">
            <button type="button" @click="showModal = false" class="flex-1 py-4 bg-white/5 rounded-xl text-[9px] font-black uppercase tracking-widest border border-gray-800">Batal</button>
            <button type="submit" :disabled="loadingSubmit" class="flex-1 py-4 bg-red-500 text-black rounded-xl text-[9px] font-black uppercase tracking-widest hover:bg-red-500">
              {{ loadingSubmit ? 'Memproses...' : isEdit ? 'Simpan' : 'Buat Sesi' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </main>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { CalendarIcon, ClockIcon, ActivityIcon, UsersIcon } from 'lucide-vue-next'
import api from '../../utils/api'

const sessions = ref([])
const loading = ref(true)
const loadingSubmit = ref(false)
const showModal = ref(false)
const isEdit = ref(false)
const currentId = ref(null)
const userData = JSON.parse(localStorage.getItem('user') || '{}')

const form = ref({
  title: '',
  deskripsi: '',
  start_time: '',
  end_time: '',
  price: 0
})

const fetchData = async () => {
  loading.value = true
  try {
    const res = await api.get('/sessions')
    const data = res.data?.data || []
    sessions.value = Array.isArray(data) ? data.filter(s => String(s.trainer_id) === String(userData.id)) : []
  } catch (err) {
    console.error("Fetch Error:", err)
  } finally {
    loading.value = false
  }
}

const handleSubmit = async () => {
  loadingSubmit.value = true
  try {
    const payload = {
      title: form.value.title,
      description: form.value.deskripsi || '',
      start_time: form.value.start_time ? new Date(form.value.start_time).toISOString() : null,
      end_time: form.value.end_time ? new Date(form.value.end_time).toISOString() : null,
      price: Number(form.value.price) || 0,
      max_participants: 5
    }

    if (isEdit.value) {
      await api.put(`/sessions/${currentId.value}`, payload)
    } else {
      await api.post('/sessions', payload)
    }
    showModal.value = false
    await fetchData()
  } catch (err) {
    alert("Gagal: " + (err.response?.data?.error?.message || err.response?.data?.message || "Cek koneksi"))
  } finally {
    loadingSubmit.value = false
  }
}

const showCannotDelete = (session) => {
  alert(`Sesi "${session.title}" tidak bisa dihapus karena sudah memiliki ${session.booking_count} booking aktif.\n\nSilakan batalkan semua booking terlebih dahulu.`)
}

const deleteSession = async (id) => {
  const session = sessions.value.find(s => s.id === id)
  if (session?.booking_count > 0) {
    showCannotDelete(session)
    return
  }
  if (!confirm('Yakin ingin menghapus sesi ini?')) return
  try {
    await api.delete(`/sessions/${id}`)
    await fetchData()
  } catch (err) {
    const status = err.response?.status
    const msg = err.response?.data?.error?.message || err.response?.data?.message || err.message
    if (status === 409) {
      alert('Tidak bisa dihapus: ' + msg)
    } else if (status === 403) {
      alert('Tidak punya izin: ' + msg)
    } else {
      alert('Gagal menghapus: ' + msg)
    }
  }
}

const openEditModal = (session) => {
  isEdit.value = true
  currentId.value = session.id
  form.value = {
    title: session.title || '',
    deskripsi: session.description || session.deskripsi || '',
    start_time: session.start_time ? new Date(session.start_time).toISOString().slice(0, 16) : '',
    end_time: session.end_time ? new Date(session.end_time).toISOString().slice(0, 16) : '',
    price: session.price || 0
  }
  showModal.value = true
}

const openCreateModal = () => {
  isEdit.value = false
  form.value = { title: '', deskripsi: '', start_time: '', end_time: '', price: 0 }
  showModal.value = true
}

const formatRupiah = (price) => price ? `Rp${Number(price).toLocaleString('id-ID')}` : 'Rp0'
const formatTime = (d) => d ? new Date(d).toLocaleTimeString('id-ID', {hour:'2-digit', minute:'2-digit'}) : '--'
const formatDate = (d) => d ? new Date(d).toLocaleDateString('id-ID', {day:'numeric', month:'short'}) : '--'

onMounted(fetchData)
</script>
