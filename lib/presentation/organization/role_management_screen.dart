import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/permission.dart';
import 'package:events360_admin/models/role.dart';
import 'package:flutter/material.dart';

class RoleManagementScreen extends StatefulWidget {
  final String organizationId;

  const RoleManagementScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  late Future<List<Role>> _rolesFuture;
  late Future<List<Permission>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _rolesFuture = SupabaseService().getRoles();
    _permissionsFuture = SupabaseService().getPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
      ),
      body: FutureBuilder<List<Role>>(
        future: _rolesFuture,
        builder: (context, roleSnapshot) {
          if (roleSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (roleSnapshot.hasError) {
            return Center(child: Text('Error: ${roleSnapshot.error}'));
          }

          final roles = roleSnapshot.data ?? [];

          return FutureBuilder<List<Permission>>(
            future: _permissionsFuture,
            builder: (context, permissionSnapshot) {
              if (permissionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (permissionSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${permissionSnapshot.error}'));
              }

              final permissions = permissionSnapshot.data ?? [];

              return ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  final role = roles[index];
                  return RolePermissionCard(
                    role: role,
                    permissions: permissions,
                    onPermissionsChanged: () => _loadData(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RolePermissionCard extends StatelessWidget {
  final Role role;
  final List<Permission> permissions;
  final VoidCallback onPermissionsChanged;

  const RolePermissionCard({
    super.key,
    required this.role,
    required this.permissions,
    required this.onPermissionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (role.description != null) ...[
              Constants.h8,
              Text(
                role.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            Constants.h16,
            FutureBuilder<List<String>>(
              future: SupabaseService().getRolePermissions(role.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final rolePermissions = snapshot.data ?? [];

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: permissions.map((permission) {
                    final isEnabled = rolePermissions.contains(permission.id);
                    return FilterChip(
                      label: Text(permission.name),
                      selected: isEnabled,
                      onSelected: (selected) async {
                        try {
                          if (selected) {
                            await SupabaseService().addRolePermission(
                              role.id,
                              permission.id,
                            );
                          } else {
                            await SupabaseService().removeRolePermission(
                              role.id,
                              permission.id,
                            );
                          }
                          onPermissionsChanged();
                        } on Exception catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating permissions: $e'),
                              ),
                            );
                          }
                        }
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
