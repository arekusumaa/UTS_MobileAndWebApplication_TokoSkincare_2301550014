import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order.dart';
import '../../services/layanan_firestore.dart';
import '../../widgets/common/stream_keadaan.dart';

/// Padanan halaman "Reservasi Saya" pada modul Minggu 10.
///
/// Sumber data BUKAN lagi `Provider.orders`, melainkan
/// `LayananToko.streamPesananSaya()` yang memakai
/// `.where('uid', isEqualTo: uid).snapshots()`. Karena itu:
///  * tiap pengguna hanya melihat pesanannya sendiri,
///  * perubahan status oleh admin langsung tampil tanpa refresh,
///  * data tetap ada setelah F5 (berasal dari server, bukan memori).
class RiwayatPesananScreen extends StatefulWidget {
  const RiwayatPesananScreen({super.key, this.layanan});

  /// Injeksi untuk widget test: `LayananMemori()` tanpa koneksi Firebase.
  final LayananToko? layanan;

  @override
  State<RiwayatPesananScreen> createState() => _RiwayatPesananScreenState();
}

class _RiwayatPesananScreenState extends State<RiwayatPesananScreen> {
  Stream<List<Order>>? _streamPesanan;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dibuat sekali: kalau dibuat di build(), StreamBuilder berlangganan
    // ulang setiap rebuild dan sempat menampilkan loading berkedip.
    _streamPesanan ??= (widget.layanan ?? context.read<LayananToko>())
        .streamPesananSaya();
  }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: StreamKeadaan<List<Order>>(
        stream: _streamPesanan ?? Stream.value(const <Order>[]),
        isEmpty: (daftar) => daftar.isEmpty,
        judulKosong: 'Belum ada pesanan',
        pesanKosong: 'Pesanan Anda akan muncul di sini setelah checkout',
        ikonKosong: Icons.receipt_long_outlined,
        builder: (context, orders) => ListView.builder(
          padding: const EdgeInsets.all(AppConstants.margin),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.backgroundSecondary,
                  child: const Icon(Icons.receipt_outlined,
                      color: AppColors.primary),
                ),
                title: Text(order.id,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                subtitle: Text(
                    '${order.tanggalFormatted} - ${order.itemCount} item',
                    style: AppTextStyles.caption),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(order.totalFormatted,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor(order.status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.status.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(order.status),
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Penerima: ${order.namaPenerima ?? '-'}',
                            style: AppTextStyles.keterangan),
                        Text('Telepon: ${order.telepon ?? '-'}',
                            style: AppTextStyles.keterangan),
                        Text('Alamat: ${order.alamat}',
                            style: AppTextStyles.keterangan),
                        const Divider(height: 16),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        '${item.product.nama} x${item.quantity}',
                                        style: AppTextStyles.keterangan),
                                  ),
                                  Text(
                                    'Rp ${item.subtotal.toString().replaceAllMapped(
                                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                          (m) => '${m[1]}.',
                                        )}',
                                    style: AppTextStyles.keterangan,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
