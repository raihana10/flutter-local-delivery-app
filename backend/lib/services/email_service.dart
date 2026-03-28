import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

/// Envoie des e-mails via [Resend](https://resend.com) si [resendApiKey] est défini.
/// Sinon, journalise uniquement (aucune erreur bloquante).
class EmailService {
  EmailService({
    required this.resendApiKey,
    required this.fromAddress,
    this.adminEmails = const [],
  });

  final String? resendApiKey;
  final String fromAddress;
  final List<String> adminEmails;

  bool get _enabled =>
      resendApiKey != null &&
      resendApiKey!.isNotEmpty &&
      fromAddress.isNotEmpty;

  Future<void> sendToUser({
    required String to,
    required String subject,
    required String html,
  }) async {
    if (!_enabled) {
      print('[EmailService] (désactivé) → $to : $subject');
      return;
    }
    await _postResend(toSingle: to, subject: subject, html: html);
  }

  Future<void> notifyAdmins({
    required String subject,
    required String html,
  }) async {
    if (adminEmails.isEmpty) {
      print('[EmailService] Définissez ADMIN_NOTIFICATION_EMAILS dans le .env du backend.');
      return;
    }
    if (!_enabled) {
      print('[EmailService] (désactivé) → admins ($subject)');
      return;
    }
    final to = adminEmails.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (to.isEmpty) return;
    await _postResend(recipients: to, subject: subject, html: html);
  }

  Future<void> _postResend({
    List<String>? recipients,
    String? toSingle,
    required String subject,
    required String html,
  }) async {
    final List<String> toList;
    if (recipients != null && recipients.isNotEmpty) {
      toList = recipients;
    } else if (toSingle != null) {
      toList = [toSingle];
    } else {
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': fromAddress,
          'to': toList,
          'subject': subject,
          'html': html,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        print('[EmailService] Envoyé → ${toList.join(", ")} : $subject');
      } else {
        print('[EmailService] Resend ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      print('[EmailService] Erreur: $e');
    }
  }

  static EmailService fromEnv() {
    final env = DotEnv(includePlatformEnvironment: true)..load();
    final admins = (env['ADMIN_NOTIFICATION_EMAILS'] ?? '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return EmailService(
      resendApiKey: env['RESEND_API_KEY'],
      fromAddress: env['EMAIL_FROM'] ?? '',
      adminEmails: admins,
    );
  }
}
