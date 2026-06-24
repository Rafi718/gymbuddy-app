<template>
  <aside class="w-64 bg-[#0a0a0a] text-gray-400 flex flex-col h-screen sticky top-0 border-r border-white/5 shadow-2xl shrink-0">

    <div class="p-6">
      <router-link to="/" class="flex items-center gap-3">
        <img src="/src/assets/gymbuddy-logo.png" alt="GymBuddy" class="h-8 w-auto" />
      </router-link>
    </div>

    <nav class="flex-1 px-4 space-y-1">
      <router-link
        v-for="item in navItems" :key="item.path"
        :to="item.path"
        class="flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-all duration-200"
        :class="$route.path === item.path
          ? 'bg-red-500/10 text-red-500 border border-red-500/20'
          : 'text-gray-400 hover:text-white hover:bg-white/5'"
      >
        <component :is="item.icon" class="w-5 h-5" />
        <span>{{ item.label }}</span>
      </router-link>
    </nav>

    <div class="p-5 border-t border-white/5 space-y-4">
      <router-link to="/trainer-panel/profile" class="flex items-center gap-3">
        <div class="w-9 h-9 rounded-lg overflow-hidden bg-red-500 flex items-center justify-center text-black font-bold text-xs uppercase italic shrink-0">
          <img v-if="user?.foto" :src="photoUrl" class="w-full h-full object-cover" alt="Avatar" />
          <span v-else>{{ userInitials }}</span>
        </div>
        <div class="min-w-0">
          <p class="text-white text-sm font-bold truncate">{{ user?.nama || 'Trainer' }}</p>
          <p class="text-gray-500 text-xs truncate">{{ user?.email || '' }}</p>
        </div>
      </router-link>

      <button
        @click="handleLogout"
        class="flex w-full items-center gap-3 px-4 py-3 border border-white/10 rounded-xl text-sm hover:bg-red-500/10 hover:border-red-500/30 hover:text-red-400 transition-all duration-200 cursor-pointer"
      >
        <LogOutIcon class="w-5 h-5" />
        <span>Keluar</span>
      </button>
    </div>
  </aside>
</template>

<script setup>
import { useRouter, useRoute } from 'vue-router'
import { computed } from 'vue'
import { LayoutDashboardIcon, CalendarCheckIcon, UsersIcon, UserIcon, LogOutIcon } from 'lucide-vue-next'
import { useAuthStore } from '../stores/authStore'

const router = useRouter()
const $route = useRoute()
const authStore = useAuthStore()

const user = computed(() => authStore.user)
const API_BASE = import.meta.env.VITE_API_URL || (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1' ? 'http://localhost:5000/api/v1' : 'https://api.gymbuddy.site/api/v1')
const photoUrl = computed(() => {
  if (!user.value?.foto) return ''
  const base = API_BASE.replace('/api/v1', '')
  return `${base}/${user.value.foto}`
})
const userInitials = computed(() => {
  const name = user.value?.nama || 'T'
  const p = name.split(' ')
  return p.length > 1 ? (p[0][0] + p[1][0]).toUpperCase() : p[0][0].toUpperCase()
})

const navItems = [
  { path: '/trainer-panel/dashboard', label: 'Dashboard', icon: LayoutDashboardIcon },
  { path: '/trainer-panel/sesion', label: 'Kelola Sesi', icon: CalendarCheckIcon },
  { path: '/trainer-panel/clien', label: 'Daftar Booker', icon: UsersIcon },
  { path: '/trainer-panel/profile', label: 'Profil', icon: UserIcon },
]

const handleLogout = () => {
  localStorage.removeItem('token')
  localStorage.removeItem('user')
  authStore.logout?.() || (authStore.user = null)
  router.push('/login')
}
</script>
