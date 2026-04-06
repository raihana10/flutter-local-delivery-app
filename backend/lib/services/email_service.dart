import 'dart:convert';
import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Envoie des e-mails via SMTP.
class EmailService {
  EmailService({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUser,
    required this.smtpPass,
    required this.fromAddress,
    this.adminEmails = const [],
  });

  final String smtpHost;
  final int smtpPort;
  final String smtpUser;
  final String smtpPass;
  final String fromAddress;
  final List<String> adminEmails;

  bool get _enabled =>
      smtpHost.isNotEmpty &&
      smtpPort > 0 &&
      smtpUser.isNotEmpty &&
      smtpPass.isNotEmpty &&
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
    await _sendSmtp(toSingle: to, subject: subject, html: html);
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
    await _sendSmtp(recipients: to, subject: subject, html: html);
  }

  Future<void> _sendSmtp({
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
      final smtpServer = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: smtpUser,
        password: smtpPass,
        ignoreBadCertificate: true,
        ssl: smtpPort == 465,
        allowInsecure: smtpPort == 587,
      );

      final message = Message()
        ..from = Address(fromAddress)
        ..recipients.addAll(toList)
        ..subject = subject
        ..html = html;

      final sendReport = await send(message, smtpServer);
      print('[EmailService] Envoyé → ${toList.join(", ")} : $subject');
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
      smtpHost: env['SMTP_HOST'] ?? '',
      smtpPort: int.tryParse(env['SMTP_PORT'] ?? '587') ?? 587,
      smtpUser: env['SMTP_USER'] ?? '',
      smtpPass: env['SMTP_PASS'] ?? '',
      fromAddress: env['EMAIL_FROM'] ?? '',
      adminEmails: admins,
    );
  }
}
