enum UserRole {
  client('client'),
  livreur('livreur'), 
  business('business'),
  superAdmin('super_admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}

class User {
  final int id;
  final String email;
  final String nom;
  final String? numTl;
  final UserRole role;
  final bool estActif;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.nom,
    this.numTl,
    required this.role,
    required this.estActif,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id_user'] ?? json['id'] ?? 0,
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      numTl: json['num_tl'],
      role: UserRole.fromString(json['role'] ?? 'client'),
      estActif: json['est_actif'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_user': id,
      'email': email,
      'nom': nom,
      'num_tl': numTl,
      'role': role.value,
      'est_actif': estActif,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? nom,
    String? numTl,
    UserRole? role,
    bool? estActif,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nom: nom ?? this.nom,
      numTl: numTl ?? this.numTl,
      role: role ?? this.role,
      estActif: estActif ?? this.estActif,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Client {
  final int id;
  final int idUser;
  final String? sexe;
  final DateTime? dateNaissance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  const Client({
    required this.id,
    required this.idUser,
    this.sexe,
    this.dateNaissance,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id_client'] ?? 0,
      idUser: json['id_user'] ?? 0,
      sexe: json['sexe'],
      dateNaissance: json['date_naissance'] != null 
          ? DateTime.parse(json['date_naissance']) 
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_client': id,
      'id_user': idUser,
      'sexe': sexe,
      'date_naissance': dateNaissance?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String nom;
  final String? numTl;
  final UserRole role;
  final String? sexe;
  final DateTime? dateNaissance;
  // Additional fields for role-specific data
  final String? cni; // For livreur
  final String? businessType; // For business
  final String? businessDescription; // For business

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.nom,
    this.numTl,
    required this.role,
    this.sexe,
    this.dateNaissance,
    this.cni,
    this.businessType,
    this.businessDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nom': nom,
      'num_tl': numTl,
      'role': role.value,
      'sexe': sexe,
      'date_naissance': dateNaissance?.toIso8601String().split('T')[0], // Format YYYY-MM-DD
      'cni': cni,
      'business_type': businessType,
      'business_description': businessDescription,
    };
  }
}

class AuthResponse {
  final User user;
  final String token;
  final String? message;

  const AuthResponse({
    required this.user,
    required this.token,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
      message: json['message'],
    );
  }
}
