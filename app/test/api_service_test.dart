import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_arena/app/data/providers/api_service.dart';

void main() {
  group('ApiService.buildUri', () {
    test('joins base, path and query parameters', () {
      final api = ApiService(baseUrl: 'http://10.0.2.2:5000/api');
      final uri = api.buildUri('/questions', {
        'category': 'science',
        'difficulty': 'easy',
        'count': '10',
      });
      expect(
        uri.toString(),
        'http://10.0.2.2:5000/api/questions?category=science&difficulty=easy&count=10',
      );
    });

    test('normalizes a path without leading slash', () {
      final api = ApiService(baseUrl: 'http://localhost:5000/api');
      expect(api.buildUri('categories').toString(),
          'http://localhost:5000/api/categories');
    });

    test('works without query parameters', () {
      final api = ApiService(baseUrl: 'https://quiz.example.com/api');
      expect(api.buildUri('/auth/me').toString(),
          'https://quiz.example.com/api/auth/me');
    });

    test('encodes special characters in query values', () {
      final api = ApiService(baseUrl: 'http://localhost:5000/api');
      final uri = api.buildUri('/questions', {'category': 'a b'});
      expect(uri.queryParameters['category'], 'a b');
      // Dart's Uri encodes spaces in query values as '+' (form encoding).
      expect(uri.toString(), contains('category=a+b'));
    });

    test('dynamic path segments are preserved', () {
      final api = ApiService(baseUrl: 'http://localhost:5000/api');
      expect(api.buildUri('/users/abc123').toString(),
          'http://localhost:5000/api/users/abc123');
    });
  });
}
