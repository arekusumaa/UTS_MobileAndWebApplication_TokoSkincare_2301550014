import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/app_bottom_nav.dart';
import '../../widgets/common/app_sidebar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/cart/cart_item_tile.dart';

class KeranjangScreen extends StatelessWidget {
  const KeranjangScreen({super.key});

  void _navigateTo(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/beranda');
        break;
      case 1:
        context.go('/produk');
        break;
      case 2:
        break;
      case 3:
        context.go('/akun');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= AppConstants.mobileBreakpoint;

    final content = cart.isEmpty
        ? EmptyState(
            title: 'Keranjang masih kosong',
            message: 'Pilih produk skincare favoritmu dan mulai belanja!',
            icon: Icons.shopping_cart_outlined,
            buttonText: 'Mulai Belanja',
            onButtonPressed: () => context.go('/produk'),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.margin),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CartItemTile(
                        cartItem: item,
                        onIncrement: () => cart.incrementQuantity(item.product.id),
                        onDecrement: () => cart.decrementQuantity(item.product.id),
                        onRemove: () {
                          cart.removeFromCart(item.product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.product.nama} dihapus dari keranjang'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              // Total bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Total (${cart.totalItems} item)', style: AppTextStyles.isi),
                          const Spacer(),
                          Text(
                            cart.totalFormatted,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Checkout',
                        icon: Icons.shopping_cart,
                        onPressed: () => context.go('/checkout'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

    if (isWeb) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(currentIndex: 2, onTap: (i) => _navigateTo(context, i)),
            Expanded(
              child: Scaffold(
                appBar: AppBar(title: const Text('Keranjang')),
                body: content,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: content,
      bottomNavigationBar: cart.isEmpty
          ? AppBottomNav(currentIndex: 2, onTap: (i) => _navigateTo(context, i))
          : null,
    );
  }
}
