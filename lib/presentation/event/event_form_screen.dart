import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/core/widgets/app_snackbar.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/presentation/event/agenda_dialog.dart';
import 'package:events360_admin/presentation/event/sponsor_selection_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EventFormScreen extends StatefulWidget {
  final String organizationId;
  final Event? event;

  const EventFormScreen({
    super.key,
    required this.organizationId,
    this.event,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String? _bannerImageUrl;

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List<EventAgenda> _agendaItems = [];
  List<String> _selectedSponsorIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startDate);
      _endTime = TimeOfDay.fromDateTime(widget.event!.endDate);
      _agendaItems = List.from(widget.event!.agendaItems);
      _selectedSponsorIds = List.from(widget.event!.sponsorIds);
      _bannerImageUrl = widget.event!.bannerImageUrl;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920, // Limit image size
      maxHeight: 1080,
      imageQuality: 85, // Compress image
    );

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final imageUrl = await SupabaseService()
            .uploadEventBanner(kIsWeb ? image : image.path);

        if (imageUrl != null) {
          setState(() => _bannerImageUrl = imageUrl);
        } else {
          if (mounted) {
            showSnackBar(context, "Failed to upload image");
          }
        }
      } on Exception catch (e) {
        if (mounted) {
          showSnackBar(context, "Error uploading image: $e");
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate == null || _endDate!.isBefore(_startDate!)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
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

  Future<void> _manageAgendaItems() async {
    final result = await showDialog<List<EventAgenda>>(
      context: context,
      builder: (context) => AgendaDialog(
        organizationId: widget.organizationId,
        agendaItems: _agendaItems,
      ),
    );

    if (result != null) {
      setState(() => _agendaItems = result);
    }
  }

  Future<void> _manageSponsors() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => SponsorSelectionDialog(
        organizationId: widget.organizationId,
        selectedSponsorIds: _selectedSponsorIds,
      ),
    );

    if (result != null) {
      setState(() => _selectedSponsorIds = result);
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      showSnackBar(context, "Please select start and end dates and times");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = Event(
        id: widget.event?.id,
        organizationId: widget.organizationId,
        title: _titleController.text,
        description: _descriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        startTime: _startTime!,
        endTime: _endTime!,
        location: _locationController.text,
        bannerImageUrl: _bannerImageUrl,
        agendaItems: _agendaItems,
        sponsorIds: _selectedSponsorIds,
      );

      if (widget.event == null) {
        await SupabaseService().createEvent(event);
      } else {
        await SupabaseService().updateEvent(event);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Exception {
      if (mounted) {
        showSnackBar(context, "Oops! Something went wrong");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEvent,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    widget.event == null
                        ? 'Event Details'
                        : 'Edit Event Details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  Constants.h24,
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  Constants.h16,
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Banner',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Constants.h16,
                          if (_bannerImageUrl != null)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _bannerImageUrl!,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                      child: Icon(Icons.error_outline,
                                          size: 48, color: Colors.red),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton.filled(
                                    onPressed: () =>
                                        setState(() => _bannerImageUrl = null),
                                    icon: const Icon(Icons.close),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image),
                              label: const Text('Upload Banner Image'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Constants.h32,
                  TextFormField(
                    maxLines: 3,
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required field' : null,
                  ),
                  Constants.h16,
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date & Time',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Constants.h16,
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('Start Date'),
                                  subtitle: Text(
                                    _startDate != null
                                        ? DateFormat('MMM d, yyyy')
                                            .format(_startDate!)
                                        : 'Not set',
                                  ),
                                  onTap: () => _selectDate(context, true),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('End Date'),
                                  subtitle: Text(
                                    _endDate != null
                                        ? DateFormat('MMM d, yyyy')
                                            .format(_endDate!)
                                        : 'Not set',
                                  ),
                                  onTap: () => _selectDate(context, false),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  title: const Text('Start Time'),
                                  subtitle: Text(
                                    _startTime != null
                                        ? _startTime!.format(context)
                                        : 'Not set',
                                  ),
                                  onTap: () => _selectTime(context, true),
                                ),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: const Text('End Time'),
                                  subtitle: Text(
                                    _endTime != null
                                        ? _endTime!.format(context)
                                        : 'Not set',
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
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            validator: (value) => value?.isEmpty ?? true
                                ? 'Required field'
                                : null,
                          ),
                          Constants.h24,
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _manageAgendaItems,
                                  icon: const Icon(Icons.schedule),
                                  label: const Text('Manage Agenda'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              Constants.w16,
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _manageSponsors,
                                  icon: const Icon(Icons.business),
                                  label: const Text('Manage Sponsors'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
