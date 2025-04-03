import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/constants/permission_constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/models/sponsor.dart';
import 'package:flutter/material.dart';

class SponsorManagementScreen extends StatefulWidget {
  final String organizationId;

  const SponsorManagementScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<SponsorManagementScreen> createState() =>
      _SponsorManagementScreenState();
}

class _SponsorManagementScreenState extends State<SponsorManagementScreen> {
  late Future<List<Sponsor>> _sponsorsFuture;

  @override
  void initState() {
    super.initState();
    _loadSponsors();
  }

  void _loadSponsors() {
    _sponsorsFuture =
        SupabaseService().getOrganizationSponsors(widget.organizationId);
  }

  Future<void> _addEditSponsor([Sponsor? sponsor]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SponsorDialog(
        organizationId: widget.organizationId,
        sponsor: sponsor,
      ),
    );

    if (result == true) {
      _loadSponsors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEditSponsor(),
          ),
        ],
      ),
      body: FutureBuilder<List<Sponsor>>(
        future: _sponsorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sponsors = snapshot.data ?? [];

          if (sponsors.isEmpty) {
            return const Center(
              child: Text('No sponsors added yet'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: ListView.builder(
                itemCount: sponsors.length,
                itemBuilder: (context, index) {
                  final sponsor = sponsors[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      elevation: 4,
                      child: SponsorListTile(
                        sponsor: sponsor,
                        onEdit: () {
                          if (!UserRoleService.hasPermission(
                              PermissionConstants.MANAGE_SPONSORS)) {
                            showSnackBar(context,
                                "You don't have the necessary permissions to manage sponsors");
                            return;
                          }
                          _addEditSponsor(sponsor);
                        },
                        onDelete: () async {
                          if (!UserRoleService.hasPermission(
                              PermissionConstants.MANAGE_SPONSORS)) {
                            showSnackBar(context,
                                "You don't have the necessary permissions to manage sponsors");
                            return;
                          }
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                  'Are you sure you want to delete this sponsor?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await SupabaseService().deleteSponsor(
                                sponsor.id,
                                widget.organizationId,
                              );
                              _loadSponsors();
                            } on Exception catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error deleting sponsor: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class SponsorListTile extends StatelessWidget {
  final Sponsor sponsor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SponsorListTile({
    super.key,
    required this.sponsor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              sponsor.logoUrl != null
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(sponsor.logoUrl!),
                    )
                  : CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        sponsor.name[0].toUpperCase(),
                        style:
                            const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sponsor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (sponsor.sponsorshipLevel?.isNotEmpty ?? false)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sponsor.sponsorshipLevel!,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SponsorDialog extends StatefulWidget {
  final String organizationId;
  final Sponsor? sponsor;

  const SponsorDialog({
    super.key,
    required this.organizationId,
    this.sponsor,
  });

  @override
  State<SponsorDialog> createState() => _SponsorDialogState();
}

class _SponsorDialogState extends State<SponsorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sponsorshipLevelController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.sponsor != null) {
      _nameController.text = widget.sponsor!.name;
      _websiteController.text = widget.sponsor!.website ?? '';
      _descriptionController.text = widget.sponsor!.description ?? '';
      _sponsorshipLevelController.text = widget.sponsor!.sponsorshipLevel ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.5,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.sponsor == null ? 'Add Sponsor' : 'Edit Sponsor',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required field' : null,
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'Website',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _sponsorshipLevelController,
                          decoration: const InputDecoration(
                            labelText: 'Sponsorship Level',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _isLoading = true);

                            try {
                              final sponsor = Sponsor(
                                organizationId: widget.organizationId,
                                name: _nameController.text,
                                website: _websiteController.text,
                                description: _descriptionController.text,
                                sponsorshipLevel:
                                    _sponsorshipLevelController.text,
                              );

                              if (widget.sponsor == null) {
                                await SupabaseService().addSponsor(sponsor);
                              } else {
                                await SupabaseService().updateSponsor(sponsor);
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            } on Exception catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving sponsor: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.sponsor == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
