import 'product.dart';

class CartItem {
  final Product product;
  final int cantidad;

  CartItem({
    required this.product,
    this.cantidad = 1,
  });

  double get subtotal => product.precio * cantidad;

  CartItem copyWith({
    Product? product,
    int? cantidad,
  }) {
    return CartItem(
      product: product ?? this.product,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}
