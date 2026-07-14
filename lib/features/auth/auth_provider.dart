import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_user.dart';
import '../../providers/supabase_provider.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(supabaseClientProvider).auth.currentUser;
  if (user == null) return null;

  // Fetch the role from the 'users_roles' or 'users' table
  // Assuming a table 'profiles' with 'id' and 'role'
  try {
    final response = await ref
        .watch(supabaseClientProvider)
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    
    return AppUser.fromJson(response);
  } catch (e) {
    // Si no hay perfil, podemos crear uno basico o regresar nulo/error
    // Para propositos de este MVP, lo devolveremos como despachador.
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      role: UserRole.despachador,
    );
  }
});
