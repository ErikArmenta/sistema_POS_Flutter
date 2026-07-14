enum UserRole {
  superAdmin,
  administrador,
  despachador,
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole;
    switch (json['role']) {
      case 'super_admin':
        parsedRole = UserRole.superAdmin;
        break;
      case 'administrador':
        parsedRole = UserRole.administrador;
        break;
      case 'despachador':
      default:
        parsedRole = UserRole.despachador;
        break;
    }

    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: parsedRole,
    );
  }
  
  Map<String, dynamic> toJson() {
    String roleString;
    switch (role) {
      case UserRole.superAdmin:
        roleString = 'super_admin';
        break;
      case UserRole.administrador:
        roleString = 'administrador';
        break;
      case UserRole.despachador:
        roleString = 'despachador';
        break;
    }
    return {
      'id': id,
      'email': email,
      'role': roleString,
    };
  }

  bool get isAdminOrSuperAdmin =>
      role == UserRole.superAdmin || role == UserRole.administrador;
}
