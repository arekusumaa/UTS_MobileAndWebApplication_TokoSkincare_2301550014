import 'package:flutter/material.dart';
import '../data/models/order.dart';
import '../data/models/cart_item.dart';
import '../data/data_sources/mock_order_source.dart';
import '../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider({OrderRepository? source, Listenable? sync})
      : _orderSource = source ?? MockOrderSource(),
        _sync = sync {
    _orders = _orderSource.getAllOrders();
    _sync?.addListener(_onDataBerubah);
  }

  final OrderRepository _orderSource;
  final Listenable? _sync;

  List<Order> _orders = [];
  Order? _lastOrder;

  List<Order> get orders => _orders;
  Order? get lastOrder => _lastOrder;

  /// Snapshot Firestore bisa datang dari admin yang mengubah status pesanan.
  void _onDataBerubah() {
    _orders = _orderSource.getAllOrders();
    final id = _lastOrder?.id;
    if (id != null) {
      for (final o in _orders) {
        if (o.id == id) _lastOrder = o;
      }
    }
    notifyListeners();
  }

  void createOrder({
    required List<CartItem> items,
    required int total,
    required String alamat,
    String? namaPenerima,
    String? telepon,
  }) {
    final now = DateTime.now();
    // Timestamp milidetik ditambahkan supaya dua checkout berurutan tidak
    // menghasilkan id dokumen yang sama (Firestore menimpa dokumen).
    final orderId =
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';

    final order = Order(
      id: orderId,
      items: List.from(items),
      total: total,
      status: OrderStatus.menunggu,
      tanggal: now,
      alamat: alamat,
      namaPenerima: namaPenerima,
      telepon: telepon,
    );

    _orderSource.createOrder(order);
    _orders = _orderSource.getAllOrders();
    _lastOrder = order;
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    _orderSource.updateStatus(orderId, status);
    _orders = _orderSource.getAllOrders();
    if (_lastOrder?.id == orderId) {
      _lastOrder = _lastOrder!.copyWith(status: status);
    }
    notifyListeners();
  }

  List<Order> getOrdersByUser(String userId) {
    return _orderSource.getOrdersByUser(userId);
  }

  Order? getOrderById(String id) {
    return _orderSource.getOrderById(id);
  }

  @override
  void dispose() {
    _sync?.removeListener(_onDataBerubah);
    super.dispose();
  }
}
