import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:flutter/material.dart';

class UserRoleService {
  static String? _roleId;
  static List<String> _permissions = [];
  static Map<String, String> _permissionMap = {};

  static String? get roleId => _roleId;
  static List<String> get permissions => _permissions;

  static Future<void> initialize(String userId) async {
    try {
      final response = await SupabaseService()
          .client
          .from('members')
          .select('role_id')
          .eq('auth_id', userId)
          .single();

      _roleId = response['role_id'];

      // Get all permissions first to build the map
      final allPermissions = await SupabaseService()
          .client
          .from('permissions')
          .select('id, name');

      // Build permission map (id -> name)
      _permissionMap = Map.fromEntries(
        allPermissions.map<MapEntry<String, String>>(
            (permission) => MapEntry(permission['id'], permission['name'])),
      );

      // Get user's role permissions
      if (_roleId != null) {
        final permissionsResponse = await SupabaseService()
            .client
            .from('role_permissions')
            .select('permission_id')
            .eq('role_id', _roleId!);

        // Convert permission IDs to permission codes
        _permissions = permissionsResponse
            .map<String>((json) => _permissionMap[json['permission_id']] ?? '')
            .where((code) => code.isNotEmpty)
            .toList();
      }
    } on Exception catch (e) {
      debugPrint('Error initializing user role: $e');
      _roleId = null;
      _permissions = [];
      _permissionMap = {};
    }
  }

  static bool hasPermission(String permissionCode) {
    return _permissions.contains(permissionCode);
  }

  static void clear() {
    _roleId = null;
    _permissions = [];
    _permissionMap = {};
  }
}
