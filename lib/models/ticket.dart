import 'package:uuid/uuid.dart';

class Ticket {
  final String? id;
  final String? eventId;
  final String organizationId;
  final String name;
  final String? description;
  final double price;
  final int quantity;
  final int availableQuantity;
  final DateTime? startSaleDate;
  final DateTime? endSaleDate;
  final String ticketType;
  final int maxTicketsPerUser;
  final bool isActive;
  final List<String>? benefits;
  final int tierOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? event;

  Ticket({
    String? id,
    this.eventId,
    required this.name,
    this.description,
    required this.price,
    required this.quantity,
    required this.availableQuantity,
    required this.organizationId,
    this.startSaleDate,
    this.endSaleDate,
    this.ticketType = 'regular',
    this.maxTicketsPerUser = 1,
    this.isActive = true,
    this.benefits,
    this.event,
    this.tierOrder = 0,
    this.createdAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      eventId: json['event_id'],
      organizationId: json['organization_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
      availableQuantity: json['available_quantity'],
      startSaleDate: json['start_sale_date'] != null
          ? DateTime.parse(json['start_sale_date'])
          : null,
      endSaleDate: json['end_sale_date'] != null
          ? DateTime.parse(json['end_sale_date'])
          : null,
      ticketType: json['ticket_type'] ?? 'regular',
      maxTicketsPerUser: json['max_tickets_per_user'] ?? 1,
      isActive: json['is_active'] ?? true,
      benefits:
          json['benefits'] != null ? List<String>.from(json['benefits']) : null,
      tierOrder: json['tier_order'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      event: json['events'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'organization_id': organizationId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'available_quantity': availableQuantity,
      'start_sale_date': startSaleDate?.toIso8601String(),
      'end_sale_date': endSaleDate?.toIso8601String(),
      'ticket_type': ticketType,
      'max_tickets_per_user': maxTicketsPerUser,
      'is_active': isActive,
      'benefits': benefits,
      'tier_order': tierOrder,
    };
  }
}
