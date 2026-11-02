import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/order_provider.dart';
import '../../data/models/order.dart';

class KelolaPesananScreen extends StatelessWidget {
  const KelolaPesananScreen({super.key});

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.menunggu:
        return AppColors.warning;
      case OrderStatus.diproses:
        return Colors.blue;
      case OrderStatus.dikirim:
        return Colors.purple;
      case OrderStatus.selesai:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final orders = orderProvider.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: orders.isEmpty
          ? const Center(child: Text('Belum ada pesanan masuk'))
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.margin),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: _statusColor(order.status).withOpacity(0.15),
                      child: Icon(Icons.receipt, color: _statusColor(order.status), size: 20),
                    ),
                    title: Text(order.id,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text('${order.tanggalFormatted} - ${order.namaPenerima ?? "-"}',
                        style: AppTextStyles.caption),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(order.status),
                        ),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Penerima: ${order.namaPenerima ?? "-"}', style: AppTextStyles.keterangan),
                            Text('Telepon: ${order.telepon ?? "-"}', style: AppTextStyles.keterangan),
                            Text('Alamat: ${order.alamat}', style: AppTextStyles.keterangan),
                            const SizedBox(height: 8),
                            ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text('${item.product.nama} x${item.quantity}',
                                            style: AppTextStyles.keterangan),
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
                            Row(
                              children: [
                                const Text('Total'),
                                const Spacer(),
                                Text(order.totalFormatted,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500, color: AppColors.primary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Ubah Status:', style: AppTextStyles.subjudul),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: OrderStatus.values.map((status) {
                                return ChoiceChip(
                                  label: Text(status.label),
                                  selected: order.status == status,
                                  onSelected: (_) {
                                    orderProvider.updateOrderStatus(order.id, status);
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Status diubah ke: ${status.label}')),
                                    );
                                  },
                                  selectedColor: _statusColor(status),
                                  labelStyle: TextStyle(
                                    color: order.status == status
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
