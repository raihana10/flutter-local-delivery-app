import 'dart:convert';
import 'dart:io';

void main() async {
  final httpClient = HttpClient();
  final request = await httpClient.post('localhost', 8084, '/admin/notifications');
  request.headers.set('content-type', 'application/json');
  request.headers.set('x-admin-id', '1');
  request.add(utf8.encode(jsonEncode({
    'titre': 'Test',
    'message': 'A test',
    'type': 'Tous'
  })));
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print('Body: ${responseBody}');
  exit(0);
}
