import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../providers/supabase_provider.dart';

final posControllerProvider = StateNotifierProvider<PosController, List<CartItem>>((ref) {
  return PosController(ref);
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(posControllerProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

class PosController extends StateNotifier<List<CartItem>> {
  final Ref ref;

  PosController(this.ref) : super([]);

  Future<String?> scanProduct(String barcode) async {
    // 1. Verificar si ya está en el carrito
    final existingIndex = state.indexWhere((item) => item.product.codigoBarras == barcode);
    if (existingIndex >= 0) {
      incrementQuantity(state[existingIndex].product.id);
      return null;
    }

    // 2. Buscar en Supabase
    try {
      final response = await ref.read(supabaseClientProvider)
          .from('inventario')
          .select()
          .eq('codigo_barras', barcode)
          .maybeSingle();

      if (response != null) {
        final product = Product.fromJson(response);
        state = [...state, CartItem(product: product, cantidad: 1)];
        return null;
      } else {
        return 'Producto no encontrado en inventario';
      }
    } catch (e) {
      // Manejar error (por ejemplo, producto no encontrado)
      print('Error al escanear: $e');
      return 'Error al buscar el producto';
    }
  }

  void incrementQuantity(String productId) {
    state = state.map((item) {
      if (item.product.id == productId) {
        // Podríamos verificar el stock máximo aquí
        if (item.cantidad < item.product.stock) {
          return item.copyWith(cantidad: item.cantidad + 1);
        }
      }
      return item;
    }).toList();
  }

  void decrementQuantity(String productId) {
    state = state.map((item) {
      if (item.product.id == productId && item.cantidad > 1) {
        return item.copyWith(cantidad: item.cantidad - 1);
      }
      return item;
    }).toList();
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  Future<bool> processSale() async {
    if (state.isEmpty) return false;

    final supabase = ref.read(supabaseClientProvider);
    final total = state.fold(0.0, (sum, item) => sum + item.subtotal);

    try {
      // Utilizar una función RPC o hacer las consultas necesarias
      // Insertar en tabla ventas
      final saleResponse = await supabase.from('ventas').insert({
        'total': total,
        'productos': state.map((e) => {
          'id': e.product.id,
          'cantidad': e.cantidad,
          'precio': e.product.precio
        }).toList(),
      }).select().single();

      // Actualizar stock en la tabla inventario
      for (final item in state) {
        final newStock = item.product.stock - item.cantidad;
        await supabase.from('inventario').update({
          'stock': newStock
        }).eq('id', item.product.id);
      }

      // Limpiar carrito
      state = [];
      return true;
    } catch (e) {
      print('Error procesando venta: $e');
      return false;
    }
  }
}
