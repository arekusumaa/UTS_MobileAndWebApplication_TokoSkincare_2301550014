import '../models/order.dart';

abstract class OrderRepository {
  List<Order> getAllOrders();
  List<Order> getOrdersByUser(String userId);
  Order? getOrderById(String id);
  void createOrder(Order order);
  void updateStatus(String orderId, OrderStatus status);
}
