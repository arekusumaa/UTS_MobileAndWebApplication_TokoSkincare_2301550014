import '../models/order.dart';
import '../repositories/order_repository.dart';
import 'mock_data.dart';

class MockOrderSource implements OrderRepository {
  final List<Order> _orders = List.from(MockData.orders);

  @override
  List<Order> getAllOrders() => List.from(_orders);

  @override
  List<Order> getOrdersByUser(String userId) {
    // For mock, return all orders (assume single pelanggan)
    return List.from(_orders);
  }

  @override
  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void createOrder(Order order) {
    _orders.insert(0, order);
  }

  @override
  void updateStatus(String orderId, OrderStatus status) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: status);
    }
  }
}
