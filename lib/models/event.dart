import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Event {
  final String id;
  final String organizationId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String location;
  final String? venue;
  final int? maxCapacity;
  final String? bannerImageUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<EventAgenda> agendaItems;
  final List<String> sponsorIds;

  Event({
    String? id,
    required this.organizationId,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.venue,
    this.maxCapacity,
    this.bannerImageUrl,
    this.isPublished = false,
    List<EventAgenda>? agendaItems,
    List<String>? sponsorIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        agendaItems = agendaItems ?? [],
        sponsorIds = sponsorIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Event.fromJson(Map<String, dynamic> json) {
    final startDateTime = DateTime.parse(json['start_date']);
    final endDateTime = DateTime.parse(json['end_date']);

    return Event(
      id: json['id'],
      organizationId: json['organization_id'],
      title: json['title'],
      description: json['description'],
      startDate:
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
      endDate: DateTime(endDateTime.year, endDateTime.month, endDateTime.day),
      startTime:
          TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute),
      endTime: TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute),
      location: json['location'],
      bannerImageUrl: json['banner_image_url'],
      venue: json['venue'],
      maxCapacity: json['max_capacity'],
      isPublished: json['is_published'] ?? false,
      agendaItems: (json['agenda_items'] as List?)
              ?.map((item) => EventAgenda.fromJson(item))
              .toList() ??
          [],
      sponsorIds:
          (json['sponsor_ids'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime.hour,
      startTime.minute,
    );

    final endDateTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    return {
      'id': id,
      'organization_id': organizationId,
      'title': title,
      'description': description,
      'start_date': startDateTime.toIso8601String(),
      'end_date': endDateTime.toIso8601String(),
      'location': location,
      'venue': venue,
      'max_capacity': maxCapacity,
      'banner_image_url': bannerImageUrl,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class EventAgenda {
  final String id;
  final String? eventId;
  final String title;
  final String? description;
  final String speakerId;
  final DateTime startTime;
  final DateTime endTime;
  final String location;

  EventAgenda({
    String? id,
    this.eventId,
    required this.title,
    this.description,
    required this.speakerId,
    required this.startTime,
    required this.endTime,
    required this.location,
  }) : id = id ?? const Uuid().v4();

  factory EventAgenda.fromJson(Map<String, dynamic> json) {
    return EventAgenda(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'],
      description: json['description'],
      speakerId: json['speaker_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'description': description,
      'speaker_id': speakerId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'location': location,
    };
  }
}
