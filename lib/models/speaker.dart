import 'package:uuid/uuid.dart';

class Speaker {
  final String id;
  final String organizationId;
  final String name;
  final String? title;
  final String? bio;
  final String? imageUrl;
  final String? email;
  final String? phone;
  final String? company;
  final DateTime createdAt;
  final DateTime updatedAt;

  Speaker({
    String? id,
    required this.organizationId,
    required this.name,
    this.title,
    this.bio,
    this.imageUrl,
    this.email,
    this.phone,
    this.company,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Speaker.fromJson(Map<String, dynamic> json) {
    return Speaker(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      title: json['title'],
      bio: json['bio'],
      imageUrl: json['image_url'],
      email: json['email'],
      phone: json['phone'],
      company: json['company'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'title': title,
      'bio': bio,
      'image_url': imageUrl,
      'email': email,
      'phone': phone,
      'company': company,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
