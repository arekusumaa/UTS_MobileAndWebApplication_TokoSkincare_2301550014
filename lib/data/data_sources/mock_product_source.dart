import '../models/product.dart';
import '../repositories/product_repository.dart';
import 'mock_data.dart';

class MockProductSource implements ProductRepository {
  final List<Product> _products = List.from(MockData.products);

  @override
  List<Product> getAllProducts() => List.from(_products);

  @override
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Product> getByKategori(String kategori) {
    if (kategori == 'Semua' || kategori.isEmpty) return List.from(_products);
    return _products.where((p) => p.kategori == kategori).toList();
  }

  @override
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return List.from(_products);
    final q = query.toLowerCase();
    return _products.where((p) {
      return p.nama.toLowerCase().contains(q) ||
          p.kategori.toLowerCase().contains(q) ||
          p.kandunganAktif.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @override
  List<Product> filterByTipeKulit(String tipeKulit) {
    if (tipeKulit.isEmpty || tipeKulit == 'Semua') return List.from(_products);
    return _products.where((p) => p.tipeKulitCocok.contains(tipeKulit)).toList();
  }

  @override
  List<Product> getRekomendasi(String tipeKulit) {
    if (tipeKulit.isEmpty) {
      return _products.where((p) => !p.isStokHabis).take(4).toList();
    }
    final filtered = _products
        .where((p) => p.tipeKulitCocok.contains(tipeKulit) && !p.isStokHabis)
        .toList();
    if (filtered.isEmpty) {
      return _products.where((p) => !p.isStokHabis).take(4).toList();
    }
    return filtered.take(4).toList();
  }

  @override
  List<Product> getStokMenipis() {
    return _products.where((p) => p.stok <= 5).toList();
  }

  @override
  void addProduct(Product product) {
    _products.add(product);
  }

  @override
  void updateProduct(Product product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
    }
  }

  @override
  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  void reduceStok(String id, int amount) {
    final idx = _products.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final p = _products[idx];
      final newStok = (p.stok - amount).clamp(0, 999999);
      _products[idx] = p.copyWith(stok: newStok);
    }
  }
}
