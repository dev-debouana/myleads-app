import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contacts_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                bottom: 32,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 4,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'RB',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    auth.userName.isEmpty ? 'Régis Bouana' : auth.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.userEmail.isEmpty ? 'regis@debouana.com' : auth.userEmail,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                  ),

                  // Stats
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _statItem('${contacts.totalContacts}', 'Contacts'),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                      _statItem('${contacts.hotLeads}', 'Hot Leads'),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                      _statItem('95%', 'Scan OK'),
                    ],
                  ),
                ],
              ),
            ),

            // Menu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _menuItem(
                    Icons.person,
                    AppStrings.myAccount,
                    AppStrings.myAccountDesc,
                    AppColors.primary.withOpacity(0.08),
                    AppColors.primary,
                    () {},
                  ),
                  _menuItem(
                    Icons.notifications,
                    AppStrings.notifications,
                    AppStrings.notificationsDesc,
                    AppColors.accent.withOpacity(0.1),
                    AppColors.accent,
                    () {},
                  ),
                  _menuItem(
                    Icons.star,
                    AppStrings.subscription,
                    AppStrings.subscriptionDesc,
                    AppColors.warm.withOpacity(0.1),
                    AppColors.warm,
                    () => context.push('/pricing'),
                  ),
                  _menuItem(
                    Icons.cloud_upload,
                    AppStrings.sync,
                    AppStrings.syncDesc,
                    AppColors.success.withOpacity(0.1),
                    AppColors.success,
                    () {},
                  ),
                  _menuItem(
                    Icons.download,
                    AppStrings.export,
                    AppStrings.exportDesc,
                    const Color(0xFF34495E).withOpacity(0.08),
                    const Color(0xFF34495E),
                    () {},
                  ),
                  _menuItem(
                    Icons.settings,
                    AppStrings.settings,
                    AppStrings.settingsDesc,
                    AppColors.cold.withOpacity(0.15),
                    AppColors.cold,
                    () {},
                  ),
                  const SizedBox(height: 8),
                  _menuItem(
                    Icons.logout,
                    AppStrings.logout,
                    AppStrings.logoutDesc,
                    AppColors.hot.withOpacity(0.1),
                    AppColors.hot,
                    () {
                      ref.read(authProvider.notifier).logout();
                      context.go('/login');
                    },
                    isLogout: true,
                  ),
                  const SizedBox(height: 20),
                  // App version
                  Text(
                    'My Leads v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'De Bouana - ${AppStrings.slogan}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isLogout ? AppColors.hot : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
