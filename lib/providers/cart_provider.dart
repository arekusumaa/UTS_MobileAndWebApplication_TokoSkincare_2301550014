import 'package:flutter/material.dart';
import '../data/models/cart_item.dart';
import '../data/models/product.dart';
import '../data/data_sources/mock_cart_source.dart';
import '../data/repositories/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  /// Keranjang kini disimpan ke `carts/{uid}/items/{productId}` (Firestore)
  /// atau ke memori (mock). Setiap perubahan langsung diteruskan ke repository,
  /// sehingga isi keranjang tidak hilang saat browser di-refresh atau pindah
  /// perangkat.
  CartProvider({CartRepository? source, Listenable? sync})
      : _source = source ?? MockCartSource(),
        _sync = sync {
    _items.addAll(_source.getCart());
    _sync?.addListener(_onDataBerubah);
  }

  final CartRepository _source;
  final Listenable? _sync;
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  int get totalHarga {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  String get totalFormatted => 'Rp ${totalHarga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  void _simpan() => _source.saveCart(List<CartItem>.from(_items));

  /// Snapshot Firestore berubah (perangkat lain / setelah login). Hanya
  /// membaca cache, tidak menulis balik, sehingga tidak terjadi loop.
  void _onDataBerubah() {
    _items
      ..clear()
      ..addAll(_source.getCart());
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIdx = _items.indexWhere((item) => item.product.id == product.id);
    if (existingIdx >= 0) {
      _items[existingIdx] = _items[existingIdx].copyWith(
        quantity: _items[existingIdx].quantity + quantity,
      );
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _simpan();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _simpan();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
      _simpan();
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx >= 0) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + 1);
      _simpan();
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity - 1);
      } else {
        removeFromCart(productId);
        return;
      }
      _simpan();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _simpan();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    final idx = _items.indexWhere((item) => item.product.id == productId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }

  @override
  void dispose() {
    _sync?.removeListener(_onDataBerubah);
    super.dispose();
  }
}
