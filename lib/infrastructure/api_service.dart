// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as shelf_io;
// import 'package:shelf_router/shelf_router.dart' as shelf_router;
// import 'package:supabase_flutter/supabase_flutter.dart';

// class ApiService {
//   final SupabaseClient _supabase;
//   final int _port;
//   final bool isWeb;

//   ApiService({
//     required SupabaseClient supabase,
//     required int port,
//     this.isWeb = false,
//   })  : _supabase = supabase,
//         _port = port;

//   Future<void> startServer() async {
//     if (isWeb) {
//       debugPrint('Running in web mode - API server not started');
//       return; // Don't start server in web mode
//     }

//     // Create a router
//     final app = shelf_router.Router();

//     // Define routes
//     app.get('/tickets/<eventId>', _getTicketsHandler);
//     app.post('/purchase', _purchaseHandler);
//     app.get('/validate-key', _validateApiKeyHandler);

//     // Create a pipeline with middleware
//     final handler = const Pipeline()
//         .addMiddleware(logRequests())
//         .addMiddleware(_corsMiddleware())
//         .addHandler(app.call);

//     // Desktop platform server initialization
//     await shelf_io.serve(
//       handler,
//       InternetAddress.anyIPv4,
//       _port,
//     );

//     debugPrint('API server started on port $_port');
//   }

//   // Handler for ticket retrieval
//   Future<Response> _getTicketsHandler(Request request, String eventId) async {
//     try {
//       final response = await _supabase
//           .from('tickets')
//           .select()
//           .eq('event_id', eventId)
//           .eq('is_active', true);

//       return Response.ok(
//         jsonEncode(response),
//         headers: {'Content-Type': 'application/json'},
//       );
//     } on Exception catch (e) {
//       debugPrint('Error fetching tickets: $e');
//       return Response.internalServerError(
//         body: jsonEncode({'error': 'Failed to fetch tickets'}),
//         headers: {'Content-Type': 'application/json'},
//       );
//     }
//   }

//   // Handler for ticket purchase
//   Future<Response> _purchaseHandler(Request request) async {
//     try {
//       final payload = jsonDecode(await request.readAsString());
//       final ticketId = payload['ticketId'];
//       final quantity = int.tryParse(payload['quantity'].toString());
//       final organizationId = payload['organizationId'];

//       if (ticketId == null || quantity == null || organizationId == null) {
//         return Response(400,
//             body: jsonEncode({'error': 'Missing required fields'}),
//             headers: {'Content-Type': 'application/json'});
//       }

//       final ticketResponse = await _supabase
//           .from('tickets')
//           .select()
//           .eq('id', ticketId)
//           .eq('organization_id', organizationId)
//           .single();

//       final price = double.tryParse(ticketResponse['price'].toString()) ?? 0.0;
//       final amount = (price * quantity * 100).toInt(); // Convert to paise

//       // Create Razorpay order
//       final authString =
//           '${dotenv.env['RAZORPAY_KEY_ID']}:${dotenv.env['RAZORPAY_KEY_SECRET']}';
//       final basicAuth = base64Encode(utf8.encode(authString));

//       final orderResponse = await http.post(
//         Uri.parse('https://api.razorpay.com/v1/orders'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Basic $basicAuth'
//         },
//         body: jsonEncode({
//           'amount': amount,
//           'currency': 'INR',
//           'receipt': 'order_${DateTime.now().millisecondsSinceEpoch}',
//           'partial_payment': false,
//           'notes': {
//             'ticketId': ticketId,
//             'quantity': quantity,
//             'organizationId': organizationId
//           }
//         }),
//       );

//       if (orderResponse.statusCode != 200) {
//         final error = jsonDecode(orderResponse.body);
//         throw Exception('Razorpay error: ${error['error']['description']}');
//       }

//       final orderData = jsonDecode(orderResponse.body);

//       return Response.ok(jsonEncode({
//         'paymentIntent': {
//           'key_id': dotenv.env['RAZORPAY_KEY_ID'],
//           'order_id': orderData['id'],
//           'amount': amount,
//           'currency': 'INR',
//           'name': ticketResponse['name'],
//           'description': '${quantity}x ${ticketResponse['name']}',
//           'prefill': {'contact': '', 'email': ''}
//         }
//       }));
//     } on Exception catch (e) {
//       debugPrint('Payment error: $e');
//       return Response.internalServerError(
//         body: jsonEncode({'error': e.toString()}),
//       );
//     }
//   }

//   // Handler for API key validation
//   Future<Response> _validateApiKeyHandler(Request request) async {
//     try {
//       final apiKey = request.headers['x-api-key'];
//       if (apiKey == null) {
//         return Response(401,
//             body: jsonEncode({'error': 'API key is required'}),
//             headers: {'Content-Type': 'application/json'});
//       }

//       // Check if the API key exists and is not expired
//       final keyData = await _supabase
//           .from('widget_keys')
//           .select('organization_id, event_id, expires_at')
//           .eq('api_key', apiKey)
//           .single();

//       final expiresAt = DateTime.parse(keyData['expires_at']);

//       if (expiresAt.isBefore(DateTime.now())) {
//         // Log the attempt to use expired key
//         await _supabase.from('security_logs').insert({
//           'event_type': 'expired_key_use',
//           'api_key': apiKey,
//           'ip_address': request.headers['x-forwarded-for'] ?? 'unknown',
//           'timestamp': DateTime.now().toIso8601String(),
//         });

//         return Response(401,
//             body: jsonEncode({'error': 'API key has expired'}),
//             headers: {'Content-Type': 'application/json'});
//       }

//       // Return the organization ID associated with this key
//       return Response.ok(
//         jsonEncode({
//           'organizationId': keyData['organization_id'],
//           'eventId': keyData['event_id'],
//         }),
//         headers: {'Content-Type': 'application/json'},
//       );
//     } on Exception catch (e) {
//       // Log failed validation attempts
//       try {
//         await _supabase.from('security_logs').insert({
//           'event_type': 'invalid_key_attempt',
//           'api_key': request.headers['x-api-key'] ?? 'not_provided',
//           'ip_address': request.headers['x-forwarded-for'] ?? 'unknown',
//           'error': e.toString(),
//           'timestamp': DateTime.now().toIso8601String(),
//         });
//       } on Exception catch (_) {
//         // Silently continue if logging fails
//       }

//       return Response(401,
//           body: jsonEncode({'error': 'Invalid API key'}),
//           headers: {'Content-Type': 'application/json'});
//     }
//   }

//   // CORS middleware
//   // Improve CORS middleware to handle preflight requests properly
//   Middleware _corsMiddleware() {
//     return (Handler innerHandler) {
//       return (Request request) async {
//         // Handle preflight OPTIONS requests
//         if (request.method == 'OPTIONS') {
//           return Response.ok('', headers: {
//             'Access-Control-Allow-Origin': '*',
//             'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
//             'Access-Control-Allow-Headers':
//                 'X-API-Key, Content-Type, Authorization',
//             'Access-Control-Max-Age': '86400',
//           });
//         }

//         // Process the actual request
//         final response = await innerHandler(request);

//         // Add CORS headers to all responses
//         return response.change(headers: {
//           ...response.headers,
//           'Access-Control-Allow-Origin': '*',
//           'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
//           'Access-Control-Allow-Headers':
//               'X-API-Key, Content-Type, Authorization',
//         });
//       };
//     };
//   }

//   // Add a middleware for centralized error handling
//   Middleware _errorHandlingMiddleware() {
//     return (Handler innerHandler) {
//       return (Request request) async {
//         try {
//           // Process the request normally
//           return await innerHandler(request);
//         } on Exception catch (e) {
//           // Log the error with context
//           debugPrint('API Error: ${e.toString()}');
//           debugPrint('Request path: ${request.url.path}');
//           debugPrint('Request method: ${request.method}');

//           // Log to database for monitoring
//           try {
//             await _supabase.from('error_logs').insert({
//               'error': e.toString(),
//               'path': request.url.path,
//               'method': request.method,
//               'timestamp': DateTime.now().toIso8601String(),
//               'headers': request.headers.toString(),
//             });
//           } on Exception catch (_) {
//             // Continue even if logging fails
//           }

//           // Return appropriate error response
//           if (e is PostgrestException) {
//             return Response(400,
//                 body: jsonEncode({
//                   'error': 'Database error',
//                   'message': e.message,
//                   'code': e.code
//                 }),
//                 headers: {'Content-Type': 'application/json'});
//           }

//           return Response.internalServerError(
//               body: jsonEncode({
//                 'error': 'Internal server error',
//                 'requestId': DateTime.now().millisecondsSinceEpoch.toString()
//               }),
//               headers: {'Content-Type': 'application/json'});
//         }
//       };
//     };
//   }
// }
