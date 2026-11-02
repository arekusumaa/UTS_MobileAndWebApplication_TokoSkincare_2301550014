import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/empty_state.dart';
import '../../data/models/order.dart';

class StatusPesananScreen extends StatelessWidget {
  const StatusPesananScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.lastOrder;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Status Pesanan')),
        body: EmptyState(
          title: 'Belum ada pesanan',
          message: 'Pesanan Anda akan muncul di sini setelah checkout',
          icon: Icons.receipt_long_outlined,
          buttonText: 'Kembali ke Produk',
          onButtonPressed: () => context.go('/produk'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pesanan'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.margin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: AppColors.successLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.success, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pesanan Berhasil Dibuat!', style: AppTextStyles.judul),
                  const SizedBox(height: 4),
                  Text('Nomor: ${order.id}', style: AppTextStyles.keterangan),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status tracker
            _buildStatusTracker(order.status),
            const SizedBox(height: 24),

            // Order summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detail Pesanan', style: AppTextStyles.subjudul),
                  const SizedBox(height: 12),
                  Text('Tanggal: ${order.tanggalFormatted}', style: AppTextStyles.keterangan),
                  const SizedBox(height: 4),
                  Text('Penerima: ${order.namaPenerima ?? '-'}', style: AppTextStyles.keterangan),
                  const SizedBox(height: 4),
                  Text('Alamat: ${order.alamat}', style: AppTextStyles.keterangan),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.product.nama} x${item.quantity}',
                                style: AppTextStyles.keterangan,
                              ),
                            ),
                            Text(
                              'Rp ${(item.subtotal).toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (m) => '${m[1]}.',
                                  )}',
                              style: AppTextStyles.keterangan,
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Total', style: AppTextStyles.subjudul),
                      const Spacer(),
                      Text(
                        order.totalFormatted,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            CustomButton(
              label: 'Kembali ke Beranda',
              icon: Icons.home,
              onPressed: () => context.go('/beranda'),
            ),
            const SizedBox(height: 12),
            CustomButton(
              label: 'Lihat Riwayat Pesanan',
              type: ButtonType.secondary,
              onPressed: () => context.go('/riwayat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTracker(OrderStatus currentStatus) {
    final statuses = OrderStatus.values;
    final currentIdx = statuses.indexOf(currentStatus);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Pengiriman', style: AppTextStyles.subjudul),
          const SizedBox(height: 16),
          Row(
            children: statuses.asMap().entries.map((entry) {
              final idx = entry.key;
              final status = entry.value;
              final isDone = idx <= currentIdx;
              final isCurrent = idx == currentIdx;

              Color color;
              if (isDone) {
                color = AppColors.success;
              } else {
                color = AppColors.textTertiary;
              }

              return Expanded(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone ? color : AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDone ? color : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isDone
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400,
                            color: isDone ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    if (idx < statuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 20),
                          color: idx < currentIdx ? AppColors.success : AppColors.border,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
