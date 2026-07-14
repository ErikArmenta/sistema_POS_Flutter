import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../providers/supabase_provider.dart';
import '../../models/app_user.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(supabaseClientProvider).from('profiles').select();
      setState(() {
        _users = (response as List).map((e) => AppUser.fromJson(e)).toList();
      });
    } catch (e) {
      print('Error al cargar usuarios: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeRole(AppUser user, UserRole newRole) async {
    try {
      await ref.read(supabaseClientProvider)
          .from('profiles')
          .update({'role': newRole == UserRole.superAdmin ? 'super_admin' : (newRole == UserRole.administrador ? 'administrador' : 'despachador')})
          .eq('id', user.id);
      await _loadUsers();
    } catch (e) {
      print('Error actualizando rol: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(AppConstants.padding),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user.email, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${user.id}'),
                    trailing: DropdownButton<UserRole>(
                      value: user.role,
                      onChanged: (UserRole? newValue) {
                        if (newValue != null) {
                          _changeRole(user, newValue);
                        }
                      },
                      items: UserRole.values.map<DropdownMenuItem<UserRole>>((UserRole value) {
                        return DropdownMenuItem<UserRole>(
                          value: value,
                          child: Text(value.name),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
