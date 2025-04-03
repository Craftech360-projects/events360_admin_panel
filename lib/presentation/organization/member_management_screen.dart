import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/member.dart';
import 'package:events360_admin/models/role.dart';
import 'package:flutter/material.dart';

class MemberManagementScreen extends StatefulWidget {
  final String organizationId;

  const MemberManagementScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  late Future<List<Member>> _membersFuture;
  late Future<List<Role>> _rolesFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _loadRoles();
  }

  void _loadMembers() {
    _membersFuture =
        SupabaseService().getOrganizationMembers(widget.organizationId);
  }

  void _loadRoles() {
    _rolesFuture = SupabaseService().getRoles();
  }

  Future<void> _inviteMember() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => InviteMemberDialog(
        organizationId: widget.organizationId,
      ),
    );

    if (result == true) {
      _loadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _inviteMember,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: FutureBuilder<List<Member>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No members yet. Click the + button to invite members.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return MemberListTile(
                      member: member,
                      onRoleChanged: (roleId) async {
                        try {
                          await SupabaseService().updateMember(
                            Member(
                              id: member.id,
                              organizationId: member.organizationId,
                              roleId: roleId,
                              email: member.email,
                            ),
                          );
                          _loadMembers();
                        } on Exception catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error updating member: $e')),
                          );
                        }
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Removal'),
                            content: const Text(
                                'Are you sure you want to remove this member?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await SupabaseService().deleteMember(member.id);
                            _loadMembers();
                          } on Exception catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Error removing member: $e')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MemberListTile extends StatelessWidget {
  final Member member;
  final Function(String) onRoleChanged;
  final VoidCallback onDelete;

  const MemberListTile({
    super.key,
    required this.member,
    required this.onRoleChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(member.email[0].toUpperCase()),
      ),
      title: Text(member.email),
      subtitle: FutureBuilder<List<Role>>(
        future: SupabaseService().getRoles(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final roles = snapshot.data!;
          final currentRole = roles.firstWhere(
            (role) => role.id == member.roleId,
            orElse: () => Role(name: 'Unknown'),
          );

          return DropdownButton<String>(
            value: currentRole.id,
            items: roles.map((role) {
              return DropdownMenuItem(
                value: role.id,
                child: Text(role.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onRoleChanged(value);
            },
          );
        },
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}

class InviteMemberDialog extends StatefulWidget {
  final String organizationId;

  const InviteMemberDialog({
    super.key,
    required this.organizationId,
  });

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _selectedRoleId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Member'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  // Add email format validation
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              Constants.h16,
              FutureBuilder<List<Role>>(
                future: SupabaseService().getRoles(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedRoleId,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: snapshot.data!.map((role) {
                      return DropdownMenuItem(
                        value: role.id,
                        child: Text(role.name),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedRoleId = value),
                    validator: (value) =>
                        value == null ? 'Please select a role' : null,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  try {
                    await SupabaseService().inviteMember(
                      Member(
                        organizationId: widget.organizationId,
                        roleId: _selectedRoleId!,
                        email: _emailController.text.trim(),
                      ),
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  } on Exception catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error inviting member: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Invite'),
        ),
      ],
    );
  }
}
