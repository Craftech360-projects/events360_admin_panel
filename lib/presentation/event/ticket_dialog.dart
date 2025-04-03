import 'package:events360_admin/core/constants/constants.dart';
import 'package:events360_admin/infrastructure/supabase_service.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/models/ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TicketDialog extends StatefulWidget {
  String eventId;
  final Ticket? ticket;

  TicketDialog({
    super.key,
    required this.eventId,
    this.ticket,
  });

  @override
  State<TicketDialog> createState() => _TicketDialogState();
}

class _TicketDialogState extends State<TicketDialog> {
  List<Event> _events = [];
  bool _loadingEvents = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _availableQuantityController = TextEditingController();
  final _maxTicketsPerUserController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _tierOrderController = TextEditingController();
  DateTime? _startSaleDate;
  DateTime? _endSaleDate;
  String _ticketType = 'regular';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    if (widget.ticket != null) {
      _nameController.text = widget.ticket!.name;
      _descriptionController.text = widget.ticket!.description ?? '';
      _priceController.text = widget.ticket!.price.toString();
      _quantityController.text = widget.ticket!.quantity.toString();
      _availableQuantityController.text =
          widget.ticket!.availableQuantity.toString();
      _maxTicketsPerUserController.text =
          widget.ticket!.maxTicketsPerUser.toString();
      _benefitsController.text = widget.ticket!.benefits?.join('\n') ?? '';
      _tierOrderController.text = widget.ticket!.tierOrder.toString();
      _startSaleDate = widget.ticket!.startSaleDate;
      _endSaleDate = widget.ticket!.endSaleDate;
      _ticketType = widget.ticket!.ticketType;
      _isActive = widget.ticket!.isActive;
    }
  }

  Future<void> _loadEvents() async {
    try {
      final response = await SupabaseService().getEvents();
      setState(() {
        _events = response.map((e) => Event.fromJson(e)).toList();
        _loadingEvents = false;

        // If no event is selected and we have events, select the first one
        if (widget.eventId.isEmpty && _events.isNotEmpty) {
          widget.eventId = _events.first.id;
        }
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading events: $e')),
        );
      }
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _saveTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final benefits = _benefitsController.text
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();

      final ticket = Ticket(
        id: widget.ticket?.id,
        eventId: widget.eventId,
        organizationId: SupabaseService.organizationId ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        availableQuantity: int.parse(_availableQuantityController.text),
        maxTicketsPerUser: int.tryParse(_maxTicketsPerUserController.text) ?? 1,
        startSaleDate: _startSaleDate,
        endSaleDate: _endSaleDate,
        ticketType: _ticketType,
        isActive: _isActive,
        benefits: benefits,
        tierOrder: int.tryParse(_tierOrderController.text) ?? 0,
      );

      if (widget.ticket == null) {
        await SupabaseService().createTicket(ticket);
      } else {
        await SupabaseService().updateTicket(ticket);
      }

      if (!context.mounted) return;
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      if (!context.mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving ticket: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: AlertDialog(
          title: Text(widget.ticket == null ? 'Add Ticket' : 'Edit Ticket'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 500,
                    child: Column(
                      children: [
                        if (widget.ticket == null)
                          _loadingEvents
                              ? const CircularProgressIndicator()
                              : DropdownButtonFormField<String>(
                                  value: widget.eventId.isEmpty
                                      ? null
                                      : widget.eventId,
                                  decoration: const InputDecoration(
                                    labelText: 'Select Event*',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _events.map((event) {
                                    return DropdownMenuItem(
                                      value: event.id,
                                      child: Text(event.title),
                                    );
                                  }).toList(),
                                  validator: (value) => value == null
                                      ? 'Please select an event'
                                      : null,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => widget.eventId = value);
                                    }
                                  },
                                ),
                        if (widget.ticket == null) Constants.h16,
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ticket Name*',
                            border: OutlineInputBorder(),
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
                          ),
                          maxLines: 2,
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Price*',
                            border: OutlineInputBorder(),
                            prefixText: '₹',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'))
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required field';
                            final price = double.tryParse(value!);
                            if (price == null || price < 0) {
                              return 'Invalid price';
                            }
                            return null;
                          },
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Total Quantity*',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required field';
                            final quantity = int.tryParse(value!);
                            if (quantity == null || quantity <= 0) {
                              return 'Must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _availableQuantityController,
                          decoration: const InputDecoration(
                            labelText: 'Available Quantity*',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Required field';
                            final availableQty = int.tryParse(value!);
                            final totalQty =
                                int.tryParse(_quantityController.text) ?? 0;
                            if (availableQty == null || availableQty < 0) {
                              return 'Must be 0 or greater';
                            }
                            if (availableQty > totalQty) {
                              return 'Cannot exceed total quantity';
                            }
                            return null;
                          },
                        ),
                        Constants.h16,
                        DropdownButtonFormField<String>(
                          value: _ticketType,
                          decoration: const InputDecoration(
                            labelText: 'Ticket Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'regular', child: Text('Regular')),
                            DropdownMenuItem(value: 'vip', child: Text('VIP')),
                            DropdownMenuItem(
                                value: 'early_bird', child: Text('Early Bird')),
                          ],
                          onChanged: (value) =>
                              setState(() => _ticketType = value!),
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _maxTicketsPerUserController,
                          decoration: const InputDecoration(
                            labelText: 'Max Tickets Per User',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value?.isEmpty ?? true) return null;
                            final max = int.tryParse(value!);
                            if (max == null || max <= 0) {
                              return 'Must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _benefitsController,
                          decoration: const InputDecoration(
                            labelText: 'Benefits (One per line)',
                            border: OutlineInputBorder(),
                            helperText: 'Enter each benefit on a new line',
                          ),
                          maxLines: 3,
                        ),
                        Constants.h16,
                        TextFormField(
                          controller: _tierOrderController,
                          decoration: const InputDecoration(
                            labelText: 'Tier Order',
                            border: OutlineInputBorder(),
                            helperText: 'Lower numbers appear first',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                        Constants.h16,
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Sale Start'),
                                subtitle: Text(
                                  _startSaleDate != null
                                      ? DateFormat('MMM d, yyyy')
                                          .format(_startSaleDate!)
                                      : 'Not set',
                                ),
                                onTap: () => _selectDate(context, true),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('Sale End'),
                                subtitle: Text(
                                  _endSaleDate != null
                                      ? DateFormat('MMM d, yyyy')
                                          .format(_endSaleDate!)
                                      : 'Not set',
                                ),
                                onTap: () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile(
                          title: const Text('Active'),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTicket,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startSaleDate ?? DateTime.now()
          : _endSaleDate ??
              (_startSaleDate?.add(const Duration(days: 1)) ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startSaleDate = picked;
          if (_endSaleDate != null && _endSaleDate!.isBefore(_startSaleDate!)) {
            _endSaleDate = null;
          }
        } else {
          _endSaleDate = picked;
        }
      });
    }
  }
}
