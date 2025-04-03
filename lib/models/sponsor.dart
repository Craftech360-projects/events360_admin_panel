import 'package:uuid/uuid.dart';

class Sponsor {
  final String id;
  final String organizationId;
  final String name;
  final String? logoUrl;
  final String? website;
  final String? description;
  final String? sponsorshipLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Sponsor({
    String? id,
    required this.organizationId,
    required this.name,
    this.logoUrl,
    this.website,
    this.description,
    this.sponsorshipLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Sponsor.fromJson(Map<String, dynamic> json) {
    return Sponsor(
      id: json['id'],
      organizationId: json['organization_id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      website: json['website'],
      description: json['description'],
      sponsorshipLevel: json['sponsorship_level'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'name': name,
      'logo_url': logoUrl,
      'website': website,
      'description': description,
      'sponsorship_level': sponsorshipLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
