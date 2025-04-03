import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PastEventsScreen extends StatefulWidget {
  const PastEventsScreen({super.key});

  @override
  State<PastEventsScreen> createState() => _PastEventsScreenState();
}

class _PastEventsScreenState extends State<PastEventsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pastEvents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPastEvents();
  }

  Future<void> _loadPastEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pastEvents = await SupabaseService().getPastEvents();
      setState(() {
        _isLoading = false;
        _pastEvents = pastEvents;
      });
    }on Exception  catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading past events: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Events'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Past Events',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            onPressed: _loadPastEvents,
                          ),
                        ],
                      ),
                      Constants.h24,
                      Expanded(
                        child: _pastEvents.isEmpty
                            ? const Center(
                                child: Text(
                                  'No past events found',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _pastEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _pastEvents[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ExpansionTile(
                                      title: Text(
                                        event['name'] ?? 'Unnamed Event',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${_formatDate(event['start_date'])} - ${_formatDate(event['end_date'])}',
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildDetailRow('Client',
                                                  event['client'] ?? 'N/A'),
                                              _buildDetailRow('Location',
                                                  event['location'] ?? 'N/A'),
                                              _buildDetailRow(
                                                  'Description',
                                                  event['description'] ??
                                                      'N/A'),
                                              Constants.h16,
                                              const Text(
                                                'Event Statistics',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Constants.h8,
                                              Row(
                                                children: [
                                                  _buildStatItem('Speakers',
                                                      '${event['speaker_count'] ?? 0}'),
                                                  _buildStatItem('Attendees',
                                                      '${event['attendee_count'] ?? 0}'),
                                                  _buildStatItem('Sponsors',
                                                      '${event['sponsor_count'] ?? 0}'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } on Exception {
      return 'Invalid date';
    }
  }
}
