import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Remplacez par VOTRE clé API
  const apiKey = 're_3EHnLw3z_G2PhN2R4FwE51QrvNTuLoq8B';
  const from = 'onboarding@resend.dev';
  
  // Test avec 2 emails
  final emails = [
    'elbarkoukialae@gmail.com',
    'elbarkoukialaez@gmail.com'
  ];
  
  print('Test envoi à ${emails.length} destinataires:');
  print('Emails: $emails');
  
  try {
    final response = await http.post(
      Uri.parse('https://api.resend.com/emails'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'from': from,
        'to': emails,
        'subject': 'Test multi-destinataires',
        'html': '<p>Test avec ${emails.length} destinataires</p>',
      }),
    );
    
    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✅ Succès !');
    } else {
      print('❌ Échec: ${response.body}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}