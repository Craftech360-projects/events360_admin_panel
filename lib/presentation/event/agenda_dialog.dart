import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/models/speaker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AgendaDialog extends StatefulWidget {
  final String organizationId;
  final List<EventAgenda> agendaItems;

  const AgendaDialog({
    super.key,
    required this.organizationId,
    required this.agendaItems,
  });

  @override
  State<AgendaDialog> createState() => _AgendaDialogState();
}

class _AgendaDialogState extends State<AgendaDialog> {
  late List<EventAgenda> _items;
  late Future<List<Speaker>> _speakersFuture;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.agendaItems);
    _speakersFuture =
        SupabaseService().getOrganizationSpeakers(widget.organizationId);
  }

  void _addItem() {
    showDialog<EventAgenda>(
      context: context,
      builder: (context) => AgendaItemDialog(
        organizationId: widget.organizationId,
      ),
    ).then((item) {
      if (item != null) {
        setState(() => _items.add(item));
      }
    });
  }

  void _editItem(int index) {
    showDialog<EventAgenda>(
      context: context,
      builder: (context) => AgendaItemDialog(
        organizationId: widget.organizationId,
        item: _items[index],
      ),
    ).then((item) {
      if (item != null) {
        setState(() => _items[index] = item);
      }
    });
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Event Agenda',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton.filled(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add Item',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editItem(index),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() => _items.removeAt(index));
                                  },
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${DateFormat.jm().format(item.startTime)} - ${DateFormat.jm().format(item.endTime)}',
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(item.location),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                    onPressed: () => Navigator.pop(context, _items),
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

class AgendaItemDialog extends StatefulWidget {
  final String organizationId;
  final EventAgenda? item;

  const AgendaItemDialog({
    super.key,
    required this.organizationId,
    this.item,
  });

  @override
  State<AgendaItemDialog> createState() => _AgendaItemDialogState();
}

class _AgendaItemDialogState extends State<AgendaItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedSpeakerId;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleController.text = widget.item!.title;
      _descriptionController.text = widget.item?.description ?? "";
      _locationController.text = widget.item!.location;
      _startTime = TimeOfDay.fromDateTime(DateTime.now());
      _endTime = TimeOfDay.fromDateTime(DateTime.now());
      _selectedSpeakerId = widget.item!.speakerId;
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? _startTime ?? TimeOfDay.now()
          : _endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item == null ? 'Add Agenda Item' : 'Edit Agenda Item',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required field' : null,
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 3,
                        ),
                        Constants.h16,
                        FutureBuilder<List<Speaker>>(
                          future: SupabaseService()
                              .getOrganizationSpeakers(widget.organizationId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            final speakers = snapshot.data!;
                            return DropdownButtonFormField<String>(
                              value: _selectedSpeakerId,
                              decoration: const InputDecoration(
                                labelText: 'Speaker',
                                border: OutlineInputBorder(),
                              ),
                              items: speakers.map((speaker) {
                                return DropdownMenuItem(
                                  value: speaker.id,
                                  child: Text(speaker.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedSpeakerId = value);
                              },
                              validator: (value) => value == null
                                  ? 'Please select a speaker'
                                  : null,
                            );
                          },
                        ),
                        Constants.h16,
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Start Time'),
                                subtitle: Text(
                                  _startTime?.format(context) ?? 'Not set',
                                ),
                                onTap: () => _selectTime(context, true),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('End Time'),
                                subtitle: Text(
                                  _endTime?.format(context) ?? 'Not set',
                                ),
                                onTap: () => _selectTime(context, false),
                              ),
                            ),
                          ],
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required field' : null,
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      if (_startTime == null || _endTime == null) {
                        showSnackBar(
                            context, "Please select start and end time");
                        return;
                      }

                      // Convert TimeOfDay to DateTime
                      final now = DateTime.now();
                      final startDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _startTime!.hour,
                        _startTime!.minute,
                      );
                      final endDateTime = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      );

                      final item = EventAgenda(
                        id: widget.item?.id,
                        title: _titleController.text,
                        description: _descriptionController.text,
                        speakerId: _selectedSpeakerId!,
                        startTime: startDateTime,
                        endTime: endDateTime,
                        location: _locationController.text,
                      );

                      Navigator.pop(context, item);
                    },
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
