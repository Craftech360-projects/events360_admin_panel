import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/models/ticket.dart';
import 'package:events360_admin/presentation/event/publish_tickets_dialog.dart';
import 'package:events360_admin/presentation/event/ticket_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketManagementScreen extends StatefulWidget {
  final String? eventId;
  const TicketManagementScreen({super.key, this.eventId});

  @override
  State<TicketManagementScreen> createState() => _TicketManagementScreenState();
}

class _TicketManagementScreenState extends State<TicketManagementScreen> {
  final dialogKey = GlobalKey<PublishTicketsDialogState>();
  late Future<List<Ticket>> _ticketsFuture;
  List<Event> _events = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadTickets();
  }

  Future<void> _loadEvents() async {
    try {
      final response = await SupabaseService().getEvents();
      setState(() {
        _events = response.map((e) => Event.fromJson(e)).toList();
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
    }
  }

  void _loadTickets() {
    // If eventId is provided, show tickets for that event only // Otherwise, show all tickets

    _ticketsFuture = SupabaseService().getAllTickets();

    //widget.eventId != null // ? SupabaseService().getEventTickets(widget.eventId!) : SupabaseService().getAllTickets();
  }

  Future<void> _addEditTicket([Ticket? ticket]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TicketDialog(
        eventId: widget.eventId ?? '',
        ticket: ticket,
      ),
    );

    if (result == true) {
      setState(() {
        _loadTickets();
      });
    }
  }

  Future<void> _publishTickets() async {
    setState(() => isLoading = true);

    try {
      final unpublishedTickets =
          await SupabaseService().getUnpublishedTickets();

      if (unpublishedTickets.isEmpty) {
        showSnackBar(context, 'No unpublished tickets found');
        return;
      }

      if (!mounted) return;

      final result = await showDialog<Set<Ticket>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Tickets to Publish'),
          content: SizedBox(
            width: double.maxFinite,
            child: PublishTicketsDialog(
              key: dialogKey,
              tickets: unpublishedTickets,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final selectedTickets = dialogKey.currentState?.selectedTickets;
                Navigator.pop(context, selectedTickets);
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      );

      if (result == null || result.isEmpty) {
        debugPrint('No tickets selected, returning');
        return;
      }

      // Generate widget code for the event
      final eventId = result.first.eventId!;
      final widgetCode =
          await SupabaseService().generateTicketWidgetCode(eventId);
      if (!mounted) return;

      // Show success dialog with embed code
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tickets Published Successfully'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Use this code to embed the ticket widget:'),
              const SizedBox(height: 16),
              SelectableText('''
              <script src="https://events360tickets.vercel.app/events360.js"></script>
              <div id="widget-container"></div>
              <script>
                const ticketWidget = new Events360({
                  apiKey: "${widgetCode.apiKey}",
                  environment: "${kReleaseMode ? 'production' : 'local'}",
                  theme: "light"
                });

                window.addEventListener("load", async () => {
                  try {
                    await ticketWidget.init("widget-container");
                  } catch (error) {
                    console.error("Widget initialization failed:", error);
                  }
                });
              </script>
              '''),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      // Refresh the tickets list
      setState(() {
        _loadTickets();
      });
    } on Exception catch (e) {
      debugPrint('Error in publish flow: $e');
      if (!mounted) return;
      showSnackBar(context, 'Error publishing tickets: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showEmbedCode(String eventId) async {
    setState(() => isLoading = true);

    try {
      // Get the widget code for this event
      final widgetCode = await SupabaseService().getTicketWidgetCode(eventId);

      if (!mounted) return;

      if (widgetCode == null) {
        showSnackBar(context,
            'No embed code found for this event. Please publish tickets first.');
        return;
      }

      // Show dialog with embed code
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ticket Widget Embed Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Use this code to embed the ticket widget:'),
              const SizedBox(height: 16),
              SelectableText('''
              <script src="/sdk/events360.js"></script>
              <div id="widget-container"></div>
              <script>
                const ticketWidget = new Events360({
                  apiKey: "${widgetCode.apiKey}",
                  environment: "local",
                  theme: "light"
                });

                window.addEventListener("load", async () => {
                  try {
                    await ticketWidget.init("widget-container");
                  } catch (error) {
                    console.error("Widget initialization failed:", error);
                  }
                });
              </script>
              '''),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Error retrieving embed code: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addEditTicket(),
          ),
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Publish Tickets',
            onPressed: () => _publishTickets(),
          ),
        ],
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return const Center(
              child: Text('No tickets added yet'),
            );
          }

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: ListView.builder(
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.event != null) ...[
                          Text(ticket.name),
                          Text(
                            '${ticket.event!['title']}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Colors.blue,
                                ),
                          ),
                          Constants.h4,
                          if (ticket.event!['venue'] != null)
                            Text(
                              'Venue: ${ticket.event!['venue']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (ticket.event!['start_date'] != null)
                            Text(
                              'Event Date: ${DateFormat('MMM d, y').format(DateTime.parse(ticket.event!['start_date']))}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          Constants.h8,
                        ],
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Constants.h4,
                            Text(ticket.description ??
                                'Event description not provided'),
                            Constants.h4,
                            Text(
                              'Price: ${currencyFormat.format(ticket.price)} • Quantity: ${ticket.quantity}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (ticket.startSaleDate != null &&
                                ticket.endSaleDate != null)
                              Constants.h4,
                            Text(
                              'Sale Period: ${DateFormat('MMM d').format(ticket.startSaleDate!)} - ${DateFormat('MMM d').format(ticket.endSaleDate!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                  value: ticket.isActive,
                                  onChanged: (value) async {
                                    try {
                                      await SupabaseService().updateTicket(
                                        Ticket(
                                          id: ticket.id,
                                          eventId: ticket.eventId,
                                          name: ticket.name,
                                          description: ticket.description,
                                          organizationId:
                                              SupabaseService.organizationId ??
                                                  '',
                                          price: ticket.price,
                                          quantity: ticket.quantity,
                                          maxTicketsPerUser:
                                              ticket.maxTicketsPerUser,
                                          startSaleDate: ticket.startSaleDate,
                                          endSaleDate: ticket.endSaleDate,
                                          isActive: value,
                                          availableQuantity:
                                              ticket.availableQuantity,
                                        ),
                                      );
                                    } on Exception {
                                      if (!context.mounted) return;
                                      showSnackBar(
                                          context, "Failed to update ticket");
                                    }
                                  }),
                            ),
                            Constants.h16,
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _addEditTicket(ticket),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.code),
                                  tooltip: 'View Embed Code',
                                  onPressed: () =>
                                      _showEmbedCode(ticket.eventId!),
                                ),
                                isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: isLoading
                                            ? null
                                            : () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'Confirm Delete'),
                                                    content: const Text(
                                                      'Are you sure you want to delete this ticket?',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                        child: const Text(
                                                            'Cancel'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                        child: const Text(
                                                            'Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  setState(
                                                      () => isLoading = true);
                                                  try {
                                                    await SupabaseService()
                                                        .deleteTicket(
                                                            ticket.id ?? '');
                                                    if (mounted) {
                                                      setState(() {
                                                        isLoading = false;
                                                        _loadTickets();
                                                      });
                                                    }
                                                  } on Exception {
                                                    if (!context.mounted) {
                                                      return;
                                                    }
                                                    showSnackBar(context,
                                                        "Failed to delete ticket");
                                                    setState(() =>
                                                        isLoading = false);
                                                  }
                                                }
                                              },
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
