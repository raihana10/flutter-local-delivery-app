import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  // Charger .env
  DotEnv env = DotEnv(includePlatformEnvironment: true)..load();
  
  final smtpHost = env['SMTP_HOST'] ?? '';
  final smtpPort = int.tryParse(env['SMTP_PORT'] ?? '587') ?? 587;
  final smtpUser = env['SMTP_USER'] ?? '';
  final smtpPass = env['SMTP_PASS'] ?? '';
  final fromAddress = env['EMAIL_FROM'] ?? '';

  print('Testing SMTP configuration:');
  print('Host: $smtpHost');
  print('Port: $smtpPort');
  print('User: $smtpUser');
  print('Password: ${smtpPass.substring(0, 4)}...');

  try {
    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: smtpUser,
      password: smtpPass,
      allowInsecure: true, // Pour le test
    );

    final message = Message()
      ..from = Address(fromAddress)
      ..recipients.add('elbarkoukialae@gmail.com')
      ..subject = 'Test Email'
      ..html = '<h1>Test</h1><p>This is a test email</p>';

    final sendReport = await send(message, smtpServer);
    print('Email sent successfully!');
  } catch (e) {
    print('Error: $e');
  }
}