<template>
  <div class="min-h-screen bg-[#000000] flex flex-col items-center justify-center p-6 font-sans">
    
    <div class="max-w-5xl w-full mx-auto flex justify-center mt-20 mb-12">
      
      <div class="w-full grid grid-cols-1 md:grid-cols-2 bg-[#111111] rounded-[2.5rem] overflow-hidden shadow-2xl">
        
        <div class="relative hidden md:block overflow-hidden">
          <img src="/src/assets/gymapp-register.jpg" alt="Register Image"
               class="absolute inset-0 w-full h-full object-cover" />
          
          <div class="absolute inset-0 bg-black/60 backdrop-blur-[2px]"></div>
          
          <div class="relative z-10 p-12 h-full flex flex-col justify-center text-white">
            <p class="text-red-500 font-bold uppercase tracking-widest text-xs mb-3">Bergabung dengan GymBuddy</p>
            <h1 class="text-4xl lg:text-5xl font-bold leading-tight mb-6">
              Mulai Perjalanan Fitness-mu <span class="text-red-500">Hari ini</span>, Jadilah versi Terbaik Dirimu!
            </h1>
            <p class="text-gray-300 text-sm mb-8 max-w-xs">
              Daftar sekarang dan temukan cara termudah serta aman untuk memesan personal trainer sesuai kebutuhanmu.
            </p>
          </div>
        </div>

        <div class="p-10 md:p-14 bg-[#000000] flex flex-col justify-center">
          <div class="mb-10">
            <h2 class="text-4xl font-bold text-white mb-2">Daftar Akun<span class="text-red-500">.</span></h2>
            <p class="text-gray-400">Silakan lengkapi detail data diri Anda.</p>
          </div>

          <form @submit.prevent="handleRegister" class="space-y-6" novalidate>
            <div class="space-y-2">
              <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Nama Lengkap</label>
              <input v-model="formData.nama" type="text" autocomplete="name" placeholder="Masukkan nama lengkap"
                     :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 outline-none transition-all placeholder-gray-700', errors.nama ? 'ring-2 ring-red-500' : 'focus:ring-red-500']">
              <p v-if="errors.nama" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.nama }}</p>
            </div>

            <div class="space-y-2">
              <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Alamat Email</label>
              <input v-model="formData.email" type="email" autocomplete="email" placeholder="nama@email.com"
                     :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 outline-none transition-all placeholder-gray-700', errors.email ? 'ring-2 ring-red-500' : 'focus:ring-red-500']">
              <p v-if="errors.email" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.email }}</p>
            </div>

            <div class="space-y-2">
              <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Password</label>
              <input v-model="formData.password" type="password" autocomplete="new-password" placeholder="Minimal 6 karakter"
                     :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 outline-none transition-all placeholder-gray-700', errors.password ? 'ring-2 ring-red-500' : 'focus:ring-red-500']">
              <p v-if="errors.password" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.password }}</p>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div class="space-y-2">
                <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Provinsi</label>
                <input v-model="formData.propinsi" type="text" autocomplete="address-level1" placeholder="Jawa Tengah"
                       :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 outline-none transition-all placeholder-gray-700', errors.propinsi ? 'ring-2 ring-red-500' : 'focus:ring-red-500']">
                <p v-if="errors.propinsi" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.propinsi }}</p>
              </div>
              <div class="space-y-2">
                <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Kota</label>
                <input v-model="formData.kota" type="text" autocomplete="address-level2" placeholder="Purwokerto"
                       :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 outline-none transition-all placeholder-gray-700', errors.kota ? 'ring-2 ring-red-500' : 'focus:ring-red-500']">
                <p v-if="errors.kota" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.kota }}</p>
              </div>
            </div>

            <div class="space-y-2 relative">
              <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Daftar Sebagai</label>
              <select v-model="formData.role"
                      :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 focus:ring-red-500 outline-none appearance-none cursor-pointer', errors.role ? 'ring-2 ring-red-500' : '']">
                <option value="" disabled>Pilih peran Anda</option>
                <option value="customer">Member (Customer)</option>
                <option value="trainer">Trainer (Pelatih)</option>
              </select>
              <p v-if="errors.role" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.role }}</p>
              <span class="absolute right-6 top-[55px] -translate-y-1/2 text-red-500 pointer-events-none text-xs">▼</span>
            </div>

            <div v-if="formData.role === 'trainer'" class="space-y-2">
              <label class="text-xs font-semibold text-gray-500 uppercase ml-1">Spesialisasi</label>
              <input v-model="formData.spesialisasi" type="text" placeholder="Contoh: Strength Training, Yoga, Cardio"
                     :class="['w-full bg-[#1A1A1A] border-none text-white px-6 py-4 rounded-full focus:ring-2 outline-none transition-all placeholder-gray-700', errors.spesialisasi ? 'ring-2 ring-red-500' : 'focus:ring-red-500']">
              <p v-if="errors.spesialisasi" class="text-red-400 text-[10px] font-bold ml-2 mt-1">{{ errors.spesialisasi }}</p>
            </div>

            <button type="submit" :disabled="loading"
                    class="w-full bg-red-500 text-white py-4 rounded-full font-bold text-lg hover:bg-red-600 shadow-xl shadow-red-500/20 transition-all mt-4">
              {{ loading ? 'Memproses...' : 'Buat Akun' }}
            </button>
          </form>

          <p class="mt-8 text-center text-gray-400 text-sm">
            Sudah punya akun? 
            <router-link to="/login" class="text-blue-400 font-bold hover:underline">Log in di sini</router-link>
          </p>
        </div>
      </div>
    </div>
  </div>

  <!-- Toast Notification -->
  <Transition name="toast">
    <div v-if="toast.show" 
         :class="toast.type === 'success' ? 'bg-green-500' : 'bg-red-500'"
         class="fixed bottom-6 right-6 px-6 py-4 rounded-2xl text-white font-bold text-sm shadow-2xl z-50">
      {{ toast.message }}
    </div>
  </Transition>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api from '../utils/api'

const router = useRouter()
const loading = ref(false)
const toast = ref({ show: false, message: '', type: 'success' })

const showToast = (message, type = 'success') => {
  toast.value = { show: true, message, type }
  setTimeout(() => { toast.value.show = false }, 3000)
}

const formData = ref({
  nama: '',
  email: '',
  password: '',
  role: '',
  spesialisasi: '',
  propinsi: '',
  kota: ''
})

const errors = ref({
  nama: '',
  email: '',
  password: '',
  role: '',
  spesialisasi: '',
  propinsi: '',
  kota: ''
})

const validateForm = () => {
  const e = { nama: '', email: '', password: '', role: '', spesialisasi: '', propinsi: '', kota: '' }
  let valid = true

  if (!formData.value.nama.trim()) { e.nama = 'Nama lengkap wajib diisi'; valid = false }
  if (!formData.value.email.trim()) { e.email = 'Email wajib diisi'; valid = false }
  else if (!formData.value.email.includes('@')) { e.email = 'Format email tidak valid'; valid = false }
  if (!formData.value.password) { e.password = 'Password wajib diisi'; valid = false }
  else if (formData.value.password.length < 6) { e.password = 'Minimal 6 karakter'; valid = false }
  if (!formData.value.propinsi.trim()) { e.propinsi = 'Provinsi wajib diisi'; valid = false }
  if (!formData.value.kota.trim()) { e.kota = 'Kota wajib diisi'; valid = false }
  if (!formData.value.role) { e.role = 'Pilih role Anda'; valid = false }
  if (formData.value.role === 'trainer' && !formData.value.spesialisasi.trim()) {
    e.spesialisasi = 'Spesialisasi wajib diisi untuk trainer'; valid = false
  }

  errors.value = e
  return valid
}

const handleRegister = async () => {
  if (!validateForm()) return

  loading.value = true
  try {
    const endpoint = formData.value.role === 'trainer' 
      ? '/auth/register/trainer' 
      : '/auth/register'
    
    const payload = {
      nama: formData.value.nama,
      email: formData.value.email,
      password: formData.value.password,
      propinsi: formData.value.propinsi,
      kota: formData.value.kota
    }

    if (formData.value.role === 'trainer') {
      payload.spesialisasi = formData.value.spesialisasi
    }

    await api.post(endpoint, payload)
    
    showToast('Pendaftaran Berhasil! Silakan Login.', 'success')
    setTimeout(() => router.push('/login'), 1500)
  } catch (error) {
    const msg = error.response?.data?.error?.message || error.response?.data?.message || 'Gagal mendaftar. Periksa koneksi.'
    showToast(msg, 'error')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.toast-enter-active, .toast-leave-active {
  transition: all 0.4s ease;
}
.toast-enter-from {
  opacity: 0;
  transform: translateX(100px);
}
.toast-leave-to {
  opacity: 0;
  transform: translateY(20px);
}
</style>
