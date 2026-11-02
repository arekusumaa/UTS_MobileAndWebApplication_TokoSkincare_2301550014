import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primaryLight,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Beranda'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shop_outlined),
          selectedIcon: Icon(Icons.shop),
          label: Text('Produk'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: Text('Keranjang'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Akun'),
        ),
      ],
    );
  }
}
