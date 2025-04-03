import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/constants/permission_constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/models/organization.dart';
import 'package:flutter/material.dart';

class OrganizationScreen extends StatefulWidget {
  final String organizationId;

  const OrganizationScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<Organization?> _organizationFuture;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrganization();
  }

  void _loadOrganization() {
    _organizationFuture =
        SupabaseService().getOrganization(widget.organizationId);
  }

  void _populateFields(Organization organization) {
    _usernameController.text = organization.username ?? '';
    _bioController.text = organization.bio ?? '';
    _contactEmailController.text = organization.contactEmail ?? '';
    _contactPhoneController.text = organization.contactPhone ?? '';
    _addressController.text = organization.address ?? '';
    _cityController.text = organization.city ?? '';
    _stateController.text = organization.state ?? '';
    _countryController.text = organization.country ?? '';
    _postalCodeController.text = organization.postalCode ?? '';
    _websiteController.text = organization.website ?? '';
  }

  Future<void> _saveOrganization(Organization organization) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedOrganization = Organization(
        id: organization.id,
        username: _usernameController.text,
        bio: _bioController.text,
        contactEmail: _contactEmailController.text,
        contactPhone: _contactPhoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        postalCode: _postalCodeController.text,
        website: _websiteController.text,
      );

      await SupabaseService().updateOrganization(updatedOrganization);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization updated successfully')),
        );
        setState(() => _isEditing = false);
        _loadOrganization();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating organization: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildInfoCard(Widget child) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Organization Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          FutureBuilder<Organization?>(
            future: _organizationFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return IconButton(
                icon: Icon(_isEditing ? Icons.save : Icons.edit),
                onPressed: _isSaving
                    ? null
                    : () {
                        if (!UserRoleService.hasPermission(
                            PermissionConstants.MANAGE_ORGANIZATION)) {
                          showSnackBar(context,
                              "You don't have the necessary permissions to manage organization");
                          return;
                        }

                        if (_isEditing) {
                          _saveOrganization(snapshot.data!);
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Organization?>(
        future: _organizationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Organization not found'),
                ],
              ),
            );
          }

          final organization = snapshot.data!;
          if (!_isEditing) _populateFields(organization);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              child: Icon(
                                Icons.business,
                                size: 48,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Constants.h16,
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Organization Name',
                                border: OutlineInputBorder(),
                              ),
                              enabled: _isEditing,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Required field'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      _buildSectionTitle('Basic Information'),
                      _buildInfoCard(
                        Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              enabled: _isEditing,
                            ),
                            Constants.h16,
                            TextFormField(
                              controller: _bioController,
                              decoration: const InputDecoration(
                                labelText: 'Bio',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                              ),
                              maxLines: 3,
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                      _buildSectionTitle('Contact Information'),
                      _buildInfoCard(
                        Column(
                          children: [
                            TextFormField(
                              controller: _contactEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              enabled: _isEditing,
                            ),
                            Constants.h16,
                            TextFormField(
                              controller: _contactPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              enabled: _isEditing,
                            ),
                            Constants.h16,
                            TextFormField(
                              controller: _websiteController,
                              decoration: const InputDecoration(
                                labelText: 'Website',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.language),
                              ),
                              enabled: _isEditing,
                            ),
                          ],
                        ),
                      ),
                      _buildSectionTitle('Address'),
                      _buildInfoCard(
                        Column(
                          children: [
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Street Address',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              enabled: _isEditing,
                            ),
                            Constants.h16,
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: const InputDecoration(
                                      labelText: 'City',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.location_city),
                                    ),
                                    enabled: _isEditing,
                                  ),
                                ),
                                Constants.w16,
                                Expanded(
                                  child: TextFormField(
                                    controller: _stateController,
                                    decoration: const InputDecoration(
                                      labelText: 'State',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.map),
                                    ),
                                    enabled: _isEditing,
                                  ),
                                ),
                              ],
                            ),
                            Constants.h16,
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _countryController,
                                    decoration: const InputDecoration(
                                      labelText: 'Country',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.public),
                                    ),
                                    enabled: _isEditing,
                                  ),
                                ),
                                Constants.w16,
                                Expanded(
                                  child: TextFormField(
                                    controller: _postalCodeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Postal Code',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.local_post_office),
                                    ),
                                    enabled: _isEditing,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Constants.h32,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
