import 'dart:convert';

class UserModel {
  final String dominio;
  final String email;
  final String token;

  UserModel({required this.dominio, required this.email, required this.token});

  Map<String, dynamic> toMap() => {
        'dominio': dominio,
        'email': email,
        'token': token,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        dominio: map['dominio'],
        email: map['email'],
        token: map['token'],
      );

  String toJson() => json.encode(toMap());
}
