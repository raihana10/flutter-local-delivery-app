import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() async {
  // Charger .env
  final env = DotEnv(includePlatformEnvironment: true)..load();
  
  final smtpUser = env['SMTP_USER'] ?? '';
  final smtpPass = env['SMTP_PASS'] ?? '';
  
  print('Test avec:');
  print('User: $smtpUser');
  print('Pass: ${smtpPass.substring(0, 4)}... (${smtpPass.length} caractères)');
  print('');

  try {
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      port: 587,
      username: smtpUser,
      password: smtpPass,
      allowInsecure: true,
    );

    final message = Message()
      ..from = Address(smtpUser)
      ..recipients.add(smtpUser)
      ..subject = 'Test Email'
      ..html = '<h1>Succès!</h1><p>Le test fonctionne à ${DateTime.now()}</p>';

    print('Envoi en cours...');
    await send(message, smtpServer);
    print('✅ EMAIL ENVOYÉ AVEC SUCCÈS !');
  } catch (e) {
    print('❌ Erreur: $e');
  }
}