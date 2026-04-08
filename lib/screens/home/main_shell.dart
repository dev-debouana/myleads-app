import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/navigation_provider.dart';
import '../home/home_screen.dart';
import '../contacts/contacts_screen.dart';
import '../scan/scan_screen.dart';
import '../reminders/reminders_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static final _screens = [
    const HomeScreen(),
    const ContactsScreen(),
    const ScanScreen(),
    const RemindersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentTab,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, currentTab),
      extendBody: true,
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int current) {
    return Container(
      height: 88 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Home', 0, current, ref),
            _navItem(Icons.people_rounded, 'Contacts', 1, current, ref),
            _scanButton(ref),
            _navItem(Icons.access_time_rounded, 'Rappels', 3, current, ref),
            _navItem(Icons.person_rounded, 'Profil', 4, current, ref),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, int current, WidgetRef ref) {
    final isActive = current == index;
    return GestureDetector(
      onTap: () => ref.read(currentTabProvider.notifier).state = index,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.accent : AppColors.textLight,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.accent : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanButton(WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(currentTabProvider.notifier).state = 2,
      child: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}
