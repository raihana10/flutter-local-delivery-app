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
    int safeInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }
    return User(
      id: safeInt(json['id_user'] ?? json['id']),
      email: (json['email'] ?? '').toString(),
      nom: (json['nom'] ?? '').toString(),
      numTl: json['num_tl']?.toString(),
      role: UserRole.fromString(json['role']?.toString() ?? 'client'),
      estActif: json['est_actif'] == true || json['est_actif'] == 1,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
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
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] is Map<String, dynamic> ? User.fromJson(json['user']) : null,
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
  final String? vehicleType; // For livreur
  final List<String>? documents; // For livreur

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
    this.vehicleType,
    this.documents,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'nom': nom,
      'num_tl': numTl,
      'role': role.value,
      'sexe': sexe,
      'date_naissance':
          dateNaissance?.toIso8601String().split('T')[0], // Format YYYY-MM-DD
      'cni': cni,
      'business_type': businessType,
      'business_description': businessDescription,
      'vehicle_type': vehicleType,
      'documents': documents,
    };
  }
}

class Livreur {
  final int id;
  final int idUser;
  final String? vehicleType;
  final List<String>? documents;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  const Livreur({
    required this.id,
    required this.idUser,
    this.vehicleType,
    this.documents,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Livreur.fromJson(Map<String, dynamic> json) {
    return Livreur(
      id: json['id_livreur'] ?? 0,
      idUser: json['id_user'] ?? 0,
      vehicleType: json['vehicle_type'],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] is Map<String, dynamic> ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_livreur': id,
      'id_user': idUser,
      'vehicle_type': vehicleType,
      'documents': documents,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user?.toJson(),
    };
  }

  Livreur copyWith({
    int? id,
    int? idUser,
    String? vehicleType,
    List<String>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
  }) {
    return Livreur(
      id: id ?? this.id,
      idUser: idUser ?? this.idUser,
      vehicleType: vehicleType ?? this.vehicleType,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
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
