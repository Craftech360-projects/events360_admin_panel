import 'package:uuid/uuid.dart';

class Organization {
  final String id;
  final String? username;
  final String? bio;
  final String? logoUrl;
  final String? contactEmail;
  final String? contactPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? website;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    String? id,
    this.username,
    this.bio,
    this.logoUrl,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.website,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'],
      username: json['username'],
      bio: json['bio'],
      logoUrl: json['logo_url'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      website: json['website'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'bio': bio,
      'logo_url': logoUrl,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'website': website,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
