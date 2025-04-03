import 'package:cached_network_image/cached_network_image.dart';
import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/constants/permission_constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/presentation/event/event_details_screen.dart';
import 'package:events360_admin/presentation/event/event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventManagementScreen extends StatefulWidget {
  final String organizationId;

  const EventManagementScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  final _eventsNotifier = ValueNotifier<List<Event>>([]);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events =
          await SupabaseService().getOrganizationEvents(widget.organizationId);
      _eventsNotifier.value = events;
    } on Exception catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> addEditEvent([Event? event]) async {
    // Check permission
    if (event == null &&
        !UserRoleService.hasPermission(
            'a2222222-2222-2222-2222-222222222222')) {
      showSnackBar(
          context, "You don't have the necessary permissions to add events");
      return;
    }

    if (event != null &&
        !UserRoleService.hasPermission(
            'a3333333-3333-3333-3333-333333333333')) {
      showSnackBar(
          context, "You don't have the necessary permissions to edit events");
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          organizationId: widget.organizationId,
          event: event,
        ),
      ),
    );

    if (result == true) {
      await _loadEvents();
    }
  }

  Future<void> _showEventDetails(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(event: event),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => addEditEvent(),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Event>>(
        valueListenable: _eventsNotifier,
        builder: (context, events, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (events.isEmpty) {
            return const Center(
              child: Text('No events added yet'),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.5,
              ),
              child: ListView.builder(
                itemCount: events.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    onTap: () => _showEventDetails(event),
                    event: event,
                    onEdit: () => addEditEvent(event),
                    onDelete: () async {
                      // Check permission
                      if (!UserRoleService.hasPermission(
                         PermissionConstants.DELETE_EVENT)) {
                        showSnackBar(context,
                            "You don't have the necessary permissions to delete events");
                        return;
                      }

                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete this event?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
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
                          await SupabaseService().deleteEvent(
                            event.id,
                            widget.organizationId,
                          );
                          await _loadEvents();
                        } on Exception catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error deleting event: $e')),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _eventsNotifier.dispose();
    super.dispose();
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Replace the image check with bannerImageUrl
            if (event.bannerImageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                child: CachedNetworkImage(
                  imageUrl: event.bannerImageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Constants.h8,
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${dateFormat.format(event.startDate)} - ${dateFormat.format(event.endDate)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Constants.h8,
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        event.location,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (event.description.isNotEmpty) ...[
                    Constants.h8,
                    Text(
                      event.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  Constants.h16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
