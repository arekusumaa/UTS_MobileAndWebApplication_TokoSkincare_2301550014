import 'package:flutter/material.dart';
import '../data/models/order.dart';
import '../data/models/cart_item.dart';
import '../data/data_sources/mock_order_source.dart';

class OrderProvider extends ChangeNotifier {
  final MockOrderSource _orderSource = MockOrderSource();

  List<Order> _orders = [];
  Order? _lastOrder;

  List<Order> get orders => _orders;
  Order? get lastOrder => _lastOrder;

  OrderProvider() {
    _orders = _orderSource.getAllOrders();
  }

  void createOrder({
    required List<CartItem> items,
    required int total,
    required String alamat,
    String? namaPenerima,
    String? telepon,
  }) {
    final now = DateTime.now();
    final orderId =
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(orders.length + 1).toString().padLeft(3, '0')}';

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
}
