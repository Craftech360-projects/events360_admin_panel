import 'package:uuid/uuid.dart';

class Member {
  final String id;
  final String? authId;
  final String organizationId;
  final String roleId;
  final String? userName;
  final String email;
  final String? profileImageUrl;
  final bool isActive;
  final String? invitationToken;
  final DateTime? invitationSentAt;
  final DateTime? invitationAcceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    String? id,
    this.authId,
    required this.organizationId,
    required this.roleId,
    this.userName,
    required this.email,
    this.profileImageUrl,
    this.isActive = true,
    this.invitationToken,
    this.invitationSentAt,
    this.invitationAcceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      authId: json['auth_id'],
      organizationId: json['organization_id'],
      roleId: json['role_id'],
      userName: json['username'],
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
      isActive: json['is_active'] ?? true,
      invitationToken: json['invitation_token'],
      invitationSentAt: json['invitation_sent_at'] != null
          ? DateTime.parse(json['invitation_sent_at'])
          : null,
      invitationAcceptedAt: json['invitation_accepted_at'] != null
          ? DateTime.parse(json['invitation_accepted_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'organization_id': organizationId,
      'role_id': roleId,
      'username': userName,
      'email': email,
      'profile_image_url': profileImageUrl,
      'is_active': isActive,
      'invitation_token': invitationToken,
      'invitation_sent_at': invitationSentAt?.toIso8601String(),
      'invitation_accepted_at': invitationAcceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
