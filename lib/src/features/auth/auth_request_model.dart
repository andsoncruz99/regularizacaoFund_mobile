import 'dart:convert';

class AuthRequestModel {
  String email;
  String password;
  String dominio;

  AuthRequestModel({
    required this.email,
    required this.password,
    required this.dominio,
  });

  AuthRequestModel copyWith({
    String? email,
    String? password,
    String? dominio,
  }) =>
      AuthRequestModel(
        email: email ?? this.email,
        password: password ?? this.password,
        dominio: dominio ?? this.dominio,
      );

  factory AuthRequestModel.fromMap(Map<String, dynamic> map) =>
      AuthRequestModel(
        email: map['email'],
        password: map['password'],
        dominio: map['dominio'],
      );

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {'usuario': email, 'senha': password};

  factory AuthRequestModel.fromJson(String source) =>
      AuthRequestModel.fromJson(json.decode(source));
}
