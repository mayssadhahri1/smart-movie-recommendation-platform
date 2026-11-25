class UserModel {
  final int id;
  final String nom;
  final String email;
  final String role;
  final String token;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('UserModel JSON: $json');
    return UserModel(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? '',
    );
  }
}