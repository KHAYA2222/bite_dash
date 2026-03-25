// screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'seed_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthProvider authProvider;
  const ProfileScreen({super.key, required this.authProvider});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Cancel', style: TextStyle(fontFamily: 'Nunito'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child:
                const Text('Sign Out', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.authProvider.signOut();
      // AuthWrapper in main.dart handles navigation back to LoginScreen
    }
  }

  void _openEditSheet(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _EditProfileSheet(
        authProvider: widget.authProvider,
        user: user,
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.construction_rounded, color: Colors.white, size: 18),
        SizedBox(width: 10),
        Text('Feature coming soon',
            style:
                TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
      ]),
      backgroundColor: const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // ListenableBuilder ensures the whole screen rebuilds whenever
    // authProvider notifies — e.g. after updateProfile() or signOut().
    return ListenableBuilder(
      listenable: widget.authProvider,
      builder: (context, _) {
        final user = widget.authProvider.currentUser;

        // If signed out while on this screen, pop back
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: cs.background,
          body: FadeTransition(
            opacity: _fade,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(cs, theme, user)),
                SliverToBoxAdapter(child: _buildStatsRow(cs, theme)),
                SliverToBoxAdapter(
                  child: _buildSectionLabel('Account', theme),
                ),
                SliverToBoxAdapter(
                  child: _buildMenuSection(cs, [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Edit Profile',
                      onTap: () => _openEditSheet(user),
                    ),
                    _MenuItem(
                      icon: Icons.location_on_outlined,
                      label: 'Delivery Addresses',
                      onTap: _showComingSoon,
                    ),
                    _MenuItem(
                      icon: Icons.credit_card_outlined,
                      label: 'Payment Methods',
                      onTap: _showComingSoon,
                    ),
                  ]),
                ),
                SliverToBoxAdapter(child: _buildSectionLabel('Orders', theme)),
                SliverToBoxAdapter(
                  child: _buildMenuSection(cs, [
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Order History',
                      onTap: _showComingSoon,
                    ),
                    _MenuItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Favourites',
                      onTap: _showComingSoon,
                    ),
                  ]),
                ),
                SliverToBoxAdapter(child: _buildSectionLabel('Support', theme)),
                SliverToBoxAdapter(
                  child: _buildMenuSection(cs, [
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: _showComingSoon,
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About Foodie',
                      onTap: _showComingSoon,
                    ),
                    _MenuItem(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Seed Database',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SeedScreen()),
                      ),
                    ),
                  ]),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: _buildMenuSection(cs, [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        onTap: _signOut,
                        isDestructive: true,
                      ),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme cs, ThemeData theme, UserModel user) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name, email, phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1B2B1C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: const Color(0xFF9E9E9E)),
                ),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: const Color(0xFF9E9E9E)),
                  ),
                ],
              ],
            ),
          ),

          // Edit button
          GestureDetector(
            onTap: () => _openEditSheet(user),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_outlined, color: cs.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(ColorScheme cs, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatCard(
              label: 'Orders', value: '0', icon: Icons.receipt_long_outlined),
          _VertDivider(),
          _StatCard(
              label: 'Favourites',
              value: '0',
              icon: Icons.favorite_border_rounded),
          _VertDivider(),
          _StatCard(
              label: 'Reviews', value: '0', icon: Icons.star_border_rounded),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800, color: const Color(0xFF1B2B1C)),
      ),
    );
  }

  Widget _buildMenuSection(ColorScheme cs, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                onTap: item.onTap,
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.isDestructive
                        ? const Color(0xFFFFEBEE)
                        : cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon,
                      size: 20,
                      color: item.isDestructive ? cs.error : cs.primary),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color:
                        item.isDestructive ? cs.error : const Color(0xFF1B2B1C),
                  ),
                ),
                trailing: item.isDestructive
                    ? null
                    : Icon(Icons.chevron_right_rounded,
                        color: Colors.grey.shade400),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              if (idx < items.length - 1)
                Divider(height: 1, indent: 68, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: cs.primary, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF1B2B1C),
              )),
          Text(label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              )),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 48,
        color: Colors.grey.shade100,
      );
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final AuthProvider authProvider;
  final UserModel user;

  const _EditProfileSheet({required this.authProvider, required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name cannot be empty',
              style: TextStyle(fontFamily: 'Nunito')),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    final success = await widget.authProvider.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Text('Profile updated!',
              style:
                  TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),

          Text('Edit Profile',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900, color: const Color(0xFF1B2B1C))),
          const SizedBox(height: 6),
          Text('Update your personal information',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF9E9E9E))),
          const SizedBox(height: 24),

          // Name
          _Label('Full Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Your full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 16),

          // Phone
          _Label('Phone Number'),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              hintText: '+27 71 000 0000',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 28),

          // Email (read-only)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    size: 18, color: Colors.grey.shade400),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email (cannot be changed)',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: Colors.grey.shade400)),
                    Text(
                      widget.user.email,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          ListenableBuilder(
            listenable: widget.authProvider,
            builder: (_, __) {
              final loading = widget.authProvider.isLoading;
              return ElevatedButton(
                onPressed: loading ? null : _save,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF3A3A3A),
        ),
      );
}
