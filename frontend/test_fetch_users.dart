import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final response = await dio.get(
      'http://localhost:8084/admin/users/livreurs', 
      options: Options(headers: {'x-admin-id': '1'})
    );
    print('Livreurs:');
    print(response.data);
    
    final response2 = await dio.get(
      'http://localhost:8084/admin/users/businesses', 
      options: Options(headers: {'x-admin-id': '1'})
    );
    print('\nBusinesses:');
    print(response2.data);
  } catch (e) {
    print('Error: $e');
  }
}
