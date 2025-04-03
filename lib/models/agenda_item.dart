class AgendaItem {
  final String? id; 
  final String? eventId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? speakerId;
  final Map<String, dynamic>? speaker;

  AgendaItem({
    this.id,
    this.eventId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.speakerId,
    this.speaker,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      'title': title,
      if (description != null) 'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
      if (speakerId != null) 'speaker_id': speakerId,
    };
  }

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    return AgendaItem(
      id: json['id']?.toString(),
      eventId: json['event_id']?.toString(),
      title: json['title'] ?? '',
      description: json['description'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'] ?? '',
      speakerId: json['speaker_id']?.toString(),
      speaker: json['speakers'],
    );
  }

  AgendaItem copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? speakerId,
    Map<String, dynamic>? speaker,
  }) {
    return AgendaItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      speakerId: speakerId ?? this.speakerId,
      speaker: speaker ?? this.speaker,
    );
  }
}
