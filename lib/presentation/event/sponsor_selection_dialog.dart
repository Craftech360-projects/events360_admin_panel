import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/sponsor.dart';
import 'package:flutter/material.dart';

class SponsorSelectionDialog extends StatefulWidget {
  final String organizationId;
  final List<String> selectedSponsorIds;

  const SponsorSelectionDialog({
    super.key,
    required this.organizationId,
    required this.selectedSponsorIds,
  });

  @override
  State<SponsorSelectionDialog> createState() => _SponsorSelectionDialogState();
}

class _SponsorSelectionDialogState extends State<SponsorSelectionDialog> {
  late List<String> _selectedIds;
  late Future<List<Sponsor>> _sponsorsFuture;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedSponsorIds);
    _loadSponsors();
  }

  void _loadSponsors() {
    _sponsorsFuture =
        SupabaseService().getOrganizationSponsors(widget.organizationId);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Sponsors',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<List<Sponsor>>(
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
                        child: Text('No sponsors available'),
                      );
                    }

                    return ListView.builder(
                      itemCount: sponsors.length,
                      itemBuilder: (context, index) {
                        final sponsor = sponsors[index];
                        final isSelected = _selectedIds.contains(sponsor.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: isSelected,
                            title: Text(
                              sponsor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: sponsor.sponsorshipLevel?.isNotEmpty ??
                                    false
                                ? Container(
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
                                  )
                                : null,
                            secondary: sponsor.logoUrl != null
                                ? CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        NetworkImage(sponsor.logoUrl!),
                                  )
                                : CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    child: Text(
                                      sponsor.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            onChanged: (selected) {
                              setState(() {
                                if (selected ?? false) {
                                  _selectedIds.add(sponsor.id);
                                } else {
                                  _selectedIds.remove(sponsor.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedIds),
                    child: const Text('Save'),
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
