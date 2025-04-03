import 'package:emailjs/emailjs.dart' as emailjs;

class EmailService {
  // Replace these with your EmailJS credentials
  static const String _serviceId = 'service_rnqw837';
  static const String _templateId = 'template_j2wfrk8';
  static const String _userId = '5fjmaV5FkkNfp8hPI';
  static const String _accessToken = 'cEpYXjMRXADl_kVV8aEOI';

  Future<void> sendInvitationEmail({
    required String toEmail,
    required String invitationToken,
  }) async {
    try {
      final invitationLink =
          'https://events360adminpanel.vercel.app/#/member_signup?token=$invitationToken';

      final templateParams = {
        'email': toEmail,
        'invitation_link': invitationLink,
        'user_subject': 'Invitation to join Events360 Organization'
      };

      await emailjs.send(
        _serviceId,
        _templateId,
        templateParams,
        const emailjs.Options(
          publicKey: _userId,
          privateKey: _accessToken,
        ),
      );
    } catch (e) {
      throw Exception('Failed to send invitation email: $e');
    }
  }
}
