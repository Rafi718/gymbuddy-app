<template>
  <div class="p-8 text-white">
    <header class="mb-8 flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-black uppercase tracking-tighter">Kelola Pengguna</h1>
        <p class="text-gray-500 text-sm mt-1">Manajemen semua pengguna, pelatih, dan admin</p>
      </div>
      <div class="text-xs text-gray-600 font-bold">{{ total }} total</div>
    </header>

    <!-- Search & Filter -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <input v-model="search" type="search" autocomplete="search" placeholder="Cari nama atau email..." @input="fetchData"
             class="bg-[#0f1115] border border-gray-800 p-3 rounded-xl text-sm focus:border-red-500 outline-none transition-all">
      <select v-model="roleFilter" @change="fetchData"
              class="bg-[#0f1115] border border-gray-800 p-3 rounded-xl text-sm text-gray-400 outline-none">
        <option value="">Semua Peran</option>
        <option value="customer">Pelanggan</option>
        <option value="trainer">Pelatih</option>
        <option value="admin">Admin</option>
      </select>
      <div></div>
    </div>

    <!-- Table -->
    <div class="bg-[#0f1115] rounded-2xl border border-gray-900 overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-left">
          <thead>
            <tr class="bg-black/20">
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase tracking-widest">Nama</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase tracking-widest">Email</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase tracking-widest">Peran</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase tracking-widest">Lokasi</th>
              <th class="py-4 px-6 text-[10px] font-black text-gray-500 uppercase tracking-widest">Aksi</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in users" :key="u.id" class="border-b border-gray-900/50 hover:bg-white/[0.02]">
              <td class="py-4 px-6 text-sm font-medium">{{ u.nama }}</td>
              <td class="py-4 px-6 text-sm text-gray-400">{{ u.email }}</td>
              <td class="py-4 px-6">
                <span :class="roleBadge(u.role)" class="text-[9px] px-3 py-1 rounded-full border font-black uppercase">{{ roleLabel(u.role) }}</span>
              </td>
              <td class="py-4 px-6 text-sm text-gray-400">{{ u.kota || '-' }}</td>
              <td class="py-4 px-6">
                <button @click="deleteUser(u.id)" class="text-red-400 hover:text-red-300 text-xs font-bold uppercase">Hapus</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Pagination -->
    <div v-if="totalPages > 1" class="flex justify-center gap-2 mt-6">
      <button @click="page = Math.max(1, page - 1); fetchData()" :disabled="page === 1"
              class="px-4 py-2 bg-[#0f1115] border border-gray-800 rounded-xl text-xs font-bold disabled:opacity-50">← Sebelumnya</button>
      <span class="px-4 py-2 text-sm text-gray-500">Halaman {{ page }} dari {{ totalPages }}</span>
      <button @click="page = Math.min(totalPages, page + 1); fetchData()" :disabled="page === totalPages"
              class="px-4 py-2 bg-[#0f1115] border border-gray-800 rounded-xl text-xs font-bold disabled:opacity-50">Berikutnya →</button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../../utils/api'

const users = ref([])
const search = ref('')
const roleFilter = ref('')
const page = ref(1)
const total = ref(0)
const limit = 20
const totalPages = computed(() => Math.ceil(total.value / limit))

const roleBadge = (role) => {
  const map = { admin: 'bg-red-500/10 text-red-500 border-red-500/20', trainer: 'bg-blue-500/10 text-blue-500 border-blue-500/20', customer: 'bg-green-500/10 text-green-500 border-green-500/20' }
  return map[role] || 'bg-gray-500/10 text-gray-500 border-gray-500/20'
}

const roleLabel = (role) => {
  const map = { admin: 'Admin', trainer: 'Pelatih', customer: 'Pelanggan' }
  return map[role?.toLowerCase()] || role
}

const fetchData = async () => {
  try {
    const params = { page: page.value, limit }
    if (search.value) params.search = search.value
    if (roleFilter.value) params.role = roleFilter.value
    const res = await api.get('/users', { params })
    users.value = res.data?.data || []
    total.value = res.data?.meta?.total || users.value.length
  } catch (err) { console.error(err) }
}

const deleteUser = async (id) => {
  if (!confirm('Yakin ingin menghapus user ini?')) return
  try {
    await api.delete(`/users/${id}`)
    fetchData()
  } catch (err) { alert(err.response?.data?.error?.message || err.response?.data?.message || 'Gagal') }
}

import { computed } from 'vue'
onMounted(fetchData)
</script>
