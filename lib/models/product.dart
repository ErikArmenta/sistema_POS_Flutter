class Product {
  final String id;
  final String nombre;
  final String codigoBarras;
  final double precio;
  final int stock;

  Product({
    required this.id,
    required this.nombre,
    required this.codigoBarras,
    required this.precio,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigoBarras: json['codigo_barras'] as String,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo_barras': codigoBarras,
      'precio': precio,
      'stock': stock,
    };
  }

  Product copyWith({
    String? id,
    String? nombre,
    String? codigoBarras,
    double? precio,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
    );
  }
}
