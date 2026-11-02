import '../models/product.dart';

abstract class ProductRepository {
  List<Product> getAllProducts();
  Product? getProductById(String id);
  List<Product> getByKategori(String kategori);
  List<Product> searchProducts(String query);
  List<Product> filterByTipeKulit(String tipeKulit);
  List<Product> getRekomendasi(String tipeKulit);
  List<Product> getStokMenipis();
  void addProduct(Product product);
  void updateProduct(Product product);
  void deleteProduct(String id);
  void reduceStok(String id, int amount);
}
