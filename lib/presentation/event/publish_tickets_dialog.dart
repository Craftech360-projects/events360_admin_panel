import 'package:events360_admin/models/ticket.dart';
import 'package:flutter/material.dart';

class PublishTicketsDialog extends StatefulWidget {
  final List<Ticket> tickets;

  const PublishTicketsDialog({
    super.key,
    required this.tickets,
  });

  @override
  State<PublishTicketsDialog> createState() => PublishTicketsDialogState();
}

class PublishTicketsDialogState extends State<PublishTicketsDialog> {
  final Set<Ticket> selectedTickets = {};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.tickets.length,
      itemBuilder: (context, index) {
        final ticket = widget.tickets[index];
        return CheckboxListTile(
          value: selectedTickets.contains(ticket),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                selectedTickets.add(ticket);
                debugPrint('Ticket selected: ${ticket.name}');
              } else {
                selectedTickets.remove(ticket);
                debugPrint('Ticket unselected: ${ticket.name}');
              }
            });
          },
          title: Text(ticket.name),
          subtitle: Text('Event: ${ticket.event?['title'] ?? 'Unknown Event'}'),
        );
      },
    );
  }
}
