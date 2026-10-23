import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'appcolors.dart';

abstract final class VeroColors {
  static const background = AppColors.background;
  static const surface = AppColors.surface;
  static const text = AppColors.textDark;
  static const muted = AppColors.textMuted;
  static const primary = AppColors.primaryDark;
  static const primaryBright = AppColors.primary;
  static const primaryLight = AppColors.primaryLight;
  static const border = AppColors.border;
  static const water = AppColors.blueWater;
  static const waterLight = AppColors.blueWaterLight;
  static const gemini = AppColors.purpleAI;
  static const geminiLight = AppColors.purpleAILight;
  static const gold = Color(0xffF59E0B);
}

ThemeData veroTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: VeroColors.primaryBright,
    brightness: brightness,
    surface: dark ? const Color(0xff142437) : VeroColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xff0B1C30)
        : VeroColors.background,
    cardTheme: CardThemeData(
      color: dark ? const Color(0xff142437) : VeroColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: dark ? const Color(0xff29415e) : VeroColors.border,
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xff142437) : VeroColors.surface,
      foregroundColor: dark ? Colors.white : VeroColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );
}

class VeroTopBar extends StatelessWidget {
  const VeroTopBar({super.key, required this.title, this.onMenu});
  final String title;
  final VoidCallback? onMenu;
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VEROEQUILIBRAFIT+',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: VeroColors.primary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notificações',
          ),
          InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(24),
            child: const CircleAvatar(
              backgroundColor: VeroColors.primary,
              child: Icon(Icons.person_outline, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class VeroActionCard extends StatelessWidget {
  const VeroActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: VeroColors.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  color: VeroColors.muted,
                ),
          ],
        ),
      ),
    ),
  );
}

class VeroBottomNavigation extends StatelessWidget {
  const VeroBottomNavigation({super.key, required this.location});
  final String location;
  @override
  Widget build(BuildContext context) {
    const tabs = [
      ('/', 'Início', Icons.home_outlined),
      ('/training', 'Treinos', Icons.fitness_center_outlined),
      ('/nutrition', 'Nutrição', Icons.restaurant_outlined),
      ('/profile', 'Perfil', Icons.account_circle_outlined),
    ];
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: VeroColors.surface,
          border: Border(top: BorderSide(color: VeroColors.border)),
        ),
        child: Row(
          children: tabs.map((tab) {
            final active =
                location == tab.$1 ||
                (tab.$1 != '/' && location.startsWith(tab.$1));
            return Expanded(
              child: Semantics(
                selected: active,
                button: true,
                label: tab.$2,
                child: InkWell(
                  onTap: () => context.go(tab.$1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.$3,
                          color: active ? VeroColors.primary : VeroColors.muted,
                        ),
                        Text(
                          tab.$2,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: active
                                ? VeroColors.primary
                                : VeroColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
