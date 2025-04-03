import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/constants/permission_constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/models/speaker.dart';
import 'package:flutter/material.dart';

class SpeakerManagementScreen extends StatefulWidget {
  final String organizationId;

  const SpeakerManagementScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<SpeakerManagementScreen> createState() =>
      _SpeakerManagementScreenState();
}

class _SpeakerManagementScreenState extends State<SpeakerManagementScreen> {
  late Future<List<Speaker>> _speakersFuture;

  @override
  void initState() {
    super.initState();
    _loadSpeakers();
  }

  void _loadSpeakers() {
    _speakersFuture =
        SupabaseService().getOrganizationSpeakers(widget.organizationId);
  }

  Future<void> _addEditSpeaker([Speaker? speaker]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SpeakerDialog(
        organizationId: widget.organizationId,
        speaker: speaker,
      ),
    );

    if (result == true) {
      _loadSpeakers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speakers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEditSpeaker(),
          ),
        ],
      ),
      body: FutureBuilder<List<Speaker>>(
        future: _speakersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final speakers = snapshot.data ?? [];

          if (speakers.isEmpty) {
            return const Center(
              child: Text('No speakers added yet'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: ListView.builder(
                itemCount: speakers.length,
                itemBuilder: (context, index) {
                  final speaker = speakers[index];
                  return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Card(
                        elevation: 4,
                        child: SpeakerListTile(
                            speaker: speaker,
                            onEdit: () {
                              if (!UserRoleService.hasPermission(
                                 PermissionConstants.MANAGE_SPEAKERS)) {
                                showSnackBar(context,
                                    "You don't have the necessary permissions to manage speakers");
                                return;
                              }
                              _addEditSpeaker(speaker);
                            },
                            onDelete: () async {
                              if (!UserRoleService.hasPermission(
                                  PermissionConstants.MANAGE_SPEAKERS)) {
                                showSnackBar(context,
                                    "You don't have the necessary permissions to manage speakers");
                                return;
                              }

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: const Text(
                                      'Are you sure you want to delete this speaker?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await SupabaseService().deleteSpeaker(
                                    speaker.id,
                                    widget.organizationId,
                                  );
                                  _loadSpeakers();
                                } on Exception catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text('Error deleting speaker: $e')),
                                  );
                                }
                              }
                            }),
                      ));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class SpeakerListTile extends StatelessWidget {
  final Speaker speaker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SpeakerListTile({
    super.key,
    required this.speaker,
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
              speaker.imageUrl != null
                  ? CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(speaker.imageUrl!),
                    )
                  : CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        speaker.name[0].toUpperCase(),
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
                      speaker.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (speaker.title?.isNotEmpty ?? false)
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
                          speaker.title!,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    if (speaker.company?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          speaker.company!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7),
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

class SpeakerDialog extends StatefulWidget {
  final String organizationId;
  final Speaker? speaker;

  const SpeakerDialog({
    super.key,
    required this.organizationId,
    this.speaker,
  });

  @override
  State<SpeakerDialog> createState() => _SpeakerDialogState();
}

class _SpeakerDialogState extends State<SpeakerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.speaker != null) {
      _nameController.text = widget.speaker!.name;
      _titleController.text = widget.speaker!.title ?? '';
      _bioController.text = widget.speaker!.bio ?? '';
      _emailController.text = widget.speaker!.email ?? '';
      _phoneController.text = widget.speaker!.phone ?? '';
      _companyController.text = widget.speaker!.company ?? '';
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
                widget.speaker == null ? 'Add Speaker' : 'Edit Speaker',
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
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company',
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
                              final speaker = Speaker(
                                organizationId: widget.organizationId,
                                name: _nameController.text,
                                title: _titleController.text,
                                bio: _bioController.text,
                                email: _emailController.text,
                                phone: _phoneController.text,
                                company: _companyController.text,
                              );

                              if (widget.speaker == null) {
                                await SupabaseService().addSpeaker(speaker);
                              } else {
                                await SupabaseService().updateSpeaker(speaker);
                              }

                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            } on Exception catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error saving speaker: $e'),
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
                        : Text(widget.speaker == null ? 'Add' : 'Save'),
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
