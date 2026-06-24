<template>
  <main class="p-8 text-white overflow-y-auto">
      <div class="max-w-5xl">
        
        <div class="bg-[#161920] rounded-[2rem] p-8 border border-gray-900 mb-8 relative overflow-hidden">
          <div class="relative z-10 flex flex-col md:flex-row items-center gap-8">
            <div class="relative flex-shrink-0">
              <div class="w-24 h-24 rounded-2xl overflow-hidden bg-red-500 flex-shrink-0 flex items-center justify-center text-black font-black text-3xl uppercase italic shadow-[0_0_20px_rgba(239,68,68,0.2)]">
                <img v-if="user.foto" :src="photoUrl" class="w-full h-full object-cover" alt="Foto Profil" />
                <span v-else>{{ getInitials(user.nama) }}</span>
              </div>
              <input ref="photoInput" type="file" accept="image/*" class="hidden" @change="handlePhotoChange" />
            </div>

            <div class="flex-grow text-center md:text-left">
              <h2 class="text-2xl font-black uppercase tracking-tight mb-1 italic">{{ user.nama || 'Loading...' }}</h2>
              <div class="text-gray-500 text-sm mb-5">
                <p class="flex items-center justify-center md:justify-start gap-2">
                  <MailIcon class="w-4 h-4 text-red-500" /> {{ user.email }}
                </p>
                <p class="uppercase flex items-center justify-center md:justify-start gap-2 mt-1">
                  <MapPinIcon class="w-4 h-4 text-red-500" /> {{ user.kota || 'Kota belum diatur' }}, {{ user.propinsi || '' }}
                </p>
              </div>
              
              <div class="flex items-center justify-center md:justify-start gap-3">
                <button @click="openEditModal" class="bg-red-500 text-black px-6 py-2.5 rounded-xl font-bold text-[10px] uppercase tracking-widest hover:bg-red-400 shadow-lg shadow-red-500/10">
                  Edit Profil Trainer
                </button>
                <button v-if="!user.foto" @click="triggerPhotoUpload" class="bg-gray-800 text-white px-4 py-2.5 rounded-xl font-bold text-[10px] uppercase tracking-widest hover:bg-gray-700 border border-gray-700">
                  Ganti Foto
                </button>
                <template v-else>
                  <button @click="triggerPhotoUpload" class="bg-gray-800 text-white px-4 py-2.5 rounded-xl font-bold text-[10px] uppercase tracking-widest hover:bg-gray-700 border border-gray-700">
                    Ganti Foto
                  </button>
                  <button @click="handlePhotoDelete" class="bg-gray-900 text-red-500 px-4 py-2.5 rounded-xl font-bold text-[10px] uppercase tracking-widest hover:bg-gray-800 border border-gray-800">
                    Hapus Foto
                  </button>
                </template>
              </div>
            </div>
          </div>
        </div>
        
        <div class="bg-[#161920] p-10 rounded-[2rem] border border-gray-900 shadow-xl">
          <h3 class="font-black uppercase text-[10px] tracking-[0.2em] text-gray-500 mb-8">Informasi Detail</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-10">
            <div v-for="(val, label) in infoFields" :key="label" class="border-b border-gray-800 pb-4">
              <p class="text-[9px] uppercase font-black text-red-500 tracking-[0.2em] mb-1.5 opacity-80">{{ label }}</p>
              <p class="text-sm font-bold text-white uppercase italic">{{ val || '-' }}</p>
            </div>
          </div>
        </div>

      </div>

      <div v-if="showModal" class="fixed inset-0 z-[999] flex items-center justify-center p-6">
        <div class="absolute inset-0 bg-black/90 backdrop-blur-md" @click="showModal = false"></div>
        <div class="relative bg-[#161920] w-full max-w-lg rounded-[2.5rem] border border-gray-800 p-10 shadow-2xl">
          <h3 class="text-xl font-black uppercase italic mb-8 text-red-500">Perbarui Profil</h3>
          
          <form @submit.prevent="handleUpdate" class="space-y-5">
            <div>
              <label class="text-[10px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Nama Lengkap</label>
              <input type="text" v-model="editForm.nama" autocomplete="name" class="w-full bg-black border border-gray-800 rounded-2xl py-4 px-6 text-white outline-none focus:border-red-500">
            </div>

            <div>
              <label class="text-[10px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Email Resmi</label>
              <input type="email" v-model="editForm.email" autocomplete="email" class="w-full bg-black border border-gray-800 rounded-2xl py-4 px-6 text-white outline-none focus:border-red-500">
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-[10px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Province</label>
                <input type="text" v-model="editForm.propinsi" autocomplete="address-level1" class="w-full bg-black border border-gray-800 rounded-2xl py-4 px-6 text-white focus:border-red-500 outline-none">
              </div>
              <div>
                <label class="text-[10px] font-black uppercase text-gray-600 mb-2 block tracking-widest">City</label>
                <input type="text" v-model="editForm.kota" autocomplete="address-level2" class="w-full bg-black border border-gray-800 rounded-2xl py-4 px-6 text-white focus:border-red-500 outline-none">
              </div>
            </div>

            <div>
              <label class="text-[10px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Spesialisasi</label>
              <input type="text" v-model="editForm.spesialisasi" placeholder="Strength Training, Yoga, Cardio..." class="w-full bg-black border border-gray-800 rounded-2xl py-4 px-6 text-white focus:border-red-500 outline-none">
            </div>

            <div>
              <label class="text-[10px] font-black uppercase text-gray-600 mb-2 block tracking-widest">Bio</label>
              <textarea v-model="editForm.bio" placeholder="Ceritakan diri Anda sebagai trainer..." class="w-full bg-black border border-gray-800 rounded-2xl py-4 px-6 text-white focus:border-red-500 outline-none h-24"></textarea>
            </div>

            <div class="flex gap-4 pt-6">
              <button type="button" @click="showModal = false" class="flex-1 py-4 bg-gray-900 rounded-2xl text-[10px] font-black uppercase text-gray-400">Batal</button>
              <button type="submit" class="flex-1 py-4 bg-red-500 text-black rounded-2xl text-[10px] font-black uppercase shadow-lg shadow-red-500/20">Simpan Perubahan</button>
            </div>
          </form>
        </div>
      </div>
    </main>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { MailIcon, MapPinIcon } from 'lucide-vue-next'
import api from '../../utils/api'
import { useAuthStore } from '../../stores/authStore'

const authStore = useAuthStore()
const user = ref({ id: '', nama: '', email: '', role: '', kota: '', propinsi: '', foto: '' })
const showModal = ref(false)
const editForm = ref({ nama: '', propinsi: '', kota: '', email: '', spesialisasi: '', bio: '' })
const photoInput = ref(null)

const API_BASE = import.meta.env.VITE_API_URL || (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' ? 'http://localhost:5000/api/v1' : 'https://api.gymbuddy.site/api/v1')
const photoUrl = computed(() => {
  if (!user.value.foto) return ''
  const base = API_BASE.replace('/api/v1', '')
  return `${base}/${user.value.foto}`
})

const infoFields = computed(() => ({
  "Nama Trainer": user.value.nama,
  "Email Resmi": user.value.email,
  "Spesialisasi": user.value.spesialisasi,
  "Bio": user.value.bio,
  "Kota": user.value.kota,
  "Provinsi": user.value.propinsi,
  "Role Akun": user.value.role
}))

const fetchUserProfile = async () => {
  try {
    await authStore.init()
    if (authStore.user) { user.value = authStore.user }
  } catch (error) { console.error("Gagal load profil:", error) }
}

const openEditModal = () => {
  // Isi form dengan data user saat ini
  editForm.value = { 
    nama: user.value.nama,
    email: user.value.email,
    propinsi: user.value.propinsi,
    kota: user.value.kota,
    spesialisasi: user.value.spesialisasi || '',
    bio: user.value.bio || ''
  }
  showModal.value = true
}

const handleUpdate = async () => {
  try {
    await api.put('/users/profile', {
      nama: editForm.value.nama,
      email: editForm.value.email,
      propinsi: editForm.value.propinsi,
      kota: editForm.value.kota,
      spesialisasi: editForm.value.spesialisasi,
      bio: editForm.value.bio
    })
    
    // Update tampilan lokal
    user.value = { ...user.value, ...editForm.value }
    showModal.value = false
    alert("Profil Trainer GymBuddy Berhasil Diperbarui!")
  } catch (error) {
    alert("Gagal update data.")
  }
}

const getInitials = (name) => {
  if (!name) return 'GB'
  const p = name.split(' ')
  return p.length > 1 ? (p[0][0] + p[1][0]).toUpperCase() : p[0][0].toUpperCase()
}

const triggerPhotoUpload = () => {
  photoInput.value?.click()
}

const handlePhotoChange = async (e) => {
  const file = e.target.files?.[0]
  if (!file) return

  const formData = new FormData()
  formData.append('foto', file)

  try {
    const res = await api.post('/upload/profile', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    const fotoPath = res.data?.data?.foto
    if (fotoPath) {
      user.value.foto = fotoPath
      // update authStore dan localStorage supaya refleksi di seluruh UI
      const updatedUser = { ...authStore.user, foto: fotoPath }
      authStore.setUser(updatedUser)
      alert('Foto profil berhasil diperbarui!')
    }
  } catch (err) {
    console.error('Upload foto gagal:', err)
    alert('Gagal upload foto. Coba lagi.')
  }
  // reset input supaya bisa pilih file yang sama lagi
  e.target.value = ''
}

const handlePhotoDelete = async () => {
  if (!confirm('Yakin ingin menghapus foto profil?')) return
  try {
    await api.put('/users/profile', { foto: null })
    user.value.foto = ''
    const updatedUser = { ...authStore.user }
    delete updatedUser.foto
    authStore.setUser(updatedUser)
    alert('Foto profil berhasil dihapus!')
  } catch (err) {
    console.error('Hapus foto gagal:', err)
    alert('Gagal menghapus foto. Coba lagi.')
  }
}

onMounted(fetchUserProfile)
</script>