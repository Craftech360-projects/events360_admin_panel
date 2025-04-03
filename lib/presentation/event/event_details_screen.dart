import 'package:cached_network_image/cached_network_image.dart';
import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/models/sponsor.dart';
import 'package:events360_admin/presentation/event/event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late Future<List<Sponsor>> _sponsorsFuture;
  // final bool _isLoading = false; ====> USE LATER

  @override
  void initState() {
    super.initState();
  }

  Future<void> _editEvent() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          organizationId: widget.event.organizationId,
          event: widget.event,
        ),
      ),
    );

    if (result == true) {
      // Reload event details
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editEvent,
          ),
          IconButton(
            icon: const Icon(Icons.confirmation_number),
            onPressed: () => showSnackBar(context, "Coming Soon"),
            // _manageTickets,
            tooltip: 'Manage Tickets',
          ),
          Constants.w16,
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (widget.event.bannerImageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.event.bannerImageUrl!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  Constants.h24,
                ],
                Text(
                  widget.event.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Constants.h24,
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Details',
                          style: theme.textTheme.titleLarge,
                        ),
                        Constants.h16,
                        _buildDetailRow(
                          context,
                          Icons.calendar_today,
                          'Date',
                          '${dateFormat.format(widget.event.startDate)} - ${dateFormat.format(widget.event.endDate)}',
                        ),
                        _buildDetailRow(
                          context,
                          Icons.access_time,
                          'Time',
                          '${timeFormat.format(DateTime(
                            widget.event.startDate.year,
                            widget.event.startDate.month,
                            widget.event.startDate.day,
                            widget.event.startTime.hour,
                            widget.event.startTime.minute,
                          ))} - ${timeFormat.format(DateTime(
                            widget.event.endDate.year,
                            widget.event.endDate.month,
                            widget.event.endDate.day,
                            widget.event.endTime.hour,
                            widget.event.endTime.minute,
                          ))}',
                        ),
                        _buildDetailRow(
                          context,
                          Icons.location_on,
                          'Location',
                          widget.event.location,
                        ),
                      ],
                    ),
                  ),
                ),
                Constants.h16,
                if (widget.event.description.isNotEmpty) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: theme.textTheme.titleLarge,
                          ),
                          Constants.h16,
                          Text(
                            widget.event.description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Constants.h16,
                ],
                if (widget.event.agendaItems.isNotEmpty) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agenda',
                            style: theme.textTheme.titleLarge,
                          ),
                          Constants.h16,
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.event.agendaItems.length,
                            itemBuilder: (context, index) {
                              final item = widget.event.agendaItems[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  child: Text('${index + 1}'),
                                ),
                                title: Text(item.title),
                                subtitle: Text(item.description ??
                                    "No Description Available"),
                                trailing: Text(
                                  '${timeFormat.format(DateTime(
                                    2023,
                                    1,
                                    1,
                                    item.startTime.hour,
                                    item.startTime.minute,
                                  ))} - ${timeFormat.format(DateTime(
                                    2023,
                                    1,
                                    1,
                                    item.endTime.hour,
                                    item.endTime.minute,
                                  ))}',
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Constants.h16,
                ],
                if (widget.event.sponsorIds.isNotEmpty) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sponsors',
                            style: theme.textTheme.titleLarge,
                          ),
                          Constants.h16,
                          FutureBuilder<List<Sponsor>>(
                            future: _sponsorsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Text(
                                    'Error loading sponsors: ${snapshot.error}');
                              }

                              final sponsors = snapshot.data ?? [];
                              final eventSponsors = sponsors
                                  .where((s) =>
                                      widget.event.sponsorIds.contains(s.id))
                                  .toList();

                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: eventSponsors.map((sponsor) {
                                  return Column(
                                    children: [
                                      if (sponsor.logoUrl != null) ...[
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: sponsor.logoUrl!,
                                            height: 80,
                                            width: 120,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      Text(
                                        sponsor.name,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
