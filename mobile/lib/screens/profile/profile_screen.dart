import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_provider.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _api = ApiService();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _kotaController = TextEditingController();
  final _propinsiController = TextEditingController();
  bool _isEditing = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _kotaController.dispose();
    _propinsiController.dispose();
    super.dispose();
  }

  void _initForm(Map<String, dynamic>? user) {
    if (user == null) return;
    _namaController.text = user['nama'] ?? '';
    _emailController.text = user['email'] ?? '';
    _kotaController.text = user['kota'] ?? '';
    _propinsiController.text = user['propinsi'] ?? '';
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await _api.getUserProfile();
      final user = res['data'] ?? res['user'];
      if (user != null && mounted) {
        _initForm(user);
      }
    } catch (e) {
      // Use data from auth provider as fallback
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama tidak boleh kosong')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final res = await _api.updateProfile({
        'nama': _namaController.text.trim(),
        'kota': _kotaController.text.trim(),
        'propinsi': _propinsiController.text.trim(),
      });
      if (res['success'] != false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green[700],
          ),
        );
        setState(() => _isEditing = false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal memperbarui profil'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() => _isEditing = false);
                _initForm(user);
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar with camera button
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.primary.withAlpha(30),
                        backgroundImage: _getProfileImage(user),
                        child: _getProfileImage(user) == null
                            ? Text(
                                _getInitials(user?['nama'] ?? 'U'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Role badge
                  if (user?['role'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user!['role'])[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getRoleLabel(user['role']),
                        style: TextStyle(
                          color: _getRoleColor(user['role'])[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Profile form
                  if (_isEditing) ...[
                    _buildTextField(_namaController, 'Nama Lengkap', Icons.person, enabled: true),
                    const SizedBox(height: 16),
                    _buildTextField(_emailController, 'Email', Icons.email, enabled: false),
                    const SizedBox(height: 16),
                    _buildTextField(_kotaController, 'Kota', Icons.location_city, enabled: true),
                    const SizedBox(height: 16),
                    _buildTextField(_propinsiController, 'Provinsi', Icons.map, enabled: true),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    _buildInfoTile('Nama', user?['nama'] ?? '-', Icons.person),
                    _buildInfoTile('Email', user?['email'] ?? '-', Icons.email),
                    _buildInfoTile('Kota', user?['kota'] ?? '-', Icons.location_city),
                    _buildInfoTile('Provinsi', user?['propinsi'] ?? '-', Icons.map),
                    if (user?['created_at'] != null)
                      _buildInfoTile(
                        'Bergabung Sejak',
                        _formatDate(user!['created_at']),
                        Icons.calendar_today,
                      ),
                  ],

                  const SizedBox(height: 32),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red[700]),
                    title: Text('Keluar', style: TextStyle(color: Colors.red[700])),
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {required bool enabled}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage(Map<String, dynamic>? user) {
    final foto = user?['foto'] as String?;
    if (foto == null || foto.isEmpty) return null;
    final base = ApiService.baseUrl.replaceAll('/api', '');
    return CachedNetworkImageProvider('$base/$foto');
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'trainer': return 'Trainer';
      default: return 'Member';
    }
  }

  MaterialColor _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'trainer': return Colors.blue;
      default: return Colors.green;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (picked == null || !mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mengupload foto...'), backgroundColor: Colors.blue),
    );
    
    try {
      final res = await _api.uploadPhoto(File(picked.path));
      if (res['success'] != false && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        _loadProfile();
        ref.read(authProvider.notifier).refreshUser();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal upload foto'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal upload foto'), backgroundColor: Colors.red),
        );
      }
    }
  }
}


