import 'dart:convert';

class OmieAccount {
  final String id;
  final String name;
  final String appKey;
  final String appSecret;
  final String? cnpj;

  OmieAccount({
    required this.id,
    required this.name,
    required this.appKey,
    required this.appSecret,
    this.cnpj,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'appKey': appKey,
      'appSecret': appSecret,
      'cnpj': cnpj,
    };
  }

  factory OmieAccount.fromMap(Map<String, dynamic> map) {
    return OmieAccount(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      appKey: map['appKey'] ?? '',
      appSecret: map['appSecret'] ?? '',
      cnpj: map['cnpj'],
    );
  }

  String toJson() => json.encode(toMap());

  factory OmieAccount.fromJson(String source) => OmieAccount.fromMap(json.decode(source));
}
