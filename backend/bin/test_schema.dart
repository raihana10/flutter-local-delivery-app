import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    // We can GET a local user to see the exact error by throwing an explicitly bad insert!
    print('Testing error format...');
  } catch (e) {
    print(e);
  }
}

