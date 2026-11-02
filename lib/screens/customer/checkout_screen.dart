import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/cart/order_summary.dart';

enum PaymentMethod { transferBank, cod, ewallet }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();
  final _alamatController = TextEditingController();
  PaymentMethod _payment = PaymentMethod.transferBank;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _namaController.text = auth.currentUser?.nama ?? '';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _handleCheckout() {
    if (_formKey.currentState?.validate() ?? false) {
      final cart = context.read<CartProvider>();
      final orderProvider = context.read<OrderProvider>();
      final productProvider = context.read<ProductProvider>();

      orderProvider.createOrder(
        items: cart.items,
        total: cart.totalHarga + 10000,
        alamat: _alamatController.text.trim(),
        namaPenerima: _namaController.text.trim(),
        telepon: _teleponController.text.trim(),
      );

      // Reduce stock
      for (final item in cart.items) {
        productProvider.reduceStok(item.product.id, item.quantity);
      }

      cart.clearCart();

      context.go('/status-pesanan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= AppConstants.tabletBreakpoint;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              const Text('Keranjang kosong', style: AppTextStyles.subjudul),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/produk'),
                child: const Text('Mulai Belanja'),
              ),
            ],
          ),
        ),
      );
    }

    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alamat Pengiriman', style: AppTextStyles.subjudul),
          const SizedBox(height: 12),
          TextFormField(
            controller: _namaController,
            decoration: const InputDecoration(
              labelText: 'Nama Penerima',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => Validators.required(v, fieldName: 'Nama'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _teleponController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) => Validators.numeric(v, fieldName: 'Nomor Telepon'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alamatController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alamat Lengkap',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            validator: (v) => Validators.requiredMinLength(
              v,
              minLength: 10,
              fieldName: 'Alamat',
            ),
          ),
          const SizedBox(height: 24),
          Text('Metode Pembayaran (Simulasi)', style: AppTextStyles.subjudul),
          const SizedBox(height: 8),
          ...PaymentMethod.values.map((method) {
            return RadioListTile<PaymentMethod>(
              value: method,
              groupValue: _payment,
              onChanged: (v) => setState(() => _payment = v!),
              title: Text(_paymentLabel(method)),
              subtitle: Text(_paymentDesc(method), style: AppTextStyles.caption),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              dense: true,
            );
          }),
        ],
      ),
    );

    final summaryContent = OrderSummary(
      items: cart.items,
      total: cart.totalHarga,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.margin),
        child: isWeb
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: formContent),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: summaryContent),
                ],
              )
            : Column(
                children: [
                  formContent,
                  const SizedBox(height: 24),
                  summaryContent,
                ],
              ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: CustomButton(
            label: 'Buat Pesanan',
            icon: Icons.check_circle_outline,
            onPressed: _handleCheckout,
          ),
        ),
      ),
    );
  }

  String _paymentLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.transferBank:
        return 'Transfer Bank';
      case PaymentMethod.cod:
        return 'Bayar di Tempat (COD)';
      case PaymentMethod.ewallet:
        return 'E-Wallet';
    }
  }

  String _paymentDesc(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.transferBank:
        return 'BCA, BNI, Mandiri — simulasi, tidak ada pembayaran nyata';
      case PaymentMethod.cod:
        return 'Bayar tunai saat pesanan tiba';
      case PaymentMethod.ewallet:
        return 'GoPay, OVO, DANA — simulasi';
    }
  }
}
