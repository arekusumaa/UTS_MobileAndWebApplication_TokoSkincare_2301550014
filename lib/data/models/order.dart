import 'cart_item.dart';

enum OrderStatus {
  menunggu('Menunggu'),
  diproses('Diproses'),
  dikirim('Dikirim'),
  selesai('Selesai');

  final String label;
  const OrderStatus(this.label);
}

class Order {
  final String id;
  final List<CartItem> items;
  final int total;
  final OrderStatus status;
  final DateTime tanggal;
  final String alamat;
  final String? namaPenerima;
  final String? telepon;

  const Order({
    required this.id,
    required this.items,
    required this.total,
    required this.status,
    required this.tanggal,
    required this.alamat,
    this.namaPenerima,
    this.telepon,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get tanggalFormatted {
    final d = tanggal;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get totalFormatted => 'Rp ${total.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  Order copyWith({
    String? id,
    List<CartItem>? items,
    int? total,
    OrderStatus? status,
    DateTime? tanggal,
    String? alamat,
    String? namaPenerima,
    String? telepon,
  }) {
    return Order(
      id: id ?? this.id,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      tanggal: tanggal ?? this.tanggal,
      alamat: alamat ?? this.alamat,
      namaPenerima: namaPenerima ?? this.namaPenerima,
      telepon: telepon ?? this.telepon,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'status': status.name,
      'tanggal': tanggal.toIso8601String(),
      'alamat': alamat,
      'namaPenerima': namaPenerima,
      'telepon': telepon,
    };
  }
}
