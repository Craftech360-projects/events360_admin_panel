import 'dart:io';

import 'package:events360_admin/infrastructure/email_service.dart';
import 'package:events360_admin/infrastructure/user_role_service.dart';
import 'package:events360_admin/models/event.dart';
import 'package:events360_admin/models/member.dart';
import 'package:events360_admin/models/organization.dart';
import 'package:events360_admin/models/permission.dart';
import 'package:events360_admin/models/role.dart';
import 'package:events360_admin/models/speaker.dart';
import 'package:events360_admin/models/sponsor.dart';
import 'package:events360_admin/models/ticket.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WidgetCode {
  final String apiKey;
  final DateTime expiresAt;

  WidgetCode({required this.apiKey, required this.expiresAt});
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static late final SupabaseClient _client;
  static String? _organizationId;
  static const String _orgIdKey = 'organization_id';
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static String? get organizationId => _organizationId;

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: "https://uqnquoamrxvidtwrkdsn.supabase.co",
      anonKey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxbnF1b2Ftcnh2aWR0d3JrZHNuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE3ODUxNjAsImV4cCI6MjA1NzM2MTE2MH0.CCHMq2B-5Q57kIV5T0J5HD4i2fRNl46TtYArnQczMKQ",
      postgrestOptions: const PostgrestClientOptions(schema: 'admin'),
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'authorization, x-client-info, apikey, content-type',
      },
    );

    _client = Supabase.instance.client;
    await _loadStoredSession();
    await loadOrganizationIdFromStorage();
  }

  static Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString(_authTokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);

      if (authToken != null && refreshToken != null) {
        await _client.auth.setSession(refreshToken);
      }
    } on Exception catch (e) {
      debugPrint('Error loading stored session: $e');
    }
  }

  static Future<void> _saveSession(Session session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, session.accessToken);
      await prefs.setString(_refreshTokenKey, session.refreshToken!);
    } on Exception catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_refreshTokenKey);
    await _saveOrganizationId(null);
    await _client.auth.signOut();
    UserRoleService.clear();
  }

  // Make the method accessible from outside the class
  static Future<void> loadOrganizationIdFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _organizationId = prefs.getString(_orgIdKey);
    } on Exception catch (e) {
      debugPrint('Error loading organization ID from storage: $e');
    }
  }

  static Future<void> _saveOrganizationId(String? orgId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (orgId != null) {
        await prefs.setString(_orgIdKey, orgId);
      } else {
        await prefs.remove(_orgIdKey);
      }
      _organizationId = orgId;
    } on Exception catch (e) {
      debugPrint('Error saving organization ID to storage: $e');
    }
  }

  SupabaseClient get client => _client;

  /// *** -------------------------------------------------------------------------- ***
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      // Sign out any existing session first to avoid token conflicts
      await _client.auth.signOut();

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await _saveSession(response.session!);

        // Verify if user is an admin and get organization ID
        final memberCheck = await _client
            .from('members')
            .select('organization_id')
            .eq('auth_id', response.user!.id)
            .maybeSingle();

        if (memberCheck == null) {
          await signOut();
          throw 'Access denied. Only authorized members can access this app.';
        }

        final orgId = memberCheck['organization_id'];
        await _saveOrganizationId(orgId);
      }

      return response;
    } on Exception catch (e) {
      debugPrint('Sign in error: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw 'Invalid email or password.';
      }
      throw 'Login failed. Please try again.';
    }
  }

  Future<bool> isAuthenticated() async {
    final session = _client.auth.currentSession;
    return session != null;
  }

  // Event methods with admin filtering ✅
  Future<List<Map<String, dynamic>>> getEvents() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('events')
          .select()
          .eq('organization_id', _organizationId!)
          .order('start_date');
      return response;
    } on Exception catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

/* -------------------------------------------------------------------------- */
  // Speaker methods with organization filtering
  Future<List<Speaker>> getOrganizationSpeakers(String organizationId) async {
    try {
      final response = await _client
          .from('speakers')
          .select()
          .eq('organization_id', organizationId)
          .order('name');
      return response.map((json) => Speaker.fromJson(json)).toList();
    } on Exception catch (e) {
      debugPrint('Error fetching speakers: $e');
      return [];
    }
  }

  Future<Speaker> addSpeaker(Speaker speaker) async {
    try {
      final response = await _client
          .from('speakers')
          .insert(speaker.toJson())
          .select()
          .single();

      return Speaker.fromJson(response);
    } catch (e) {
      debugPrint('Error adding speaker: $e');
      rethrow;
    }
  }

  Future<void> updateSpeaker(Speaker speaker) async {
    try {
      await _client
          .from('speakers')
          .update(speaker.toJson())
          .eq('id', speaker.id)
          .eq('organization_id', speaker.organizationId);
    } catch (e) {
      debugPrint('Error updating speaker: $e');
      rethrow;
    }
  }

  Future<void> deleteSpeaker(String speakerId, String organizationId) async {
    try {
      await _client
          .from('speakers')
          .delete()
          .eq('id', speakerId)
          .eq('organization_id', organizationId);
    } catch (e) {
      debugPrint('Error deleting speaker: $e');
      rethrow;
    }
  }

  // Sponsor methods with organization filtering
  Future<List<Sponsor>> getOrganizationSponsors(String organizationId) async {
    try {
      final response = await _client
          .from('sponsors')
          .select()
          .eq('organization_id', organizationId)
          .order('name');
      return response.map((json) => Sponsor.fromJson(json)).toList();
    } on Exception catch (e) {
      debugPrint('Error fetching sponsors: $e');
      return [];
    }
  }

  Future<Sponsor> addSponsor(Sponsor sponsor) async {
    try {
      final response = await _client
          .from('sponsors')
          .insert(sponsor.toJson())
          .select()
          .single();

      return Sponsor.fromJson(response);
    } catch (e) {
      debugPrint('Error adding sponsor: $e');
      rethrow;
    }
  }

  Future<void> updateSponsor(Sponsor sponsor) async {
    try {
      await _client
          .from('sponsors')
          .update(sponsor.toJson())
          .eq('id', sponsor.id)
          .eq('organization_id', sponsor.organizationId);
    } catch (e) {
      debugPrint('Error updating sponsor: $e');
      rethrow;
    }
  }

  Future<void> deleteSponsor(String sponsorId, String organizationId) async {
    try {
      await _client
          .from('sponsors')
          .delete()
          .eq('id', sponsorId)
          .eq('organization_id', organizationId);
    } catch (e) {
      debugPrint('Error deleting sponsor: $e');
      rethrow;
    }
  }

// Speaker methods with admin filtering ✅
  Future<List<Map<String, dynamic>>> getSpeakers() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('speakers')
          .select()
          .eq('organization_id', _organizationId!)
          .order('name');
      return response;
    } on Exception catch (e) {
      debugPrint('Error fetching speakers: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSpeaker(int id) async {
    try {
      final response =
          await _client.from('speakers').select().eq('id', id).single();
      return response;
    } on Exception catch (e) {
      debugPrint('Error fetching speaker: $e');
      return null;
    }
  }

/* -------------------------------------------------------------------------- */
  // Event management methods
  Future<List<Event>> getOrganizationEvents(String organizationId) async {
    try {
      final response = await _client
          .from('events')
          .select('*, agenda_items(*)')
          .eq('organization_id', organizationId)
          .order('start_date');
      return response.map((json) => Event.fromJson(json)).toList();
    } on Exception catch (e) {
      debugPrint('Error fetching events: $e');
      return [];
    }
  }

  Future<Event> createEvent(Event event) async {
    try {
      final response = await _client
          .from('events')
          .insert(event.toJson())
          .select('*, agenda_items(*)')
          .single();
      return Event.fromJson(response);
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _client
          .from('events')
          .update(event.toJson())
          .eq('id', event.id)
          .eq('organization_id', event.organizationId);

      // Update agenda items
      await _client.from('agenda_items').delete().eq('event_id', event.id);

      if (event.agendaItems.isNotEmpty) {
        await _client.from('agenda_items').insert(
              event.agendaItems
                  .map((item) => {
                        ...item.toJson(),
                        'event_id': event.id,
                      })
                  .toList(),
            );
      }

      // Update event sponsors
      await _client.from('event_sponsors').delete().eq('event_id', event.id);

      if (event.sponsorIds.isNotEmpty) {
        await _client.from('event_sponsors').insert(
              event.sponsorIds
                  .map((sponsorId) => {
                        'event_id': event.id,
                        'sponsor_id': sponsorId,
                      })
                  .toList(),
            );
      }
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId, String organizationId) async {
    try {
      await _client
          .from('events')
          .delete()
          .eq('id', eventId)
          .eq('organization_id', organizationId);
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPastEvents() async {
    try {
      final response = await _client
          .from('past_events')
          .select()
          .order('end_date', ascending: false);

      return response;
    } on Exception catch (e) {
      debugPrint('Error fetching past events: $e');
      return [];
    }
  }

  // Add this method to the SupabaseService class
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (_organizationId == null) {
      return {
        'eventCount': 0,
        'speakerCount': 0,
        'sponsorCount': 0,
        'ticketCount': 0,
      };
    }

    try {
      final eventsResponse = await _client
          .from('events')
          .select()
          .eq('organization_id', _organizationId!);

      final speakersResponse = await _client
          .from('speakers')
          .select()
          .eq('organization_id', _organizationId!);

      final sponsorsResponse = await _client
          .from('sponsors')
          .select()
          .eq('organization_id', _organizationId!);

      final ticketsResponse = await _client
          .from('tickets')
          .select()
          .eq('organization_id', _organizationId!);

      // Convert responses to counts
      final eventCount = eventsResponse.length;
      final speakerCount = speakersResponse.length;
      final sponsorCount = sponsorsResponse.length;
      final ticketCount = ticketsResponse.length;

      return {
        'eventCount': eventCount,
        'speakerCount': speakerCount,
        'sponsorCount': sponsorCount,
        'ticketCount': ticketCount,
      };
    } on Exception catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      return {
        'eventCount': 0,
        'speakerCount': 0,
        'sponsorCount': 0,
        'ticketCount': 0,
      };
    }
  }

// Organization methods
  Future<AuthResponse> signUpWithOrganization({
    required String email,
    required String password,
    required String username,
    required String contactPhone,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          final organization = await createOrganization(
            Organization(
              username: username,
              contactEmail: email,
              contactPhone: contactPhone,
            ),
          );

          // Create member record with admin role
          await _client.from('members').insert({
            'auth_id': response.user!.id,
            'organization_id': organization.id,
            'role_id': await _getAdminRoleId(),
            'email': email,
            'first_name': username,
            'is_active': true,
          });

          return response;
        } on Exception catch (e) {
          debugPrint('Error creating organization/member record: $e');
          // Add stack trace for better debugging
          debugPrint(StackTrace.current.toString());
          throw 'Organization setup failed. Please contact support.';
        }
      }

      return response;
    } catch (e) {
      if (e.toString().contains('unique constraint')) {
        throw 'Email already registered. Please sign in instead.';
      }
      debugPrint('Registration failed: ${e.toString()}');
      throw 'Registration failed: ${e.toString()}';
    }
  }

  Future<Organization> createOrganization(Organization organization) async {
    try {
      final response = await _client
          .from('organizations')
          .insert(organization.toJson())
          .select()
          .single();

      return Organization.fromJson(response);
    } catch (e) {
      debugPrint('Error creating organization: $e');
      rethrow;
    }
  }

  Future<String> _getAdminRoleId() async {
    final response =
        await _client.from('roles').select().eq('name', 'admin').single();
    return response['id'];
  }

  Future<Organization?> getOrganization(String id) async {
    try {
      final response =
          await _client.from('organizations').select().eq('id', id).single();
      return Organization.fromJson(response);
    } on Exception catch (e) {
      debugPrint('Error fetching organization: $e');
      return null;
    }
  }

  Future<void> updateOrganization(Organization organization) async {
    try {
      await _client
          .from('organizations')
          .update(organization.toJson())
          .eq('id', organization.id);
    } catch (e) {
      debugPrint('Error updating organization: $e');
      rethrow;
    }
  }

  // Member methods
  Future<void> inviteMember(Member member) async {
    try {
      // Generate a unique invitation token
      final invitationToken = const Uuid().v4();

      // Create member record with pending status
      final memberData = {
        ...member.toJson(),
        'invitation_token': invitationToken,
        'invitation_sent_at': DateTime.now().toIso8601String(),
        'is_active': false,
      };

      await _client.from('members').insert(memberData);

      // Send invitation email using EmailJS
      final emailService = EmailService();
      await emailService.sendInvitationEmail(
        toEmail: member.email,
        invitationToken: invitationToken,
      );
    } catch (e) {
      debugPrint('Error inviting member: $e');
      rethrow;
    }
  }

  // Add method to verify invitation token
  Future<Member?> verifyInvitationToken(String token) async {
    final response = await _client
        .from('members')
        .select()
        .eq('invitation_token', token)
        .single();

    return Member.fromJson(response);
  }

  // Add method to complete member signup
  Future<AuthResponse> completeMemberSignup({
    required String email,
    required String password,
    required String invitationToken,
    String? userName,
  }) async {
    final member = await verifyInvitationToken(invitationToken);
    if (member == null) {
      throw Exception('Invalid invitation token');
    }

    // Create auth user
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      throw Exception('Failed to create user');
    }

    // Step 1: Update member record with new data
    await _client.from('members').update({
      'auth_id': authResponse.user!.id,
      'username': userName,
      'email': email,
      'invitation_accepted_at': DateTime.now().toIso8601String(),
      'is_active': true,
    }).eq('invitation_token', invitationToken);

    // Step 2: Clear the invitation token in a separate update
    await _client.from('members').update({
      'invitation_token': null,
    }).eq('invitation_token', invitationToken);

    return authResponse;
  }

  Future<List<Member>> getOrganizationMembers(String organizationId) async {
    try {
      final response = await _client
          .from('members')
          .select()
          .eq('organization_id', organizationId);
      return response.map((json) => Member.fromJson(json)).toList();
    } on Exception catch (e) {
      debugPrint('Error fetching organization members: $e');
      return [];
    }
  }

  Future<void> updateMember(Member member) async {
    try {
      await _client.from('members').update(member.toJson()).eq('id', member.id);
    } catch (e) {
      debugPrint('Error updating member: $e');
      rethrow;
    }
  }

  Future<void> deleteMember(String memberId) async {
    try {
      await _client.from('members').delete().eq('id', memberId);
    } catch (e) {
      debugPrint('Error deleting member: $e');
      rethrow;
    }
  }

  // Role and Permission methods
  Future<List<Role>> getRoles() async {
    try {
      final response = await _client.from('roles').select();
      return response.map((json) => Role.fromJson(json)).toList();
    } on Exception catch (e) {
      debugPrint('Error fetching roles: $e');
      return [];
    }
  }

  Future<List<Permission>> getPermissions() async {
    try {
      final response = await _client.from('permissions').select();
      return response.map((json) => Permission.fromJson(json)).toList();
    } on Exception catch (e) {
      debugPrint('Error fetching permissions: $e');
      return [];
    }
  }

  Future<List<String>> getRolePermissions(String roleId) async {
    try {
      final response = await _client
          .from('role_permissions')
          .select('permission_id')
          .eq('role_id', roleId);
      return response
          .map<String>((json) => json['permission_id'] as String)
          .toList();
    } on Exception catch (e) {
      debugPrint('Error fetching role permissions: $e');
      return [];
    }
  }

  Future<void> addRolePermission(String roleId, String permissionId) async {
    try {
      await _client.from('role_permissions').insert({
        'role_id': roleId,
        'permission_id': permissionId,
      });
    } catch (e) {
      debugPrint('Error adding role permission: $e');
      rethrow;
    }
  }

  Future<void> removeRolePermission(String roleId, String permissionId) async {
    try {
      await _client
          .from('role_permissions')
          .delete()
          .eq('role_id', roleId)
          .eq('permission_id', permissionId);
    } catch (e) {
      debugPrint('Error removing role permission: $e');
      rethrow;
    }
  }

  // Ticket management methods ------------------><-------------------
  Future<WidgetCode> generateTicketWidgetCode(String eventId) async {
    try {
      debugPrint('Starting widget code generation for event: $eventId');

      // Generate a secure API key
      final uuid = const Uuid().v4();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final apiKey = '$uuid-$timestamp';
      debugPrint('Generated API key: $apiKey');
      debugPrint('Organization ID: $_organizationId');

      // Store the API key in the database with the event ID
      await _client.from('widget_keys').insert({
        'api_key': apiKey,
        'event_id': eventId,
        'organization_id': _organizationId,
        'environment': kReleaseMode ? 'production' : 'local',
        'expires_at':
            DateTime.now().add(const Duration(days: 365)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Widget key stored in database');

      return WidgetCode(
        apiKey: apiKey,
        expiresAt: DateTime.now().add(const Duration(days: 365)),
      );
    } catch (e) {
      debugPrint('Error generating widget code: $e');
      rethrow;
    }
  }

  Future<WidgetCode?> getTicketWidgetCode(String eventId) async {
    try {
      final response = await _client
          .from('widget_keys')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return WidgetCode(
        apiKey: response['api_key'],
        expiresAt: DateTime.parse(response['expires_at']),
      );
    } on Exception catch (e) {
      debugPrint('Error getting widget code: $e');
      rethrow;
    }
  }

  Future<List<Ticket>> getUnpublishedTickets() async {
    try {
      // First get all event IDs that have widget keys
      final publishedEventIds = await _client
          .from('widget_keys')
          .select('event_id')
          .eq('organization_id', _organizationId!);

      // Get the list of event IDs
      final eventIds =
          publishedEventIds.map((row) => row['event_id'] as String).toList();

      // Then get tickets for events that don't have widget keys
      final response = await _client
          .from('tickets')
          .select('''
            *,
            events!inner (
              id,
              title
            )
          ''')
          .eq('organization_id', _organizationId!)
          .not('event_id', 'in', '(${eventIds.join(',')})')
          .order('created_at', ascending: false);

      return response.map((json) => Ticket.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching unpublished tickets: $e');
      rethrow;
    }
  }

  Future<List<Ticket>> getAllTickets() async {
    if (_organizationId == null) return [];

    try {
      final response = await _client
          .from('tickets')
          .select('''
            *,
            events (
              id,
              title,
              start_date,
              end_date,
              venue
            )
          ''')
          .eq('organization_id', _organizationId!)
          .order('created_at', ascending: false);

      return response.map((json) => Ticket.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching all tickets: $e');
      rethrow;
    }
  }

  Future<List<Ticket>> getEventTicketsByType(
      String eventId, String ticketType) async {
    try {
      final response = await _client
          .from('tickets')
          .select()
          .eq('event_id', eventId)
          .eq('ticket_type', ticketType)
          .order('tier_order');
      return response.map((json) => Ticket.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching tickets by type: $e');
      rethrow;
    }
  }

  Future<void> updateTicketAvailability(
      String ticketId, int newQuantity) async {
    try {
      await _client
          .from('tickets')
          .update({'available_quantity': newQuantity}).eq('id', ticketId);
    } catch (e) {
      debugPrint('Error updating ticket availability: $e');
      rethrow;
    }
  }

  Future<Ticket> createTicket(Ticket ticket) async {
    try {
      final response = await _client
          .from('tickets')
          .insert(ticket.toJson())
          .select()
          .single();
      return Ticket.fromJson(response);
    } catch (e) {
      debugPrint('Error creating ticket: $e');
      rethrow;
    }
  }

  Future<void> updateTicket(Ticket ticket) async {
    try {
      await _client
          .from('tickets')
          .update(ticket.toJson())
          .eq('id', ticket.id ?? '')
          .eq('event_id', ticket.eventId ?? '');
    } catch (e) {
      debugPrint('Error updating ticket: $e');
      rethrow;
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    try {
      await _client.from('tickets').delete().eq('id', ticketId);
    } catch (e) {
      debugPrint('Error deleting ticket: $e');
      rethrow;
    }
  }

  Future<String?> uploadEventBanner(dynamic imageFile) async {
    try {
      final fileName = '${const Uuid().v4()}.jpg';
      final path = 'banners/$fileName';

      if (kIsWeb) {
        // For web platform
        if (imageFile is XFile) {
          final bytes = await imageFile.readAsBytes();
          await _client.storage.from('event-banners').uploadBinary(path, bytes);
        }
      } else {
        // For mobile platforms
        if (imageFile is String) {
          final file = File(imageFile);
          final bytes = await file.readAsBytes();
          await _client.storage.from('event-banners').uploadBinary(path, bytes);
        }
      }

      final imageUrl = _client.storage.from('event-banners').getPublicUrl(path);

      return imageUrl;
    } on Exception catch (e) {
      debugPrint('Error uploading event banner: $e');
      return null;
    }
  }
}
