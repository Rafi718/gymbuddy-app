import { createRouter, createWebHistory } from 'vue-router'


import Home from '../views/home.vue'
import About from '../views/about.vue'
import Trainer from '../views/trainer.vue'
import Login from '../views/LoginView.vue'
import Register from '../views/register.vue'

import DashboardView from '../views/dashboard/DashboardView.vue'
import FindTrainers from '../views/dashboard/FindTrainers.vue'
import MyBookings from '../views/dashboard/MyBookings.vue'
import PricingView from '../views/dashboard/PricingView.vue'
import progres from '../views/dashboard/Progres.vue'

import dbtrainer from '../views/dashboard_trainer/TrainerDashboard.vue'
import mstrainer from '../views/dashboard_trainer/ManageSessionsView.vue'
import tcvtrainer from '../views/dashboard_trainer/TrainerClientsView.vue'
import teptrainer from '../views/dashboard_trainer/TrainerEditProfile.vue'

// Admin views (lazy loaded)
const AdminDashboard = () => import('../views/admin/AdminDashboard.vue')
const AdminUsers = () => import('../views/admin/AdminUsers.vue')
const AdminTrainers = () => import('../views/admin/AdminTrainers.vue')
const AdminBookings = () => import('../views/admin/AdminBookings.vue')

const routes = [
  { path: '/', component: Home },
  { path: '/about', component: About },
  { path: '/trainer', component: Trainer },
  { path: '/login', component: Login },
  { path: '/register', component: Register },

  // Dashboard routes
  { path: '/dashboard', component: DashboardView },
  { path: '/dashboard/find-trainers', component: FindTrainers },
  { path: '/dashboard/my-bookings', component: MyBookings },
  { path: '/dashboard/pricingview', component: PricingView },
  { path: '/dashboard/progres', component: progres },
  { path: '/dashboard/profile', component: () => import('../views/dashboard/profile.vue') },
  { path: '/dashboard/profile/edit', component: () => import('../views/dashboard/EditProfileView.vue') },
  { path: '/dashboard/profile/edit/:id', component: () => import('../views/dashboard/EditProfileView.vue') },
  { path: '/dashboard/settings', component: () => import('../views/dashboard/SettingsView.vue') },

  // Dashboard trainer
  { path: '/trainer-panel/dashboard', name: 'TrainerDashboard', component: dbtrainer },
  { path: '/trainer-panel/sesion', name: 'ManageSessionsView', component: mstrainer },
  { path: '/trainer-panel/clien', name: 'TrainerClientsView', component: tcvtrainer },
  { path: '/trainer-panel/profile', name: 'TrainerEditProfile', component: teptrainer },

  // Admin Panel (wrapped in meta.requiresAuth + admin check via navigation guard)
  { path: '/admin/dashboard', component: AdminDashboard, meta: { requiresAdmin: true } },
  { path: '/admin/users', component: AdminUsers, meta: { requiresAdmin: true } },
  { path: '/admin/trainers', component: AdminTrainers, meta: { requiresAdmin: true } },
  { path: '/admin/bookings', component: AdminBookings, meta: { requiresAdmin: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Navigation Guard
router.beforeEach((to) => {
  const token = localStorage.getItem('token')
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  // Protected dashboard/trainer routes
  if ((to.path.startsWith('/dashboard') || to.path.startsWith('/trainer-panel')) && !token) {
    return { path: '/login' }
  }

  // Admin routes - check role
  if (to.meta.requiresAdmin) {
    if (!token) return { path: '/login' }
    if (user.role !== 'admin') return { path: '/dashboard' }
  }

  // Redirect logged-in users away from login/register
  if ((to.path === '/login' || to.path === '/register') && token) {
    return { path: '/dashboard' }
  }
})

export default router
