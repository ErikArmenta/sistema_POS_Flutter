import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import 'pos_provider.dart';
import '../auth/auth_provider.dart';
import '../../providers/supabase_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessingCode = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessingCode) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessingCode = true);
        
        final errorMsg = await ref.read(posControllerProvider.notifier).scanProduct(code);
        
        if (mounted) {
          if (errorMsg != null) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg), backgroundColor: AppColors.errorRed),
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Producto agregado'), backgroundColor: AppColors.successGreen, duration: Duration(milliseconds: 500)),
            );
          }
        }
        
        // Evitar escanear el mismo código múltiples veces muy rápido
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _isProcessingCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posControllerProvider);
    final total = ref.watch(cartTotalProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de Venta'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (user?.isAdminOrSuperAdmin ?? false)
            IconButton(
              icon: const Icon(Icons.people),
              tooltip: 'Usuarios',
              onPressed: () => context.push('/users'),
            ),
          IconButton(
            icon: const Icon(Icons.inventory_2),
            tooltip: 'Inventario',
            onPressed: () => context.push('/inventory'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Si la pantalla es muy ancha (Web/Escritorio), mostrar lado a lado
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(flex: 1, child: _buildScannerSection()),
                const VerticalDivider(width: 1),
                Expanded(flex: 1, child: _buildCartSection(cart, total)),
              ],
            );
          }
          // Pantalla pequeña (Móvil), mostrar en columna dividida
          return Column(
            children: [
              Expanded(flex: 2, child: _buildScannerSection()),
              Expanded(flex: 3, child: _buildCartSection(cart, total)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScannerSection() {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.successGreen, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            width: 250,
            height: 250,
          ),
          if (_isProcessingCode)
            const Positioned(
              bottom: 20,
              child: Chip(
                label: Text('Procesando...'),
                backgroundColor: AppColors.primaryBlue,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartSection(cart, total) {
    return Container(
      color: AppColors.accentWhite,
      child: Column(
        children: [
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text(
                      'El carrito está vacío',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(item.product.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('\$${item.product.precio.toStringAsFixed(2)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => ref.read(posControllerProvider.notifier).decrementQuantity(item.product.id),
                              ),
                              Text('${item.cantidad}', style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => ref.read(posControllerProvider.notifier).incrementQuantity(item.product.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.errorRed),
                                onPressed: () => ref.read(posControllerProvider.notifier).removeItem(item.product.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.padding),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: cart.isEmpty ? null : () async {
                      final success = await ref.read(posControllerProvider.notifier).processSale();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Venta procesada con éxito'), backgroundColor: AppColors.successGreen),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al procesar la venta'), backgroundColor: AppColors.errorRed),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.successGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.borderRadius)),
                    ),
                    child: const Text('COBRAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
