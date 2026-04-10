import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../widgets/iniato_button.dart';
import '../widgets/iniato_text_field.dart';
import 'login_screen.dart';

/// User profile and settings screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getProfile();
      if (user != null && mounted) {
        setState(() {
          _user = user;
          _nameController.text = user.fullName;
          _phoneController.text = user.phoneNumber;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final updated = await AuthService.updateProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      if (updated != null && mounted) {
        setState(() {
          _user = updated;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Logout', style: TextStyle(color: IniatoTheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IniatoTheme.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ─── Profile Header ───
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  automaticallyImplyLeading: false,
                  backgroundColor: IniatoTheme.green,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: IniatoTheme.backgroundGradient,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 40),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              child: Text(
                                (_user?.fullName.isNotEmpty ?? false)
                                    ? _user!.fullName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: IniatoTheme.green,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _user?.fullName ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _user?.phoneNumber ?? '',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ─── Content ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile info card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(IniatoTheme.radiusMd),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Personal Info',
                                      style: IniatoTheme.subheading
                                          .copyWith(fontSize: 16)),
                                  TextButton.icon(
                                    onPressed: () {
                                      if (_isEditing) {
                                        _saveProfile();
                                      } else {
                                        setState(() => _isEditing = true);
                                      }
                                    },
                                    icon: Icon(
                                      _isEditing ? Icons.save : Icons.edit,
                                      size: 18,
                                    ),
                                    label: Text(
                                        _isEditing ? 'Save' : 'Edit'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isEditing) ...[
                                IniatoTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person,
                                ),
                                const SizedBox(height: 12),
                                IniatoTextField(
                                  controller: _phoneController,
                                  label: 'Phone',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                              ] else ...[
                                _buildInfoRow(
                                    Icons.person, 'Name', _user?.fullName),
                                _buildInfoRow(
                                    Icons.email, 'Email', _user?.email),
                                _buildInfoRow(
                                    Icons.phone, 'Phone', _user?.phoneNumber),
                                if (_user?.gender != null)
                                  _buildInfoRow(Icons.wc, 'Gender',
                                      _user!.gender),
                                if (_user?.preferredPaymentMethod != null)
                                  _buildInfoRow(
                                      Icons.payment,
                                      'Payment',
                                      _user!.preferredPaymentMethod),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Settings items
                        _buildSettingsGroup([
                          _SettingsItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () {},
                          ),
                          _SettingsItem(
                            icon: Icons.info_outline,
                            title: 'About Iniato',
                            subtitle: 'Version 1.0.0',
                            onTap: () {},
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Logout
                        IniatoButton(
                          label: 'Logout',
                          onPressed: _logout,
                          outlined: true,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: IniatoTheme.green, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: IniatoTheme.caption.copyWith(fontSize: 12)),
              Text(value ?? '—',
                  style: IniatoTheme.body.copyWith(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(IniatoTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: IniatoTheme.green, size: 22),
                title: Text(item.title, style: IniatoTheme.body),
                subtitle: item.subtitle != null
                    ? Text(item.subtitle!, style: IniatoTheme.caption)
                    : null,
                trailing: const Icon(Icons.chevron_right,
                    color: IniatoTheme.textSecondary, size: 20),
                onTap: item.onTap,
              ),
              if (!isLast) Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
