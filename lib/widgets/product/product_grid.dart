import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product.dart';
import '../common/product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final ValueChanged<Product> onTap;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onTap,
  });

  int _getCrossAxisCount(double width) {
    if (width >= AppConstants.desktopBreakpoint) return 4;
    if (width >= AppConstants.tabletBreakpoint) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(width);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(
          product: products[index],
          onTap: () => onTap(products[index]),
        );
      },
    );
  }
}
